import random
from sqlalchemy.orm import Session
from app.repository.user_repository import UserRepository
from app.schemas.quiz_schema import QuizResult, QuizQuestionResponse
from app.models.dictionary import DictionaryWord

user_repo = UserRepository()

DEFAULT_VOCABULARY = [
    {"word": "Ambition", "translation": "Arzu, hırs, azim", "level": "B2"},
    {"word": "Goal", "translation": "Hedef, amaç", "level": "A2"},
    {"word": "Resilient", "translation": "Dirençli, çabuk toparlanan", "level": "B2"},
    {"word": "Curious", "translation": "Meraklı, ilgili", "level": "A2"},
    {"word": "Challenge", "translation": "Meydan okuma, zorluk", "level": "B1"},
    {"word": "Inspire", "translation": "İlham vermek", "level": "B1"},
    {"word": "Opportunity", "translation": "Fırsat, imkan", "level": "B1"},
    {"word": "Knowledge", "translation": "Bilgi, birikim", "level": "A2"},
    {"word": "Achieve", "translation": "Başarmak, elde etmek", "level": "B1"},
    {"word": "Persevere", "translation": "Sebat etmek, azmetmek", "level": "C1"},
    {"word": "Discovery", "translation": "Keşif, buluş", "level": "B1"},
    {"word": "Courage", "translation": "Cesaret, yüreklilik", "level": "B1"},
    {"word": "Confidence", "translation": "Özgüven, inanç", "level": "B1"},
    {"word": "Dedication", "translation": "Adanmışlık, bağlılık", "level": "B2"},
    {"word": "Wisdom", "translation": "Bilgelik, akıl", "level": "B2"},
    {"word": "Patience", "translation": "Sabır, tahammül", "level": "B1"},
    {"word": "Growth", "translation": "Büyüme, gelişim", "level": "A2"},
    {"word": "Success", "translation": "Başarı, muvaffakiyet", "level": "A2"},
    {"word": "Freedom", "translation": "Özgürlük, hürriyet", "level": "A2"},
    {"word": "Adventure", "translation": "Macera, serüven", "level": "B1"},
    {"word": "Honesty", "translation": "Dürüstlük, doğruluk", "level": "A2"},
    {"word": "Empathy", "translation": "Eşduyum, empati", "level": "B2"},
    {"word": "Generous", "translation": "Cömert, eli açık", "level": "B1"},
    {"word": "Brave", "translation": "Cesur, korkusuz", "level": "A1"},
    {"word": "Brilliant", "translation": "Parlak, zeki, muazzam", "level": "B2"},
]

FALLBACK_DISTRACTORS = [
    "Fırsat, imkan",
    "Bilgi, birikim",
    "Meydan okuma, zorluk",
    "Özgüven, inanç",
    "Keşif, buluş",
    "Sabır, tahammül",
    "Dürüstlük, doğruluk",
    "Büyüme, gelişim",
    "Başarı, muvaffakiyet",
    "Özgürlük, hürriyet",
    "Cesur, korkusuz",
    "Mutlu, sevinçli"
]

class QuizService:
    def _seed_dictionary_if_empty(self, db: Session):
        count = db.query(DictionaryWord).count()
        if count < len(DEFAULT_VOCABULARY):
            existing_words = {w.word.lower() for w in db.query(DictionaryWord.word).all()}
            for item in DEFAULT_VOCABULARY:
                if item["word"].lower() not in existing_words:
                    new_word = DictionaryWord(
                        word=item["word"].capitalize(),
                        translation=item["translation"],
                        level=item["level"],
                        phonetic=None,
                        meanings=[{"part_of_speech": "tanım", "definition": item["translation"], "example": None}]
                    )
                    db.add(new_word)
            db.commit()

    def generate_questions(self, db: Session, count: int = 5) -> list[QuizQuestionResponse]:
        self._seed_dictionary_if_empty(db)

        # Veritabanından tüm kelimeleri çek
        db_words = db.query(DictionaryWord).all()
        vocab_pool = [
            {"word": w.word.capitalize(), "translation": w.translation, "level": w.level}
            for w in db_words
        ]

        if len(vocab_pool) < 4:
            vocab_pool = DEFAULT_VOCABULARY

        # Rastgele soru seç
        sample_count = min(count, len(vocab_pool))
        selected_words = random.sample(vocab_pool, sample_count)
        
        # Benzersiz tüm çevirileri al
        all_translations = list(dict.fromkeys([item["translation"] for item in vocab_pool]))

        questions = []
        for idx, item in enumerate(selected_words):
            correct_trans = item["translation"]
            
            # Doğru cevap dışındaki benzersiz seçenekler
            wrong_candidates = [t for t in all_translations if t != correct_trans]
            
            # Eğer 3'ten az çeldirici varsa yedek havuzdan tamamla
            for fallback in FALLBACK_DISTRACTORS:
                if len(wrong_candidates) >= 3:
                    break
                if fallback != correct_trans and fallback not in wrong_candidates:
                    wrong_candidates.append(fallback)

            wrong_options = random.sample(wrong_candidates, 3)
            
            # 4 seçeneği karıştır
            options = [correct_trans] + wrong_options
            random.shuffle(options)
            correct_idx = options.index(correct_trans)

            questions.append(
                QuizQuestionResponse(
                    id=idx + 1,
                    question=f'“{item["word"]}” kelimesinin Türkçe anlamı hangisidir?',
                    word=item["word"],
                    options=options,
                    correct_index=correct_idx,
                    level=item.get("level", "A1")
                )
            )

        return questions

    def process_quiz_result(self, db: Session, user_id: int, result: QuizResult):
        earned_xp = max(0, result.correct_answers * 10)
        
        user = user_repo.get_user_by_id(db, user_id)
        if not user:
            return {
                "earned_xp": earned_xp,
                "total_xp": earned_xp,
                "current_level": 1
            }
            
        user.xp += earned_xp
        
        # Level Algoritması: Her 100 XP = 1 Level (Örn: 250 XP = Level 3)
        new_level = max(1, (user.xp // 100) + 1)
        if new_level > user.level:
            user.level = new_level
            
        db.commit()
        db.refresh(user)
        
        return {
            "earned_xp": earned_xp,
            "total_xp": user.xp,
            "current_level": user.level
        }

    def get_leaderboard(self, db: Session):
        return user_repo.get_top_users(db, limit=10)
