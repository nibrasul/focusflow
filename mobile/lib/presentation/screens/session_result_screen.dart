import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/settings_service.dart';
import '../../core/storage/sync_manager.dart';
import '../../domain/models/session_record.dart';
import '../widgets/light_card.dart';
import '../widgets/primary_button.dart';
import 'game_screen.dart';

class SessionResultScreen extends StatelessWidget {
  final SessionRecord session;
  final SyncResult syncResult;
  final SettingsService settings;

  const SessionResultScreen({
    super.key,
    required this.session,
    required this.syncResult,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    // If server provided authoritative calculations, display them; otherwise display local calculation
    final serverData = syncResult.serverResponse;
    final int displayScore = serverData != null ? (serverData['score'] as int? ?? session.score) : session.score;
    final double displayAccuracy = serverData != null
        ? (serverData['accuracy'] as num?)?.toDouble() ?? session.accuracy
        : session.accuracy;
    final double displayRt = serverData != null
        ? (serverData['average_reaction_time'] as num?)?.toDouble() ?? session.averageReactionTime
        : session.averageReactionTime;
    final int xpEarned = serverData != null ? (serverData['xp_earned'] as int? ?? 0) : (session.score * 0.1).floor();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Session Complete', style: AppTypography.title1),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: syncResult.synced ? AppColors.successLight : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: syncResult.synced ? AppColors.success : AppColors.warning,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          syncResult.synced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          size: 14,
                          color: syncResult.synced ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          syncResult.synced ? 'Synced' : 'Local Queue',
                          style: AppTypography.caption.copyWith(
                            color: syncResult.synced ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getModeDisplayName(session.gameMode),
                style: AppTypography.callout.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Main Score Card
              LightCard(
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('TOTAL SCORE', style: AppTypography.caption),
                    const SizedBox(height: 6),
                    Text(
                      '$displayScore',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    if (xpEarned > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+$xpEarned XP earned',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metrics Grid
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Accuracy',
                            value: '${displayAccuracy.toStringAsFixed(1)}%',
                            icon: Icons.track_changes_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'Avg Reaction',
                            value: '${displayRt.toStringAsFixed(0)} ms',
                            icon: Icons.speed_rounded,
                            color: AppColors.targetGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Focus Streak',
                            value: '${session.longestStreak}',
                            icon: Icons.local_fire_department_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'Distraction Errors',
                            value: '${session.distractionErrors}',
                            icon: Icons.shield_outlined,
                            color: session.distractionErrors == 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Difficulty Level',
                            value: session.level.toStringAsFixed(1),
                            icon: Icons.tune_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'Duration',
                            value: '${session.duration}s',
                            icon: Icons.timer_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LightCard(
                      backgroundColor: AppColors.secondarySurface,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              syncResult.message ?? 'Performance logged to session history.',
                              style: AppTypography.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Train Again',
                      icon: Icons.replay_rounded,
                      isSecondary: true,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(
                              gameMode: session.gameMode,
                              level: session.level,
                              settings: settings,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Dashboard',
                      icon: Icons.done_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'selective':
        return 'Selective Focus Training';
      case 'sustained':
        return 'Sustained Vigilance Training';
      case 'distraction_shield':
        return 'Distraction Resistance Training';
      case 'rule_switch':
        return 'Cognitive Rule Switching';
      case 'memory':
        return 'Working Memory Span Training';
      case 'daily':
        return 'Daily Integrated Focus Session';
      default:
        return 'Attention Training';
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LightCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.title2.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
