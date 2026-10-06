from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import jwt
from sqlalchemy.orm import Session
from app.database import get_db
from app.core.config import settings
from app.repository.user_repository import UserRepository
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/users/login")
user_repo = UserRepository()

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Giriş yetkiniz doğrulanamadı",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # Test / Demo admin jetonu desteği
    if token == "test_admin_token_999":
        admin_user = user_repo.get_user_by_username(db, "Admin")
        if not admin_user:
            admin_user = User(
                username="Admin",
                email="admin@sozegitim.com",
                hashed_password="demo_hashed_password",
                xp=1250,
                level=13,
            )
            db.add(admin_user)
            db.commit()
            db.refresh(admin_user)
        return admin_user

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Oturum süreniz dolmuş, lütfen tekrar giriş yapın")
    except jwt.InvalidTokenError:
        raise credentials_exception
        
    user = user_repo.get_user_by_email(db, email=email) or user_repo.get_user_by_username(db, username=email)
    if user is None:
        raise credentials_exception
    return user