import random
import re
from datetime import timedelta
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.repository.user_repository import UserRepository
from app.schemas.quiz_schema import (
    ActivityResult,
    QuizAnswerRequest,
    QuizAnswerResponse,
    QuizQuestionResponse,
    QuizSessionResponse,
)
from app.models.dictionary import DictionaryWord
from app.models.quiz import QuizSession, utcnow
from app.models.user import User
from app.services.learning_service import record_review
from app.services.word_service import CEFR_LEVELS
from app.services.xp_service import award_xp

user_repo = UserRepository()

XP_PER_CORRECT_ANSWER = 10
QUIZ_SESSION_LIFETIME = timedelta(minutes=30)
PLACEMENT_QUESTIONS_PER_LEVEL = 3
PLACEMENT_PASS_COUNT = 2

# Etkinlik başına kabul edilen en yüksek doğru sayısı ve doğru başına XP
ACTIVITY_RULES = {
    "matching": (6, 10),
    "mini_quiz": (1, 5),
    "reading": (1, 15),
}

def _senses(translation: str) -> set[str]:
    return {part.strip().lower() for part in translation.split(",")}

def _part_of_speech(word: DictionaryWord) -> str | None:
    return word.meanings[0].get("part_of_speech") if word.meanings else None

def _pick_distractors(db: Session, word: DictionaryWord, attribute: str) -> list[str]:
    candidates = db.query(DictionaryWord).filter(
        DictionaryWord.level == word.level,
        DictionaryWord.id != word.id
    ).order_by(func.random()).limit(60).all()
    if len(candidates) < 3:
        candidates = db.query(DictionaryWord).filter(
            DictionaryWord.id != word.id
        ).order_by(func.random()).limit(60).all()

    # Aynı türden kelimeler önce gelir; doğru cevapla anlamı örtüşen şıklar elenir
    candidates.sort(key=lambda c: _part_of_speech(c) != _part_of_speech(word))
    used = _senses(word.translation)
    distractors: list[str] = []
    for candidate in candidates:
        senses = _senses(candidate.translation)
        if not senses & used:
            used |= senses
            distractors.append(getattr(candidate, attribute))
        if len(distractors) == 3:
            break
    return distractors

def _cloze_sentence(word: DictionaryWord) -> str | None:
    example = (word.meanings[0].get("example") or "") if word.meanings else ""
    blanked, replaced = re.subn(rf"\b{re.escape(word.word)}\b", "_____", example, count=1, flags=re.IGNORECASE)
    return blanked if replaced else None

def _build_question(db: Session, word: DictionaryWord, index: int, kind: str) -> tuple[QuizQuestionResponse, int]:
    cloze = _cloze_sentence(word) if kind == "cloze" else None
    if kind == "cloze" and not cloze:
        kind = "en_tr"

    if kind in ("tr_en", "cloze"):
        correct, attribute = word.word, "word"
    else:
        correct, attribute = word.translation, "translation"

    options = [correct] + _pick_distractors(db, word, attribute)
    random.shuffle(options)

    question = {
        "en_tr": f"“{word.word}” kelimesinin Türkçe anlamı hangisidir?",
        "tr_en": f"“{word.translation}” anlamına gelen İngilizce kelime hangisidir?",
        "listening": "Duyduğun kelimenin Türkçe anlamı hangisidir?",
        "cloze": f"Boşluğa hangi kelime gelir?\n{cloze}",
    }[kind]

    return QuizQuestionResponse(
        id=index + 1,
        kind=kind,
        question=question,
        word=word.word if kind == "en_tr" else None,
        speak_text=word.word if kind == "listening" else None,
        options=options,
        level=word.level,
    ), options.index(correct)

