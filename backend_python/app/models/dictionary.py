from sqlalchemy import Column, Integer, String, JSON
from app.database import Base

class DictionaryWord(Base):
    __tablename__ = "dictionary"

    id = Column(Integer, primary_key=True, index=True)
    word = Column(String, unique=True, index=True, nullable=False)  # İngilizce kelime
    translation = Column(String, nullable=False)  # Türkçe çevirisi
    level = Column(String, nullable=False)  # A1, A2, B1, B2, C1, C2
    phonetic = Column(String, nullable=True)
    meanings = Column(JSON, nullable=False)  # Tüm o detaylı açıklamalar ve örnekleri JSON olarak gömeceğiz
