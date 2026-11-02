from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from app.repository.user_repository import UserRepository
from app.schemas.user_schema import UserCreate, UserLogin, UserUpdate
from app.models.user import User
import bcrypt
from app.core.security import create_access_token

user_repo = UserRepository()

class UserService:
    def get_password_hash(self, password: str) -> str:
        pwd_bytes = password.encode('utf-8')
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(pwd_bytes, salt)
        return hashed_password.decode('utf-8')

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        try:
            plain_pwd_bytes = plain_password.encode('utf-8')
            hashed_pwd_bytes = hashed_password.encode('utf-8')
            return bcrypt.checkpw(plain_pwd_bytes, hashed_pwd_bytes)
        except ValueError:
            # Geçersiz hash veya bcrypt sınırını aşan şifre eşleşme sayılmaz
            return False

    def register_user(self, db: Session, user: UserCreate):
        if user_repo.get_user_by_email(db, user.email):
            raise ValueError("Bu e-posta adresi zaten kayıtlı")

        if user_repo.get_user_by_username(db, user.username):
            raise ValueError("Bu kullanıcı adı zaten alınmış")

        hashed_pw = self.get_password_hash(user.password)
        try:
            return user_repo.create_user(db, user, hashed_pw)
        except IntegrityError:
            db.rollback()
            raise ValueError("Bu kullanıcı adı veya e-posta zaten kayıtlı")

    def login_user(self, db: Session, login_data: UserLogin):
        identifier = login_data.email or login_data.username
        if not identifier:
            raise ValueError("Kullanıcı adı veya e-posta girilmelidir")

        user = user_repo.get_user_by_email(db, identifier) or user_repo.get_user_by_username(db, identifier)
        if not user or not self.verify_password(login_data.password, user.hashed_password):
            raise ValueError("Kullanıcı adı/e-posta veya şifre hatalı")

        return {
            "access_token": create_access_token(user.id, user.token_version),
            "token_type": "bearer",
            "user": user
        }

    def update_profile(self, db: Session, user: User, update_data: UserUpdate):
        if update_data.username and update_data.username != user.username:
            existing = user_repo.get_user_by_username(db, update_data.username)
            if existing and existing.id != user.id:
                raise ValueError("Bu kullanıcı adı başka bir üye tarafından kullanılıyor")

        if update_data.email and update_data.email != user.email:
            existing_email = user_repo.get_user_by_email(db, update_data.email)
            if existing_email and existing_email.id != user.id:
                raise ValueError("Bu e-posta adresi başka bir üye tarafından kullanılıyor")

        return user_repo.update_user(
            db,
            user,
            username=update_data.username,
            bio=update_data.bio,
            full_name=update_data.full_name,
            email=update_data.email,
            phone_number=update_data.phone_number,
            avatar_url=update_data.avatar_url,
            language=update_data.language,
            cefr_level=update_data.cefr_level
        )

    def change_password(self, db: Session, user: User, old_pwd: str, new_pwd: str) -> str:
        if not self.verify_password(old_pwd, user.hashed_password):
            raise ValueError("Mevcut şifreniz hatalı")

        user.hashed_password = self.get_password_hash(new_pwd)
        user.token_version += 1
        db.commit()
        return create_access_token(user.id, user.token_version)

    def logout(self, db: Session, user: User):
        user.token_version += 1
        db.commit()

    def delete_account(self, db: Session, user: User, password: str):
        if not self.verify_password(password, user.hashed_password):
            raise ValueError("Şifreniz hatalı")
        db.delete(user)
        db.commit()
