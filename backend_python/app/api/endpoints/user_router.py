# app/api/endpoints/user_router.py
# User işlemleri için router

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user_schema import UserCreate, UserResponse, UserLogin, Token, UserUpdate, ChangePasswordRequest
from app.services.user_service import UserService
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()
user_service = UserService()

@router.post("/register", response_model=UserResponse, summary="Yeni kullanıcı kaydı")
def register(user: UserCreate, db: Session = Depends(get_db)):
    try:
        new_user = user_service.register_user(db, user)
        return new_user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login", response_model=Token, summary="Giriş yap ve token al")
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    try:
        token_data = user_service.login_user(db, login_data)
        return token_data
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))

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
        user_service.change_password(db, current_user, pwd_data.old_password, pwd_data.new_password)
        return {"message": "Şifreniz başarıyla güncellendi"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/logout", summary="Çıkış yap")
def logout(current_user: User = Depends(get_current_user)):
    return {"message": f"Güle güle {current_user.username}, başarıyla çıkış yapıldı."}
