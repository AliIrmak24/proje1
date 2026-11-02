# app/database.py
# SQLAlchemy bağlantı ve oturum yönetimi

from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings

def create_app_engine():
    if not settings.DATABASE_URL.startswith("sqlite"):
        return create_engine(settings.DATABASE_URL, pool_pre_ping=True)

    sqlite_engine = create_engine(
        settings.DATABASE_URL,
        connect_args={"check_same_thread": False, "timeout": 30},
    )

    # WAL okuma/yazma kilitlenmelerini önler; yabancı anahtarlar SQLite'ta varsayılan olarak kapalıdır
    @event.listens_for(sqlite_engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA synchronous=NORMAL")
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    return sqlite_engine

engine = create_app_engine()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
