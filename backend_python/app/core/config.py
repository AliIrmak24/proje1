# app/core/config.py
# .env dosyasından gizli bilgileri okur ve PostgreSQL bağlantı adresi üretir

import os
from pathlib import Path
from dotenv import load_dotenv

# .env dosyasını backend_python dizininden yükle
env_path = Path(__file__).resolve().parents[2] / '.env'
load_dotenv(dotenv_path=env_path)

class Settings:
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "postgres")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "postgres")
    POSTGRES_SERVER: str = os.getenv("POSTGRES_SERVER", "localhost")
    POSTGRES_PORT: str = os.getenv("POSTGRES_PORT", "5432")
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "sozegitim_db")
    
    # Yeni eklenenler
    SECRET_KEY: str = os.getenv("SECRET_KEY", "gizli_anahtar")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

    DATABASE_URL: str = "postgresql://postgres:Kocaefe12.@localhost:5432/sozegitim_db"

settings = Settings()
