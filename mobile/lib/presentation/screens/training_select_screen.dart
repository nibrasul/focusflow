import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/settings_service.dart';
import '../widgets/light_card.dart';
import '../widgets/primary_button.dart';
import 'game_screen.dart';

class TrainingSelectScreen extends StatefulWidget {
  final SettingsService settings;
  final double initialLevel;

  const TrainingSelectScreen({
    super.key,
    required this.settings,
    this.initialLevel = 1.0,
  });

  @override
  State<TrainingSelectScreen> createState() => _TrainingSelectScreenState();
}

class _TrainingSelectScreenState extends State<TrainingSelectScreen> {
  late double _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Training Modes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            // Level Selector Header Card
            LightCard(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DIFFICULTY LEVEL', style: AppTypography.caption),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Level ${_selectedLevel.toStringAsFixed(1)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: _selectedLevel,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      label: _selectedLevel.toStringAsFixed(1),
                      onChanged: (val) => setState(() => _selectedLevel = val),
                    ),
                  ),
                  Text(
                    _getLevelSummary(_selectedLevel),
                    style: AppTypography.footnote.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('INDIVIDUAL EXERCISES', style: AppTypography.caption),
            const SizedBox(height: 12),

            // Mode 1: Selective Focus
            _ModeCard(
              title: 'Mode 1: Selective Focus',
              category: 'Visual Search & Filter',
              description: 'Locate specific target shapes rapidly amidst feature-overlapping distractors.',
              icon: Icons.filter_center_focus_rounded,
              accentColor: AppColors.primary,
              onStart: () => _launchGame('selective'),
            ),
            const SizedBox(height: 12),

            // Mode 2: Sustained Focus
            _ModeCard(
              title: 'Mode 2: Sustained Focus',
              category: 'Continuous Vigilance (CPT)',
              description: 'Maintain alertness over time. Tap only when designated target appears, inhibiting impulses.',
              icon: Icons.timelapse_rounded,
              accentColor: AppColors.targetGreen,
              onStart: () => _launchGame('sustained'),
            ),
            const SizedBox(height: 12),

            // Mode 3: Distraction Shield
            _ModeCard(
              title: 'Mode 3: Distraction Shield',
              category: 'Interference Resistance',
              description: 'Focus on your core target while filtering out peripheral motion and misleading banners.',
              icon: Icons.shield_outlined,
              accentColor: AppColors.warning,
              onStart: () => _launchGame('distraction_shield'),
            ),
            const SizedBox(height: 12),

            // Mode 4: Rule Switch
            _ModeCard(
              title: 'Mode 4: Rule Switch',
              category: 'Cognitive Flexibility',
              description: 'Adapt instantaneously when sorting rules switch between color, shape, and exclusion.',
              icon: Icons.swap_horiz_rounded,
              accentColor: AppColors.targetPurple,
              onStart: () => _launchGame('rule_switch'),
            ),
            const SizedBox(height: 12),

            // Mode 5: Memory Focus
            _ModeCard(
              title: 'Mode 5: Memory Focus',
              category: 'Working-Memory Span',
              description: 'Memorize sequences of visual stimuli and reproduce them in exact order.',
              icon: Icons.memory_rounded,
              accentColor: AppColors.targetBlue,
              onStart: () => _launchGame('memory'),
            ),
            const SizedBox(height: 16),

            // Daily Integrated Training
            LightCard(
              backgroundColor: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Focus Session',
                        style: AppTypography.headline.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Multi-stage workout chaining all 5 modes for a balanced daily cognitive training routine.',
                    style: AppTypography.callout.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Start Daily Focus',
                    icon: Icons.play_arrow_rounded,
                    height: 46,
                    onPressed: () => _launchGame('daily'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _launchGame(String mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameMode: mode,
          level: _selectedLevel,
          settings: widget.settings,
        ),
      ),
    );
  }

  String _getLevelSummary(double level) {
    if (level <= 2.0) return 'Introductory: Low distraction density, standard response window.';
    if (level <= 5.0) return 'Intermediate: Conjunction distractors, faster exposure pacing.';
    if (level <= 8.0) return 'Advanced: High visual noise, reduced response time, longer memory span.';
    return 'Master: Maximum interference density, rapid stimulus streaming.';
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onStart;

  const _ModeCard({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return LightCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headline.copyWith(fontSize: 16)),
                    Text(
                      category,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTypography.callout.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Start Exercise',
            icon: Icons.play_arrow_rounded,
            height: 44,
            isSecondary: true,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