class QuizService:
    def create_session(self, db: Session, user: User, count: int = 5, level: str | None = None) -> QuizSessionResponse:
        level = level if level in CEFR_LEVELS else user.cefr_level
        query = db.query(DictionaryWord)
        if level:
            query = query.filter(DictionaryWord.level == level)
        words = query.order_by(func.random()).limit(count).all()
        if not words:
            raise ValueError("Bu seviyede kelime bulunamadı")

        kinds = random.choices(["en_tr", "tr_en", "listening", "cloze"], weights=[4, 2, 2, 2], k=len(words))
        return self._store_session(db, user.id, "quiz", words, kinds)

    def create_placement(self, db: Session, user: User) -> QuizSessionResponse:
        words = []
        for level in CEFR_LEVELS:
            words += db.query(DictionaryWord).filter(
                DictionaryWord.level == level
            ).order_by(func.random()).limit(PLACEMENT_QUESTIONS_PER_LEVEL).all()
        if not words:
            raise ValueError("Sözlükte kelime bulunamadı")
        return self._store_session(db, user.id, "placement", words, ["en_tr"] * len(words))

    def _store_session(self, db: Session, user_id: int, kind: str, words: list[DictionaryWord], kinds: list[str]):
        built = [_build_question(db, word, i, kinds[i]) for i, word in enumerate(words)]
        session = QuizSession(
            user_id=user_id,
            kind=kind,
            word_ids=[w.id for w in words],
            levels=[w.level for w in words],
            correct_indexes=[correct for _, correct in built],
            answers=[None] * len(words),
        )
        db.add(session)
        db.commit()
        return QuizSessionResponse(session_id=session.id, questions=[q for q, _ in built])

    def _get_open_session(self, db: Session, session_id: str, user_id: int) -> QuizSession:
        session = db.query(QuizSession).filter(
            QuizSession.id == session_id,
            QuizSession.user_id == user_id
        ).with_for_update().first()

        if not session:
            raise ValueError("Quiz oturumu bulunamadı")
        if session.submitted_at is not None:
            raise ValueError("Bu quiz zaten tamamlandı")
        if utcnow() - session.created_at > QUIZ_SESSION_LIFETIME:
            raise ValueError("Quiz oturumunun süresi doldu")
        return session

    def answer_question(self, db: Session, user_id: int, answer: QuizAnswerRequest) -> QuizAnswerResponse:
        session = self._get_open_session(db, answer.session_id, user_id)

        index = answer.question_id - 1
        if not 0 <= index < len(session.correct_indexes):
            raise ValueError("Soru bulunamadı")
        if not 0 <= answer.selected_index <= 3:
            raise ValueError("Geçersiz seçenek")

        # İlk cevap geçerlidir; tekrar gelen istek aynı sonucu alır
        answers = list(session.answers)
        correct_index = session.correct_indexes[index]
        if answers[index] is None:
            answers[index] = answer.selected_index
            session.answers = answers
            if session.kind == "quiz":
                record_review(db, user_id, session.word_ids[index], answers[index] == correct_index)
            db.commit()

        return QuizAnswerResponse(correct=answers[index] == correct_index, correct_index=correct_index)

    def submit_session(self, db: Session, user: User, session_id: str) -> dict:
        session = self._get_open_session(db, session_id, user.id)
        correct_flags = [a == c for a, c in zip(session.answers, session.correct_indexes)]

        # Aynı oturum eşzamanlı isteklerle iki kez ödüllendirilemez
        closed = db.query(QuizSession).filter(
            QuizSession.id == session_id,
            QuizSession.submitted_at.is_(None)
        ).update({QuizSession.submitted_at: utcnow()}, synchronize_session=False)
        if closed != 1:
            raise ValueError("Bu quiz zaten tamamlandı")

        wrong_ids = [word_id for word_id, ok in zip(session.word_ids, correct_flags) if not ok]
        wrong_words = {w.id: w for w in db.query(DictionaryWord).filter(DictionaryWord.id.in_(wrong_ids)).all()}
        review = [
            {"word": wrong_words[i].word, "translation": wrong_words[i].translation, "level": wrong_words[i].level}
            for i in wrong_ids if i in wrong_words
        ]

        placement_level = None
        if session.kind == "placement":
            placement_level = self._placement_level(session.levels, correct_flags)
            user.cefr_level = placement_level
            xp = 0
        else:
            xp = sum(correct_flags) * XP_PER_CORRECT_ANSWER

        result = award_xp(db, user, "quiz", xp)
        return {
            **result,
            "correct_answers": sum(correct_flags),
            "review": review,
            "placement_level": placement_level,
        }

    def _placement_level(self, levels: list[str], correct_flags: list[bool]) -> str:
        # Üst üste geçilen en yüksek seviye, kullanıcının seviyesidir
        reached = CEFR_LEVELS[0]
        for level in CEFR_LEVELS:
            correct = sum(ok for lvl, ok in zip(levels, correct_flags) if lvl == level)
            if correct < PLACEMENT_PASS_COUNT:
                break
            reached = level
        return reached

    def process_activity(self, db: Session, user: User, result: ActivityResult):
        max_correct, xp_per_correct = ACTIVITY_RULES[result.activity]
        correct_count = min(result.correct_answers, max_correct)
        return award_xp(db, user, result.activity, correct_count * xp_per_correct)

    def get_leaderboard(self, db: Session):
        return user_repo.get_top_users(db, limit=10)
