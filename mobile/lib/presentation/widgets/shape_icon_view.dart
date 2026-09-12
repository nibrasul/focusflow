import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/game_stimulus.dart';

class ShapeIconView extends StatelessWidget {
  final GameStimulus stimulus;
  final double size;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool highlighted;

  const ShapeIconView({
    super.key,
    required this.stimulus,
    this.size = 56.0,
    this.onTap,
    this.showLabel = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;

    switch (stimulus.shape) {
      case TargetShape.circle:
        iconWidget = Container(
          width: size * 0.75,
          height: size * 0.75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stimulus.displayColor,
          ),
        );
        break;
      case TargetShape.square:
        iconWidget = Container(
          width: size * 0.72,
          height: size * 0.72,
          decoration: BoxDecoration(
            color: stimulus.displayColor,
            borderRadius: BorderRadius.circular(6),
          ),
        );
        break;
      case TargetShape.diamond:
        iconWidget = Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              color: stimulus.displayColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
        break;
      case TargetShape.triangle:
        iconWidget = CustomPaint(
          size: Size(size * 0.75, size * 0.75),
          painter: _TrianglePainter(color: stimulus.displayColor),
        );
        break;
      case TargetShape.star:
        iconWidget = Icon(
          Icons.star_rounded,
          size: size * 0.88,
          color: stimulus.displayColor,
        );
        break;
    }

    final box = Semantics(
      label: stimulus.accessibleLabel,
      button: onTap != null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted ? AppColors.primary : AppColors.border,
            width: highlighted ? 2.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: iconWidget),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: box,
      );
    }
    return box;
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
