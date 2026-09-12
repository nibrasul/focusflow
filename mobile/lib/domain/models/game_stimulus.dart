import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TargetShape {
  circle,
  triangle,
  square,
  diamond,
  star,
}

enum TargetColor {
  blue,
  red,
  green,
  yellow,
  purple,
  orange,
}

class GameStimulus {
  final String id;
  final TargetShape shape;
  final TargetColor color;
  final double size;
  final bool isTarget;
  final String accessibleLabel;

  const GameStimulus({
    required this.id,
    required this.shape,
    required this.color,
    this.size = 56.0,
    this.isTarget = false,
    required this.accessibleLabel,
  });

  Color get displayColor {
    switch (color) {
      case TargetColor.blue:
        return AppColors.targetBlue;
      case TargetColor.red:
        return AppColors.targetRed;
      case TargetColor.green:
        return AppColors.targetGreen;
      case TargetColor.yellow:
        return AppColors.targetYellow;
      case TargetColor.purple:
        return AppColors.targetPurple;
      case TargetColor.orange:
        return AppColors.targetOrange;
    }
  }

  IconData get iconData {
    switch (shape) {
      case TargetShape.circle:
        return Icons.circle;
      case TargetShape.triangle:
        return Icons.change_history; // Triangle outline or shape
      case TargetShape.square:
        return Icons.square;
      case TargetShape.diamond:
        return Icons.diamond;
      case TargetShape.star:
        return Icons.star;
    }
  }

  String get shapeName => shape.name.toUpperCase();
  String get colorName => color.name.toUpperCase();
}
