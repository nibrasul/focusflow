import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, Float, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.base import Base

class GameAttempt(Base):
    __tablename__ = "game_attempts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("game_sessions.id", ondelete="CASCADE"), nullable=False)
    round_number = Column(Integer, nullable=False)
    target_type = Column(String, nullable=False)
    player_action = Column(String, nullable=False)  # hit, miss, false_alarm, timeout
    correct = Column(Boolean, nullable=False)
    reaction_time = Column(Float, nullable=False)  # in milliseconds
    distraction_present = Column(Boolean, default=False, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)

    session = relationship("GameSession", back_populates="attempts")
