from datetime import datetime, date
from sqlalchemy import Column, Integer, Float, DateTime, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.base import Base

class PlayerProfile(Base):
    __tablename__ = "player_profiles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    current_level = Column(Integer, default=1, nullable=False)
    total_xp = Column(Integer, default=0, nullable=False)
    total_sessions = Column(Integer, default=0, nullable=False)
    total_play_time = Column(Integer, default=0, nullable=False)  # in seconds
    overall_accuracy = Column(Float, default=0.0, nullable=False)  # 0.0 to 100.0
    average_reaction_time = Column(Float, default=0.0, nullable=False)  # in ms
    current_streak = Column(Integer, default=0, nullable=False)
    best_streak = Column(Integer, default=0, nullable=False)
    last_played_date = Column(Date, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="profile")
