from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database.session import get_db
from app.api.v1.sessions import get_or_create_user
from app.schemas.profile import DashboardResponse, ProfileResponse
from app.services.analytics import AnalyticsService
from app.services.adaptive_difficulty import AdaptiveDifficultyEngine
from app.models.session import GameSession
from app.models.achievement import Achievement, UserAchievement

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("", response_model=DashboardResponse)
def get_dashboard(db: Session = Depends(get_db)):
    user = get_or_create_user(db)
    profile = user.profile

    recent_sessions = AnalyticsService.get_recent_sessions(db, user.id, limit=5)
    weekly_trend = AnalyticsService.get_weekly_trends(db, user.id)

    # Check if daily focus session was completed today
    today = date.today()
    daily_completed = (
        db.query(GameSession)
        .filter(
            GameSession.user_id == user.id,
            GameSession.game_mode == "daily",
            GameSession.completed_at.isnot(None),
        )
        .filter(GameSession.started_at >= today)
        .first()
        is not None
    )

    # Adaptive difficulty recommendation
    last_sessions = (
        db.query(GameSession)
        .filter(GameSession.user_id == user.id, GameSession.completed_at.isnot(None))
        .order_by(desc(GameSession.started_at))
        .limit(5)
        .all()
    )
    accuracies = [s.accuracy for s in last_sessions]
    errors = [s.incorrect_targets + s.distraction_errors for s in last_sessions]
    current_game_level = last_sessions[0].level if last_sessions else 1.0
    recommended_level = AdaptiveDifficultyEngine.recommend(current_game_level, accuracies, errors)

    # Mode rotation logic for variety
    modes = ["selective", "sustained", "distraction_shield", "rule_switch", "memory"]
    if recent_sessions:
        last_mode = recent_sessions[0]["game_mode"]
        if last_mode in modes:
            next_idx = (modes.index(last_mode) + 1) % len(modes)
            recommended_mode = modes[next_idx]
        else:
            recommended_mode = "selective"
    else:
        recommended_mode = "selective"

    # Achievements count
    total_ach = db.query(Achievement).count()
    unlocked_ach = db.query(UserAchievement).filter(UserAchievement.user_id == user.id).count()

    return DashboardResponse(
        profile=ProfileResponse(
            user_id=user.id,
            display_name=user.display_name,
            current_level=profile.current_level,
            total_xp=profile.total_xp,
            total_sessions=profile.total_sessions,
            total_play_time=profile.total_play_time,
            overall_accuracy=profile.overall_accuracy,
            average_reaction_time=profile.average_reaction_time,
            current_streak=profile.current_streak,
            best_streak=profile.best_streak,
            last_played_date=profile.last_played_date,
        ),
        recommended_mode=recommended_mode,
        recommended_level=recommended_level,
        daily_completed=daily_completed,
        recent_sessions=recent_sessions,
        weekly_accuracy_trend=weekly_trend,
        unlocked_achievements_count=unlocked_ach,
        total_achievements_count=total_ach,
    )
