from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class Meaning(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    part_of_speech: str
    definition: str
    example: Optional[str] = None
    example_translation: Optional[str] = None
    example_source: Optional[str] = None  # Örnek cümlenin Tatoeba atfı

class WordResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    word: str
    translation: str
    level: str  # YENİ EKLENDİ
    phonetic: Optional[str] = None
    meanings: List[Meaning]
