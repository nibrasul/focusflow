import pytest
from app.services.scoring import ScoringEngine
from app.schemas.attempt import AttemptCreate

def test_empty_attempts():
    result = ScoringEngine.calculate([], level=1.0)
    assert result.score == 0
    assert result.accuracy == 0.0
    assert result.average_reaction_time == 0.0
    assert result.correct_count == 0
    assert result.missed_targets == 0
    assert result.longest_streak == 0
    assert result.xp_earned == 0

def test_perfect_session_fast_reactions():
    attempts = [
        AttemptCreate(
            round_number=i,
            target_type="triangle",
            player_action="hit",
            correct=True,
            reaction_time=320.0,
            distraction_present=False,
        )
        for i in range(1, 11)
    ]
    result = ScoringEngine.calculate(attempts, level=2.0)
    assert result.accuracy == 100.0
    assert result.correct_count == 10
    assert result.missed_targets == 0
    assert result.incorrect_targets == 0
    assert result.distraction_errors == 0
    assert result.longest_streak == 10
    assert result.average_reaction_time == 320.0
    assert result.score > 1000  # Base + speed bonus + streak multiplier
    assert result.xp_earned > 0

def test_slow_reactions_vs_fast_reactions():
    fast_attempts = [
        AttemptCreate(round_number=1, target_type="circle", player_action="hit", correct=True, reaction_time=300.0)
    ]
    slow_attempts = [
        AttemptCreate(round_number=1, target_type="circle", player_action="hit", correct=True, reaction_time=950.0)
    ]
    fast_res = ScoringEngine.calculate(fast_attempts, level=1.0)
    slow_res = ScoringEngine.calculate(slow_attempts, level=1.0)
    assert fast_res.score > slow_res.score
    # Accuracy is identical
    assert fast_res.accuracy == slow_res.accuracy == 100.0

def test_penalties_never_produce_negative_score():
    # Only errors and misses
    attempts = [
        AttemptCreate(round_number=1, target_type="circle", player_action="hit", correct=False, reaction_time=200.0, distraction_present=True),
        AttemptCreate(round_number=2, target_type="square", player_action="hit", correct=False, reaction_time=300.0, distraction_present=False),
        AttemptCreate(round_number=3, target_type="triangle", player_action="miss", correct=False, reaction_time=1500.0),
    ]
    result = ScoringEngine.calculate(attempts, level=5.0)
    assert result.accuracy == 0.0
    assert result.score >= 0  # Absolute non-negative requirement
    assert result.distraction_errors == 1
    assert result.incorrect_targets == 1
    assert result.missed_targets == 1

def test_streak_calculation_resets_on_error():
    attempts = [
        AttemptCreate(round_number=1, target_type="circle", player_action="hit", correct=True, reaction_time=400.0),
        AttemptCreate(round_number=2, target_type="circle", player_action="hit", correct=True, reaction_time=400.0),
        AttemptCreate(round_number=3, target_type="circle", player_action="hit", correct=False, reaction_time=400.0), # error
        AttemptCreate(round_number=4, target_type="circle", player_action="hit", correct=True, reaction_time=400.0),
    ]
    result = ScoringEngine.calculate(attempts, level=1.0)
    assert result.longest_streak == 2
    assert result.accuracy == 75.0
