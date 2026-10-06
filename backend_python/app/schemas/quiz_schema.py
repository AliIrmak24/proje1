from pydantic import BaseModel
from typing import List

# Mobil uygulamadan bize gelecek quiz sonucu
class QuizResult(BaseModel):
    correct_answers: int

# Kullanıcıya döneceğimiz sıralama tablosu verisi
class LeaderboardUser(BaseModel):
    username: str
    xp: int
    level: int

    class Config:
        from_attributes = True

# Dinamik quiz sorusu şeması
class QuizQuestionResponse(BaseModel):
    id: int
    question: str
    word: str
    options: List[str]
    correct_index: int
    level: str = "A1"

class QuizSubmitResponse(BaseModel):
    earned_xp: int
    total_xp: int
    current_level: int