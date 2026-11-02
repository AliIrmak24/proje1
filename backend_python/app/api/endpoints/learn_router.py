# app/api/endpoints/learn_router.py
# Aralıklı tekrar ve öğrenme istatistikleri router'ı

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.quiz_schema import LearnReviewRequest, LearnReviewResponse, LearnStatsResponse, LearnWord
from app.services.learning_service import LearningService

router = APIRouter()
learning_service = LearningService()

@router.get("/session", response_model=List[LearnWord], summary="Tekrarı gelen ve yeni kelimeleri getir")
def get_learning_session(
    limit: int = Query(10, ge=1, le=30),
    level: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return learning_service.get_session(db, current_user, limit=limit, level=level)

@router.post("/review", response_model=LearnReviewResponse, summary="Kelime kartı sonucunu kaydet")
def review_word(
    review: LearnReviewRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        return learning_service.review(db, current_user, review)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/stats", response_model=LearnStatsResponse, summary="Gerçek öğrenme istatistiklerini getir")
def get_learning_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return learning_service.get_stats(db, current_user)
