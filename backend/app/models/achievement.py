from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.base import Base

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(String, primary_key=True)  # e.g. "first_focus", "ten_sessions", "distraction_master"
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    icon_name = Column(String, nullable=False)
    category = Column(String, default="general", nullable=False)
    xp_reward = Column(Integer, default=50, nullable=False)

class UserAchievement(Base):
    __tablename__ = "user_achievements"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    achievement_id = Column(String, ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False)
    unlocked_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="user_achievements")
    achievement = relationship("Achievement")
