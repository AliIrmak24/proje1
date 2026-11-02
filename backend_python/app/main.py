# app/main.py
# SözEğitim Ana API Giriş Noktası

from fastapi import FastAPI, Depends, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from app.core.config import settings
from app.database import engine, Base, SessionLocal, get_db
from app.models import user, note, dictionary, friendship, quiz
from app.api.endpoints.user_router import router as user_router
from app.api.endpoints.word_router import router as word_router
from app.api.endpoints.note_router import router as note_router
from app.api.endpoints.quiz_router import router as quiz_router
from app.api.endpoints.friend_router import router as friend_router
from app.api.endpoints.learn_router import router as learn_router
from app.models.dictionary import DictionaryWord
from app.models.user import User
from app.schema_upgrade import upgrade_schema
from app.schemas.quiz_schema import LeaderboardUser
from app.services.dictionary_loader import sync_dictionary
from typing import List
import os
from fastapi.responses import FileResponse, JSONResponse, RedirectResponse

# Veritabanında tabloları otomatik oluşturur
Base.metadata.create_all(bind=engine)
upgrade_schema(engine)

with SessionLocal() as startup_session:
    sync_dictionary(startup_session)

app = FastAPI(
    title="SözEğitim API",
    version="3.0.0",
    description="SözEğitim İngilizce Kelime, Quiz, Aralıklı Tekrar ve Sosyal API Sistemi"
)

# Oturum Bearer token ile taşındığı için çerez izni gerekmez
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

VALIDATION_MESSAGES = {
    "email": "Geçerli bir e-posta adresi girin",
    "password": "Şifre alanı zorunludur",
    "username": "Kullanıcı adı zorunludur",
}

# Doğrulama hataları istemcide doğrudan gösterilecek tek bir mesaja çevrilir
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    error = exc.errors()[0]
    field = str(error["loc"][-1])
    if field != "email" and error["type"] == "value_error":
        detail = error["msg"].removeprefix("Value error, ")
    else:
        detail = VALIDATION_MESSAGES.get(field, "Gönderilen bilgiler geçersiz")
    return JSONResponse(status_code=422, content={"detail": detail})

# Router'ları kayıt et
app.include_router(user_router, prefix="/api/users", tags=["Kullanıcı & Giriş/Çıkış"])
app.include_router(word_router, prefix="/api/words", tags=["Sözlük"])
app.include_router(quiz_router, prefix="/api/quiz", tags=["Yarışma, Quiz & Liderlik"])
app.include_router(learn_router, prefix="/api/learn", tags=["Aralıklı Tekrar"])
app.include_router(friend_router, prefix="/api/friends", tags=["Arkadaşlar & Sosyal"])
app.include_router(note_router, prefix="/api/notes", tags=["Kelimelerim & Notlar"])

@app.get("/", summary="API Kök Durumu")
def root():
    return {
        "status": "online",
        "app": "SözEğitim API",
        "version": "3.0.0",
        "message": "SözEğitim Backend Sistemi Sorunsuz Çalışıyor!"
    }

@app.get("/api/health", summary="Sistem Sağlık ve İstatistik Kontrolü")
def health_check(db: Session = Depends(get_db)):
    word_count = db.query(DictionaryWord).count()
    user_count = db.query(User).count()
    return {
        "status": "healthy",
        "database": "connected",
        "total_words": word_count,
        "total_users": user_count,
    }

@app.get("/api/leaderboard", response_model=List[LeaderboardUser], summary="Genel Puan Sıralaması")
def global_leaderboard(db: Session = Depends(get_db)):
    from app.services.quiz_service import QuizService
    return QuizService().get_leaderboard(db)

@app.get("/api/download/apk", summary="Mobil APK Dosyası İndir")
def download_apk():
    paths = [
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "sozegitim-frontend_temel-2", "build", "app", "outputs", "flutter-apk", "app-release.apk")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "sozegitim-frontend_temel-2", "build", "app", "outputs", "flutter-apk", "app-debug.apk")),
    ]
    for path in paths:
        if os.path.exists(path):
            return FileResponse(
                path,
                media_type="application/vnd.android.package-archive",
                filename="SözEğitim.apk"
            )
    return JSONResponse(status_code=404, content={"message": "APK henüz derleniyor veya hazır değil."})

@app.get("/qr", summary="APK İndirme Bağlantısı")
@app.get("/indir", summary="APK İndirme Bağlantısı")
def qr_page():
    return RedirectResponse("/api/download/apk")
