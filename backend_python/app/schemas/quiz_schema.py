from pydantic import BaseModel, Field
from typing import List, Literal, Optional
from app.schemas.word_schema import WordResponse

# Kullanıcıya döneceğimiz sıralama tablosu verisi
class LeaderboardUser(BaseModel):
    username: str
    xp: int
    level: int

    class Config:
        from_attributes = True

# Dinamik quiz sorusu şeması (doğru cevap burada bulunmaz)
class QuizQuestionResponse(BaseModel):
    id: int
    kind: Literal["en_tr", "tr_en", "listening", "cloze"] = "en_tr"
    question: str
    word: Optional[str] = None
    speak_text: Optional[str] = None  # Dinleme sorusunda cihazın okuyacağı metin
    options: List[str]
    level: str = "A1"

class QuizSessionResponse(BaseModel):
    session_id: str
    questions: List[QuizQuestionResponse]

class QuizAnswerRequest(BaseModel):
    session_id: str
    question_id: int
    selected_index: int

class QuizAnswerResponse(BaseModel):
    correct: bool
    correct_index: int

class QuizSubmitRequest(BaseModel):
    session_id: str

# Eşleştirme, okuma ve mini quiz gibi istemcide tamamlanan etkinlikler
class ActivityResult(BaseModel):
    activity: Literal["matching", "mini_quiz", "reading"]
    correct_answers: int = Field(ge=0)

class QuizSubmitResponse(BaseModel):
    earned_xp: int
    total_xp: int
    current_level: int

class ReviewWord(BaseModel):
    word: str
    translation: str
    level: str

class QuizResultResponse(QuizSubmitResponse):
    correct_answers: int
    review: List[ReviewWord] = []  # Yanlış cevaplanan kelimeler
    placement_level: Optional[str] = None

class LearnWord(BaseModel):
    word: WordResponse
    box: int
    is_new: bool

class LearnReviewRequest(BaseModel):
    word_id: int
    known: bool

class LearnReviewResponse(QuizSubmitResponse):
    box: int
    next_review_days: float

class DailyActivity(BaseModel):
    date: str
    xp: int

class Achievement(BaseModel):
    key: str
    title: str
    unlocked: bool

class LearnStatsResponse(BaseModel):
    learned_words: int
    words_in_progress: int
    due_words: int
    words_today: int
    daily_goal: int
    streak_days: int
    total_quizzes: int
    strongest_level: Optional[str] = None
    activity: List[DailyActivity]
    achievements: List[Achievement]
