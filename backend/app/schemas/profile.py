from datetime import datetime, date
from uuid import UUID
from typing import Optional, List
from pydantic import BaseModel

class ProfileResponse(BaseModel):
    user_id: UUID
    display_name: str
    current_level: int
    total_xp: int
    total_sessions: int
    total_play_time: int
    overall_accuracy: float
    average_reaction_time: float
    current_streak: int
    best_streak: int
    last_played_date: Optional[date]

    model_config = {"from_attributes": True}

class AchievementItem(BaseModel):
    id: str
    title: str
    description: str
    icon_name: str
    category: str
    xp_reward: int
    unlocked: bool
    unlocked_at: Optional[datetime] = None

class DashboardResponse(BaseModel):
    profile: ProfileResponse
    recommended_mode: str
    recommended_level: float
    daily_completed: bool
    recent_sessions: List[dict]
    weekly_accuracy_trend: List[dict]
    unlocked_achievements_count: int
    total_achievements_count: int
