from pydantic import BaseModel

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