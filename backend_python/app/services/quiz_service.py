from sqlalchemy.orm import Session
from app.repository.user_repository import UserRepository
from app.schemas.quiz_schema import QuizResult

user_repo = UserRepository()

class QuizService:
    def process_quiz_result(self, db: Session, user_id: int, result: QuizResult):
        # 1 doğru cevap = 10 XP
        earned_xp = result.correct_answers * 10
        
        # Kullanıcıyı bul ve XP'sini ekle
        user = user_repo.get_user_by_id(db, user_id)
        user.xp += earned_xp
        
        # Level Algoritması: Her 100 XP = 1 Level (Örn: 250 XP = Level 3)
        # Matematiksel olarak: (XP // 100) + 1
        new_level = (user.xp // 100) + 1
        
        # Eğer seviye atladıysa veritabanını güncelle
        if new_level > user.level:
            user.level = new_level
            
        db.commit()
        db.refresh(user)
        
        return {
            "earned_xp": earned_xp,
            "total_xp": user.xp,
            "current_level": user.level
        }

    def get_leaderboard(self, db: Session):
        return user_repo.get_top_users(db, limit=10)
