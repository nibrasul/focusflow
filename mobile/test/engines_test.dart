import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/domain/engines/selective_focus_engine.dart';
import 'package:focus_app/domain/engines/sustained_focus_engine.dart';
import 'package:focus_app/domain/engines/distraction_shield_engine.dart';
import 'package:focus_app/domain/engines/rule_switch_engine.dart';
import 'package:focus_app/domain/engines/memory_focus_engine.dart';

void main() {
  group('Cognitive Game Engine Unit Tests', () {
    test('SelectiveFocusEngine generates valid round with exactly 1 target', () {
      final engine = SelectiveFocusEngine();
      final round = engine.generateRound(roundNumber: 1, level: 2.0);

      expect(round.items.isNotEmpty, true);
      expect(round.items.where((i) => i.isTarget).length, 1);
      expect(round.target.isTarget, true);
      expect(round.instruction.contains('Find'), true);
    });

    test('SustainedFocusEngine generates sequence of trials with Go and No-Go', () {
      final engine = SustainedFocusEngine();
      final sequence = engine.generateSequence(totalTrials: 10, level: 3.0);

      expect(sequence.length, 10);
      expect(sequence.any((t) => t.isTarget), true);
      expect(sequence.any((t) => !t.isTarget), true);
    });

    test('DistractionShieldEngine creates floating items and target', () {
      final engine = DistractionShieldEngine();
      final round = engine.generateRound(roundNumber: 1, level: 2.5);

      expect(round.target.isTarget, true);
      expect(round.fieldItems.isNotEmpty, true);
      expect(round.floatingDistractions.isNotEmpty, true);
      expect(round.fakeInstruction.isNotEmpty, true);
    });

    test('RuleSwitchEngine generates rounds with dynamic rules', () {
      final engine = RuleSwitchEngine();
      final round1 = engine.generateRound(roundNumber: 1, level: 2.0);
      expect(round1.choices.length, 4);
      expect(round1.correctChoiceIndex, inInclusiveRange(0, 3));
      expect(round1.choices[round1.correctChoiceIndex].isTarget, true);
    });

    test('MemoryFocusEngine scales sequence length with level', () {
      final engine = MemoryFocusEngine();
      final roundLow = engine.generateRound(roundNumber: 1, level: 1.0);
      expect(roundLow.sequenceLength, 3);
      expect(roundLow.sequence.length, 3);

      final roundMid = engine.generateRound(roundNumber: 2, level: 4.0);
      expect(roundMid.sequenceLength, 4);

      final roundHigh = engine.generateRound(roundNumber: 3, level: 7.5);
      expect(roundHigh.sequenceLength, 6);
    });
  });
}
