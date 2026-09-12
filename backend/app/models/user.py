import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    display_name = Column(String, nullable=False, default="Player")
    email = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    profile = relationship("PlayerProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    sessions = relationship("GameSession", back_populates="user", cascade="all, delete-orphan")
    user_achievements = relationship("UserAchievement", back_populates="user", cascade="all, delete-orphan")
