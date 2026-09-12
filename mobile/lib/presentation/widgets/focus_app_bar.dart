import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class FocusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onPause;
  final int? score;
  final int? streak;

  const FocusAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onPause,
    this.score,
    this.streak,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else if (onPause != null)
              IconButton(
                icon: const Icon(Icons.pause_circle_outline_rounded, size: 24, color: AppColors.textPrimary),
                onPressed: onPause,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.headline.copyWith(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (streak != null && streak! > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '$streak',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (score != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score pts',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
