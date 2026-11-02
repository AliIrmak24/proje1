# app/models/quiz.py
# Sunucu taraflı quiz oturumu, XP ve kelime ilerlemesi için SQLAlchemy modelleri

from datetime import datetime, timezone
from uuid import uuid4
from sqlalchemy import Column, DateTime, ForeignKey, Integer, JSON, String, UniqueConstraint
from app.database import Base

def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)

class QuizSession(Base):
    __tablename__ = "quiz_sessions"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    kind = Column(String, nullable=False, default="quiz")  # quiz, placement
    word_ids = Column(JSON, nullable=False)
    levels = Column(JSON, nullable=False)
    correct_indexes = Column(JSON, nullable=False)  # Doğru cevaplar istemciye gönderilmez
    answers = Column(JSON, nullable=False)  # Her soru için ilk verilen cevap
    created_at = Column(DateTime, default=utcnow, nullable=False)
    submitted_at = Column(DateTime, nullable=True)

class XpEvent(Base):
    __tablename__ = "xp_events"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    source = Column(String, nullable=False)  # quiz, matching, flashcards, mini_quiz, reading
    xp = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=utcnow, nullable=False, index=True)

class UserWordProgress(Base):
    __tablename__ = "user_word_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    word_id = Column(Integer, ForeignKey("dictionary.id", ondelete="CASCADE"), nullable=False, index=True)
    box = Column(Integer, nullable=False, default=0)  # Leitner kutusu (0-5)
    correct_count = Column(Integer, nullable=False, default=0)
    wrong_count = Column(Integer, nullable=False, default=0)
    last_reviewed = Column(DateTime, nullable=True)
    next_review = Column(DateTime, nullable=False, default=utcnow, index=True)

    __table_args__ = (
        UniqueConstraint("user_id", "word_id", name="unique_user_word"),
    )
