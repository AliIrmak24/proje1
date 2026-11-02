from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.quiz_schema import (
    ActivityResult,
    LeaderboardUser,
    QuizAnswerRequest,
    QuizAnswerResponse,
    QuizResultResponse,
    QuizSessionResponse,
    QuizSubmitRequest,
    QuizSubmitResponse,
)
from app.services.quiz_service import QuizService

router = APIRouter()
quiz_service = QuizService()

@router.get("/questions", response_model=QuizSessionResponse, summary="Quiz oturumu başlat ve soruları getir")
def get_quiz_questions(
    count: int = Query(5, ge=1, le=20),
    level: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        return quiz_service.create_session(db, current_user, count=count, level=level)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/placement", response_model=QuizSessionResponse, summary="Seviye belirleme testi başlat")
def get_placement_test(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        return quiz_service.create_placement(db, current_user)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/answer", response_model=QuizAnswerResponse, summary="Soruyu cevapla ve sonucunu öğren")
def answer_question(
    answer: QuizAnswerRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        return quiz_service.answer_question(db, current_user.id, answer)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

# XP, sunucuda kayıtlı cevaplara göre hesaplanır
@router.post("/submit", response_model=QuizResultResponse, summary="Quiz oturumunu bitir ve XP kazan")
def submit_quiz_result(
    result: QuizSubmitRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        return quiz_service.submit_session(db, current_user, result.session_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/activity", response_model=QuizSubmitResponse, summary="Oyun etkinliğinden sınırlı XP kazan")
def submit_activity(
    result: ActivityResult,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return quiz_service.process_activity(db, current_user, result)

# Herkes en iyiler listesini görebilir
@router.get("/leaderboard", response_model=List[LeaderboardUser], summary="En iyi 10 kullanıcıyı getir")
def get_leaderboard(db: Session = Depends(get_db)):
    return quiz_service.get_leaderboard(db)
