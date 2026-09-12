import 'dart:math';
import '../models/game_stimulus.dart';

class SustainedStimulus {
  final GameStimulus stimulus;
  final bool isTarget;
  final int durationMs;
  final int isiMs; // Inter-stimulus interval

  SustainedStimulus({
    required this.stimulus,
    required this.isTarget,
    required this.durationMs,
    required this.isiMs,
  });
}

class SustainedFocusEngine {
  final Random _random = Random();
  final TargetShape targetShape = TargetShape.star;
  final TargetColor targetColor = TargetColor.blue;

  List<SustainedStimulus> generateSequence({required int totalTrials, required double level}) {
    // Target probability ~ 30% to require sustained vigilant inhibition
    final double targetProb = 0.30;
    
    // Exposure duration shrinks with level (1400ms down to 750ms)
    final int baseDuration = max(750, (1400 - (level * 65)).round());
    
    final List<SustainedStimulus> trials = [];

    for (int i = 0; i < totalTrials; i++) {
      final bool isTarget = _random.nextDouble() < targetProb;
      GameStimulus stim;

      if (isTarget) {
        stim = GameStimulus(
          id: 'sustained_target_$i',
          shape: targetShape,
          color: targetColor,
          isTarget: true,
          accessibleLabel: '${targetColor.name} ${targetShape.name}',
        );
      } else {
        // Non-target distractor
        TargetShape s = TargetShape.values[_random.nextInt(TargetShape.values.length)];
        TargetColor c = TargetColor.values[_random.nextInt(TargetColor.values.length)];
        if (s == targetShape && c == targetColor) {
          s = TargetShape.triangle;
        }
        stim = GameStimulus(
          id: 'sustained_nontarget_$i',
          shape: s,
          color: c,
          isTarget: false,
          accessibleLabel: '${c.name} ${s.name}',
        );
      }

      // Jittered ISI (600ms - 1100ms) creates temporal unpredictability
      final int isi = 600 + _random.nextInt(500);

      trials.add(SustainedStimulus(
        stimulus: stim,
        isTarget: isTarget,
        durationMs: baseDuration,
        isiMs: isi,
      ));
    }

    return trials;
  }
}
