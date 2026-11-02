from sqlalchemy.orm import Session
from app.models.note import Note
from app.schemas.note_schema import NoteCreate

class NoteRepository:
    def save_note(self, db: Session, note_data: NoteCreate, user_id: int):
        # Aynı kelime için tek not tutulur; tekrar kaydedilirse güncellenir
        db_note = db.query(Note).filter(
            Note.user_id == user_id,
            Note.word == note_data.word
        ).first()
        if db_note:
            db_note.translation = note_data.translation
            db_note.personal_note = note_data.personal_note
        else:
            db_note = Note(**note_data.model_dump(), user_id=user_id)
            db.add(db_note)
        db.commit()
        db.refresh(db_note)
        return db_note

    def get_user_notes(self, db: Session, user_id: int):
        # Sadece o kullanıcıya ait notları getiriyoruz
        return db.query(Note).filter(Note.user_id == user_id).order_by(Note.created_at.desc()).all()
