import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/settings_service.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/sync_manager.dart';
import '../../domain/models/profile_record.dart';
import '../widgets/light_card.dart';
import '../widgets/primary_button.dart';
import 'game_screen.dart';
import 'training_select_screen.dart';
import 'progress_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final SettingsService settings;

  const DashboardScreen({super.key, required this.settings});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ApiClient _apiClient;
  late SyncManager _syncManager;

  bool _loading = true;
  ProfileRecord? _profile;
  String _recommendedMode = 'selective';
  double _recommendedLevel = 1.0;
  bool _dailyCompleted = false;
  int _unlockedAchievementsCount = 0;
  int _totalAchievementsCount = 7;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(widget.settings);
    _syncManager = SyncManager(_apiClient);
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);

    // 1. Try local SQLite profile first
    _profile = await _syncManager.getLocalProfile();

    // 2. Fetch server dashboard
    final res = await _apiClient.getDashboard();
    if (res.isSuccess && res.data != null) {
      final data = res.data!;
      final profJson = data['profile'] as Map<String, dynamic>;
      _profile = ProfileRecord.fromJson(profJson);
      _recommendedMode = data['recommended_mode'] as String? ?? 'selective';
      _recommendedLevel = (data['recommended_level'] as num?)?.toDouble() ?? 1.0;
      _dailyCompleted = data['daily_completed'] as bool? ?? false;
      _unlockedAchievementsCount = data['unlocked_achievements_count'] as int? ?? 0;
      _totalAchievementsCount = data['total_achievements_count'] as int? ?? 7;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading && _profile == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Header with Avatar and Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: AppTypography.callout.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              _profile?.displayName ?? 'Focus Athlete',
                              style: AppTypography.title1,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SettingsScreen(settings: widget.settings),
                                  ),
                                );
                                _loadDashboard();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Level & Streak Bar
                    _buildProfileSummaryCard(),
                    const SizedBox(height: 16),

                    // Daily Training Card (Hero)
                    _buildDailyTrainingHero(),
                    const SizedBox(height: 24),

                    // Training Modes Header & "See All"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TRAINING MODES', style: AppTypography.caption),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TrainingSelectScreen(
                                  settings: widget.settings,
                                  initialLevel: _recommendedLevel,
                                ),
                              ),
                            );
                            _loadDashboard();
                          },
                          child: Text(
                            'View All (5)',
                            style: AppTypography.footnote.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Mode Carousel / Tiles
                    _buildQuickModesGrid(),
                    const SizedBox(height: 24),

                    // Navigation to Progress and Achievements
                    Row(
                      children: [
                        Expanded(
                          child: LightCard(
                            backgroundColor: AppColors.surface,
                            padding: const EdgeInsets.all(16),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProgressScreen(settings: widget.settings),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.insights_rounded, color: AppColors.primary, size: 24),
                                const SizedBox(height: 8),
                                const Text('Progress', style: AppTypography.headline),
                                const SizedBox(height: 2),
                                Text('Charts & trends', style: AppTypography.caption),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LightCard(
                            backgroundColor: AppColors.surface,
                            padding: const EdgeInsets.all(16),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AchievementsScreen(settings: widget.settings),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.military_tech_rounded, color: AppColors.warning, size: 24),
                                const SizedBox(height: 8),
                                const Text('Milestones', style: AppTypography.headline),
                                const SizedBox(height: 2),
                                Text('$_unlockedAchievementsCount/$_totalAchievementsCount unlocked', style: AppTypography.caption),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    final int level = _profile?.currentLevel ?? 1;
    final int xp = _profile?.totalXp ?? 0;
    final int streak = _profile?.currentStreak ?? 0;
    final int xpInLevel = xp % 500;
    final double xpProgress = xpInLevel / 500.0;

    return LightCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Level $level',
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$xp XP Total', style: AppTypography.caption),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$streak day streak',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${500 - xpInLevel} XP to Level ${level + 1}', style: AppTypography.caption),
              Text('${(xpProgress * 100).toInt()}%', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrainingHero() {
    return LightCard(
      backgroundColor: AppColors.surface,
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _dailyCompleted ? AppColors.successLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _dailyCompleted ? 'COMPLETED TODAY' : "TODAY'S TRAINING",
                  style: AppTypography.caption.copyWith(
                    color: _dailyCompleted ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              Text('5 Modes Integrated', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Daily Focus Workout', style: AppTypography.title2),
          const SizedBox(height: 4),
          Text(
            'A structured 10-round cognitive routine combining selective, sustained, distraction resistance, rule switching, and memory recall.',
            style: AppTypography.callout.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _dailyCompleted ? 'Train Again' : 'Start Daily Focus',
            icon: Icons.play_arrow_rounded,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    gameMode: 'daily',
                    level: _recommendedLevel,
                    settings: widget.settings,
                  ),
                ),
              );
              _loadDashboard();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickModesGrid() {
    return Column(
      children: [
        _QuickModeTile(
          title: 'Selective Focus',
          subtitle: 'Locate targets amidst visual distractors',
          icon: Icons.filter_center_focus_rounded,
          color: AppColors.primary,
          isRecommended: _recommendedMode == 'selective',
          onTap: () => _launchMode('selective'),
        ),
        const SizedBox(height: 8),
        _QuickModeTile(
          title: 'Sustained Focus',
          subtitle: 'Go/No-Go vigilance stream',
          icon: Icons.timelapse_rounded,
          color: AppColors.targetGreen,
          isRecommended: _recommendedMode == 'sustained',
          onTap: () => _launchMode('sustained'),
        ),
        const SizedBox(height: 8),
        _QuickModeTile(
          title: 'Distraction Shield',
          subtitle: 'Resist visual motion & fake instructions',
          icon: Icons.shield_outlined,
          color: AppColors.warning,
          isRecommended: _recommendedMode == 'distraction_shield',
          onTap: () => _launchMode('distraction_shield'),
        ),
        const SizedBox(height: 8),
        _QuickModeTile(
          title: 'Rule Switch',
          subtitle: 'Cognitive task-switching flexibility',
          icon: Icons.swap_horiz_rounded,
          color: AppColors.targetPurple,
          isRecommended: _recommendedMode == 'rule_switch',
          onTap: () => _launchMode('rule_switch'),
        ),
        const SizedBox(height: 8),
        _QuickModeTile(
          title: 'Memory Focus',
          subtitle: 'Working memory sequence recall',
          icon: Icons.memory_rounded,
          color: AppColors.targetBlue,
          isRecommended: _recommendedMode == 'memory',
          onTap: () => _launchMode('memory'),
        ),
      ],
    );
  }

  void _launchMode(String mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameMode: mode,
          level: _recommendedLevel,
          settings: widget.settings,
        ),
      ),
    );
    _loadDashboard();
  }
}

class _QuickModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isRecommended;
  final VoidCallback onTap;

  const _QuickModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LightCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTypography.headline.copyWith(fontSize: 15)),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ADAPTIVE REC',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
