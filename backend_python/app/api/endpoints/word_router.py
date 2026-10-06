from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.schemas.word_schema import WordResponse
from app.services.word_service import WordService

router = APIRouter()
word_service = WordService()

@router.get("/", response_model=list[WordResponse])
def get_all_words(
    level: Optional[str] = None,
    search: Optional[str] = None,
    limit: Optional[int] = 6000,
    db: Session = Depends(get_db)
):
    """Tüm kelimeleri veya seviye/arama filtresine göre kelimeleri listeler."""
    return word_service.get_all_words(db, level=level, search=search, limit=limit or 6000)

@router.get("/word-of-the-day", response_model=WordResponse)
def get_word_of_the_day(level: Optional[str] = None, db: Session = Depends(get_db)):
    """Günün kelimesini (isteğe bağlı seviyeye göre) döndürür."""
    return word_service.get_word_of_the_day(db, level=level)

@router.get("/counts")
def get_level_counts(db: Session = Depends(get_db)):
    """A1, A2, B1, B2, C1, C2 seviyelerindeki kayıtlı kelime sayılarını döndürür."""
    return word_service.get_level_counts(db)

@router.get("/by-level/{level}", response_model=list[WordResponse])
def get_words_by_level(level: str, limit: Optional[int] = 6000, db: Session = Depends(get_db)):
    """Belirli bir seviyedeki (A1, A2, B1, B2, C1, C2) kelimeleri listeler."""
    return word_service.get_words_by_level(db, level, limit=limit or 6000)

@router.get("/search/{word}", response_model=WordResponse)
def search_word(word: str, db: Session = Depends(get_db)):
    """Kelime arama ve detay getirme endpointi."""
    return word_service.search_word(db, word)
