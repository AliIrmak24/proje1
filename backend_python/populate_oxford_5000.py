# backend_python/populate_oxford_5000.py
# Oxford 5000 ve CEFR Seviyeli Kapsamlı Sözlük Entegrasyon Scripti
# A1'den C2'ye kadar 3.000 - 5.000 kelimelik zengin veritabanı oluşturur.

import os
import re
import json
import csv
import io
import sqlite3
import urllib.request
import sys

def main():
    print("=== Oxford 5000 ve CEFR Sözlük Veri Tabanı Yükleyici ===")
    db_path = os.path.join(os.path.dirname(__file__), "sozegitim.db")
    
    # 1. Mevcut DB'deki kelimeleri al (kaliteli olanlar korunsun)
    existing_db_words = {}
    if os.path.exists(db_path):
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        try:
            cur.execute("SELECT word, translation, level, phonetic, meanings FROM dictionary")
            for row in cur.fetchall():
                w = row[0].strip().lower()
                existing_db_words[w] = {
                    "word": row[0],
                    "translation": row[1],
                    "level": row[2].upper() if row[2] else "B1",
                    "phonetic": row[3],
                    "meanings": json.loads(row[4]) if row[4] else []
                }
        except Exception as e:
            print(f"Mevcut DB okunurken not: {e}")
        conn.close()
    print(f"Mevcut DB'de korunan kaliteli kelimeler: {len(existing_db_words)}")

    # 2. Hilal Şengül Oxford 5000 TR Listesi (4,642 kelime)
    print("1/4: Oxford 5000 Türkçe listesi indiriliyor...")
    url_hs = "https://raw.githubusercontent.com/hilalsengul3000/oxford-5000-turkish-dictionary/main/oxford5000.html"
    try:
        req = urllib.request.Request(url_hs, headers={"User-Agent": "Mozilla/5.0"})
        raw_hs = urllib.request.urlopen(req, timeout=20).read().decode("utf-8")
        m = re.search(r"words\s*=\s*(\[.*?\]);", raw_hs, re.DOTALL)
        hs_data = json.loads(m.group(1)) if m else []
        print(f"-> Hilal Şengül listesinden {len(hs_data)} kelime alındı.")
    except Exception as e:
        print(f"Hata (Hilal Sengul): {e}")
        hs_data = []

    # 3. Tyypgzl Oxford 5000 Detayları (Fonetik & Örnek Cümleler)
    print("2/4: Oxford 5000 fonetik ve örnek cümle verileri indiriliyor...")
    url_ty = "https://raw.githubusercontent.com/tyypgzl/Oxford-5000-words/master/full-word.json"
    ty_map = {}
    try:
        req2 = urllib.request.Request(url_ty, headers={"User-Agent": "Mozilla/5.0"})
        ty_data = json.loads(urllib.request.urlopen(req2, timeout=25).read().decode("utf-8"))
        for item in ty_data:
            v = item.get("value", {})
            w = v.get("word", "").strip().lower()
            if w and w not in ty_map:
                ty_map[w] = v
        print(f"-> Tyypgzl veri setinden {len(ty_map)} kelime detayı alındı.")
    except Exception as e:
        print(f"Hata (Tyypgzl): {e}")

    # 4. Ciwga Oxford 3000 Zengin Tanımlar ve Örnek Cümleler
    print("3/4: Ciwga sözlük veri seti indiriliyor...")
    url_ciwga = "https://raw.githubusercontent.com/ciwga/Oxford3000_Vocab/main/oxford3000_vocabulary_with_collocations_and_definitions_datasets.csv"
    ciwga_map = {}
    try:
        req3 = urllib.request.Request(url_ciwga, headers={"User-Agent": "Mozilla/5.0"})
        ciwga_reader = csv.DictReader(io.StringIO(urllib.request.urlopen(req3, timeout=20).read().decode("utf-8")))
        for r in ciwga_reader:
            w = r["Word"].strip().lower()
            if w and w not in ciwga_map:
                ciwga_map[w] = {
                    "translation": r.get("Turkish Translation", "").strip(),
                    "definition": r.get("Definition", "").strip(),
                    "example": r.get("Example Sentence", "").strip(),
                    "pos": r.get("Part of Speech", "").strip()
                }
        print(f"-> Ciwga veri setinden {len(ciwga_map)} zengin tanım alındı.")
    except Exception as e:
        print(f"Hata (Ciwga): {e}")

    # 5. Ekstra İleri Seviye C2 Kelimeleri (Oxford 5000 C1'e kadar olduğundan C2 havuzunu güçlendiriyoruz)
    print("4/4: İleri düzey C2 (Mastery) kelimeleri hazırlanıyor...")
    c2_extra = [
        {"w": "ubiquitous", "tr": "Her yerde bulunan, yaygın", "pos": "sıfat", "def": "Her yerde aynı anda var gibi görünen.", "ex": "Mobile technology is ubiquitous today.", "ph": "/juːˈbɪk.wɪ.təs/"},
        {"w": "ephemeral", "tr": "Geçici, kısa ömürlü", "pos": "sıfat", "def": "Çok kısa süre devam eden durum veya varlık.", "ex": "Fame in the modern age can be ephemeral.", "ph": "/ɪˈfem.ər.əl/"},
        {"w": "paradigm", "tr": "Örüntü, model, paradigma", "pos": "isim", "def": "Bir alandaki temel düşünce ve algı kalıbı.", "ex": "The invention created a new scientific paradigm.", "ph": "/ˈpær.ə.daɪm/"},
        {"w": "serendipity", "tr": "Şans eseri keşif, tesadüfi buluş", "pos": "isim", "def": "Aramadan tesadüfen değerli bir şey bulma şansı.", "ex": "Penicillin was discovered through pure serendipity.", "ph": "/ˌser.ənˈdɪp.ə.ti/"},
        {"w": "anomalous", "tr": "Kuraldışı, olağandışı, anormal", "pos": "sıfat", "def": "Genel kurallardan veya normlardan sapan.", "ex": "The scientists found anomalous data in the experiment.", "ph": "/əˈnɒm.ə.ləs/"},
        {"w": "equivocal", "tr": "Muğlak, iki anlamlı, şüpheli", "pos": "sıfat", "def": "Birden çok anlama çekilebilen, net olmayan ifade.", "ex": "His response was polite but equivocal.", "ph": "/ɪˈkwɪv.ə.kəl/"},
        {"w": "lucid", "tr": "Açık, berrak, anlaşılır", "pos": "sıfat", "def": "Kolayca kavranabilen, parlak ve berrak.", "ex": "She gave a lucid explanation of quantum physics.", "ph": "/ˈluː.sɪd/"},
        {"w": "precipitate", "tr": "Hızlandırmak, tetiklemek", "pos": "fiil", "def": "Bir olayın erkenden ve hızla meydana gelmesine sebep olmak.", "ex": "The scandal precipitated the minister's resignation.", "ph": "/prɪˈsɪp.ɪ.teɪt/"},
        {"w": "assuage", "tr": "Yatıştırmak, dindirmek, hafifletmek", "pos": "fiil", "def": "Acıyı, korkuyu veya endişeyi hafifletmek.", "ex": "The leader tried to assuage the public's fears.", "ph": "/əˈsweɪdʒ/"},
        {"w": "erudite", "tr": "Bilgili, alim, engin bilgi sahibi", "pos": "sıfat", "def": "Kapsamlı okuma ve çalışma sonucu derin bilgi edinen.", "ex": "The professor wrote an erudite treatise on history.", "ph": "/ˈer.ʊ.daɪt/"},
        {"w": "opaque", "tr": "Mat, saydam olmayan, anlaşılması güç", "pos": "sıfat", "def": "Işığı geçirmeyen veya anlaşılması zor olan.", "ex": "The government's motives remained opaque.", "ph": "/oʊˈpeɪk/"},
        {"w": "prodigal", "tr": "Müsrif, savurgan, cömertçe saçan", "pos": "sıfat", "def": "Kaynakları düşüncesizce ve bolca harcayan.", "ex": "His prodigal spending led him into bankruptcy.", "ph": "/ˈprɒd.ɪ.ɡəl/"},
        {"w": "enigma", "tr": "Gizem, muamma, sır", "pos": "isim", "def": "Çözülmesi güç, gizemli durum veya kişi.", "ex": "The origin of the manuscript remains an enigma.", "ph": "/ɪˈnɪɡ.mə/"},
        {"w": "fervid", "tr": "Coşkulu, ateşli, hararetli", "pos": "sıfat", "def": "Aşırı tutku ve coşku sergileyen.", "ex": "He delivered a fervid speech to rally the team.", "ph": "/ˈfɜː.vɪd/"},
        {"w": "placate", "tr": "Yatıştırmak, gönlünü almak", "pos": "fiil", "def": "Kızgın birini sakinleştirmek veya tatmin etmek.", "ex": "They offered refunds to placate angry customers.", "ph": "/pləˈkeɪt/"},
        {"w": "audacious", "tr": "Cüretkar, cesur, küstahça atak", "pos": "sıfat", "def": "Büyük riskler almaya istekli, korkusuz.", "ex": "It was an audacious plan, but it worked.", "ph": "/ɔːˈdeɪ.ʃəs/"},
        {"w": "laudable", "tr": "Övgüye değer, takdire şayan", "pos": "sıfat", "def": "Övgüyü ve takdiri hak eden davranış.", "ex": "Her efforts to help the homeless are truly laudable.", "ph": "/ˈlɔː.də.bəl/"},
        {"w": "pedant", "tr": "Ukala, aşırı kuralcı, şekilci", "pos": "isim", "def": "Küçük ayrıntılara ve kurallara aşırı takılan kimse.", "ex": "A grammar pedant will correct every minor mistake.", "ph": "/ˈped.ənt/"},
        {"w": "vacillate", "tr": "Tereddüt etmek, bocalama yaşamak", "pos": "fiil", "def": "Kararlar veya fikirler arasında gidip gelmek.", "ex": "He vacillated between accepting and declining the offer.", "ph": "/ˈvæs.ə.leɪt/"},
        {"w": "capricious", "tr": "Kaprisli, değişken, sağı solu belli olmayan", "pos": "sıfat", "def": "Ansızın ve sebepsizce davranış değiştiren.", "ex": "The capricious weather ruined our hiking plans.", "ph": "/kəˈprɪʃ.əs/"},
        {"w": "engender", "tr": "Doğurmak, neden olmak, yaratmak", "pos": "fiil", "def": "Bir duyguya, duruma veya sonuca yol açmak.", "ex": "Mutual respect engenders long-lasting trust.", "ph": "/ɪnˈdʒen.dər/"},
        {"w": "loquacious", "tr": "Geveze, çok konuşan", "pos": "sıfat", "def": "Sürekli ve çok konuşma eğiliminde olan.", "ex": "The loquacious host kept the party entertained.", "ph": "/ləˈkweɪ.ʃəs/"},
        {"w": "volatile", "tr": "Değişken, uçucu, istikrarsız", "pos": "sıfat", "def": "Aniden ve tahmin edilemez şekilde değişebilen.", "ex": "The stock market has been exceptionally volatile.", "ph": "/ˈvɒl.ə.taɪl/"},
        {"w": "corroborate", "tr": "Doğrulamak, teyit etmek, kanıtlamak", "pos": "fiil", "def": "Yeni delillerle bir iddiayı desteklemek.", "ex": "Witnesses corroborated the victim's account.", "ph": "/kəˈrɒb.ə.reɪt/"},
        {"w": "laconic", "tr": "Kısa ve öz, az konuşan", "pos": "sıfat", "def": "Çok az kelime kullanarak çok şey anlatan.", "ex": "His laconic reply was simply: 'Agreed.'", "ph": "/ləˈkɒn.ɪk/"},
        {"w": "mitigate", "tr": "Hafifletmek, etkisini azaltmak", "pos": "fiil", "def": "Zararı, tehlikeyi veya şiddeti azaltmak.", "ex": "Steps were taken to mitigate the risks.", "ph": "/ˈmɪt.ɪ.ɡeɪt/"},
        {"w": "cacophony", "tr": "Kakofoni, kulak tırmalayıcı ses", "pos": "isim", "def": "Uyumsuz ve rahatsız edici gürültü bütünü.", "ex": "A cacophony of car horns filled the city street.", "ph": "/kəˈkɒf.ə.ni/"},
        {"w": "misanthrope", "tr": "İnsan sevmeyen, insandan kaçan", "pos": "isim", "def": "İnsanlığa güvenmeyen veya insanlardan uzak duran kimse.", "ex": "He lived alone in the woods like a misanthrope.", "ph": "/ˈmɪs.ən.θrəʊp/"},
        {"w": "venerate", "tr": "Büyük saygı duymak, hürmet etmek", "pos": "fiil", "def": "Derin bir saygı ve hayranlık beslemek.", "ex": "Scholars venerate the ancient philosopher.", "ph": "/ˈven.ər.eɪt/"},
        {"w": "obdurate", "tr": "İnatçı, dik kafalı, katı yürekli", "pos": "sıfat", "def": "Görüşünü veya tutumunu değiştirmeyi reddeden.", "ex": "He remained obdurate in his refusal to apologize.", "ph": "/ˈɒb.djʊə.rət/"},
        {"w": "esoteric", "tr": "Gizli, ezoterik, sadece azınlığın bildiği", "pos": "sıfat", "def": "Yalnızca uzman veya sınırlı bir grubun kavradığı.", "ex": "The lecture was full of esoteric terminology.", "ph": "/ˌes.əˈter.ɪk/"},
        {"w": "fastidious", "tr": "Titiz, kılı kırk yaran, zor beğenen", "pos": "sıfat", "def": "Doğruluk ve temizlik konusunda aşırı dikkatli.", "ex": "She is fastidious about keeping her desk tidy.", "ph": "/fæsˈtɪd.i.əs/"},
        {"w": "magnanimous", "tr": "Yüce gönüllü, bağışlayıcı, alicenap", "pos": "sıfat", "def": "Rakiplerine veya zayıflara karşı cömert ve bağışlayıcı.", "ex": "He was magnanimous in his election victory.", "ph": "/mæɡˈnæn.ɪ.məs/"},
        {"w": "obfuscate", "tr": "Kafasını karıştırmak, anlaşılmaz kılmak", "pos": "fiil", "def": "Gerçeği veya konuyu kasten belirsizleştirmek.", "ex": "The lawyer tried to obfuscate the real issues.", "ph": "/ˈɒb.fʌs.keɪt/"},
        {"w": "pernicious", "tr": "Zararlı, sinsi, yıkıcı", "pos": "sıfat", "def": "Sessizce ve yavaş yavaş büyük zarar veren.", "ex": "Smoking has a pernicious effect on overall health.", "ph": "/pəˈnɪʃ.əs/"},
        {"w": "veracity", "tr": "Doğruluk, dürüstlük, hakikat", "pos": "isim", "def": "Gerçeğe uygunluk veya doğruyu söyleme kalitesi.", "ex": "The committee questioned the veracity of his statement.", "ph": "/vəˈræs.ə.ti/"},
        {"w": "clandestine", "tr": "Gizli, gizlice yürütülen, saklı", "pos": "sıfat", "def": "Yasa dışı veya gizli tutulan plan/hareket.", "ex": "They held a clandestine meeting after midnight.", "ph": "/klænˈdes.tɪn/"},
        {"w": "alacrity", "tr": "Şevk, çeviklik, hevesli çabukluk", "pos": "isim", "def": "İstekli ve sevinçli bir çeviklikle davranma.", "ex": "She accepted the promotion with great alacrity.", "ph": "/əˈlæk.rə.ti/"},
        {"w": "quintessential", "tr": "Özü oluşturan, mükemmel örneği olan", "pos": "sıfat", "def": "Bir niteliğin en tipik ve kusursuz temsilcisi.", "ex": "This cafe is the quintessential Parisian bistro.", "ph": "/ˌkwɪn.tɪˈsen.ʃəl/"},
        {"w": "mellifluous", "tr": "Tatlı, kulağa hoş gelen, ahenkli", "pos": "sıfat", "def": "Müzikal ve dinlemesi huzur veren ses.", "ex": "Her mellifluous voice captivated the audience.", "ph": "/meˈlɪf.lu.əs/"},
        {"w": "quixotic", "tr": "Donkişotça, hayalperest, pratik olmayan", "pos": "sıfat", "def": "Aşırı idealist fakat gerçekleşmesi imkansız.", "ex": "It was a quixotic quest to fix all world problems at once.", "ph": "/kwɪkˈsɒt.ɪk/"},
        {"w": "taciturn", "tr": "Az konuşan, ketum, suskun", "pos": "sıfat", "def": "Alışkanlık olarak sessiz kalmayı tercih eden.", "ex": "His grandfather was a taciturn but caring man.", "ph": "/ˈtæs.ɪ.tɜːn/"},
        {"w": "recalcitrant", "tr": "İtaatsiz, dikbaşlı, laf dinlemez", "pos": "sıfat", "def": "Otoriteye veya kurallara inatla direnen.", "ex": "The recalcitrant student refused to participate.", "ph": "/rɪˈkæl.sɪ.trənt/"},
        {"w": "zeitgeist", "tr": "Zamanın ruhu, dönemin anlayışı", "pos": "isim", "def": "Belirli bir dönemin genel düşünce ve inanç iklimi.", "ex": "The film captured the zeitgeist of the 1960s.", "ph": "/ˈtsaɪt.ɡaɪst/"},
        {"w": "salubrious", "tr": "Sağlığa yararlı, sıhhatli, şifalı", "pos": "sıfat", "def": "İklim veya çevre olarak sağlığa iyi gelen.", "ex": "The mountain air is famously salubrious.", "ph": "/səˈluː.bri.əs/"},
        {"w": "sycophant", "tr": "Dalkavuk, şakşakçı, yaltakçı", "pos": "isim", "def": "Çıkar sağlamak için güçlülere övgüler yağdıran.", "ex": "The CEO was surrounded by sycophants who never disagreed.", "ph": "/ˈsɪk.ə.fænt/"},
        {"w": "hubris", "tr": "Kibir, aşırı gurur, kendini beğenmişlik", "pos": "isim", "def": "İnsanın düşüşüne yol açan aşırı kibir.", "ex": "His hubris blinded him to the coming disaster.", "ph": "/ˈhjuː.brɪs/"},
        {"w": "chicanery", "tr": "Hilekarlık, dalavere, göz boyama", "pos": "isim", "def": "Politik veya yasal oyunlarla insanları aldatma.", "ex": "The treaty was obtained by political chicanery.", "ph": "/ʃɪˈkeɪ.nər.i/"},
        {"w": "supercilious", "tr": "Kibirli, burnu havada, tepeden bakan", "pos": "sıfat", "def": "Başkalarını küçümseyen ve üstünlük taslayan.", "ex": "He gave a supercilious smile and walked away.", "ph": "/ˌsuː.pəˈsɪl.i.əs/"},
        {"w": "effrontery", "tr": "Yüzsüzlük, arsızlık, pişkinlik", "pos": "isim", "def": "Utanmaz ve cüretkar davranış biçimi.", "ex": "She had the effrontery to ask for more money.", "ph": "/ɪˈfrʌn.tər.i/"},
        {"w": "garrulous", "tr": "Çenebaz, boşboğaz, geveze", "pos": "sıfat", "def": "Önemsiz konular hakkında durmaksızın konuşan.", "ex": "A garrulous neighbor delayed his departure.", "ph": "/ˈɡær.əl.əs/"},
        {"w": "ineffable", "tr": "Kelimelerle anlatılamaz, tarifsiz", "pos": "sıfat", "def": "Aşırı güzellik veya büyüklükten dolayı anlatılamayan.", "ex": "The view from the summit gave him ineffable joy.", "ph": "/ɪnˈef.ə.bəl/"},
        {"w": "proclivity", "tr": "Eğilim, meyil, yatkınlık", "pos": "isim", "def": "Doğal olarak bir şeye yönelme arzusu.", "ex": "She showed a proclivity for mathematics early on.", "ph": "/prəˈklɪv.ə.ti/"},
        {"w": "soporific", "tr": "Uyku getiren, uyuşturan", "pos": "sıfat", "def": "Uyuşukluk veya uyku hali veren etki.", "ex": "The heat and monotonous sound had a soporific effect.", "ph": "/ˌsɒp.ərˈɪf.ɪk/"},
        {"w": "trenchant", "tr": "Keskin, etkili, sivri dilli", "pos": "sıfat", "def": "Net, sert ve can alıcı eleştiri sunan.", "ex": "She offered a trenchant critique of the policy.", "ph": "/ˈtren.tʃənt/"},
        {"w": "scintillating", "tr": "Işıl ışıl, parıldayan, kıvrak zekalı", "pos": "sıfat", "def": "Son derece parlak, canlı ve büyüleyici.", "ex": "They engaged in scintillating conversation over dinner.", "ph": "/ˈsɪn.tɪ.leɪ.tɪŋ/"},
        {"w": "pellucid", "tr": "Pırıl pırıl, saydam, son derece açık", "pos": "sıfat", "def": "Net ve hiçbir belirsizlik taşımayan ifade.", "ex": "His style of writing was elegant and pellucid.", "ph": "/pəˈluː.sɪd/"},
        {"w": "surreptitious", "tr": "Gizlice yapılan, el altından, sinsi", "pos": "sıfat", "def": "Fark edilmemek için gizlice sürdürülen eylem.", "ex": "She cast a surreptitious glance at her phone.", "ph": "/ˌsʌr.əpˈtɪʃ.əs/"},
        {"w": "sagacious", "tr": "Sağduyulu, basiretli, derin görüşlü", "pos": "sıfat", "def": "Sağlam muhakeme ve ileri görüş sergileyen.", "ex": "The leader was praised for his sagacious decisions.", "ph": "/səˈɡeɪ.ʃəs/"},
        {"w": "panacea", "tr": "Her derde deva, mucizevi çözüm", "pos": "isim", "def": "Tüm sorunları tek seferde çözeceğine inanılan şey.", "ex": "Technology is helpful, but it is not a panacea.", "ph": "/ˌpæn.əˈsiː.ə/"},
        {"w": "pernicious", "tr": "Yıkıcı, sinsi ve ölümcül", "pos": "sıfat", "def": "Yavaşça fakat ağır zarar veren tesir.", "ex": "Rumors can have a pernicious influence on morale.", "ph": "/pəˈnɪʃ.əs/"},
        {"w": "vicarious", "tr": "Başkası üzerinden yaşanan, dolaylı", "pos": "sıfat", "def": "Başkalarının deneyimini izleyerek hissetme.", "ex": "Parents often take vicarious pride in their children's success.", "ph": "/vɪˈkeə.ri.əs/"},
        {"w": "inured", "tr": "Alışkın, bağışıklık kazanmış, duyarsızlaşmış", "pos": "sıfat", "def": "Sık maruz kaldığı için zorluklara bağışık olan.", "ex": "Soldiers became inured to the hardships of winter.", "ph": "/ɪˈnjʊəd/"},
        {"w": "recondite", "tr": "Derin, anlaşılması güç, gizemli", "pos": "sıfat", "def": "Çoğu insanın bilmediği karmaşık ve derin bilgi.", "ex": "He possessed recondite knowledge of ancient scripts.", "ph": "/ˈrek.ən.daɪt/"},
        {"w": "specious", "tr": "Görünüşte doğru fakat aldatıcı", "pos": "sıfat", "def": "İlk bakışta doğru gelen ama asılsız olan sav.", "ex": "Don't fall for specious arguments that lack evidence.", "ph": "/ˈspiː.ʃəs/"},
        {"w": "redolent", "tr": "Buram buram kokan, anımsatan", "pos": "sıfat", "def": "Belirli bir kokuyu veya anıyı güçlüce çağrıştıran.", "ex": "The old attic was redolent of cedar and nostalgia.", "ph": "/ˈred.əl.ənt/"},
        {"w": "equanimity", "tr": "İtidal, soğukkanlılık, sükunet", "pos": "isim", "def": "Baskı altındayken bile sakinliğini koruma erdemi.", "ex": "She handled the emergency with admirable equanimity.", "ph": "/ˌek.wəˈnɪm.ə.ti/"},
        {"w": "implacable", "tr": "Yatıştırılamaz, amansız, tavizsiz", "pos": "sıfat", "def": "Öfkesi dindirilemeyen veya fikri değiştirilemeyen.", "ex": "He proved to be an implacable opponent of the regime.", "ph": "/ɪmˈplæk.ə.bəl/"},
        {"w": "abnegation", "tr": "Kendinden feragat etme, fedakarlık", "pos": "isim", "def": "Kendi çıkarlarından ve zevklerinden vazgeçme.", "ex": "Monks practice self-abnegation and quiet devotion.", "ph": "/ˌæb.nɪˈɡeɪ.ʃən/"},
        {"w": "truculent", "tr": "Kavgacı, saldırgan, vahşi tavırlı", "pos": "sıfat", "def": "Kolayca tartışma veya çatışma çıkaran.", "ex": "The boxer adopted a truculent stance during the weigh-in.", "ph": "/ˈtrʌk.jʊ.lənt/"},
        {"w": "demagogue", "tr": "Demagog, halk avcısı", "pos": "isim", "def": "Halkın duygularını ve önyargılarını sömüren hatip.", "ex": "The demagogue promised easy solutions to complex crises.", "ph": "/ˈdem.ə.ɡɒɡ/"},
        {"w": "lugubrious", "tr": "Kederli, hüzünlü, matemli", "pos": "sıfat", "def": "Aşırı derecede hüzün ve keder yansıtan.", "ex": "The violin melody had a lugubrious beauty.", "ph": "/luːˈɡuː.bri.əs/"},
        {"w": "alleviate", "tr": "Hafifletmek, teskin etmek", "pos": "fiil", "def": "Sıkıntıyı veya acıyı daha dayanılır kılmak.", "ex": "Medicine can alleviate the symptoms of migraine.", "ph": "/əˈliː.vi.eɪt/"},
        {"w": "parsimonious", "tr": "Aşırı tutumlu, cimri, eli sıkı", "pos": "sıfat", "def": "Para veya kaynak harcamaktan kaçınan.", "ex": "The company was parsimonious in funding research.", "ph": "/ˌpɑː.sɪˈməʊ.ni.əs/"},
        {"w": "cogent", "tr": "İkna edici, mantıklı, tutarlı", "pos": "sıfat", "def": "Güçlü mantığıyla karşı tarafı ikna eden fikir.", "ex": "She put forward a cogent argument in the debate.", "ph": "/ˈkəʊ.dʒənt/"},
        {"w": "mercurial", "tr": "Cıva gibi değişken, dengesiz", "pos": "sıfat", "def": "Ruh hali anında değişebilen, öngörülemez.", "ex": "His mercurial temperament made teamwork challenging.", "ph": "/mɜːˈkjʊə.ri.əl/"},
        {"w": "nefarious", "tr": "Kötü niyetli, haince, alçakça", "pos": "sıfat", "def": "Ahlaken çirkin ve kötü amaçlar güden.", "ex": "The villains hatched a nefarious plot.", "ph": "/nɪˈfeə.ri.əs/"},
        {"w": "salient", "tr": "Göze çarpan, belirgin, can alıcı", "pos": "sıfat", "def": "En önemli veya dikkat çekici olan nokta.", "ex": "Let's summarize the salient points of the proposal.", "ph": "/ˈseɪ.li.ənt/"},
        {"w": "ubiquity", "tr": "Her yerdellik, her zaman mevcudiyet", "pos": "isim", "def": "Her yerde aynı anda bulunma niteliği.", "ex": "The ubiquity of smartphones changed human behavior.", "ph": "/juːˈbɪk.wə.ti/"},
    ]

    # --- BİRLEŞTİRME HAVUZU (Master Pool) ---
    all_final_words = {}

    # 1) Öncelik: Mevcut DB'deki kaliteli kelimeler
    for k, v in existing_db_words.items():
        all_final_words[k] = v

    # 2) C2 Ekstra kelimeleri ekle
    for c in c2_extra:
        k = c["w"].lower()
        all_final_words[k] = {
            "word": c["w"].capitalize(),
            "translation": c["tr"],
            "level": "C2",
            "phonetic": c.get("ph", ""),
            "meanings": [{
                "part_of_speech": c["pos"],
                "definition": c["def"],
                "example": c["ex"]
            }]
        }

    # 3) Ciwga Kelimeleri (Zengin Tanımlar ve Örnek Cümleler)
    for k, c_data in ciwga_map.items():
        if k not in all_final_words and c_data["translation"]:
            all_final_words[k] = {
                "word": k.capitalize(),
                "translation": c_data["translation"],
                "level": "B1", # geçici default, altta oxford 5k seviyesi ile ezilecek
                "phonetic": "",
                "meanings": [{
                    "part_of_speech": c_data["pos"] or "kelime",
                    "definition": c_data["definition"] or f"{k.capitalize()} ({c_data['pos'] or 'kelime'})",
                    "example": c_data["example"] or ""
                }]
            }

    # 4) Hilal Şengül Oxford 5000 (A1-C1 Resmi Seviyeler ve Türkçe Anlamlar)
    valid_levels = {"A1", "A2", "B1", "B2", "C1"}
    for item in hs_data:
        raw_entry = item.get("word", "")
        lvl = item.get("level", "").upper().strip()
        pos = item.get("type", "kelime").strip()
        
        if " - " not in raw_entry:
            continue
            
        parts = raw_entry.split(" - ", 1)
        eng_raw = parts[0].strip()
        tr_raw = parts[1].strip()
        
        if not eng_raw or not tr_raw:
            continue
            
        k = eng_raw.lower()
        if lvl not in valid_levels:
            lvl = "B1"

        # Eğer zaten varsa seviyesini doğrula
        if k in all_final_words:
            # Mevcut seviye C2 değilse Oxford 5000 seviyesine ayarla
            if all_final_words[k]["level"] != "C2":
                all_final_words[k]["level"] = lvl
            # Türkçe karşılığı eksikse ekle
            if not all_final_words[k].get("translation"):
                all_final_words[k]["translation"] = tr_raw
            continue

        # Yeni kelime olarak ekle
        ty_info = ty_map.get(k, {})
        phonetic = ty_info.get("phonetics", {}).get("us") or ty_info.get("phonetics", {}).get("uk") or ""
        examples = ty_info.get("examples", [])
        ex = examples[0] if examples else ""
        
        all_final_words[k] = {
            "word": eng_raw.capitalize(),
            "translation": tr_raw,
            "level": lvl,
            "phonetic": phonetic,
            "meanings": [{
                "part_of_speech": pos,
                "definition": f"{eng_raw.capitalize()} ({pos}): {tr_raw}",
                "example": ex
            }]
        }

    # 5) Tyypgzl Fonetiklerini Ekle (Eksik kalan fonetikleri tamamla)
    for k, word_obj in all_final_words.items():
        if not word_obj.get("phonetic") and k in ty_map:
            ph = ty_map[k].get("phonetics", {}).get("us") or ty_map[k].get("phonetics", {}).get("uk") or ""
            if ph:
                word_obj["phonetic"] = ph

    print(f"\nToplam işlenen benzersiz kelime sayısı: {len(all_final_words)}")

    # Seviye istatistikleri
    level_counts = {}
    for w in all_final_words.values():
        lvl = w["level"].upper()
        level_counts[lvl] = level_counts.get(lvl, 0) + 1

    print("\n--- CEFR Seviye Dağılımı ---")
    for lvl in ["A1", "A2", "B1", "B2", "C1", "C2"]:
        print(f"  {lvl}: {level_counts.get(lvl, 0)} kelime")

    # Veritabanına Yazma
    print("\nVeritabanına (sozegitim.db) kaydediliyor...")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Tabloyu kontrol et / oluştur
    cur.execute("""
        CREATE TABLE IF NOT EXISTS dictionary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT UNIQUE NOT NULL,
            translation TEXT NOT NULL,
            level TEXT NOT NULL,
            phonetic TEXT,
            meanings JSON
        )
    """)

    # Hepsini tek seferde upsert et
    inserted = 0
    updated = 0
    for w_obj in all_final_words.values():
        word_text = w_obj["word"]
        translation = w_obj["translation"]
        level = w_obj["level"].upper()
        phonetic = w_obj.get("phonetic") or ""
        meanings_json = json.dumps(w_obj.get("meanings") or [], ensure_ascii=False)

        cur.execute("SELECT id FROM dictionary WHERE LOWER(word) = LOWER(?)", (word_text,))
        row = cur.fetchone()
        if row:
            cur.execute("""
                UPDATE dictionary 
                SET translation = ?, level = ?, phonetic = ?, meanings = ?
                WHERE id = ?
            """, (translation, level, phonetic, meanings_json, row[0]))
            updated += 1
        else:
            cur.execute("""
                INSERT INTO dictionary (word, translation, level, phonetic, meanings)
                VALUES (?, ?, ?, ?, ?)
            """, (word_text, translation, level, phonetic, meanings_json))
            inserted += 1

    conn.commit()

    # Son doğrulama
    cur.execute("SELECT COUNT(*) FROM dictionary")
    total_db = cur.fetchone()[0]
    print(f"\nBAŞARILI: Veritabanında şu an tam {total_db} kelime bulunuyor!")
    print(f"Yeni eklenen: {inserted}, Güncellenen: {updated}")

    cur.execute("SELECT level, COUNT(*) FROM dictionary GROUP BY level ORDER BY level")
    print("\nVeritabanındaki Güncel Seviye Sayımları:")
    for row in cur.fetchall():
        print(f"  {row[0]}: {row[1]} kelime")

    conn.close()

if __name__ == "__main__":
    main()
