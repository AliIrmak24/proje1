import datetime
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.schemas.word_schema import WordResponse, Meaning
from app.models.dictionary import DictionaryWord

RICH_SEED_WORDS = [
    # A1
    {"word": "apple", "translation": "Elma", "level": "A1", "phonetic": "/ˈæp.əl/", "meanings": [{"part_of_speech": "isim", "definition": "Ağaçta yetişen yuvarlak, tatlı meyve.", "example": "I eat an apple every morning."}]},
    {"word": "book", "translation": "Kitap", "level": "A1", "phonetic": "/bʊk/", "meanings": [{"part_of_speech": "isim", "definition": "Okumak veya yazmak için ciltlenmiş yapraklar.", "example": "She is reading a wonderful book."}]},
    {"word": "friend", "translation": "Arkadaş, dost", "level": "A1", "phonetic": "/frend/", "meanings": [{"part_of_speech": "isim", "definition": "Karşılıklı sevgi ve güven duyulan kişi.", "example": "He is my best friend from school."}]},
    {"word": "water", "translation": "Su", "level": "A1", "phonetic": "/ˈwɔː.tər/", "meanings": [{"part_of_speech": "isim", "definition": "Yaşam için vazgeçilmez berrak sıvı.", "example": "Drink plenty of water every day."}]},
    {"word": "house", "translation": "Ev, konut", "level": "A1", "phonetic": "/haʊs/", "meanings": [{"part_of_speech": "isim", "definition": "İnsanların barındığı yapı.", "example": "They bought a new house near the park."}]},
    {"word": "happy", "translation": "Mutlu, sevinçli", "level": "A1", "phonetic": "/ˈhæp.i/", "meanings": [{"part_of_speech": "sıfat", "definition": "İyi hissetme ve tatmin olma durumu.", "example": "We are very happy to meet you."}]},
    {"word": "brave", "translation": "Cesur, korkusuz", "level": "A1", "phonetic": "/breɪv/", "meanings": [{"part_of_speech": "sıfat", "definition": "Tehlikelerden korkmayan, yürekli.", "example": "The brave firefighter saved the cat."}]},
    {"word": "family", "translation": "Aile", "level": "A1", "phonetic": "/ˈfæm.əl.i/", "meanings": [{"part_of_speech": "isim", "definition": "Anne, baba ve çocuklardan oluşan topluluk.", "example": "Family comes first in life."}]},
    {"word": "cat", "translation": "Kedi", "level": "A1", "phonetic": "/kæt/", "meanings": [{"part_of_speech": "isim", "definition": "Küçük, evcil, tüylü hayvan.", "example": "The cat is sleeping on the sofa."}]},
    {"word": "dog", "translation": "Köpek", "level": "A1", "phonetic": "/dɒɡ/", "meanings": [{"part_of_speech": "isim", "definition": "Sadık ve evcil hayvan.", "example": "The dog is playing in the garden."}]},
    {"word": "school", "translation": "Okul", "level": "A1", "phonetic": "/skuːl/", "meanings": [{"part_of_speech": "isim", "definition": "Eğitim ve öğretim yapılan kurum.", "example": "Children go to school every morning."}]},
    {"word": "teacher", "translation": "Öğretmen", "level": "A1", "phonetic": "/ˈtiː.tʃər/", "meanings": [{"part_of_speech": "isim", "definition": "Öğrencilere ders veren kişi.", "example": "My teacher is very kind and patient."}]},

    # A2
    {"word": "curious", "translation": "Meraklı, ilgili", "level": "A2", "phonetic": "/ˈkjʊə.ri.əs/", "meanings": [{"part_of_speech": "sıfat", "definition": "Bir şeyi öğrenmek veya bilmek isteyen.", "example": "Children are naturally curious about nature."}]},
    {"word": "travel", "translation": "Seyahat etmek, gezmek", "level": "A2", "phonetic": "/ˈtræv.əl/", "meanings": [{"part_of_speech": "fiil", "definition": "Bir yerden bir yere gitmek.", "example": "They love to travel around the world."}]},
    {"word": "knowledge", "translation": "Bilgi, birikim", "level": "A2", "phonetic": "/ˈnɒl.ɪdʒ/", "meanings": [{"part_of_speech": "isim", "definition": "Öğrenme veya gözlem yoluyla kazanılan şey.", "example": "Reading is the foundation of knowledge."}]},
    {"word": "advice", "translation": "Tavsiye, öğüt", "level": "A2", "phonetic": "/ədˈvaɪs/", "meanings": [{"part_of_speech": "isim", "definition": "Yol gösterici öneri.", "example": "She gave me valuable advice on my career."}]},
    {"word": "healthy", "translation": "Sağlıklı, sıhhatli", "level": "A2", "phonetic": "/ˈhel.θi/", "meanings": [{"part_of_speech": "sıfat", "definition": "Bedensel ve ruhsal olarak iyi durumda olan.", "example": "Daily exercise keeps you healthy."}]},
    {"word": "simple", "translation": "Basit, sade", "level": "A2", "phonetic": "/ˈsɪm.pəl/", "meanings": [{"part_of_speech": "sıfat", "definition": "Anlaşılması veya yapılması kolay olan.", "example": "The solution was surprisingly simple."}]},
    {"word": "growth", "translation": "Büyüme, gelişim", "level": "A2", "phonetic": "/ɡrəʊθ/", "meanings": [{"part_of_speech": "isim", "definition": "Zamanla olgunlaşma ve genişleme.", "example": "Personal growth requires continuous effort."}]},
    {"word": "weather", "translation": "Hava durumu", "level": "A2", "phonetic": "/ˈweð.ər/", "meanings": [{"part_of_speech": "isim", "definition": "Bir bölgedeki atmosfer koşulları.", "example": "The weather is sunny today."}]},
    {"word": "important", "translation": "Önemli, mühim", "level": "A2", "phonetic": "/ɪmˈpɔː.tənt/", "meanings": [{"part_of_speech": "sıfat", "definition": "Büyük değer veya anlam taşıyan.", "example": "Education is very important for everyone."}]},
    {"word": "beautiful", "translation": "Güzel, hoş", "level": "A2", "phonetic": "/ˈbjuː.tɪ.fəl/", "meanings": [{"part_of_speech": "sıfat", "definition": "Estetik olarak hoş ve çekici.", "example": "The sunset was incredibly beautiful."}]},

    # B1
    {"word": "challenge", "translation": "Meydan okuma, zorluk", "level": "B1", "phonetic": "/ˈtʃæl.ɪndʒ/", "meanings": [{"part_of_speech": "isim", "definition": "Yetenek ve çaba gerektiren güç durum.", "example": "Learning coding is an exciting challenge."}]},
    {"word": "inspire", "translation": "İlham vermek, esinlendirmek", "level": "B1", "phonetic": "/ɪnˈspaɪər/", "meanings": [{"part_of_speech": "fiil", "definition": "Birinde bir şey yapma isteği uyandırmak.", "example": "Her courage inspired everyone in the team."}]},
    {"word": "opportunity", "translation": "Fırsat, imkan", "level": "B1", "phonetic": "/ˌɒp.əˈtʃuː.nə.ti/", "meanings": [{"part_of_speech": "isim", "definition": "Bir işi gerçekleştirmeye elverişli durum.", "example": "This internship is a great career opportunity."}]},
    {"word": "courage", "translation": "Cesaret, yüreklilik", "level": "B1", "phonetic": "/ˈkʌr.ɪdʒ/", "meanings": [{"part_of_speech": "isim", "definition": "Korku karşısında yılmama gücü.", "example": "It takes courage to speak in front of people."}]},
    {"word": "generous", "translation": "Cömert, eli açık", "level": "B1", "phonetic": "/ˈdʒen.ər.əs/", "meanings": [{"part_of_speech": "sıfat", "definition": "Varlığını paylaşmaktan kaçınmayan.", "example": "He was generous enough to help the students."}]},
    {"word": "confidence", "translation": "Özgüven, inanç", "level": "B1", "phonetic": "/ˈkɒn.fɪ.dəns/", "meanings": [{"part_of_speech": "isim", "definition": "Kişinin kendine ve yeteneklerine olan güveni.", "example": "Practice builds self-confidence."}]},
    {"word": "adventure", "translation": "Macera, serüven", "level": "B1", "phonetic": "/ədˈven.tʃər/", "meanings": [{"part_of_speech": "isim", "definition": "Heyecan ve tehlike içeren deneyim.", "example": "Their trip to the Alps was a real adventure."}]},
    {"word": "experience", "translation": "Deneyim, tecrübe", "level": "B1", "phonetic": "/ɪkˈspɪə.ri.əns/", "meanings": [{"part_of_speech": "isim", "definition": "Yaşayarak öğrenilen bilgi ve beceri.", "example": "Travel gives you valuable life experience."}]},
    {"word": "environment", "translation": "Çevre, ortam", "level": "B1", "phonetic": "/ɪnˈvaɪ.rən.mənt/", "meanings": [{"part_of_speech": "isim", "definition": "Canlıların yaşadığı doğal veya yapay ortam.", "example": "We must protect the environment for future generations."}]},

    # B2
    {"word": "ambition", "translation": "Büyük başarı arzusu, hırs, azim", "level": "B2", "phonetic": "/æmˈbɪʃ.ən/", "meanings": [{"part_of_speech": "isim", "definition": "Büyük bir hedefe ulaşma kararlılığı ve isteği.", "example": "Her ambition is to become a leading software architect."}]},
    {"word": "resilient", "translation": "Dirençli, çabuk toparlanan", "level": "B2", "phonetic": "/rɪˈzɪl.jənt/", "meanings": [{"part_of_speech": "sıfat", "definition": "Zorluklar karşısında yılmayan ve toparlanabilen.", "example": "Humans are remarkably resilient when faced with adversity."}]},
    {"word": "dedication", "translation": "Adanmışlık, bağlılık", "level": "B2", "phonetic": "/ˌded.ɪˈkeɪ.ʃən/", "meanings": [{"part_of_speech": "isim", "definition": "Kendini bir amaca veya göreve verme.", "example": "Success requires immense dedication and patience."}]},
    {"word": "wisdom", "translation": "Bilgelik, akıl", "level": "B2", "phonetic": "/ˈwɪz.dəm/", "meanings": [{"part_of_speech": "isim", "definition": "Doğru karar verme yeteneği ve deneyim birikimi.", "example": "With age comes deep wisdom and calm."}]},
    {"word": "empathy", "translation": "Eşduyum, empati", "level": "B2", "phonetic": "/ˈem.pə.θi/", "meanings": [{"part_of_speech": "isim", "definition": "Başkasının hislerini anlama yeteneği.", "example": "Empathy is essential for compassionate leadership."}]},
    {"word": "brilliant", "translation": "Parlak, zeki, muazzam", "level": "B2", "phonetic": "/ˈbrɪl.jənt/", "meanings": [{"part_of_speech": "sıfat", "definition": "Olağanüstü zeka veya parlaklık gösteren.", "example": "The scientist proposed a brilliant solution."}]},
    {"word": "phenomenon", "translation": "Fenomen, olgu", "level": "B2", "phonetic": "/fəˈnɒm.ɪ.nən/", "meanings": [{"part_of_speech": "isim", "definition": "Gözlemlenebilen dikkat çekici olay veya durum.", "example": "Social media is a global phenomenon."}]},
    {"word": "perspective", "translation": "Bakış açısı, perspektif", "level": "B2", "phonetic": "/pəˈspek.tɪv/", "meanings": [{"part_of_speech": "isim", "definition": "Bir konuya yaklaşma biçimi veya görüş.", "example": "Try to see it from a different perspective."}]},

    # C1
    {"word": "persevere", "translation": "Sebat etmek, azmetmek", "level": "C1", "phonetic": "/ˌpɜː.sɪˈvɪər/", "meanings": [{"part_of_speech": "fiil", "definition": "Tüm zorluklara ve engellere rağmen vazgeçmemek.", "example": "You must persevere through setbacks to master a craft."}]},
    {"word": "eloquent", "translation": "Güzel konuşan, beliğ, etkileyici", "level": "C1", "phonetic": "/ˈel.ə.kwənt/", "meanings": [{"part_of_speech": "sıfat", "definition": "Düşüncelerini akıcı ve etkileyici aktaran.", "example": "He gave an eloquent speech at the global summit."}]},
    {"word": "meticulous", "translation": "Titiz, kılı kırk yaran", "level": "C1", "phonetic": "/məˈtɪk.jə.ləs/", "meanings": [{"part_of_speech": "sıfat", "definition": "Ayrıntılara aşırı özen gösteren.", "example": "The researcher kept meticulous records of every experiment."}]},
    {"word": "inevitable", "translation": "Kaçınılmaz, önüne geçilemez", "level": "C1", "phonetic": "/ɪnˈev.ɪ.tə.bəl/", "meanings": [{"part_of_speech": "sıfat", "definition": "Gerçekleşmesi mutlak olan durum.", "example": "Change is an inevitable reality in technological progress."}]},
    {"word": "profound", "translation": "Derin, köklü, nüfuz edici", "level": "C1", "phonetic": "/prəˈfaʊnd/", "meanings": [{"part_of_speech": "sıfat", "definition": "Çok derin veya büyük etkisi olan.", "example": "The mentor's words had a profound impact on his worldview."}]},
    {"word": "pragmatic", "translation": "Pragmatik, pratik, gerçekçi", "level": "C1", "phonetic": "/præɡˈmæt.ɪk/", "meanings": [{"part_of_speech": "sıfat", "definition": "Teoriden çok pratiğe dayanan yaklaşım.", "example": "We need a pragmatic solution to this problem."}]},
    {"word": "nuance", "translation": "Nüans, ince ayrım", "level": "C1", "phonetic": "/ˈnjuː.ɑːns/", "meanings": [{"part_of_speech": "isim", "definition": "Anlam veya ifadedeki çok ince fark.", "example": "Language learners must understand cultural nuances."}]},

    # C2
    {"word": "ubiquitous", "translation": "Her yerde bulunan, yaygın", "level": "C2", "phonetic": "/juːˈbɪk.wɪ.təs/", "meanings": [{"part_of_speech": "sıfat", "definition": "Her yerde aynı anda var gibi görünen.", "example": "Mobile phones have become ubiquitous in modern society."}]},
    {"word": "ephemeral", "translation": "Geçici, kısa ömürlü", "level": "C2", "phonetic": "/ɪˈfem.ər.əl/", "meanings": [{"part_of_speech": "sıfat", "definition": "Çok kısa süre devam eden.", "example": "Fame can be ephemeral in the age of social media."}]},
    {"word": "paradigm", "translation": "Örüntü, model, paradigma", "level": "C2", "phonetic": "/ˈpær.ə.daɪm/", "meanings": [{"part_of_speech": "isim", "definition": "Bir alandaki temel düşünce veya davranış kalıbı.", "example": "The internet created a new paradigm for communication."}]},
    {"word": "serendipity", "translation": "Şans eseri keşif, tesadüfi buluş", "level": "C2", "phonetic": "/ˌser.ənˈdɪp.ə.ti/", "meanings": [{"part_of_speech": "isim", "definition": "Tesadüfen güzel ve değerli bir şey bulmak.", "example": "Their meeting was pure serendipity."}]}
]

