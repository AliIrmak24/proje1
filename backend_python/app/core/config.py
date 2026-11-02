# app/core/config.py
# .env dosyasından gizli bilgileri ve bağlantı ayarlarını okur

import os
from pathlib import Path
from dotenv import load_dotenv

# .env dosyasını backend_python dizininden yükle
backend_dir = Path(__file__).resolve().parents[2]
load_dotenv(dotenv_path=backend_dir / '.env')

class Settings:
    # Boş bırakılırsa yerel SQLite kullanılır; Postgres için tam bağlantı adresi verilir
    DATABASE_URL: str = os.getenv("DATABASE_URL") or f"sqlite:///{backend_dir / 'sozegitim.db'}"

    SECRET_KEY: str = os.getenv("SECRET_KEY", "")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

    # Virgülle ayrılmış izinli adresler; yetkilendirme çerez değil Bearer token ile yapılır
    CORS_ORIGINS: list[str] = [o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()]

settings = Settings()

if len(settings.SECRET_KEY) < 32:
    raise RuntimeError(
        "SECRET_KEY eksik veya çok kısa. backend_python/.env dosyasına en az 32 karakterlik "
        "rastgele bir değer yazın (.env.example dosyasına bakın)."
    )
