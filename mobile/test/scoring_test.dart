import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/domain/models/attempt_record.dart';
import 'package:focus_app/domain/engines/local_scoring.dart';

void main() {
  group('LocalScoring Tests', () {
    test('Empty attempts produce clean zero metrics', () {
      final res = LocalScoring.calculate([], 1.0);
      expect(res.score, 0);
      expect(res.accuracy, 0.0);
      expect(res.averageReactionTime, 0.0);
      expect(res.correctCount, 0);
      expect(res.longestStreak, 0);
      expect(res.xpEarned, 0);
    });

    test('10 perfect hits produce high score and 100% accuracy', () {
      final attempts = List.generate(
        10,
        (i) => AttemptRecord(
          id: 'test_$i',
          sessionId: 'session_1',
          roundNumber: i + 1,
          targetType: 'TRIANGLE',
          playerAction: 'hit',
          correct: true,
          reactionTime: 350.0,
        ),
      );

      final res = LocalScoring.calculate(attempts, 2.0);
      expect(res.accuracy, 100.0);
      expect(res.correctCount, 10);
      expect(res.longestStreak, 10);
      expect(res.missedTargets, 0);
      expect(res.incorrectTargets, 0);
      expect(res.distractionErrors, 0);
      expect(res.averageReactionTime, 350.0);
      expect(res.score, greaterThan(1200));
      expect(res.xpEarned, greaterThan(0));
    });

    test('Score never goes negative on multiple errors', () {
      final attempts = [
        AttemptRecord(
          id: '1',
          sessionId: 's',
          roundNumber: 1,
          targetType: 'T',
          playerAction: 'hit',
          correct: false,
          reactionTime: 300.0,
          distractionPresent: true,
        ),
        AttemptRecord(
          id: '2',
          sessionId: 's',
          roundNumber: 2,
          targetType: 'T',
          playerAction: 'miss',
          correct: false,
          reactionTime: 1200.0,
        ),
      ];

      final res = LocalScoring.calculate(attempts, 5.0);
      expect(res.score, greaterThanOrEqualTo(0));
      expect(res.accuracy, 0.0);
      expect(res.distractionErrors, 1);
      expect(res.missedTargets, 1);
    });
  });
}
