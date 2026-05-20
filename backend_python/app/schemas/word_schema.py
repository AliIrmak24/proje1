from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class Meaning(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    
    part_of_speech: str
    definition: str
    example: Optional[str] = None

class WordResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    
    word: str
    translation: str
    level: str  # YENİ EKLENDİ
    phonetic: Optional[str] = None
    meanings: List[Meaning]