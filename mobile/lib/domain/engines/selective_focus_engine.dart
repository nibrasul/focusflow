import 'dart:math';
import '../models/game_stimulus.dart';

class SelectiveFocusRound {
  final int roundNumber;
  final GameStimulus target;
  final List<GameStimulus> items;
  final String instruction;

  SelectiveFocusRound({
    required this.roundNumber,
    required this.target,
    required this.items,
    required this.instruction,
  });
}

class SelectiveFocusEngine {
  final Random _random = Random();

  SelectiveFocusRound generateRound({required int roundNumber, required double level}) {
    // Determine grid size based on difficulty level (6 to 20 items)
    final int itemCount = min(20, max(6, (4 + (level * 1.6)).round()));

    final shapes = TargetShape.values;
    final colors = TargetColor.values;

    // Pick target
    final targetShape = shapes[_random.nextInt(shapes.length)];
    final targetColor = colors[_random.nextInt(colors.length)];

    final target = GameStimulus(
      id: 'target_$roundNumber',
      shape: targetShape,
      color: targetColor,
      isTarget: true,
      accessibleLabel: '${targetColor.name} ${targetShape.name}',
    );

    final List<GameStimulus> items = [target];

    // Generate distractors with partial feature overlap (conjunction search)
    for (int i = 1; i < itemCount; i++) {
      TargetShape distractorShape;
      TargetColor distractorColor;

      // Higher difficulty introduces shared features
      final bool shareShape = _random.nextBool() && level >= 2.5;
      final bool shareColor = _random.nextBool() && level >= 3.5;

      if (shareShape) {
        distractorShape = targetShape;
        distractorColor = colors[(_random.nextInt(colors.length - 1) + colors.indexOf(targetColor) + 1) % colors.length];
      } else if (shareColor) {
        distractorColor = targetColor;
        distractorShape = shapes[(_random.nextInt(shapes.length - 1) + shapes.indexOf(targetShape) + 1) % shapes.length];
      } else {
        distractorShape = shapes[_random.nextInt(shapes.length)];
        distractorColor = colors[_random.nextInt(colors.length)];
        if (distractorShape == targetShape && distractorColor == targetColor) {
          distractorColor = colors[(colors.indexOf(targetColor) + 1) % colors.length];
        }
      }

      items.add(GameStimulus(
        id: 'distractor_${roundNumber}_$i',
        shape: distractorShape,
        color: distractorColor,
        isTarget: false,
        accessibleLabel: '${distractorColor.name} ${distractorShape.name}',
      ));
    }

    // Shuffle item positions
    items.shuffle(_random);

    return SelectiveFocusRound(
      roundNumber: roundNumber,
      target: target,
      items: items,
      instruction: 'Find & tap ${target.colorName} ${target.shapeName}',
    );
  }
}
