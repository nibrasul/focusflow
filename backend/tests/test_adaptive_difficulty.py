from app.services.adaptive_difficulty import AdaptiveDifficultyEngine

def test_clamping_boundaries():
    # Below minimum
    assert AdaptiveDifficultyEngine.recommend(0.5, [50.0], [5]) == 1.0
    # Above maximum
    assert AdaptiveDifficultyEngine.recommend(10.5, [95.0], [0]) == 10.0
    # At minimum decreasing
    assert AdaptiveDifficultyEngine.recommend(1.0, [50.0], [4]) == 1.0
    # At maximum increasing
    assert AdaptiveDifficultyEngine.recommend(10.0, [95.0], [0]) == 10.0

def test_gradual_increase_on_high_performance():
    new_lvl = AdaptiveDifficultyEngine.recommend(
        current_level=2.0,
        recent_accuracies=[92.0, 95.0, 91.0],
        recent_error_counts=[1, 0, 1]
    )
    assert new_lvl == 2.5

def test_gradual_decrease_on_low_accuracy():
    new_lvl = AdaptiveDifficultyEngine.recommend(
        current_level=3.0,
        recent_accuracies=[60.0, 58.0],
        recent_error_counts=[4, 3]
    )
    assert new_lvl == 2.5

def test_maintain_level_on_moderate_performance():
    new_lvl = AdaptiveDifficultyEngine.recommend(
        current_level=3.0,
        recent_accuracies=[78.0, 82.0],
        recent_error_counts=[2, 2]
    )
    assert new_lvl == 3.0
