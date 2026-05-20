from sqlalchemy.orm import Session
from app.schemas.note_schema import NoteCreate
from app.repository.note_repository import NoteRepository

note_repo = NoteRepository()

class NoteService:
    def add_note(self, db: Session, note_data: NoteCreate, user_id: int):
        return note_repo.create_note(db, note_data, user_id)

    def get_notes(self, db: Session, user_id: int):
        return note_repo.get_user_notes(db, user_id)