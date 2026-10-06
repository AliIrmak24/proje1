# app/api/endpoints/friend_router.py
# Arkadaşlar ve Sosyal Etkileşim Router'ı

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.friend_service import FriendService
from app.schemas.user_schema import FriendRequestCreate

router = APIRouter()
friend_service = FriendService()

@router.get("/", summary="Kullanıcının arkadaşlarını listele")
def get_my_friends(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return friend_service.list_friends(db, current_user.id)

@router.get("/search", summary="Arkadaş eklemek için kullanıcı ara")
def search_potential_friends(
    q: str = Query(..., min_length=1, description="Aranacak kullanıcı adı"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return friend_service.search_users_to_add(db, current_user.id, q)

@router.post("/add", summary="Kullanıcı adına göre arkadaş ekle")
def add_friend(
    payload: FriendRequestCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        friend_service.add_friend_by_username(db, current_user.id, payload.target_username)
        return {"message": f"{payload.target_username} başarıyla arkadaş listenize eklendi!"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{target_user_id}", summary="Arkadaşı listeden çıkar")
def remove_friend(
    target_user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        friend_service.remove_friend(db, current_user.id, target_user_id)
        return {"message": "Arkadaş listenizden çıkarıldı"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
