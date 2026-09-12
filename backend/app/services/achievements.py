from datetime import datetime
from uuid import UUID
from typing import List
from sqlalchemy.orm import Session
from app.models.achievement import Achievement, UserAchievement
from app.models.profile import PlayerProfile
from app.models.session import GameSession

INITIAL_ACHIEVEMENTS = [
    {
        "id": "first_focus",
        "title": "First Step",
        "description": "Completed your first attention training session.",
        "icon_name": "flag_checkered",
        "category": "milestone",
        "xp_reward": 50,
    },
    {
        "id": "five_sessions",
        "title": "Habit Former",
        "description": "Completed 5 training sessions.",
        "icon_name": "award",
        "category": "milestone",
        "xp_reward": 100,
    },
    {
        "id": "ten_sessions",
        "title": "Dedicated Mind",
        "description": "Completed 10 training sessions.",
        "icon_name": "trophy",
        "category": "milestone",
        "xp_reward": 200,
    },
    {
        "id": "distraction_master",
        "title": "Distraction Shield Master",
        "description": "Finished Distraction Shield with zero distraction errors.",
        "icon_name": "shield",
        "category": "mastery",
        "xp_reward": 150,
    },
    {
        "id": "swift_reflex",
        "title": "Swift Reflexes",
        "description": "Maintained an average reaction time under 400ms.",
        "icon_name": "zap",
        "category": "reflex",
        "xp_reward": 150,
    },
    {
        "id": "laser_accuracy",
        "title": "Laser Focus",
        "description": "Achieved 100% accuracy in a session with at least 10 rounds.",
        "icon_name": "target",
        "category": "accuracy",
        "xp_reward": 200,
    },
    {
        "id": "streak_master",
        "title": "Flow State",
        "description": "Achieved a focus streak of 15 or more consecutive correct responses.",
        "icon_name": "flame",
        "category": "streak",
        "xp_reward": 175,
    },
]

class AchievementService:
    @staticmethod
    def seed_achievements(db: Session):
        for data in INITIAL_ACHIEVEMENTS:
            existing = db.query(Achievement).filter(Achievement.id == data["id"]).first()
            if not existing:
                ach = Achievement(**data)
                db.add(ach)
        db.commit()

    @staticmethod
    def evaluate_and_unlock(db: Session, user_id: UUID, session: GameSession, profile: PlayerProfile) -> List[str]:
        # Get already unlocked achievements
        unlocked_ids = {
            ua.achievement_id
            for ua in db.query(UserAchievement).filter(UserAchievement.user_id == user_id).all()
        }

        newly_unlocked = []

        def grant(ach_id: str):
            if ach_id not in unlocked_ids:
                ua = UserAchievement(user_id=user_id, achievement_id=ach_id, unlocked_at=datetime.utcnow())
                db.add(ua)
                unlocked_ids.add(ach_id)
                newly_unlocked.append(ach_id)
                ach = db.query(Achievement).filter(Achievement.id == ach_id).first()
                if ach:
                    profile.total_xp += ach.xp_reward

        # Evaluation rules:
        if profile.total_sessions >= 1:
            grant("first_focus")
        if profile.total_sessions >= 5:
            grant("five_sessions")
        if profile.total_sessions >= 10:
            grant("ten_sessions")

        if session.game_mode == "distraction_shield" and session.distraction_errors == 0 and session.accuracy >= 80.0:
            grant("distraction_master")

        if 0 < session.average_reaction_time < 400.0 and session.accuracy >= 80.0:
            grant("swift_reflex")

        if session.accuracy >= 100.0 and len(session.attempts) >= 10:
            grant("laser_accuracy")

        if session.longest_streak >= 15:
            grant("streak_master")

        db.commit()
        return newly_unlocked
