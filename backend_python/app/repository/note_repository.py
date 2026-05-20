from sqlalchemy.orm import Session
from app.models.note import Note
from app.schemas.note_schema import NoteCreate

class NoteRepository:
    def create_note(self, db: Session, note_data: NoteCreate, user_id: int):
        # Kelimeyi, kaydeden kişinin ID'si ile birlikte tabloya ekliyoruz
        db_note = Note(**note_data.model_dump(), user_id=user_id)
        db.add(db_note)
        db.commit()
        db.refresh(db_note)
        return db_note

    def get_user_notes(self, db: Session, user_id: int):
        # Sadece o kullanıcıya ait notları getiriyoruz
        return db.query(Note).filter(Note.user_id == user_id).all()