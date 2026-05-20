from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.note_schema import NoteCreate, NoteResponse
from app.services.note_service import NoteService
from app.api.deps import get_current_user # Kapı görevlimiz
from app.models.user import User

router = APIRouter()
note_service = NoteService()

# Bu işlemi yapmak için "current_user" olmak zorunludur!
@router.post("/add", response_model=NoteResponse)
def add_new_note(
    note_data: NoteCreate, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user) 
):
    # Kapı görevlisinden geçen kullanıcının ID'sini otomatik olarak alıyoruz
    return note_service.add_note(db, note_data, current_user.id)

@router.get("/my-notes", response_model=List[NoteResponse])
def get_my_notes(
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    return note_service.get_notes(db, current_user.id)

@router.delete("/delete/{note_id}", summary="Kayıtlı notu sil")
def delete_note(
    note_id: int, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    from app.models.note import Note
    note = db.query(Note).filter(Note.id == note_id, Note.user_id == current_user.id).first()
    
    if not note:
        raise HTTPException(status_code=404, detail="Not bulunamadı veya silme yetkiniz yok")
        
    db.delete(note)
    db.commit()
    return {"message": "Not başarıyla silindi"}