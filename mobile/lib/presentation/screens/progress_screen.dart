import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/settings_service.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/sync_manager.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/profile_record.dart';
import '../widgets/light_card.dart';

class ProgressScreen extends StatefulWidget {
  final SettingsService settings;

  const ProgressScreen({super.key, required this.settings});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late SyncManager _syncManager;
  late ApiClient _apiClient;

  bool _loading = true;
  ProfileRecord? _profile;
  List<SessionRecord> _sessions = [];
  List<dynamic> _serverTrends = [];

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(widget.settings);
    _syncManager = SyncManager(_apiClient);
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() => _loading = true);

    // 1. Fetch local data from SQLite
    _profile = await _syncManager.getLocalProfile();
    _sessions = await _syncManager.getLocalSessions(limit: 30);

    // 2. Fetch server trends if available
    final dashboardRes = await _apiClient.getDashboard();
    if (dashboardRes.isSuccess && dashboardRes.data != null) {
      _serverTrends = dashboardRes.data!['weekly_accuracy_trend'] as List<dynamic>? ?? [];
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Focus Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadProgressData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Overview Stats Header
                  _buildOverviewStats(),
                  const SizedBox(height: 20),

                  // Accuracy Trend Section
                  Text('7-DAY ACCURACY TREND', style: AppTypography.caption),
                  const SizedBox(height: 8),
                  _buildAccuracyTrendCard(),
                  const SizedBox(height: 20),

                  // Reaction Time Consistency
                  Text('REACTION TIME TREND', style: AppTypography.caption),
                  const SizedBox(height: 8),
                  _buildReactionTimeCard(),
                  const SizedBox(height: 20),

                  // Completed Sessions History
                  Text('RECENT SESSIONS', style: AppTypography.caption),
                  const SizedBox(height: 8),
                  _buildSessionsHistory(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewStats() {
    final int totalSessions = _profile?.totalSessions ?? _sessions.length;
    final double overallAcc = _profile?.overallAccuracy ??
        (_sessions.isNotEmpty
            ? (_sessions.map((s) => s.accuracy).reduce((a, b) => a + b) / _sessions.length * 10).round() / 10.0
            : 0.0);
    final double avgRt = _profile?.averageReactionTime ??
        (_sessions.isNotEmpty
            ? (_sessions.map((s) => s.averageReactionTime).reduce((a, b) => a + b) / _sessions.length * 10).round() / 10.0
            : 0.0);

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Sessions',
            value: '$totalSessions',
            icon: Icons.fitness_center_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Overall Acc',
            value: overallAcc > 0 ? '${overallAcc.toStringAsFixed(1)}%' : '--',
            icon: Icons.track_changes_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Avg RT',
            value: avgRt > 0 ? '${avgRt.toStringAsFixed(0)} ms' : '--',
            icon: Icons.speed_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyTrendCard() {
    // Check if we have real historical data points
    final List<FlSpot> spots = [];
    final List<String> labels = [];

    if (_serverTrends.isNotEmpty) {
      for (int i = 0; i < _serverTrends.length; i++) {
        final t = _serverTrends[i];
        final acc = t['accuracy'];
        labels.add(t['day_label'] as String? ?? '');
        if (acc != null) {
          spots.add(FlSpot(i.toDouble(), (acc as num).toDouble()));
        }
      }
    } else if (_sessions.isNotEmpty) {
      final recent = _sessions.take(7).toList().reversed.toList();
      for (int i = 0; i < recent.length; i++) {
        spots.add(FlSpot(i.toDouble(), recent[i].accuracy));
        labels.add('S${i + 1}');
      }
    }

    if (spots.length < 2) {
      return LightCard(
        backgroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.show_chart_rounded, size: 36, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'Complete more sessions to unlock your progress trend.',
                style: AppTypography.callout,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Requires at least 2 completed sessions.',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return LightCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 25,
                  getTitlesWidget: (val, meta) => Text(
                    '${val.toInt()}%',
                    style: AppTypography.caption.copyWith(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < labels.length) {
                      return Text(labels[idx], style: AppTypography.caption.copyWith(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionTimeCard() {
    if (_sessions.length < 2) {
      return LightCard(
        backgroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.speed_rounded, size: 36, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'Reaction time trends will appear here.',
                style: AppTypography.callout,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Complete more sessions to analyze your cognitive speed.',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final recent = _sessions.take(6).toList().reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < recent.length; i++) {
      spots.add(FlSpot(i.toDouble(), recent[i].averageReactionTime));
    }

    return LightCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (val, meta) => Text(
                    '${val.toInt()}ms',
                    style: AppTypography.caption.copyWith(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (val, meta) => Text(
                    'S${val.toInt() + 1}',
                    style: AppTypography.caption.copyWith(fontSize: 10),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.targetGreen,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.targetGreen.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsHistory() {
    if (_sessions.isEmpty) {
      return LightCard(
        backgroundColor: AppColors.surface,
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'No completed sessions yet. Start your first exercise!',
            style: AppTypography.callout,
          ),
        ),
      );
    }

    return Column(
      children: _sessions.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: LightCard(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.gameMode.toUpperCase().replaceAll('_', ' '),
                        style: AppTypography.headline.copyWith(fontSize: 14),
                      ),
                      Text(
                        '${s.accuracy.toStringAsFixed(0)}% acc • ${s.averageReactionTime.toStringAsFixed(0)}ms • Lvl ${s.level.toStringAsFixed(1)}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${s.score} pts',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LightCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
