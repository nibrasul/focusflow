import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/settings_service.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/sync_manager.dart';
import '../../core/storage/app_database.dart';
import '../widgets/light_card.dart';
import '../widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late SyncManager _syncManager;
  late ApiClient _apiClient;

  int _pendingSyncCount = 0;
  String _connectionStatus = 'Untested';
  bool _testingConnection = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.settings.baseUrl);
    _apiClient = ApiClient(widget.settings);
    _syncManager = SyncManager(_apiClient);
    _refreshPendingCount();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _refreshPendingCount() async {
    final db = await AppDatabase.instance;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    final count = (result.first['count'] as num?)?.toInt() ?? 0;
    if (mounted) {
      setState(() => _pendingSyncCount = count);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = 'Testing...';
    });

    // Temporarily save base URL
    widget.settings.baseUrl = _urlController.text.trim();
    final healthy = await _apiClient.checkHealth();

    if (mounted) {
      setState(() {
        _testingConnection = false;
        _connectionStatus = healthy ? 'Connected to FastAPI Backend' : 'Could not reach server';
      });
    }
  }

  Future<void> _triggerManualSync() async {
    setState(() => _syncing = true);
    final count = await _syncManager.syncPendingQueue();
    await _refreshPendingCount();

    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0 ? 'Synced $count sessions.' : 'No pending sessions to sync.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
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
            // Feedback & Accessibility
            Text('FEEDBACK & ACCESSIBILITY', style: AppTypography.caption),
            const SizedBox(height: 8),
            LightCard(
              backgroundColor: AppColors.surface,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sound Effects', style: AppTypography.body),
                    subtitle: const Text('Auditory cues during training', style: AppTypography.caption),
                    value: widget.settings.soundEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => widget.settings.soundEnabled = val);
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  SwitchListTile(
                    title: const Text('Haptic Feedback', style: AppTypography.body),
                    subtitle: const Text('Subtle touch feedback on hits and errors', style: AppTypography.caption),
                    value: widget.settings.hapticsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => widget.settings.hapticsEnabled = val);
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  SwitchListTile(
                    title: const Text('Reduce Motion', style: AppTypography.body),
                    subtitle: const Text('Minimizes background animations and transitions', style: AppTypography.caption),
                    value: widget.settings.reduceMotion,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => widget.settings.reduceMotion = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Backend & Synchronization
            Text('BACKEND & SYNC', style: AppTypography.caption),
            const SizedBox(height: 8),
            LightCard(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FastAPI Endpoint', style: AppTypography.headline),
                  const SizedBox(height: 4),
                  Text(
                    'Localhost (127.0.0.1:8000) or your Mac LAN IP for physical iPhone.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.secondarySurface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    style: AppTypography.footnote.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _connectionStatus,
                          style: AppTypography.caption.copyWith(
                            color: _connectionStatus.contains('Connected')
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _testingConnection ? null : _testConnection,
                        child: Text(_testingConnection ? 'Checking...' : 'Test Connection'),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Offline Sync Queue', style: AppTypography.subhead),
                          Text(
                            '$_pendingSyncCount pending upload',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      PrimaryButton(
                        label: 'Sync Now',
                        height: 38,
                        isLoading: _syncing,
                        isSecondary: true,
                        onPressed: _pendingSyncCount > 0 ? _triggerManualSync : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About & Transparency
            Text('ABOUT', style: AppTypography.caption),
            const SizedBox(height: 8),
            LightCard(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FocusFlow Attention Trainer', style: AppTypography.headline),
                  const SizedBox(height: 4),
                  const Text('Version 1.0.0 (Build 1)', style: AppTypography.footnote),
                  const SizedBox(height: 12),
                  Text(
                    'Attention and concentration training through interactive gameplay. Metrics represent actual in-game performance. Does not diagnose ADHD, cure attention disorders, or make unsupported clinical claims.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
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
}
