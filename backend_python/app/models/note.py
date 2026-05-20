from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.database import Base

class Note(Base):
    __tablename__ = "notes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    word = Column(String, index=True, nullable=False)
    translation = Column(String, nullable=False)
    personal_note = Column(String, nullable=True) # Kullanıcının kendi ekleyeceği özel not (opsiyonel)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Kullanıcı tablosu ile ilişki kuruyoruz
    owner = relationship("User")
