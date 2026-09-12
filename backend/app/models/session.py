import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.base import Base

class GameSession(Base):
    __tablename__ = "game_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    game_mode = Column(String, nullable=False)  # selective, sustained, distraction_shield, rule_switch, memory, daily
    started_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    completed_at = Column(DateTime, nullable=True)
    duration = Column(Integer, default=0, nullable=False)  # duration in seconds
    level = Column(Float, default=1.0, nullable=False)
    score = Column(Integer, default=0, nullable=False)
    accuracy = Column(Float, default=0.0, nullable=False)  # percentage 0.0 - 100.0
    average_reaction_time = Column(Float, default=0.0, nullable=False)  # in ms
    missed_targets = Column(Integer, default=0, nullable=False)
    incorrect_targets = Column(Integer, default=0, nullable=False)
    distraction_errors = Column(Integer, default=0, nullable=False)
    longest_streak = Column(Integer, default=0, nullable=False)

    user = relationship("User", back_populates="sessions")
    attempts = relationship("GameAttempt", back_populates="session", cascade="all, delete-orphan", order_by="GameAttempt.round_number")
