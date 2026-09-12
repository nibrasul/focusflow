import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/settings_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/light_card.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final SettingsService settings;

  const OnboardingScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 24),
              const Text(
                'Train Your\nConcentration.',
                style: AppTypography.largeTitle,
              ),
              const SizedBox(height: 12),
              Text(
                'Science-inspired cognitive exercises to build selective focus, sustained attention, and distraction resistance.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _FeatureTile(
                      icon: Icons.filter_center_focus_rounded,
                      title: '5 Core Training Modes',
                      subtitle: 'Selective search, sustained vigilance, distraction shield, rule switching, and working memory.',
                    ),
                    SizedBox(height: 16),
                    _FeatureTile(
                      icon: Icons.timer_outlined,
                      title: 'Precision RT Tracking',
                      subtitle: 'Sub-millisecond reaction time measurement from stimulus rendering to actual touch.',
                    ),
                    SizedBox(height: 16),
                    _FeatureTile(
                      icon: Icons.auto_graph_rounded,
                      title: 'Adaptive Difficulty',
                      subtitle: 'Challenges scale smoothly based on your real performance and focus consistency.',
                    ),
                    SizedBox(height: 16),
                    _FeatureTile(
                      icon: Icons.cloud_off_rounded,
                      title: 'Local-First Resilience',
                      subtitle: 'Play seamlessly offline. Results securely queue and synchronize when reconnected.',
                    ),
                  ],
                ),
              ),
              LightCard(
                backgroundColor: AppColors.secondarySurface,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention and concentration training through interactive gameplay. Not intended as a medical diagnostic tool or clinical treatment.',
                        style: AppTypography.footnote.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Get Started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  settings.onboardingCompleted = true;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(settings: settings),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.headline.copyWith(fontSize: 16)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTypography.callout.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
