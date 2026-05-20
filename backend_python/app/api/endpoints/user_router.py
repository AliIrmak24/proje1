# app/api/endpoints/user_router.py
# User işlemleri için router

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user_schema import UserCreate, UserResponse, UserLogin, Token
from app.services.user_service import UserService
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()
user_service = UserService()

@router.post("/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    try:
        new_user = user_service.register_user(db, user)
        return new_user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login", response_model=Token)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    try:
        # Servise git, kontrolleri yap ve token'ı al
        token_data = user_service.login_user(db, login_data)
        return token_data
    except ValueError as e:
        # Eğer şifre yanlışsa 401 (Yetkisiz) hatası dön
        raise HTTPException(status_code=401, detail=str(e))

@router.get("/me", response_model=UserResponse, summary="Kendi profil bilgilerimi getir")
def get_user_profile(current_user: User = Depends(get_current_user)):
    return current_user
