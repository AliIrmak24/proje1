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

@router.get("/requests", summary="Gelen arkadaşlık isteklerini listele")
def get_friend_requests(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return friend_service.list_pending_requests(db, current_user.id)

@router.post("/add", summary="Kullanıcı adına göre arkadaşlık isteği gönder")
def add_friend(
    payload: FriendRequestCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        status = friend_service.add_friend_by_username(db, current_user.id, payload.target_username)
        if status == "accepted":
            return {"status": status, "message": f"{payload.target_username} artık arkadaşınız!"}
        return {"status": status, "message": f"{payload.target_username} kullanıcısına istek gönderildi"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/requests/{request_id}/accept", summary="Arkadaşlık isteğini kabul et")
def accept_friend_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        friend_service.respond_to_request(db, current_user.id, request_id, accept=True)
        return {"message": "Arkadaşlık isteği kabul edildi"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.delete("/requests/{request_id}", summary="Arkadaşlık isteğini reddet")
def reject_friend_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        friend_service.respond_to_request(db, current_user.id, request_id, accept=False)
        return {"message": "Arkadaşlık isteği reddedildi"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

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
