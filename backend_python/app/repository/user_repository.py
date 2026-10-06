# app/repository/user_repository.py
# User CRUD işlemleri

from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from app.models.user import User
from app.schemas.user_schema import UserCreate

class UserRepository:
    def get_user_by_email(self, db: Session, email: str):
        return db.query(User).filter(func.lower(User.email) == email.lower().strip()).first()

    def get_user_by_username(self, db: Session, username: str):
        return db.query(User).filter(func.lower(User.username) == username.lower().strip()).first()

    def create_user(self, db: Session, user: UserCreate, hashed_password: str):
        db_user = User(
            username=user.username,
            email=user.email,
            hashed_password=hashed_password,
            xp=0,
            level=1,
            bio="SözEğitim öğrencisi",
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user

    def get_user_by_id(self, db: Session, user_id: int):
        return db.query(User).filter(User.id == user_id).first()

    def get_top_users(self, db: Session, limit: int = 50):
        # Kullanıcıları XP'ye göre büyükten küçüğe sırala
        return db.query(User).order_by(User.xp.desc()).limit(limit).all()

    def search_users(self, db: Session, query_str: str, current_user_id: int, limit: int = 20):
        # Kendisi hariç kullanıcı adına göre ara
        pattern = f"%{query_str}%"
        return db.query(User).filter(
            User.id != current_user_id,
            or_(User.username.ilike(pattern), User.email.ilike(pattern))
        ).limit(limit).all()

    def update_user(
        self, 
        db: Session, 
        user: User, 
        username: str | None = None, 
        bio: str | None = None,
        full_name: str | None = None,
        email: str | None = None,
        phone_number: str | None = None,
        avatar_url: str | None = None,
        language: str | None = None
    ):
        if username:
            user.username = username
        if bio is not None:
            user.bio = bio
        if full_name is not None:
            user.full_name = full_name
        if email:
            user.email = email
        if phone_number is not None:
            user.phone_number = phone_number
        if avatar_url is not None:
            user.avatar_url = avatar_url
        if language is not None:
            user.language = language
        db.commit()
        db.refresh(user)
        return user

    def update_password(self, db: Session, user: User, new_hashed_password: str):
        user.hashed_password = new_hashed_password
        db.commit()
        db.refresh(user)
        return user
