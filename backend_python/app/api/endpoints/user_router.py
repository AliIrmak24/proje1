# app/api/endpoints/user_router.py
# User işlemleri için router

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.core.rate_limit import login_limiter, register_limiter
from app.database import get_db
from app.schemas.user_schema import (
    ChangePasswordRequest,
    DeleteAccountRequest,
    Token,
    UserCreate,
    UserLogin,
    UserResponse,
    UserUpdate,
)
from app.services.user_service import UserService
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()
user_service = UserService()

def _client_ip(request: Request) -> str:
    return request.client.host if request.client else "unknown"

@router.post("/register", response_model=UserResponse, summary="Yeni kullanıcı kaydı")
def register(user: UserCreate, request: Request, db: Session = Depends(get_db)):
    key = _client_ip(request)
    register_limiter.check(key)
    register_limiter.record(key)
    try:
        new_user = user_service.register_user(db, user)
        return new_user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login", response_model=Token, summary="Giriş yap ve token al")
def login(login_data: UserLogin, request: Request, db: Session = Depends(get_db)):
    identifier = (login_data.email or login_data.username or "").lower().strip()
    key = f"{_client_ip(request)}:{identifier}"
    login_limiter.check(key)
    try:
        token_data = user_service.login_user(db, login_data)
    except ValueError as e:
        login_limiter.record(key)
        raise HTTPException(status_code=401, detail=str(e))
    login_limiter.reset(key)
    return token_data

@router.get("/me", response_model=UserResponse, summary="Kendi profil bilgilerimi getir")
def get_user_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=UserResponse, summary="Profil bilgilerimi güncelle")
def update_user_profile(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        updated_user = user_service.update_profile(db, current_user, update_data)
        return updated_user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/change-password", summary="Şifre değiştir")
def change_password(
    pwd_data: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        access_token = user_service.change_password(db, current_user, pwd_data.old_password, pwd_data.new_password)
        return {"message": "Şifreniz başarıyla güncellendi", "access_token": access_token}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/logout", summary="Çıkış yap")
def logout(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    user_service.logout(db, current_user)
    return {"message": "Başarıyla çıkış yapıldı"}

@router.delete("/me", summary="Hesabı ve tüm verileri kalıcı olarak sil")
def delete_account(
    payload: DeleteAccountRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        user_service.delete_account(db, current_user, payload.password)
        return {"message": "Hesabınız silindi"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
