import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSecondary;
  final bool isLoading;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isSecondary = false,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null || widget.isLoading;

    Color bg;
    Color fg;

    if (widget.isSecondary) {
      bg = widget.backgroundColor ?? AppColors.secondarySurface;
      fg = widget.textColor ?? AppColors.textPrimary;
    } else {
      bg = widget.backgroundColor ?? AppColors.primary;
      fg = widget.textColor ?? Colors.white;
    }

    if (disabled) {
      bg = AppColors.border;
      fg = AppColors.textMuted;
    }

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _controller.forward(),
      onTapUp: disabled
          ? null
          : (_) {
              _controller.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: disabled ? null : () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: widget.isSecondary ? Border.all(color: AppColors.border) : null,
            boxShadow: widget.isSecondary || disabled
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x26007AFF),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTypography.headline.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
