from typing import List
from dataclasses import dataclass
from app.schemas.attempt import AttemptCreate

@dataclass
class ScoringResult:
    score: int
    accuracy: float
    average_reaction_time: float
    correct_count: int
    missed_targets: int
    incorrect_targets: int
    distraction_errors: int
    longest_streak: int
    xp_earned: int

class ScoringEngine:
    @staticmethod
    def calculate(attempts: List[AttemptCreate], level: float) -> ScoringResult:
        if not attempts:
            return ScoringResult(
                score=0,
                accuracy=0.0,
                average_reaction_time=0.0,
                correct_count=0,
                missed_targets=0,
                incorrect_targets=0,
                distraction_errors=0,
                longest_streak=0,
                xp_earned=0,
            )

        correct_count = 0
        missed_targets = 0
        incorrect_targets = 0
        distraction_errors = 0
        valid_reaction_times = []
        
        current_streak = 0
        longest_streak = 0
        speed_bonus_total = 0.0

        for att in attempts:
            # Action classification
            action = att.player_action.lower()
            if att.correct:
                correct_count += 1
                current_streak += 1
                if current_streak > longest_streak:
                    longest_streak = current_streak
                
                # Reaction time bonus for fast, correct responses
                # Clamped between 100ms and 2000ms
                rt = max(100.0, min(att.reaction_time, 2500.0))
                valid_reaction_times.append(rt)
                
                # Bonus if faster than 800ms
                if rt < 800.0:
                    speed_bonus_total += (800.0 - rt) / 10.0
            else:
                current_streak = 0
                if action in ("miss", "timeout"):
                    missed_targets += 1
                elif att.distraction_present:
                    distraction_errors += 1
                else:
                    incorrect_targets += 1

        total_evaluations = len(attempts)
        accuracy = round((correct_count / total_evaluations) * 100.0, 1) if total_evaluations > 0 else 0.0
        
        avg_rt = round(sum(valid_reaction_times) / len(valid_reaction_times), 1) if valid_reaction_times else 0.0

        # Multiplier scales smoothly with difficulty level (1.0 to 10.0)
        clamped_level = max(1.0, min(level, 10.0))
        level_multiplier = 1.0 + ((clamped_level - 1.0) * 0.15)
        
        base_points = correct_count * 100 * level_multiplier
        
        # Streak multiplier caps at 2.0x (requires 20 consecutive hits)
        streak_multiplier = min(2.0, 1.0 + (longest_streak * 0.05))
        
        # Penalties
        penalties = (incorrect_targets * 40) + (distraction_errors * 60) + (missed_targets * 25)
        
        gross_score = (base_points + speed_bonus_total) * streak_multiplier
        net_score = int(round(max(0.0, gross_score - penalties)))

        # XP calculation based on net score, accuracy, and difficulty
        base_xp = int(net_score * 0.1)
        accuracy_xp_bonus = int(accuracy * 0.5) if accuracy >= 70.0 else 0
        xp_earned = max(10, base_xp + accuracy_xp_bonus) if correct_count > 0 else 0

        return ScoringResult(
            score=net_score,
            accuracy=accuracy,
            average_reaction_time=avg_rt,
            correct_count=correct_count,
            missed_targets=missed_targets,
            incorrect_targets=incorrect_targets,
            distraction_errors=distraction_errors,
            longest_streak=longest_streak,
            xp_earned=xp_earned,
        )
