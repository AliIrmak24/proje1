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

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = int(payload.get("sub"))
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Oturum süreniz dolmuş, lütfen tekrar giriş yapın")
    except (jwt.InvalidTokenError, TypeError, ValueError):
        raise credentials_exception

    user = user_repo.get_user_by_id(db, user_id)
    if user is None or payload.get("ver") != user.token_version:
        raise credentials_exception
    return user
