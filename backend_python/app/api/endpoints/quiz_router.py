from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.quiz_schema import QuizResult, LeaderboardUser, QuizQuestionResponse, QuizSubmitResponse
from app.services.quiz_service import QuizService

router = APIRouter()
quiz_service = QuizService()

@router.get("/questions", response_model=List[QuizQuestionResponse], summary="Dinamik quiz soruları getir")
def get_quiz_questions(count: int = 5, db: Session = Depends(get_db)):
    return quiz_service.generate_questions(db, count=count)

# Sadece giriş yapan kullanıcılar XP kazanabilir
@router.post("/submit", response_model=QuizSubmitResponse, summary="Quiz sonucunu gönder ve XP kazan")
def submit_quiz_result(
    result: QuizResult, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return quiz_service.process_quiz_result(db, current_user.id, result)

# Herkes en iyiler listesini görebilir
@router.get("/leaderboard", response_model=List[LeaderboardUser], summary="En iyi 10 kullanıcıyı getir")
def get_leaderboard(db: Session = Depends(get_db)):
    return quiz_service.get_leaderboard(db)
