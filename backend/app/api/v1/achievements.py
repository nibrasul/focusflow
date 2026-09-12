from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.api.v1.sessions import get_or_create_user
from app.models.achievement import Achievement, UserAchievement
from app.schemas.profile import AchievementItem

router = APIRouter(prefix="/achievements", tags=["Achievements"])

@router.get("", response_model=List[AchievementItem])
def list_achievements(db: Session = Depends(get_db)):
    user = get_or_create_user(db)
    all_ach = db.query(Achievement).all()
    user_ach_map = {
        ua.achievement_id: ua.unlocked_at
        for ua in db.query(UserAchievement).filter(UserAchievement.user_id == user.id).all()
    }

    result = []
    for a in all_ach:
        unlocked = a.id in user_ach_map
        result.append(
            AchievementItem(
                id=a.id,
                title=a.title,
                description=a.description,
                icon_name=a.icon_name,
                category=a.category,
                xp_reward=a.xp_reward,
                unlocked=unlocked,
                unlocked_at=user_ach_map.get(a.id),
            )
        )
    return result
