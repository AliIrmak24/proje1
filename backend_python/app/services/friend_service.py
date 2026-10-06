# app/services/friend_service.py
# Arkadaşlık iş mantığı

from sqlalchemy.orm import Session
from app.repository.friend_repository import FriendRepository
from app.repository.user_repository import UserRepository

friend_repo = FriendRepository()
user_repo = UserRepository()

class FriendService:
    def list_friends(self, db: Session, user_id: int):
        return friend_repo.get_accepted_friends(db, user_id)

    def list_pending_requests(self, db: Session, user_id: int):
        return friend_repo.get_pending_requests(db, user_id)

    def add_friend_by_username(self, db: Session, user_id: int, target_username: str):
        target_user = user_repo.get_user_by_username(db, target_username)
        if not target_user:
            raise ValueError(f"'{target_username}' adında bir kullanıcı bulunamadı")
        return friend_repo.send_friend_request(db, user_id, target_user.id)

    def remove_friend(self, db: Session, user_id: int, target_user_id: int):
        return friend_repo.remove_friend(db, user_id, target_user_id)

    def search_users_to_add(self, db: Session, user_id: int, query_str: str):
        users = user_repo.search_users(db, query_str, current_user_id=user_id)
        results = []
        for u in users:
            friendship = friend_repo.get_friendship(db, user_id, u.id)
            is_friend = friendship is not None and friendship.status == "accepted"
            results.append({
                "id": u.id,
                "username": u.username,
                "level": u.level,
                "xp": u.xp,
                "bio": u.bio,
                "is_friend": is_friend,
            })
        return results
