from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.word_schema import WordResponse
from app.services.word_service import WordService

router = APIRouter()
word_service = WordService()

@router.get("/search/{word}", response_model=WordResponse)
def search_word(word: str, db: Session = Depends(get_db)):
    return word_service.search_word(db, word)
