# -*- coding: utf-8 -*-
"""
SözEğitim - 2. Parti Kelime Yükleme (Toplam 500+ Seviyeli Kelimeye Ulaşma)
"""
import os
import sqlite3
import json

db_path = os.path.join(os.path.dirname(__file__), "sozegitim.db")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

ADDITIONAL_WORDS = [
    # A1 & A2 Ek Kelimeler
    ("Apple", "Elma", "A1", "/ˈæp.əl/", "isim", "An apple a day keeps the doctor away.", "Red sweet apples."),
    ("Banana", "Muz", "A1", "/bəˈnɑː.nə/", "isim", "Monkeys love ripe bananas.", "Eat a yellow banana."),
    ("Brother", "Erkek kardeş", "A1", "/ˈbrʌð.ər/", "isim", "My brother is an engineer.", "Older brother."),
    ("Sister", "Kız kardeş", "A1", "/ˈsɪs.tər/", "isim", "My sister plays the piano beautifully.", "Younger sister."),
    ("Mother", "Anne", "A1", "/ˈmʌð.ər/", "isim", "Mother's love is unconditional.", "Happy Mother's Day."),
    ("Child", "Çocuk", "A1", "/tʃaɪld/", "isim", "Every child deserves quality education.", "A cheerful child."),
    ("Garden", "Bahçe", "A1", "/ˈɡɑː.dən/", "isim", "Flowers bloom in our green garden.", "Water the garden."),
    ("School", "Okul", "A1", "/skuːl/", "isim", "Children walk to school every morning.", "High school."),
    ("Teacher", "Öğretmen", "A1", "/ˈtiː.tʃər/", "isim", "A good teacher inspires hope.", "English teacher."),
    ("Doctor", "Doktor, hekim", "A1", "/ˈdɒk.tər/", "isim", "The doctor examined the patient.", "Family doctor."),
    ("Music", "Müzik", "A1", "/ˈmjuː.zɪk/", "isim", "Music touches the human soul.", "Classical music."),
    ("Morning", "Sabah", "A1", "/ˈmɔː.nɪŋ/", "isim", "Start your morning with gratitude.", "Morning coffee."),
    ("Evening", "Akşam", "A1", "/ˈiːv.nɪŋ/", "isim", "We take a walk in the cool evening.", "Good evening."),
    ("Summer", "Yaz mevsimi", "A1", "/ˈsʌm.ər/", "isim", "Summer days are sunny and long.", "Summer vacation."),
    ("Winter", "Kış mevsimi", "A1", "/ˈwɪn.tər/", "isim", "Snow falls during the cold winter.", "Winter jacket."),
    ("Spring", "İlkbahar, yay", "A1", "/sprɪŋ/", "isim", "Spring brings new life to nature.", "Early spring."),
    ("Autumn", "Sonbahar, güz", "A1", "/ˈɔː.təm/", "isim", "Leaves turn gold in autumn.", "Autumn breeze."),
    ("Rain", "Yağmur, yağmak", "A1", "/reɪn/", "isim", "Gentle rain nourishes the dry soil.", "Heavy rain."),
    ("Sun", "Güneş", "A1", "/sʌn/", "isim", "The sun rises in the east.", "Warm sunshine."),
    ("Moon", "Ay", "A1", "/muːn/", "isim", "The full moon shines brightly tonight.", "Crescent moon."),
    ("Star", "Yıldız", "A1", "/stɑːr/", "isim", "Millions of stars illuminate the sky.", "Shooting star."),
    ("River", "Nehir, ırmak", "A1", "/ˈrɪv.ər/", "isim", "The mighty river flows into the sea.", "Cross the river."),
    ("Sea", "Deniz", "A1", "/siː/", "isim", "We swim in the warm Mediterranean sea.", "Deep blue sea."),
    ("Mountain", "Dağ", "A1", "/ˈmaʊn.tɪn/", "isim", "They climbed to the mountain summit.", "Snowy mountain."),
    ("Tree", "Ağaç", "A1", "/triː/", "isim", "Plant a tree for future generations.", "Ancient olive tree."),
    ("Flower", "Çiçek", "A1", "/flaʊər/", "isim", "Fresh flowers brighten the living room.", "Smell the flower."),
    ("Friend", "Arkadaş, dost", "A1", "/frend/", "isim", "A faithful friend is a rare treasure.", "Best friends forever."),
    ("Family", "Aile", "A1", "/ˈfæm.əl.i/", "isim", "Family is where life begins and love never ends.", "Loving family."),
    ("House", "Ev, konut", "A1", "/haʊs/", "isim", "They built a lovely wooden house.", "House near the lake."),
    ("Table", "Masa, tablo", "A1", "/ˈteɪ.bəl/", "isim", "Sit around the dinner table.", "Round wooden table."),
    ("Chair", "Sandalye, koltuk", "A1", "/tʃeər/", "isim", "Pull up a chair and join us.", "Comfortable chair."),
    ("Window", "Pencere", "A1", "/ˈwɪn.dəʊ/", "isim", "Open the window for fresh air.", "Look through window."),
    ("Computer", "Bilgisayar", "A1", "/kəmˈpjuː.tər/", "isim", "Modern computers solve complex equations.", "Personal computer."),
    ("Phone", "Telefon", "A1", "/fəʊn/", "isim", "Answer the ringing phone.", "Smart phone."),
    ("Money", "Para", "A1", "/ˈmʌn.i/", "isim", "Time is more valuable than money.", "Save your money."),
    ("Market", "Pazar, piyasa", "A1", "/ˈmɑː.kɪt/", "isim", "Buy fresh fruits from the local market.", "Global market."),
    ("Shop", "Dükkan, mağaza", "A1", "/ʃɒp/", "isim", "Let's visit the neighborhood book shop.", "Coffee shop."),
    ("Street", "Sokak, cadde", "A1", "/striːt/", "isim", "The stone street is full of history.", "Cross the street."),
    ("Village", "Köy", "A1", "/ˈvɪl.ɪdʒ/", "isim", "Peaceful life in a mountain village.", "Small village."),
    ("Journey", "Yolculuk, seyahat", "A2", "/ˈdʒɜː.ni/", "isim", "Every long journey starts with a single step.", "Safe journey."),
    ("Adventure", "Macera, serüven", "A2", "/ədˈven.tʃər/", "isim", "Life is either an adventure or nothing.", "Exciting adventure."),
    ("Brave", "Cesur, yürekli", "A2", "/breɪv/", "sıfat", "Brave souls conquer their fears.", "Brave firefighter."),
    ("Clever", "Zeki, akıllı", "A2", "/ˈklev.ər/", "sıfat", "The clever student solved the riddle.", "Clever solution."),
    ("Danger", "Tehlike", "A2", "/ˈdeɪn.dʒər/", "isim", "Warning signs alert drivers of danger.", "Out of danger."),
    ("Famous", "Ünlü, tanınmış", "A2", "/ˈfeɪ.məs/", "sıfat", "Leonardo da Vinci is a famous painter.", "World famous."),
    ("Gentle", "Nazik, yumuşak, kibar", "A2", "/ˈdʒen.təl/", "sıfat", "Speak with a gentle and warm voice.", "Gentle breeze."),
    ("Healthy", "Sağlıklı, dinç", "A2", "/ˈhel.θi/", "sıfat", "Eat vegetables to stay healthy.", "Healthy lifestyle."),
    ("Important", "Önemli, mühim", "A2", "/ɪmˈpɔː.tənt/", "sıfat", "Honesty is the most important virtue.", "Important decision."),
    ("Joyful", "Neşeli, sevinçli", "A2", "/ˈdʒɔɪ.fəl/", "sıfat", "Children sang joyful songs.", "A joyful smile."),
    ("Kindness", "Nezaket, iyilik", "A2", "/ˈkaɪnd.nəs/", "isim", "No act of kindness is ever wasted.", "Show kindness."),
    ("Lucky", "Şanslı, talihli", "A2", "/ˈlʌk.i/", "sıfat", "We are lucky to have true friends.", "Lucky number."),
    ("Mistake", "Hata, kusur", "A2", "/mɪˈsteɪk/", "isim", "Mistakes are proof that you are trying.", "Learn from mistakes."),
    ("Nature", "Doğa, tabiat", "A2", "/ˈneɪ.tʃər/", "isim", "Preserve the beauty of virgin nature.", "Mother nature."),
    ("Opportunity", "Fırsat, vesile", "B1", "/ˌɒp.əˈtʃuː.nə.ti/", "isim", "Opportunity dances with those who are ready.", "Seize the opportunity."),
    ("Patience", "Sabır, tahammül", "B1", "/ˈpeɪ.ʃəns/", "isim", "Patience is bitter, but its fruit is sweet.", "Have patience."),
    ("Peace", "Barış, huzur", "B1", "/piːs/", "isim", "Inner peace brings true happiness.", "World peace."),
    ("Promise", "Söz vermek, vaat", "B1", "/ˈprɒm.ɪs/", "fiil", "Always keep the promise you make.", "Keep your promise."),
    ("Protect", "Korumak, muhafaza etmek", "B1", "/prəˈtekt/", "fiil", "Protect your mind from negativity.", "Protect the environment."),
    ("Respect", "Saygı duymak, hürmet", "B1", "/rɪˈspekt/", "isim", "Treat every person with deep respect.", "Earn respect."),
    ("Success", "Başarı, muvaffakiyet", "B1", "/səkˈses/", "isim", "Success is the sum of small daily efforts.", "Key to success."),
    ("Trust", "Güvenmek, itimat", "B1", "/trʌst/", "isim", "Trust is earned through consistent actions.", "Build mutual trust."),
    ("Victory", "Zafer, galibiyet", "B1", "/ˈvɪk.tər.i/", "isim", "Victory belongs to the most persevering.", "Sweet victory."),
    ("Wisdom", "Bilgelik, hikmet", "B2", "/ˈwɪz.dəm/", "isim", "Wisdom begins with self-awareness.", "Words of wisdom."),
    ("Wonder", "Merak etmek, harika", "B1", "/ˈwʌn.dər/", "fiil", "The seven wonders of the ancient world.", "I wonder why."),
    ("Courage", "Cesaret, yüreklilik", "B1", "/ˈkʌr.ɪdʒ/", "isim", "Courage does not mean lack of fear.", "Have the courage."),
    ("Honesty", "Dürüstlük, doğruluk", "B1", "/ˈɒn.ə.sti/", "isim", "Honesty is the fastest path to peace.", "Honesty in work."),
    ("Harmony", "Uyum, ahenk", "B2", "/ˈhɑː.mə.ni/", "isim", "Live in harmony with the environment.", "Musical harmony."),
    ("Inspiration", "İlham, esin", "B2", "/ˌɪn.spɪˈreɪ.ʃən/", "isim", "Nature is an infinite source of inspiration.", "Find inspiration."),
    ("Justice", "Adalet, hakkaniyet", "B2", "/ˈdʒʌs.tɪs/", "isim", "Justice must prevail for all citizens.", "Social justice."),
    ("Liberty", "Özgürlük, hürriyet", "B2", "/ˈlɪb.ə.ti/", "isim", "Liberty is the breath of humanity.", "Statue of Liberty."),
    ("Gratitude", "Şükran, minnettarlık", "B2", "/ˈɡræt.ɪ.tʃuːd/", "isim", "Express gratitude for every blessing.", "Heart of gratitude."),
    ("Perseverance", "Sebat, azim, kararlılık", "C1", "/ˌpɜː.sɪˈvɪə.rəns/", "isim", "Perseverance turns failures into triumph.", "Through perseverance."),
    ("Integrity", "Dürüstlük, erdemlilik, tamlık", "C1", "/ɪnˈteɡ.rə.ti/", "isim", "Integrity is doing the right thing when alone.", "High integrity."),
    ("Serenity", "Huzur, dinginlik, sükunet", "C1", "/səˈren.ə.ti/", "isim", "Walk through life with serene calmness.", "Serenity of mind."),
    ("Tenacity", "İnat, pes etmeme, azim", "C1", "/təˈnæs.ə.ti/", "isim", "Tenacity in the face of immense adversity.", "Fierce tenacity."),
    ("Epiphany", "Aydınlanma anı, ani idrak", "C2", "/ɪˈpɪf.ən.i/", "isim", "He experienced an epiphany while reading.", "A sudden epiphany."),
    ("Equanimity", "Soğukkanlılık, sükunet", "C2", "/ˌek.wəˈnɪm.ə.ti/", "isim", "Bear both praise and blame with equanimity.", "Mental equanimity."),
    ("Veracity", "Doğruluk, dürüstlük, hakikat", "C2", "/vəˈræs.ə.ti/", "isim", "Historians scrutinized the veracity of reports.", "Doubt veracity."),
    ("Resilience", "Esneklik, toparlanma gücü", "B2", "/rɪˈzɪl.jəns/", "isim", "Emotional resilience overcomes hardships.", "Build resilience."),
    ("Compassion", "Şefkat, merhamet", "B2", "/kəmˈpæʃ.ən/", "isim", "Show compassion to those in difficulty.", "Feel compassion."),
    ("Generosity", "Cömertlik, alicenaplık", "B2", "/ˌdʒen.əˈrɒs.ə.ti/", "isim", "Generosity enriches the human spirit.", "Kind generosity."),
    ("Modesty", "Alçakgönüllülük, tevazu", "B2", "/ˈmɒd.ɪ.sti/", "isim", "True greatness is crowned with modesty.", "Modesty of mind."),
    ("Simplicity", "Sadelik, basitlik", "B2", "/sɪmˈplɪs.ə.ti/", "isim", "Simplicity is the ultimate sophistication.", "Living in simplicity."),
    ("Curiosity", "Merak, öğrenme arzusu", "B1", "/ˌkjʊə.riˈɒs.ə.ti/", "isim", "Stay hungry, stay curious.", "Intellectual curiosity."),
    ("Loyalty", "Sadakat, bağlılık", "B2", "/ˈlɔɪ.əl.ti/", "isim", "Loyalty binds communities together.", "Fierce loyalty."),
    ("Diligence", "Çalışkanlık, özen", "C1", "/ˈdɪl.ɪ.dʒəns/", "isim", "Diligence is the mother of good fortune.", "With great diligence."),
    ("Prudence", "Sağduyu, basiret, ihtiyat", "C1", "/ˈpruː.dəns/", "isim", "Exercise financial prudence in investments.", "Act with prudence."),
    ("Fortitude", "Metanet, dayanıklılık, cesaret", "C1", "/ˈfɔː.tɪ.tʃuːd/", "isim", "Endure hardships with moral fortitude.", "Courage and fortitude."),
    ("Altruism", "Özgecilik, fedakarlık", "C1", "/ˈæl.tru.ɪ.zəm/", "isim", "Pure altruism inspires generations.", "Act of altruism."),
    ("Benevolence", "İyilikseverlik, hayırhahlık", "C1", "/bəˈnev.əl.əns/", "isim", "Universal benevolence transforms societies.", "Deeds of benevolence."),
    ("Magnanimity", "Yüce gönüllülük, alicenaplık", "C2", "/ˌmæɡ.nəˈnɪm.ə.ti/", "isim", "Magnanimity towards defeated opponents.", "True magnanimity."),
    ("Ubiquity", "Her yerde bulunma, yaygınlık", "C2", "/juːˈbɪk.wə.ti/", "isim", "The ubiquity of mobile connectivity.", "Ubiquity of ideas."),
    ("Evanescence", "Uçuculuk, geçicilik", "C2", "/ˌev.əˈnes.əns/", "isim", "The evanescence of morning mist.", "Poetic evanescence."),
    ("Ineffability", "Tarifsizlik, anlatılamazlık", "C2", "/ɪnˌef.əˈbɪl.ə.ti/", "isim", "The ineffability of mystic moments.", "State of ineffability."),
    ("Sagacity", "Feraset, bilgelik, basiret", "C2", "/səˈɡæs.ə.ti/", "isim", "The sagacity of ancient statesmen.", "Intellectual sagacity."),
    ("Fidelity", "Bağlılık, doğruluk, sadakat", "C1", "/fɪˈdel.ə.ti/", "isim", "Fidelity to sacred moral oaths.", "High fidelity."),
    ("Efficacy", "Yararlılık, etkililik", "C1", "/ˈef.ɪ.kə.si/", "isim", "Clinical trials proved vaccine efficacy.", "Proven efficacy."),
    ("Clarity", "Açıklık, berraklık, duruluk", "B2", "/ˈklær.ə.ti/", "isim", "Clarity of vision drives successful leadership.", "Mental clarity."),
    ("Courteous", "Nazik, terbiyeli, kibar", "B2", "/ˈkɜː.ti.əs/", "sıfat", "Be courteous to everyone you meet.", "Courteous behavior."),
    ("Earnest", "Samimi, gayretli, içten", "B2", "/ˈɜː.nɪst/", "sıfat", "An earnest effort will always be rewarded.", "In earnest."),
    ("Genuine", "Hakiki, samimi, öz", "B2", "/ˈdʒen.ju.ɪn/", "sıfat", "A genuine smile opens every door.", "Genuine friendship."),
    ("Humility", "Tevazu, alçakgönüllülük", "B2", "/hjuːˈmɪl.ə.ti/", "isim", "Humility is the foundation of virtue.", "Walk with humility."),
    ("Noble", "Asil, soylu, yüce", "B2", "/ˈnəʊ.bəl/", "sıfat", "Forgiveness is a noble quality.", "A noble cause."),
    ("Sincere", "Samimi, içten, dürüst", "B1", "/sɪnˈsɪər/", "sıfat", "Please accept our sincere apologies.", "Sincere feelings."),
    ("Tolerant", "Hoşgörülü, müsamahakar", "B2", "/ˈtɒl.ər.ənt/", "sıfat", "A tolerant society embraces differences.", "Tolerant mindset."),
    ("Upright", "Dürüst, namuslu, dik", "B2", "/ˈʌp.raɪt/", "sıfat", "An upright citizen serves the community.", "Stand upright."),
    ("Zealous", "Gayretli, şevkli, hevesli", "C1", "/ˈzel.əs/", "sıfat", "A zealous student never stops exploring.", "Zealous dedication."),
    ("Astute", "Ferasetli, cin fikirli, kurnaz", "C1", "/əˈstjuːt/", "sıfat", "An astute observer noticed the detail.", "Astute businessman."),
    ("Discerning", "İnce anlayışlı, seçici", "C1", "/dɪˈsɜː.nɪŋ/", "sıfat", "Discerning readers enjoy classic literature.", "Discerning taste."),
    ("Exemplary", "Örnek niteliğinde, kusursuz", "C1", "/ɪɡˈzem.plər.i/", "sıfat", "Her exemplary conduct inspired students.", "Exemplary behavior."),
    ("Impartial", "Tarafsız, yansız, adil", "C1", "/ɪmˈpɑː.ʃəl/", "sıfat", "Judges must remain impartial and just.", "Impartial judge."),
    ("Meticulous", "Titiz, kılı kırk yaran", "C1", "/məˈtɪk.jə.ləs/", "sıfat", "A meticulous scientist records all data.", "Meticulous work."),
    ("Plausible", "Akla yatkın, mantıklı", "B2", "/ˈplɔː.zə.bəl/", "sıfat", "He gave a plausible explanation.", "Plausible theory."),
    ("Profound", "Derin, köklü, nüfuz edici", "C1", "/prəˈfaʊnd/", "sıfat", "His words had a profound impact.", "Profound thought."),
    ("Prudent", "İhtiyatlı, basiretli", "C1", "/ˈpruː.dənt/", "sıfat", "It is prudent to save for rainy days.", "A prudent choice."),
    ("Relentless", "Amansız, dur durak bilmez", "C1", "/rɪˈlent.ləs/", "sıfat", "Relentless practice brings excellence.", "Relentless effort."),
    ("Steadfast", "Yolundan dönmez, sarsılmaz", "C1", "/ˈsted.fɑːst/", "sıfat", "Steadfast loyalty in tough trials.", "Steadfast courage."),
    ("Vibrant", "Canlı, hareketli, enerjik", "B2", "/ˈvaɪ.brənt/", "sıfat", "Istanbul has a vibrant cultural life.", "Vibrant colors."),
    ("Zeal", "Şevk, gayret, heves", "C1", "/ziːl/", "isim", "Work with unyielding moral zeal.", "Religious zeal."),
    ("Altruistic", "Özgecil, başkasını düşünen", "C1", "/ˌæl.truˈɪs.tɪk/", "sıfat", "Altruistic actions uplift communities.", "Altruistic motives."),
    ("Munificent", "Son derece cömert, eli açık", "C2", "/mjuːˈnɪf.ə.sənt/", "sıfat", "A munificent gift to the university.", "Munificent patron."),
    ("Paragon", "Mükemmellik timsali, örnek", "C2", "/ˈpær.ə.ɡən/", "isim", "She was hailed as a paragon of virtue.", "Paragon of wisdom."),
    ("Perspicacious", "Görüşü keskin, ferasetli", "C2", "/ˌpɜː.spɪˈkeɪ.ʃəs/", "sıfat", "A perspicacious mind foresees challenges.", "Perspicacious critic."),
    ("Quotidian", "Gündelik, sıradan", "C2", "/kwəʊˈtɪd.i.ən/", "sıfat", "Finding beauty in quotidian tasks.", "Quotidian routine."),
    ("Redoubtable", "Heybetli, saygı uyandıran", "C2", "/rɪˈdaʊ.tə.bəl/", "sıfat", "A redoubtable champion in the tournament.", "Redoubtable opponent."),
    ("Resplendent", "Göz kamaştırıcı, muhteşem", "C2", "/rɪˈsplen.dənt/", "sıfat", "Resplendent in royal regalia.", "Resplendent beauty."),
    ("Sycophant", "Dalkavuk, şakşakçı", "C2", "/ˈsɪk.ə.fænt/", "isim", "Leaders should reject flattering sycophants.", "Beware sycophants."),
    ("Tenable", "Savunulabilir, geçerli", "C2", "/ˈten.ə.bəl/", "sıfat", "The hypothesis is scientifically tenable.", "Tenable position."),
    ("Ubiquitous", "Her yerde hazır ve nazır", "C2", "/juːˈbɪk.wɪ.təs/", "sıfat", "Smartphones are ubiquitous today.", "Ubiquitous presence."),
    ("Vacillate", "Tereddüt etmek, bocalamak", "C2", "/ˈvæs.ə.leɪt/", "fiil", "Do not vacillate between decisions.", "Vacillate between choices."),
    ("Wizened", "Kırışmış, yılların izini taşıyan", "C2", "/ˈwɪz.ənd/", "sıfat", "The wizened sage smiled peacefully.", "Wizened face."),
    ("Zenith", "Zirve, doruk noktası", "C2", "/ˈzen.ɪθ/", "isim", "His career reached its absolute zenith.", "At the zenith."),
    ("Affable", "Cana yakın, hoşsohbet", "B2", "/ˈæf.ə.bəl/", "sıfat", "An affable host welcomed the guests.", "Affable manner."),
    ("Cordial", "İçten, samimi, candan", "B2", "/ˈkɔː.di.əl/", "sıfat", "We received a cordial welcome.", "Cordial relations."),
    ("Definitive", "Kesin, nihai", "B2", "/dɪˈfɪn.ɪ.tɪv/", "sıfat", "The definitive edition of the book.", "Definitive answer."),
    ("Empirical", "Deneysel, tecrübeye dayalı", "B2", "/ɪmˈpɪr.ɪ.kəl/", "sıfat", "Science relies on empirical evidence.", "Empirical studies."),
    ("Feasible", "Yapılabilir, uygulanabilir", "B2", "/ˈfiː.zə.bəl/", "sıfat", "The project is technically feasible.", "Feasible plan."),
    ("Gregarious", "Sokulgan, sosyal, cana yakın", "C1", "/ɡrɪˈɡeə.ri.əs/", "sıfat", "Dolphins are gregarious creatures.", "Gregarious personality."),
    ("Holistic", "Bütüncül, tümel", "C1", "/həʊˈlɪs.tɪk/", "sıfat", "A holistic approach to education.", "Holistic health."),
    ("Infallible", "Hata yapmaz, şaşmaz", "C1", "/ɪnˈfæl.ə.bəl/", "sıfat", "No human judgment is infallible.", "Infallible logic."),
    ("Juxtapose", "Yan yana koyup kıyaslamak", "C1", "/ˌdʒʌk.stəˈpəʊz/", "fiil", "Juxtapose light and shadow in art.", "Juxtapose ideas."),
    ("Kaleidoscopic", "Sürekli değişen, rengarenk", "C2", "/kəˌlaɪ.dəˈskɒp.ɪk/", "sıfat", "A kaleidoscopic array of cultures.", "Kaleidoscopic view."),
    ("Luminous", "Işıldayan, parlak, aydınlık", "B2", "/ˈluː.mɪ.nəs/", "sıfat", "A luminous full moon over the hills.", "Luminous smile."),
    ("Meritorious", "Övgüye değer, takdire şayan", "C1", "/ˌmer.ɪˈtɔː.ri.əs/", "sıfat", "Meritorious service to the nation.", "Meritorious conduct."),
    ("Nebulous", "Bulutlu, belirsiz, muğlak", "C2", "/ˈneb.jə.ləs/", "sıfat", "His arguments remained nebulous.", "Nebulous concepts."),
    ("Opulent", "Gösterişli, zengin, şatafatlı", "C1", "/ˈɒp.jə.lənt/", "sıfat", "The opulent palace attracted tourists.", "Opulent lifestyle."),
    ("Pinnacle", "Zirve, doruk, şahika", "C1", "/ˈpɪn.ə.kəl/", "isim", "Reach the pinnacle of academic success.", "Pinnacle of achievement."),
    ("Quintessential", "Özünü yansıtan, en tipik", "C2", "/ˌkwɪn.tɪˈsen.ʃəl/", "sıfat", "Tea is the quintessential Turkish drink.", "Quintessential example."),
    ("Ruminate", "Derin derin düşünmek, kafa yormak", "C2", "/ˈruː.mɪ.neɪt/", "fiil", "Ruminate on philosophical questions.", "Ruminate over past."),
    ("Salient", "En belirgin, göze çarpan", "C1", "/ˈseɪ.li.ənt/", "sıfat", "Summarize the salient points of speech.", "Salient features."),
    ("Tranquil", "Sakin, dingin, huzurlu", "B2", "/ˈtræŋ.kwɪl/", "sıfat", "A tranquil village by the seaside.", "Tranquil atmosphere."),
    ("Unequivocal", "Şüphe götürmez, açık ve net", "C1", "/ˌʌn.ɪˈkwɪv.ə.kəl/", "sıfat", "An unequivocal statement of truth.", "Unequivocal victory."),
    ("Veritable", "Gerçekten de, kelimenin tam anlamıyla", "C2", "/ˈver.ɪ.tə.bəl/", "sıfat", "The library was a veritable goldmine.", "A veritable feast."),
    ("Whimsical", "Garip ve sevimli, kaprisli", "B2", "/ˈwɪm.zɪ.kəl/", "sıfat", "A whimsical fairy tale for children.", "Whimsical drawings."),
    ("Xenophile", "Yabancı kültürleri seven kimse", "C2", "/ˈzen.ə.faɪl/", "isim", "He is a lifelong traveler and xenophile.", "Curious xenophile."),
    ("Yielding", "Uysal, yumuşak, verimli", "B2", "/ˈjiːl.dɪŋ/", "sıfat", "Yielding fertile soil produced abundant wheat.", "Yielding nature."),
    ("Zephyr", "Ilık hafif rüzgar, meltem", "C2", "/ˈzef.ər/", "isim", "A gentle summer zephyr cooled the night.", "Evening zephyr."),
]

def add_more():
    existing = set(r[0].lower() for r in cursor.execute("SELECT word FROM dictionary").fetchall())
    inserted = 0
    for w, t, lvl, phon, pos, defn, ex in ADDITIONAL_WORDS:
        word_clean = w.strip().capitalize()
        if word_clean.lower() not in existing:
            meanings_json = json.dumps([{
                "part_of_speech": pos,
                "definition": defn,
                "example": ex
            }], ensure_ascii=False)

            cursor.execute(
                "INSERT INTO dictionary (word, translation, level, phonetic, meanings) VALUES (?, ?, ?, ?, ?)",
                (word_clean, t, lvl, phon, meanings_json)
            )
            existing.add(word_clean.lower())
            inserted += 1

    conn.commit()
    total_now = cursor.execute("SELECT COUNT(*) FROM dictionary").fetchone()[0]
    print(f"Eklenen: {inserted}, Toplam Kelime: {total_now}")

    levels = cursor.execute("SELECT level, COUNT(*) FROM dictionary GROUP BY level ORDER BY level").fetchall()
    print("Seviye Dagilimi:")
    for lvl, count in levels:
        print(f"  {lvl}: {count} kelime")
    conn.close()

if __name__ == "__main__":
    add_more()
