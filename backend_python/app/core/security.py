# app/core/security.py
# Güvenlik ve token işlemleri

from datetime import datetime, timedelta, timezone
import jwt

from app.core.config import settings

def create_access_token(user_id: int, token_version: int):
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {"sub": str(user_id), "ver": token_version, "exp": expire}
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
