from datetime import datetime
from uuid import UUID
from typing import Optional
from pydantic import BaseModel, Field

class AttemptCreate(BaseModel):
    round_number: int = Field(ge=1)
    target_type: str
    player_action: str
    correct: bool
    reaction_time: float = Field(ge=0.0)  # ms
    distraction_present: bool = False
    timestamp: Optional[datetime] = None

class AttemptResponse(BaseModel):
    id: UUID
    session_id: UUID
    round_number: int
    target_type: str
    player_action: str
    correct: bool
    reaction_time: float
    distraction_present: bool
    timestamp: datetime

    model_config = {"from_attributes": True}
