import type { AttemptRecord, LocalScoringResult } from '../types/game';

export class LocalScoring {
  static calculate(attempts: AttemptRecord[], level: number): LocalScoringResult {
    if (!attempts || attempts.length === 0) {
      return {
        score: 0,
        accuracy: 0.0,
        averageReactionTime: 0.0,
        correctCount: 0,
        missedTargets: 0,
        incorrectTargets: 0,
        distractionErrors: 0,
        longestStreak: 0,
        xpEarned: 0,
      };
    }

    let correctCount = 0;
    let missedTargets = 0;
    let incorrectTargets = 0;
    let distractionErrors = 0;
    const validReactionTimes: number[] = [];

    let currentStreak = 0;
    let longestStreak = 0;
    let speedBonusTotal = 0.0;

    for (const att of attempts) {
      const action = att.playerAction.toLowerCase();
      if (att.correct) {
        correctCount++;
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

        const rt = Math.max(100.0, Math.min(att.reactionTime, 2500.0));
        validReactionTimes.push(rt);

        if (rt < 800.0) {
          speedBonusTotal += (800.0 - rt) / 10.0;
        }
      } else {
        currentStreak = 0;
        if (action === 'miss' || action === 'timeout') {
          missedTargets++;
        } else if (att.distractionPresent) {
          distractionErrors++;
        } else {
          incorrectTargets++;
        }
      }
    }

    const accuracy = attempts.length > 0
      ? Math.round((correctCount / attempts.length) * 1000) / 10
      : 0.0;

    const avgRt = validReactionTimes.length > 0
      ? Math.round((validReactionTimes.reduce((a, b) => a + b, 0) / validReactionTimes.length) * 10) / 10
      : 0.0;

    const clampedLevel = Math.max(1.0, Math.min(level, 10.0));
    const levelMultiplier = 1.0 + (clampedLevel - 1.0) * 0.15;

    const basePoints = correctCount * 100 * levelMultiplier;
    const streakMultiplier = Math.min(2.0, 1.0 + longestStreak * 0.05);
    const penalties = (incorrectTargets * 40) + (distractionErrors * 60) + (missedTargets * 25);

    const grossScore = (basePoints + speedBonusTotal) * streakMultiplier;
    const netScore = Math.max(0, Math.round(grossScore - penalties));

    const baseXP = Math.floor(netScore * 0.1);
    const accuracyXpBonus = accuracy >= 70.0 ? Math.floor(accuracy * 0.5) : 0;
    const xpEarned = correctCount > 0 ? Math.max(10, baseXP + accuracyXpBonus) : 0;

    return {
      score: netScore,
      accuracy,
      averageReactionTime: avgRt,
      correctCount,
      missedTargets,
      incorrectTargets,
      distractionErrors,
      longestStreak,
      xpEarned,
    };
  }
}
