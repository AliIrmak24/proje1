from sqlalchemy.orm import Session
from app.repository.user_repository import UserRepository
from app.schemas.user_schema import UserCreate, UserLogin
import bcrypt
from app.core.security import create_access_token

user_repo = UserRepository()

class UserService:
    def get_password_hash(self, password: str) -> str:
        # Şifreyi byte'a çevir, tuzla (salt) ve güvenle hashle
        pwd_bytes = password.encode('utf-8')
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(pwd_bytes, salt)
        # Veritabanına kaydetmek için tekrar string'e çeviriyoruz
        return hashed_password.decode('utf-8')

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        # Hem girilen şifreyi hem veritabanındaki şifreyi byte olarak karşılaştır
        plain_pwd_bytes = plain_password.encode('utf-8')
        hashed_pwd_bytes = hashed_password.encode('utf-8')
        return bcrypt.checkpw(plain_pwd_bytes, hashed_pwd_bytes)

    def register_user(self, db: Session, user: UserCreate):
        if user_repo.get_user_by_email(db, user.email):
            raise ValueError("Email already registered")
        
        if user_repo.get_user_by_username(db, user.username):
            raise ValueError("Username already taken")
            
        hashed_pw = self.get_password_hash(user.password)
        return user_repo.create_user(db, user, hashed_pw)

    def login_user(self, db: Session, login_data: UserLogin):
        user = user_repo.get_user_by_email(db, login_data.email)
        if not user or not self.verify_password(login_data.password, user.hashed_password):
            raise ValueError("E-posta veya şifre hatalı")
            
        access_token = create_access_token(data={"sub": user.email})
        return {"access_token": access_token, "token_type": "bearer"}
