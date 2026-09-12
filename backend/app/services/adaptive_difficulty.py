from typing import List
from app.core.config import settings

class AdaptiveDifficultyEngine:
    MIN_LEVEL = settings.MIN_DIFFICULTY
    MAX_LEVEL = settings.MAX_DIFFICULTY
    STEP = settings.DIFFICULTY_STEP

    @classmethod
    def recommend(
        cls,
        current_level: float,
        recent_accuracies: List[float],
        recent_error_counts: List[int],
    ) -> float:
        """
        Calculates recommended next difficulty level based on actual recent player performance.
        Guarantees strict clamping between MIN_LEVEL and MAX_LEVEL.
        """
        current_level = max(cls.MIN_LEVEL, min(float(current_level), cls.MAX_LEVEL))
        
        if not recent_accuracies:
            return current_level

        avg_accuracy = sum(recent_accuracies) / len(recent_accuracies)
        avg_errors = sum(recent_error_counts) / len(recent_error_counts) if recent_error_counts else 0

        new_level = current_level

        # Upward adaptation: high accuracy (> 90%) and low errors (<= 1.5 average)
        if avg_accuracy >= 90.0 and avg_errors <= 1.5:
            new_level += cls.STEP
        # Downward adaptation: low accuracy (< 65%) or high errors (>= 3 average)
        elif avg_accuracy < 65.0 or avg_errors >= 3.0:
            new_level -= cls.STEP

        # Strict clamping
        return round(max(cls.MIN_LEVEL, min(new_level, cls.MAX_LEVEL)), 1)