class WordService:
    def __init__(self):
        self._seeded = False

    def seed_words_if_needed(self, db: Session):
        if self._seeded:
            return
        count = db.query(DictionaryWord.id).count()
        if count > 100:
            self._seeded = True
            return
            
        existing_words = {w.word.lower() for w in db.query(DictionaryWord.word).all()}
        for item in RICH_SEED_WORDS:
            word_key = item["word"].lower()
            if word_key not in existing_words:
                db_word = DictionaryWord(
                    word=item["word"].capitalize(),
                    translation=item["translation"],
                    level=item["level"],
                    phonetic=item.get("phonetic"),
                    meanings=item["meanings"],
                )
                db.add(db_word)
                existing_words.add(word_key)
        db.commit()
        self._seeded = True

    def _predict_cefr_level(self, word: str) -> str:
        word = word.lower().strip()
        length = len(word)
        if length <= 4:
            return "A1"
        elif length <= 6:
            return "A2"
        elif length <= 8:
            return "B1"
        elif length <= 10:
            return "B2"
        elif length <= 12:
            return "C1"
        else:
            return "C2"

    def get_word_of_the_day(self, db: Session, level: str | None = None) -> WordResponse:
        self.seed_words_if_needed(db)
        query = db.query(DictionaryWord)

        if level and level.upper().strip() in ["A1", "A2", "B1", "B2", "C1", "C2"]:
            level_clean = level.upper().strip()
            level_words = query.filter(DictionaryWord.level == level_clean).all()
            if level_words:
                today_ordinal = datetime.date.today().toordinal()
                # Farklı seviyeler için farklı ofset
                level_offset = ord(level_clean[0]) * 7 + (int(level_clean[1]) if len(level_clean) > 1 and level_clean[1].isdigit() else 1)
                selected = level_words[(today_ordinal + level_offset) % len(level_words)]
                meanings_list = [Meaning(**m) for m in (selected.meanings or [])]
                return WordResponse(
                    word=selected.word,
                    translation=selected.translation,
                    phonetic=selected.phonetic,
                    level=selected.level,
                    meanings=meanings_list,
                )

        words = query.all()
        if not words:
            raise HTTPException(status_code=404, detail="Sözlükte kelime bulunamadı")

        # Gün bazlı deterministik seçim
        today_ordinal = datetime.date.today().toordinal()
        selected = words[today_ordinal % len(words)]

        meanings_list = [Meaning(**m) for m in (selected.meanings or [])]
        return WordResponse(
            word=selected.word,
            translation=selected.translation,
            phonetic=selected.phonetic,
            level=selected.level,
            meanings=meanings_list,
        )

    def get_level_counts(self, db: Session) -> dict[str, int]:
        self.seed_words_if_needed(db)
        levels = ["A1", "A2", "B1", "B2", "C1", "C2"]
        counts = {lvl: 0 for lvl in levels}
        all_words = db.query(DictionaryWord.level).all()
        for (lvl,) in all_words:
            if lvl in counts:
                counts[lvl] += 1
            else:
                counts[lvl] = 1
        return counts

    def get_all_words(self, db: Session, level: str | None = None, search: str | None = None, limit: int = 6000) -> list[WordResponse]:
        self.seed_words_if_needed(db)
        query = db.query(DictionaryWord)
        
        if level and level.upper() not in ["ALL", "TÜMÜ", ""]:
            query = query.filter(DictionaryWord.level == level.upper().strip())
            
        if search and search.strip():
            clean_search = f"%{search.strip()}%"
            query = query.filter(
                (DictionaryWord.word.ilike(clean_search)) | 
                (DictionaryWord.translation.ilike(clean_search))
            )
            
        words = query.order_by(DictionaryWord.level.asc(), DictionaryWord.word.asc()).limit(limit).all()
        result = []
        for w in words:
            meanings_list = [Meaning(**m) for m in (w.meanings or [])]
            result.append(
                WordResponse(
                    word=w.word,
                    translation=w.translation,
                    phonetic=w.phonetic,
                    level=w.level,
                    meanings=meanings_list,
                )
            )
        return result

    def get_words_by_level(self, db: Session, level: str, limit: int = 6000) -> list[WordResponse]:
        return self.get_all_words(db, level=level, limit=limit)

    def search_word(self, db: Session, word: str) -> WordResponse:
        self.seed_words_if_needed(db)
        clean_word = word.strip()
        
        # Sadece DB'de ara (büyük/küçük harf duyarsız)
        db_word = db.query(DictionaryWord).filter(
            DictionaryWord.word.ilike(clean_word)
        ).first()
        
        if db_word:
            meanings_list = [Meaning(**m) for m in (db_word.meanings or [])]
            return WordResponse(
                word=db_word.word,
                translation=db_word.translation,
                phonetic=db_word.phonetic,
                level=db_word.level,
                meanings=meanings_list,
            )

        raise HTTPException(status_code=404, detail=f"'{clean_word}' kelimesi sözlükte bulunamadı.")