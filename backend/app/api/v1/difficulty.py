from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import desc
from pydantic import BaseModel

from app.database.session import get_db
from app.api.v1.sessions import get_or_create_user
from app.services.adaptive_difficulty import AdaptiveDifficultyEngine
from app.models.session import GameSession

router = APIRouter(prefix="/difficulty", tags=["Difficulty"])

class DifficultyRecommendation(BaseModel):
    current_level: float
    recommended_level: float
    reason: str

@router.get("/recommendation", response_model=DifficultyRecommendation)
def get_recommendation(db: Session = Depends(get_db)):
    user = get_or_create_user(db)
    last_sessions = (
        db.query(GameSession)
        .filter(GameSession.user_id == user.id, GameSession.completed_at.isnot(None))
        .order_by(desc(GameSession.started_at))
        .limit(5)
        .all()
    )

    if not last_sessions:
        return DifficultyRecommendation(
            current_level=1.0,
            recommended_level=1.0,
            reason="Starting baseline level for new training profile."
        )

    current_level = last_sessions[0].level
    accuracies = [s.accuracy for s in last_sessions]
    errors = [s.incorrect_targets + s.distraction_errors for s in last_sessions]
    rec_level = AdaptiveDifficultyEngine.recommend(current_level, accuracies, errors)

    avg_acc = sum(accuracies) / len(accuracies)
    if rec_level > current_level:
        reason = f"High consistency ({avg_acc:.1f}% accuracy across recent sessions). Raising challenge."
    elif rec_level < current_level:
        reason = f"Challenging sessions detected ({avg_acc:.1f}% accuracy). Recalibrating to reinforce focus."
    else:
        reason = f"Stable performance ({avg_acc:.1f}% accuracy). Maintaining current level."

    return DifficultyRecommendation(
        current_level=current_level,
        recommended_level=rec_level,
        reason=reason,
    )
