from fastapi import APIRouter, Depends, Query
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
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Kelimeleri seviye/arama filtresine göre sayfa sayfa listeler."""
    return word_service.get_all_words(db, level=level, search=search, limit=limit, offset=offset)

@router.get("/word-of-the-day", response_model=WordResponse)
def get_word_of_the_day(level: Optional[str] = None, db: Session = Depends(get_db)):
    """Günün kelimesini (isteğe bağlı seviyeye göre) döndürür."""
    return word_service.get_word_of_the_day(db, level=level)

@router.get("/counts")
def get_level_counts(db: Session = Depends(get_db)):
    """A1, A2, B1, B2, C1, C2 seviyelerindeki kayıtlı kelime sayılarını döndürür."""
    return word_service.get_level_counts(db)

@router.get("/random", response_model=list[WordResponse])
def get_random_words(
    count: int = Query(5, ge=1, le=20),
    level: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Oyunlar için çevirileri birbirinden farklı rastgele kelimeler döndürür."""
    return word_service.get_random_words(db, count=count, level=level)

@router.get("/search/{word}", response_model=WordResponse)
def search_word(word: str, db: Session = Depends(get_db)):
    """Kelime arama ve detay getirme endpointi."""
    return word_service.search_word(db, word)
