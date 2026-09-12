import 'dart:math';
import '../models/game_stimulus.dart';

class MemoryFocusRound {
  final int roundNumber;
  final int sequenceLength;
  final List<GameStimulus> sequence;
  final List<GameStimulus> selectablePalette;

  MemoryFocusRound({
    required this.roundNumber,
    required this.sequenceLength,
    required this.sequence,
    required this.selectablePalette,
  });
}

class MemoryFocusEngine {
  final Random _random = Random();

  MemoryFocusRound generateRound({required int roundNumber, required double level}) {
    // Sequence length scales with difficulty level:
    // Level 1-2: 3 items, Level 3-4: 4 items, Level 5-6: 5 items, Level 7+: 6 items
    int length = 3;
    if (level >= 7.0) {
      length = 6;
    } else if (level >= 5.0) {
      length = 5;
    } else if (level >= 3.0) {
      length = 4;
    }

    final shapes = TargetShape.values;
    final colors = TargetColor.values;

    // Generate distinctive palette for this round (4 to 6 items)
    final List<GameStimulus> palette = [];
    final int paletteSize = min(6, length + 1);

    for (int i = 0; i < paletteSize; i++) {
      palette.add(GameStimulus(
        id: 'palette_$i',
        shape: shapes[i % shapes.length],
        color: colors[i % colors.length],
        accessibleLabel: '${colors[i % colors.length].name} ${shapes[i % shapes.length].name}',
      ));
    }

    // Pick sequence from the palette
    final List<GameStimulus> sequence = [];
    for (int i = 0; i < length; i++) {
      sequence.add(palette[_random.nextInt(palette.length)]);
    }

    return MemoryFocusRound(
      roundNumber: roundNumber,
      sequenceLength: length,
      sequence: sequence,
      selectablePalette: palette,
    );
  }
}
