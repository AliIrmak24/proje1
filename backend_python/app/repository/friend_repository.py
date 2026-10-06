# app/repository/friend_repository.py
# Arkadaşlık ve sosyal etkileşim veri tabanı işlemleri

from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from app.models.friendship import Friendship
from app.models.user import User

class FriendRepository:
    def get_friendship(self, db: Session, user_id: int, friend_id: int):
        return db.query(Friendship).filter(
            or_(
                and_(Friendship.user_id == user_id, Friendship.friend_id == friend_id),
                and_(Friendship.user_id == friend_id, Friendship.friend_id == user_id)
            )
        ).first()

    def get_accepted_friends(self, db: Session, user_id: int):
        friendships = db.query(Friendship).filter(
            or_(Friendship.user_id == user_id, Friendship.friend_id == user_id),
            Friendship.status == "accepted"
        ).all()

        results = []
        for f in friendships:
            target_user_id = f.friend_id if f.user_id == user_id else f.user_id
            target_user = db.query(User).filter(User.id == target_user_id).first()
            if target_user:
                results.append({
                    "friendship_id": f.id,
                    "friend": {
                        "id": target_user.id,
                        "username": target_user.username,
                        "level": target_user.level,
                        "xp": target_user.xp,
                        "bio": target_user.bio,
                    },
                    "status": f.status,
                    "created_at": f.created_at
                })
        return results

    def get_pending_requests(self, db: Session, user_id: int):
        # Bu kullanıcıya gelen bekleyen istekler
        requests = db.query(Friendship).filter(
            Friendship.friend_id == user_id,
            Friendship.status == "pending"
        ).all()

        results = []
        for r in requests:
            sender = db.query(User).filter(User.id == r.user_id).first()
            if sender:
                results.append({
                    "request_id": r.id,
                    "sender": {
                        "id": sender.id,
                        "username": sender.username,
                        "level": sender.level,
                        "xp": sender.xp,
                        "bio": sender.bio,
                    },
                    "created_at": r.created_at
                })
        return results

    def send_friend_request(self, db: Session, user_id: int, target_user_id: int):
        if user_id == target_user_id:
            raise ValueError("Kendinize arkadaşlık isteği gönderemezsiniz")

        existing = self.get_friendship(db, user_id, target_user_id)
        if existing:
            if existing.status == "accepted":
                raise ValueError("Bu kullanıcı zaten arkadaşınız")
            elif existing.status == "pending":
                raise ValueError("Zaten bekleyen bir arkadaşlık isteği bulunuyor")

        friendship = Friendship(
            user_id=user_id,
            friend_id=target_user_id,
            status="accepted"  # Hızlı ve keyifli bir sosyal deneyim için doğrudan arkadaş yapabilir veya isteğe bağlı pending
        )
        db.add(friendship)
        db.commit()
        db.refresh(friendship)
        return friendship

    def remove_friend(self, db: Session, user_id: int, target_user_id: int):
        friendship = self.get_friendship(db, user_id, target_user_id)
        if not friendship:
            raise ValueError("Arkadaşlık kaydı bulunamadı")
        db.delete(friendship)
        db.commit()
        return True
