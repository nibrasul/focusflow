import 'dart:math';
import '../models/game_stimulus.dart';

enum RuleType {
  color,
  shape,
  negation, // "NOT red" or "NOT circle"
}

class RuleSwitchRound {
  final int roundNumber;
  final RuleType ruleType;
  final String ruleDescription;
  final String targetCriterion;
  final bool isSwitchTrial;
  final List<GameStimulus> choices;
  final int correctChoiceIndex;

  RuleSwitchRound({
    required this.roundNumber,
    required this.ruleType,
    required this.ruleDescription,
    required this.targetCriterion,
    required this.isSwitchTrial,
    required this.choices,
    required this.correctChoiceIndex,
  });
}

class RuleSwitchEngine {
  final Random _random = Random();
  RuleType _currentRule = RuleType.color;
  int _trialsUnderCurrentRule = 0;

  RuleSwitchRound generateRound({required int roundNumber, required double level}) {
    // Switch rule every 2 to 3 trials to measure task-switch cost
    final bool shouldSwitch = _trialsUnderCurrentRule >= 2 && (_random.nextBool() || _trialsUnderCurrentRule >= 3);
    final bool isSwitch = shouldSwitch || roundNumber == 1;

    if (isSwitch && roundNumber > 1) {
      final available = RuleType.values.where((r) => r != _currentRule).toList();
      // Only include negation rule at difficulty level >= 3.0
      if (level < 3.0) {
        available.remove(RuleType.negation);
      }
      _currentRule = available[_random.nextInt(available.length)];
      _trialsUnderCurrentRule = 1;
    } else {
      _trialsUnderCurrentRule++;
    }

    final shapes = TargetShape.values;
    final colors = TargetColor.values;

    String ruleDesc;
    String targetCriterion;
    int correctIndex = 0;
    List<GameStimulus> choices = [];

    if (_currentRule == RuleType.color) {
      final targetColor = colors[_random.nextInt(colors.length)];
      ruleDesc = 'RULE: MATCH COLOR';
      targetCriterion = 'Tap ${targetColor.name.toUpperCase()}';

      // 4 choices
      final targetShape = shapes[_random.nextInt(shapes.length)];
      final correctStim = GameStimulus(
        id: 'rs_${roundNumber}_0',
        shape: targetShape,
        color: targetColor,
        isTarget: true,
        accessibleLabel: '${targetColor.name} ${targetShape.name}',
      );

      choices.add(correctStim);

      // 3 wrong colors
      final wrongColors = colors.where((c) => c != targetColor).toList()..shuffle(_random);
      for (int i = 0; i < 3; i++) {
        choices.add(GameStimulus(
          id: 'rs_${roundNumber}_${i + 1}',
          shape: shapes[_random.nextInt(shapes.length)],
          color: wrongColors[i],
          isTarget: false,
          accessibleLabel: wrongColors[i].name,
        ));
      }
    } else if (_currentRule == RuleType.shape) {
      final targetShape = shapes[_random.nextInt(shapes.length)];
      ruleDesc = 'RULE: MATCH SHAPE';
      targetCriterion = 'Tap ${targetShape.name.toUpperCase()}';

      final targetColor = colors[_random.nextInt(colors.length)];
      final correctStim = GameStimulus(
        id: 'rs_${roundNumber}_0',
        shape: targetShape,
        color: targetColor,
        isTarget: true,
        accessibleLabel: '${targetColor.name} ${targetShape.name}',
      );

      choices.add(correctStim);

      // 3 wrong shapes
      final wrongShapes = shapes.where((s) => s != targetShape).toList()..shuffle(_random);
      for (int i = 0; i < 3; i++) {
        choices.add(GameStimulus(
          id: 'rs_${roundNumber}_${i + 1}',
          shape: wrongShapes[i],
          color: colors[_random.nextInt(colors.length)],
          isTarget: false,
          accessibleLabel: wrongShapes[i].name,
        ));
      }
    } else {
      // Negation rule (e.g. Tap anything EXCEPT RED)
      final forbiddenColor = colors[_random.nextInt(colors.length)];
      ruleDesc = 'RULE: INHIBITION';
      targetCriterion = 'Tap NOT ${forbiddenColor.name.toUpperCase()}';

      // 3 choices have the forbidden color, 1 does not (the correct one)
      final safeColor = colors.firstWhere((c) => c != forbiddenColor);
      final correctStim = GameStimulus(
        id: 'rs_${roundNumber}_0',
        shape: shapes[_random.nextInt(shapes.length)],
        color: safeColor,
        isTarget: true,
        accessibleLabel: safeColor.name,
      );
      choices.add(correctStim);

      for (int i = 0; i < 3; i++) {
        choices.add(GameStimulus(
          id: 'rs_${roundNumber}_${i + 1}',
          shape: shapes[_random.nextInt(shapes.length)],
          color: forbiddenColor,
          isTarget: false,
          accessibleLabel: forbiddenColor.name,
        ));
      }
    }

    choices.shuffle(_random);
    correctIndex = choices.indexWhere((c) => c.isTarget);

    return RuleSwitchRound(
      roundNumber: roundNumber,
      ruleType: _currentRule,
      ruleDescription: ruleDesc,
      targetCriterion: targetCriterion,
      isSwitchTrial: isSwitch,
      choices: choices,
      correctChoiceIndex: correctIndex,
    );
  }
}
