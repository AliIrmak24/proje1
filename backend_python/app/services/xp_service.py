# app/services/xp_service.py
# XP kazanımı ve kaynak başına günlük sınırlar

from datetime import timedelta
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.models.quiz import XpEvent, utcnow
from app.models.user import User

# Son 24 saatte kaynak başına kazanılabilecek en yüksek XP
DAILY_XP_CAPS = {
    "quiz": 1000,
    "matching": 500,
    "flashcards": 300,
    "mini_quiz": 100,
    "reading": 60,
}

def award_xp(db: Session, user: User, source: str, xp: int) -> dict:
    used_xp = db.query(func.coalesce(func.sum(XpEvent.xp), 0)).filter(
        XpEvent.user_id == user.id,
        XpEvent.source == source,
        XpEvent.created_at >= utcnow() - timedelta(days=1)
    ).scalar()
    earned_xp = max(0, min(xp, DAILY_XP_CAPS[source] - used_xp))

    if earned_xp:
        db.add(XpEvent(user_id=user.id, source=source, xp=earned_xp))
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
