from datetime import datetime
from uuid import UUID
from typing import List, Optional
from pydantic import BaseModel, Field
from app.schemas.attempt import AttemptCreate, AttemptResponse

class SessionCreate(BaseModel):
    id: Optional[UUID] = None
    user_id: Optional[UUID] = None
    game_mode: str
    started_at: datetime
    level: float = Field(default=1.0, ge=1.0, le=10.0)

class SessionComplete(BaseModel):
    completed_at: datetime
    duration: int = Field(ge=0)
    level: float = Field(default=1.0, ge=1.0, le=10.0)
    # Client-submitted metrics (validated server-side)
    client_score: Optional[int] = None
    client_accuracy: Optional[float] = None
    client_avg_reaction_time: Optional[float] = None
    attempts: List[AttemptCreate] = []

class SessionResponse(BaseModel):
    id: UUID
    user_id: UUID
    game_mode: str
    started_at: datetime
    completed_at: Optional[datetime]
    duration: int
    level: float
    score: int
    accuracy: float
    average_reaction_time: float
    missed_targets: int
    incorrect_targets: int
    distraction_errors: int
    longest_streak: int
    xp_earned: Optional[int] = 0
    new_level: Optional[int] = None
    unlocked_achievements: Optional[List[str]] = []
    attempts: Optional[List[AttemptResponse]] = []

    model_config = {"from_attributes": True}
