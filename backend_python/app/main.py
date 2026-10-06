# app/main.py
# SözEğitim Ana API Giriş Noktası

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from app.database import engine, Base, get_db
from app.models import user, note, dictionary, friendship
from app.api.endpoints.user_router import router as user_router
from app.api.endpoints.word_router import router as word_router
from app.api.endpoints.note_router import router as note_router
from app.api.endpoints.quiz_router import router as quiz_router
from app.api.endpoints.friend_router import router as friend_router
from app.models.dictionary import DictionaryWord
from app.models.user import User
import os
from fastapi.responses import FileResponse, JSONResponse

# Veritabanında tabloları otomatik oluşturur
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SözEğitim API",
    version="2.0.0",
    description="SözEğitim İngilizce Kelime, Quiz, Sosyal Arkadaşlar ve Gamification API Sistemi"
)

# CORS ayarları (Tüm mobil cihazlar, emülatörler ve web için tam erişim)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Router'ları kayıt et
app.include_router(user_router, prefix="/api/users", tags=["Kullanıcı & Giriş/Çıkış"])
app.include_router(word_router, prefix="/api/words", tags=["Sözlük"])
app.include_router(quiz_router, prefix="/api/quiz", tags=["Yarışma, Quiz & Liderlik"])
app.include_router(friend_router, prefix="/api/friends", tags=["Arkadaşlar & Sosyal"])
app.include_router(note_router, prefix="/api/notes", tags=["Kelimelerim & Notlar"])

@app.get("/", summary="API Kök Durumu")
def root():
    return {
        "status": "online",
        "app": "SözEğitim API",
        "version": "2.0.0",
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

@app.get("/api/leaderboard", summary="Genel Puan Sıralaması")
def global_leaderboard(db: Session = Depends(get_db)):
    from app.services.quiz_service import QuizService
    return QuizService().get_leaderboard(db)

@app.get("/api/download/apk", summary="Mobil APK Dosyası İndir")
def download_apk():
    paths = [
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "sozegitim-frontend_temel-2", "build", "app", "outputs", "flutter-apk", "app-release.apk")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "sozegitim-frontend_temel-2", "build", "app", "outputs", "flutter-apk", "app-debug.apk")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "SözEğitim.apk")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "sozegitim.apk")),
    ]
    for path in paths:
        if os.path.exists(path):
            return FileResponse(
                path,
                media_type="application/vnd.android.package-archive",
                filename="SözEğitim.apk"
            )
    return JSONResponse(status_code=404, content={"message": "APK henüz derleniyor veya hazır değil."})

@app.get("/qr", summary="APK İndirme QR Kodu Sayfası")
@app.get("/indir", summary="APK İndirme QR Kodu Sayfası")
def qr_page():
    qr_html_path = "C:\\Users\\alii0\\Desktop\\SözEğitim_APK_QR_Kodu.html"
    if os.path.exists(qr_html_path):
        return FileResponse(qr_html_path, media_type="text/html")
    return {"message": "QR sayfası hazır"}
