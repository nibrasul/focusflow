from uuid import UUID
from datetime import datetime, timedelta, date
from typing import List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc
from app.models.session import GameSession
from app.models.profile import PlayerProfile

class AnalyticsService:
    @staticmethod
    def get_weekly_trends(db: Session, user_id: UUID) -> List[Dict[str, Any]]:
        """
        Retrieves real accuracy and reaction time averages grouped by day for the past 7 days.
        If no data exists for a day, explicitly returns accuracy=None so the UI can draw honest charts.
        """
        today = date.today()
        seven_days_ago = today - timedelta(days=6)

        sessions = (
            db.query(GameSession)
            .filter(
                GameSession.user_id == user_id,
                GameSession.started_at >= datetime.combine(seven_days_ago, datetime.min.time()),
            )
            .all()
        )

        day_map = {today - timedelta(days=i): [] for i in range(6, -1, -1)}
        for s in sessions:
            s_date = s.started_at.date()
            if s_date in day_map:
                day_map[s_date].append(s)

        trends = []
        for d, day_sessions in sorted(day_map.items()):
            if day_sessions:
                avg_acc = round(sum(s.accuracy for s in day_sessions) / len(day_sessions), 1)
                avg_rt = round(sum(s.average_reaction_time for s in day_sessions) / len(day_sessions), 1)
                trends.append({
                    "date": d.isoformat(),
                    "day_label": d.strftime("%a"),
                    "accuracy": avg_acc,
                    "avg_reaction_time": avg_rt,
                    "session_count": len(day_sessions),
                    "has_data": True,
                })
            else:
                trends.append({
                    "date": d.isoformat(),
                    "day_label": d.strftime("%a"),
                    "accuracy": None,
                    "avg_reaction_time": None,
                    "session_count": 0,
                    "has_data": False,
                })
        return trends

    @staticmethod
    def get_recent_sessions(db: Session, user_id: UUID, limit: int = 10) -> List[Dict[str, Any]]:
        sessions = (
            db.query(GameSession)
            .filter(GameSession.user_id == user_id)
            .order_by(desc(GameSession.started_at))
            .limit(limit)
            .all()
        )
        return [
            {
                "id": str(s.id),
                "game_mode": s.game_mode,
                "score": s.score,
                "accuracy": s.accuracy,
                "average_reaction_time": s.average_reaction_time,
                "duration": s.duration,
                "level": s.level,
                "started_at": s.started_at.isoformat(),
            }
            for s in sessions
        ]
