import uuid
from datetime import datetime, date
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database.session import get_db
from app.models.user import User
from app.models.profile import PlayerProfile
from app.models.session import GameSession
from app.models.attempt import GameAttempt
from app.schemas.session import SessionCreate, SessionComplete, SessionResponse
from app.services.scoring import ScoringEngine
from app.services.adaptive_difficulty import AdaptiveDifficultyEngine
from app.services.achievements import AchievementService

router = APIRouter(prefix="/sessions", tags=["Sessions"])

DEFAULT_USER_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")

def get_or_create_user(db: Session, user_id: uuid.UUID = None) -> User:
    target_id = user_id or DEFAULT_USER_ID
    user = db.query(User).filter(User.id == target_id).first()
    if not user:
        user = User(id=target_id, display_name="Focus Athlete")
        db.add(user)
        db.flush()
        profile = PlayerProfile(user_id=user.id, current_level=1, current_streak=0, best_streak=0)
        db.add(profile)
        db.commit()
        db.refresh(user)
    elif not user.profile:
        profile = PlayerProfile(user_id=user.id, current_level=1, current_streak=0, best_streak=0)
        db.add(profile)
        db.commit()
        db.refresh(user)
    return user

@router.post("", response_model=SessionResponse)
def create_session(payload: SessionCreate, db: Session = Depends(get_db)):
    user = get_or_create_user(db, payload.user_id)
    session_id = payload.id or uuid.uuid4()

    # Check if already exists (idempotent for offline sync replay)
    existing = db.query(GameSession).filter(GameSession.id == session_id).first()
    if existing:
        return existing

    session = GameSession(
        id=session_id,
        user_id=user.id,
        game_mode=payload.game_mode,
        started_at=payload.started_at,
        level=payload.level,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session

@router.post("/{session_id}/complete", response_model=SessionResponse)
def complete_session(session_id: uuid.UUID, payload: SessionComplete, db: Session = Depends(get_db)):
    session = db.query(GameSession).filter(GameSession.id == session_id).first()
    if not session:
        # If session was created offline and immediately posted as complete
        user = get_or_create_user(db)
        session = GameSession(
            id=session_id,
            user_id=user.id,
            game_mode="selective",  # fallback if not previously posted
            started_at=payload.completed_at,
            level=payload.level,
        )
        db.add(session)
        db.flush()

    # Authoritative scoring calculation from attempts
    scoring_result = ScoringEngine.calculate(payload.attempts, session.level)

    session.completed_at = payload.completed_at
    session.duration = payload.duration
    session.score = scoring_result.score
    session.accuracy = scoring_result.accuracy
    session.average_reaction_time = scoring_result.average_reaction_time
    session.missed_targets = scoring_result.missed_targets
    session.incorrect_targets = scoring_result.incorrect_targets
    session.distraction_errors = scoring_result.distraction_errors
    session.longest_streak = scoring_result.longest_streak

    # Store individual round attempts
    db.query(GameAttempt).filter(GameAttempt.session_id == session.id).delete()
    for att in payload.attempts:
        db_att = GameAttempt(
            session_id=session.id,
            round_number=att.round_number,
            target_type=att.target_type,
            player_action=att.player_action,
            correct=att.correct,
            reaction_time=att.reaction_time,
            distraction_present=att.distraction_present,
            timestamp=att.timestamp or datetime.utcnow(),
        )
        db.add(db_att)

    # Update player profile stats
    profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == session.user_id).first()
    if not profile:
        profile = PlayerProfile(user_id=session.user_id)
        db.add(profile)
        db.flush()

    profile.total_sessions += 1
    profile.total_play_time += payload.duration
    profile.total_xp += scoring_result.xp_earned

    # Cumulative running averages
    all_user_sessions = db.query(GameSession).filter(GameSession.user_id == session.user_id, GameSession.completed_at.isnot(None)).all()
    total_acc = sum(s.accuracy for s in all_user_sessions) + session.accuracy
    profile.overall_accuracy = round(total_acc / (len(all_user_sessions) + 1), 1)

    all_rts = [s.average_reaction_time for s in all_user_sessions if s.average_reaction_time > 0]
    if session.average_reaction_time > 0:
        all_rts.append(session.average_reaction_time)
    profile.average_reaction_time = round(sum(all_rts) / len(all_rts), 1) if all_rts else 0.0

    # Streaks calculation (daily continuity)
    today = date.today()
    if profile.last_played_date is None:
        profile.current_streak = 1
    elif profile.last_played_date == today:
        pass  # already played today
    elif profile.last_played_date == today - date.resolution:
        profile.current_streak += 1
    else:
        profile.current_streak = 1
    profile.last_played_date = today

    if profile.current_streak > profile.best_streak:
        profile.best_streak = profile.current_streak

    # Profile Level calculation (1 level per 500 XP)
    calculated_profile_level = max(1, (profile.total_xp // 500) + 1)
    profile.current_level = calculated_profile_level

    # Check achievements
    unlocked = AchievementService.evaluate_and_unlock(db, session.user_id, session, profile)

    db.commit()
    db.refresh(session)

    # Build response
    resp = SessionResponse.model_validate(session)
    resp.xp_earned = scoring_result.xp_earned
    resp.new_level = profile.current_level
    resp.unlocked_achievements = unlocked
    return resp

@router.get("", response_model=List[SessionResponse])
def list_sessions(limit: int = Query(default=20, ge=1, le=100), db: Session = Depends(get_db)):
    user = get_or_create_user(db)
    sessions = (
        db.query(GameSession)
        .filter(GameSession.user_id == user.id)
        .order_by(desc(GameSession.started_at))
        .limit(limit)
        .all()
    )
    return sessions
