import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/settings_service.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/achievement_record.dart';
import '../widgets/light_card.dart';

class AchievementsScreen extends StatefulWidget {
  final SettingsService settings;

  const AchievementsScreen({super.key, required this.settings});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late ApiClient _apiClient;
  bool _loading = true;
  List<AchievementRecord> _achievements = [];

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(widget.settings);
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _loading = true);
    final res = await _apiClient.getAchievements();
    if (res.isSuccess && res.data != null) {
      _achievements = (res.data as List<dynamic>)
          .map((item) => AchievementRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Offline fallback: display initial achievements list
      _achievements = [
        AchievementRecord(
          id: 'first_focus',
          title: 'First Step',
          description: 'Completed your first attention training session.',
          iconName: 'flag',
          category: 'milestone',
          xpReward: 50,
          unlocked: false,
        ),
        AchievementRecord(
          id: 'five_sessions',
          title: 'Habit Former',
          description: 'Completed 5 training sessions.',
          iconName: 'award',
          category: 'milestone',
          xpReward: 100,
          unlocked: false,
        ),
        AchievementRecord(
          id: 'ten_sessions',
          title: 'Dedicated Mind',
          description: 'Completed 10 training sessions.',
          iconName: 'trophy',
          category: 'milestone',
          xpReward: 200,
          unlocked: false,
        ),
        AchievementRecord(
          id: 'distraction_master',
          title: 'Distraction Shield Master',
          description: 'Finished Distraction Shield with zero distraction errors.',
          iconName: 'shield',
          category: 'mastery',
          xpReward: 150,
          unlocked: false,
        ),
        AchievementRecord(
          id: 'swift_reflex',
          title: 'Swift Reflexes',
          description: 'Maintained an average reaction time under 400ms.',
          iconName: 'bolt',
          category: 'reflex',
          xpReward: 150,
          unlocked: false,
        ),
      ];
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int unlockedCount = _achievements.where((a) => a.unlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAchievements,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Summary Banner
                  LightCard(
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cognitive Milestones', style: AppTypography.headline.copyWith(fontSize: 16)),
                              Text(
                                '$unlockedCount of ${_achievements.length} Unlocked',
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._achievements.map((ach) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: LightCard(
                        backgroundColor: ach.unlocked ? AppColors.surface : AppColors.secondarySurface,
                        border: Border.all(
                          color: ach.unlocked ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ach.unlocked ? AppColors.primaryLight : AppColors.border,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                ach.unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                                color: ach.unlocked ? AppColors.primary : AppColors.textMuted,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        ach.title,
                                        style: AppTypography.headline.copyWith(
                                          fontSize: 15,
                                          color: ach.unlocked ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.successLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '+${ach.xpReward} XP',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ach.description,
                                    style: AppTypography.callout.copyWith(
                                      fontSize: 13,
                                      color: ach.unlocked ? AppColors.textSecondary : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
