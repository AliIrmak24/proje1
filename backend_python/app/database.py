# app/database.py
# SQLAlchemy PostgreSQL & SQLite Dayanıklı Bağlantı ve Oturum Yönetimi

from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings
from pathlib import Path

def create_resilient_engine():
    try:
        # PostgreSQL bağlantısını dene (1 saniye zaman aşımı)
        pg_engine = create_engine(
            settings.DATABASE_URL,
            connect_args={"connect_timeout": 1},
            pool_pre_ping=True,
        )
        with pg_engine.connect() as conn:
            pass
        return pg_engine
    except Exception:
        # PostgreSQL servisi kapalıysa güvenle yerel SQLite veritabanına geç
        db_path = Path(__file__).resolve().parent.parent / "sozegitim.db"
        sqlite_engine = create_engine(
            f"sqlite:///{db_path}",
            connect_args={"check_same_thread": False, "timeout": 30},
        )

        # SQLite için WAL (Write-Ahead Logging) modunu aktif et (aynı anda okuma/yazma kilitlenmelerini önler)
        @event.listens_for(sqlite_engine, "connect")
        def set_sqlite_pragma(dbapi_connection, connection_record):
            cursor = dbapi_connection.cursor()
            cursor.execute("PRAGMA journal_mode=WAL")
            cursor.execute("PRAGMA synchronous=NORMAL")
            cursor.close()

        return sqlite_engine

engine = create_resilient_engine()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
