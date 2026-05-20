from pydantic import BaseModel
from datetime import datetime
from typing import Optional

# Kullanıcı yeni bir kelime kaydederken bize göndereceği veriler
class NoteCreate(BaseModel):
    word: str
    translation: str
    personal_note: Optional[str] = None

# Kullanıcıya kendi çalışma listesini (notlarını) gönderirken kullanacağımız format
class NoteResponse(BaseModel):
    id: int
    word: str
    translation: str
    personal_note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
