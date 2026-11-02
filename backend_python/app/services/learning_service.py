# app/services/learning_service.py
# Leitner kutularıyla aralıklı tekrar ve gerçek öğrenme istatistikleri

from datetime import date, datetime, timedelta
from sqlalchemy import case, func
from sqlalchemy.orm import Session
from app.models.dictionary import DictionaryWord
from app.models.quiz import QuizSession, UserWordProgress, XpEvent, utcnow
from app.models.user import User
from app.schemas.quiz_schema import LearnReviewRequest
from app.services.word_service import CEFR_LEVELS, to_word_response
from app.services.xp_service import award_xp

# Kutu numarasına göre bir sonraki tekrara kalan süre
BOX_INTERVALS = [
    timedelta(minutes=10),
    timedelta(days=1),
    timedelta(days=3),
    timedelta(days=7),
    timedelta(days=14),
    timedelta(days=30),
]
LEARNED_BOX = 2  # En az bir günlük aradan sonra da bilinen kelime öğrenilmiş sayılır
XP_PER_REVIEW = 10
DAILY_WORD_GOAL = 10
LOCAL_UTC_OFFSET = timedelta(hours=3)  # Günlük seri Türkiye saatine göre hesaplanır

def _local_date(moment: datetime) -> date:
    return (moment + LOCAL_UTC_OFFSET).date()

def record_review(db: Session, user_id: int, word_id: int, correct: bool) -> tuple[UserWordProgress, bool]:
    """Sonucu işler; kelime tekrar zamanı gelmişse True döner. Commit çağırana aittir."""
    now = utcnow()
    progress = db.query(UserWordProgress).filter(
        UserWordProgress.user_id == user_id,
        UserWordProgress.word_id == word_id
    ).first()
    if not progress:
        progress = UserWordProgress(
            user_id=user_id, word_id=word_id, box=0, correct_count=0, wrong_count=0, next_review=now
        )
        db.add(progress)

    was_due = progress.next_review <= now
    if correct:
        progress.correct_count += 1
        if was_due:
            progress.box = min(progress.box + 1, len(BOX_INTERVALS) - 1)
    else:
        progress.wrong_count += 1
        progress.box = 0

    progress.last_reviewed = now
    if was_due or not correct:
        progress.next_review = now + BOX_INTERVALS[progress.box]
    return progress, was_due

class LearningService:
    def get_session(self, db: Session, user: User, limit: int = 10, level: str | None = None) -> list[dict]:
        now = utcnow()
        due = db.query(UserWordProgress, DictionaryWord).join(
            DictionaryWord, DictionaryWord.id == UserWordProgress.word_id
        ).filter(
            UserWordProgress.user_id == user.id,
            UserWordProgress.next_review <= now
        ).order_by(UserWordProgress.next_review.asc()).limit(limit).all()

        items = [{"word": to_word_response(w), "box": p.box, "is_new": False} for p, w in due]

        if len(items) < limit:
            known_ids = db.query(UserWordProgress.word_id).filter(UserWordProgress.user_id == user.id)
            new_words = db.query(DictionaryWord).filter(
                DictionaryWord.level == (level or user.cefr_level or "A1"),
                DictionaryWord.id.not_in(known_ids)
            ).order_by(func.random()).limit(limit - len(items)).all()
            items.extend({"word": to_word_response(w), "box": 0, "is_new": True} for w in new_words)

        return items

    def review(self, db: Session, user: User, review: LearnReviewRequest) -> dict:
        if not db.query(DictionaryWord.id).filter(DictionaryWord.id == review.word_id).first():
            raise ValueError("Kelime bulunamadı")

        progress, was_due = record_review(db, user.id, review.word_id, review.known)
        db.flush()
        box, interval = progress.box, BOX_INTERVALS[progress.box]

        # Aynı kelimeyi art arda işaretlemek XP kazandırmaz
        xp = XP_PER_REVIEW if review.known and was_due else 0
        result = award_xp(db, user, "flashcards", xp)
        return {**result, "box": box, "next_review_days": interval.total_seconds() / 86400}

    def _streak(self, db: Session, user_id: int) -> int:
        days = {
            _local_date(created_at)
            for (created_at,) in db.query(XpEvent.created_at).filter(
                XpEvent.user_id == user_id,
                XpEvent.created_at >= utcnow() - timedelta(days=400)
            ).all()
        }
        current = _local_date(utcnow())
        if current not in days:
            current -= timedelta(days=1)  # Bugün henüz çalışmadıysa seri bozulmuş sayılmaz

        streak = 0
        while current in days:
            streak += 1
            current -= timedelta(days=1)
        return streak

    def _activity(self, db: Session, user_id: int) -> list[dict]:
        today = _local_date(utcnow())
        totals = {today - timedelta(days=i): 0 for i in range(6, -1, -1)}
        rows = db.query(XpEvent.created_at, XpEvent.xp).filter(
            XpEvent.user_id == user_id,
            XpEvent.created_at >= utcnow() - timedelta(days=8)
        ).all()
        for created_at, xp in rows:
            day = _local_date(created_at)
            if day in totals:
                totals[day] += xp
        return [{"date": day.isoformat(), "xp": xp} for day, xp in totals.items()]

    def get_stats(self, db: Session, user: User) -> dict:
        now = utcnow()
        progress = db.query(UserWordProgress).filter(UserWordProgress.user_id == user.id)
        learned = progress.filter(UserWordProgress.box >= LEARNED_BOX).count()
        day_start = datetime.combine(_local_date(now), datetime.min.time()) - LOCAL_UTC_OFFSET

        strongest = db.query(DictionaryWord.level, func.count(UserWordProgress.id)).join(
            UserWordProgress, UserWordProgress.word_id == DictionaryWord.id
        ).filter(
            UserWordProgress.user_id == user.id,
            UserWordProgress.box >= LEARNED_BOX
        ).group_by(DictionaryWord.level).all()
        strongest_level = max(
            strongest, key=lambda row: (row[1], CEFR_LEVELS.index(row[0])), default=(None, 0)
        )[0]

        total_quizzes = db.query(QuizSession).filter(
            QuizSession.user_id == user.id,
            QuizSession.kind == "quiz",
            QuizSession.submitted_at.is_not(None)
        ).count()
        streak = self._streak(db, user.id)

        return {
            "learned_words": learned,
            "words_in_progress": progress.count(),
            "due_words": progress.filter(UserWordProgress.next_review <= now).count(),
            "words_today": progress.filter(UserWordProgress.last_reviewed >= day_start).count(),
            "daily_goal": DAILY_WORD_GOAL,
            "streak_days": streak,
            "total_quizzes": total_quizzes,
            "strongest_level": strongest_level,
            "activity": self._activity(db, user.id),
            "achievements": [
                {"key": "first_quiz", "title": "İlk Quiz", "unlocked": total_quizzes >= 1},
                {"key": "streak_7", "title": "7 Gün Seri", "unlocked": streak >= 7},
                {"key": "words_100", "title": "100 Kelime", "unlocked": learned >= 100},
                {"key": "words_1000", "title": "1000 Kelime", "unlocked": learned >= 1000},
            ],
        }
