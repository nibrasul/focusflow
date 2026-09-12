import 'dart:math';
import '../models/attempt_record.dart';

class LocalScoringResult {
  final int score;
  final double accuracy;
  final double averageReactionTime;
  final int correctCount;
  final int missedTargets;
  final int incorrectTargets;
  final int distractionErrors;
  final int longestStreak;
  final int xpEarned;

  LocalScoringResult({
    required this.score,
    required this.accuracy,
    required this.averageReactionTime,
    required this.correctCount,
    required this.missedTargets,
    required this.incorrectTargets,
    required this.distractionErrors,
    required this.longestStreak,
    required this.xpEarned,
  });
}

class LocalScoring {
  static LocalScoringResult calculate(List<AttemptRecord> attempts, double level) {
    if (attempts.isEmpty) {
      return LocalScoringResult(
        score: 0,
        accuracy: 0.0,
        averageReactionTime: 0.0,
        correctCount: 0,
        missedTargets: 0,
        incorrectTargets: 0,
        distractionErrors: 0,
        longestStreak: 0,
        xpEarned: 0,
      );
    }

    int correctCount = 0;
    int missedTargets = 0;
    int incorrectTargets = 0;
    int distractionErrors = 0;
    final List<double> validReactionTimes = [];

    int currentStreak = 0;
    int longestStreak = 0;
    double speedBonusTotal = 0.0;

    for (final att in attempts) {
      final action = att.playerAction.toLowerCase();
      if (att.correct) {
        correctCount++;
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

        final rt = max(100.0, min(att.reactionTime, 2500.0));
        validReactionTimes.add(rt);

        if (rt < 800.0) {
          speedBonusTotal += (800.0 - rt) / 10.0;
        }
      } else {
        currentStreak = 0;
        if (action == 'miss' || action == 'timeout') {
          missedTargets++;
        } else if (att.distractionPresent) {
          distractionErrors++;
        } else {
          incorrectTargets++;
        }
      }
    }

    final double accuracy = attempts.isNotEmpty
        ? ((correctCount / attempts.length) * 1000).round() / 10.0
        : 0.0;

    final double avgRt = validReactionTimes.isNotEmpty
        ? ((validReactionTimes.reduce((a, b) => a + b) / validReactionTimes.length) * 10).round() / 10.0
        : 0.0;

    final double clampedLevel = max(1.0, min(level, 10.0));
    final double levelMultiplier = 1.0 + ((clampedLevel - 1.0) * 0.15);

    final double basePoints = correctCount * 100 * levelMultiplier;
    final double streakMultiplier = min(2.0, 1.0 + (longestStreak * 0.05));
    final int penalties = (incorrectTargets * 40) + (distractionErrors * 60) + (missedTargets * 25);

    final double grossScore = (basePoints + speedBonusTotal) * streakMultiplier;
    final int netScore = max(0, (grossScore - penalties).round());

    final int baseXP = (netScore * 0.1).floor();
    final int accuracyXpBonus = accuracy >= 70.0 ? (accuracy * 0.5).floor() : 0;
    final int xpEarned = correctCount > 0 ? max(10, baseXP + accuracyXpBonus) : 0;

    return LocalScoringResult(
      score: netScore,
      accuracy: accuracy,
      averageReactionTime: avgRt,
      correctCount: correctCount,
      missedTargets: missedTargets,
      incorrectTargets: incorrectTargets,
      distractionErrors: distractionErrors,
      longestStreak: longestStreak,
      xpEarned: xpEarned,
    );
  }
}
