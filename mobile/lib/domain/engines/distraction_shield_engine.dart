import 'dart:math';
import '../models/game_stimulus.dart';

class DistractionItem {
  final String id;
  final GameStimulus stimulus;
  final double initialX; // 0.0 to 1.0
  final double initialY; // 0.0 to 1.0
  final double speedX;
  final double speedY;

  DistractionItem({
    required this.id,
    required this.stimulus,
    required this.initialX,
    required this.initialY,
    required this.speedX,
    required this.speedY,
  });
}

class DistractionShieldRound {
  final int roundNumber;
  final GameStimulus target;
  final List<GameStimulus> fieldItems;
  final List<DistractionItem> floatingDistractions;
  final String fakeInstruction;
  final String realInstruction;

  DistractionShieldRound({
    required this.roundNumber,
    required this.target,
    required this.fieldItems,
    required this.floatingDistractions,
    required this.fakeInstruction,
    required this.realInstruction,
  });
}

class DistractionShieldEngine {
  final Random _random = Random();

  static const List<String> fakeAlerts = [
    'ALERT: TAP THE RED CIRCLE!',
    'OVERRIDE: SWITCH TO BLUE!',
    'ATTENTION: TAP FLASHING OBJECT!',
    'NEW RULE: IGNORE SQUARES!',
    'SYSTEM PROMPT: TAP YELLOW!',
  ];

  DistractionShieldRound generateRound({required int roundNumber, required double level}) {
    final shapes = TargetShape.values;
    final colors = TargetColor.values;

    final targetShape = shapes[_random.nextInt(shapes.length)];
    final targetColor = colors[_random.nextInt(colors.length)];

    final target = GameStimulus(
      id: 'target_$roundNumber',
      shape: targetShape,
      color: targetColor,
      isTarget: true,
      accessibleLabel: '${targetColor.name} ${targetShape.name}',
    );

    // 8 to 16 stationary field items
    final int fieldCount = min(16, max(8, (6 + (level * 1.2)).round()));
    final List<GameStimulus> fieldItems = [target];

    for (int i = 1; i < fieldCount; i++) {
      TargetShape s = shapes[_random.nextInt(shapes.length)];
      TargetColor c = colors[_random.nextInt(colors.length)];
      if (s == targetShape && c == targetColor) {
        c = colors[(colors.indexOf(targetColor) + 1) % colors.length];
      }
      fieldItems.add(GameStimulus(
        id: 'distractor_${roundNumber}_$i',
        shape: s,
        color: c,
        isTarget: false,
        accessibleLabel: '${c.name} ${s.name}',
      ));
    }
    fieldItems.shuffle(_random);

    // Floating distractions (2 to 6 floating objects drifting across screen)
    final int floatingCount = min(6, max(2, (1 + (level * 0.6)).round()));
    final List<DistractionItem> floatingItems = [];
    for (int i = 0; i < floatingCount; i++) {
      final s = shapes[_random.nextInt(shapes.length)];
      final c = colors[_random.nextInt(colors.length)];
      floatingItems.add(DistractionItem(
        id: 'float_${roundNumber}_$i',
        stimulus: GameStimulus(
          id: 'float_stim_${roundNumber}_$i',
          shape: s,
          color: c,
          isTarget: false,
          accessibleLabel: 'Floating ${c.name} ${s.name}',
        ),
        initialX: _random.nextDouble(),
        initialY: _random.nextDouble(),
        speedX: (_random.nextDouble() * 0.4 - 0.2),
        speedY: (_random.nextDouble() * 0.4 - 0.2),
      ));
    }

    final fakeAlert = fakeAlerts[_random.nextInt(fakeAlerts.length)];

    return DistractionShieldRound(
      roundNumber: roundNumber,
      target: target,
      fieldItems: fieldItems,
      floatingDistractions: floatingItems,
      fakeInstruction: fakeAlert,
      realInstruction: 'REAL TARGET: ${target.colorName} ${target.shapeName}',
    );
  }
}
