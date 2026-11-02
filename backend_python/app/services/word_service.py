import datetime
from fastapi import HTTPException
from sqlalchemy import func, or_
from sqlalchemy.orm import Session
from app.repository.user_repository import _escape_like
from app.schemas.word_schema import WordResponse
from app.models.dictionary import DictionaryWord

CEFR_LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]

def to_word_response(word: DictionaryWord) -> WordResponse:
    return WordResponse(
        id=word.id,
        word=word.word,
        translation=word.translation,
        phonetic=word.phonetic,
        level=word.level,
        meanings=word.meanings or [],
    )

def _turkish_lower(value: str) -> str:
    return value.replace("İ", "i").replace("I", "ı").lower()

class WordService:
    def get_word_of_the_day(self, db: Session, level: str | None = None) -> WordResponse:
        level_clean = (level or "").upper().strip()
        query = db.query(DictionaryWord)
        if level_clean in CEFR_LEVELS:
            query = query.filter(DictionaryWord.level == level_clean)

        count = query.count()
        if not count:
            raise HTTPException(status_code=404, detail="Sözlükte kelime bulunamadı")

        # Gün bazlı deterministik seçim
        today_ordinal = datetime.date.today().toordinal()
        selected = query.order_by(DictionaryWord.id).offset(today_ordinal % count).limit(1).one()
        return to_word_response(selected)

    def get_level_counts(self, db: Session) -> dict[str, int]:
        counts = {lvl: 0 for lvl in CEFR_LEVELS}
        rows = db.query(DictionaryWord.level, func.count(DictionaryWord.id)).group_by(DictionaryWord.level).all()
        for lvl, count in rows:
            counts[lvl] = count
        return counts

    def get_all_words(
        self,
        db: Session,
        level: str | None = None,
        search: str | None = None,
        limit: int = 50,
        offset: int = 0
    ) -> list[WordResponse]:
        query = db.query(DictionaryWord)

        if level and level.upper().strip() in CEFR_LEVELS:
            query = query.filter(DictionaryWord.level == level.upper().strip())

        if search and search.strip():
            term = search.strip()
            query = query.filter(or_(
                DictionaryWord.word.ilike(f"%{_escape_like(term.lower())}%", escape="\\"),
                DictionaryWord.translation.ilike(f"%{_escape_like(_turkish_lower(term))}%", escape="\\"),
            ))

        words = query.order_by(DictionaryWord.level.asc(), func.lower(DictionaryWord.word).asc()).offset(offset).limit(limit).all()
        return [to_word_response(w) for w in words]

    def get_random_words(self, db: Session, count: int, level: str | None = None) -> list[WordResponse]:
        query = db.query(DictionaryWord)
        if level and level.upper().strip() in CEFR_LEVELS:
            query = query.filter(DictionaryWord.level == level.upper().strip())

        # Eşleştirme oyununda iki kartın aynı çeviriyi göstermesi engellenir
        selected: dict[str, DictionaryWord] = {}
        for word in query.order_by(func.random()).limit(count * 4).all():
            selected.setdefault(word.translation, word)
            if len(selected) == count:
                break
        return [to_word_response(w) for w in selected.values()]

    def search_word(self, db: Session, word: str) -> WordResponse:
        clean_word = word.strip()

        # Sadece DB'de ara (büyük/küçük harf duyarsız)
        db_word = db.query(DictionaryWord).filter(
            func.lower(DictionaryWord.word) == clean_word.lower()
        ).first()

        if db_word:
            return to_word_response(db_word)

        raise HTTPException(status_code=404, detail=f"'{clean_word}' kelimesi sözlükte bulunamadı.")
