import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/haptics_service.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/sync_manager.dart';

import '../../domain/models/game_stimulus.dart';
import '../../domain/models/attempt_record.dart';
import '../../domain/models/session_record.dart';

import '../../domain/engines/local_scoring.dart';
import '../../domain/engines/selective_focus_engine.dart';
import '../../domain/engines/sustained_focus_engine.dart';
import '../../domain/engines/distraction_shield_engine.dart';
import '../../domain/engines/rule_switch_engine.dart';
import '../../domain/engines/memory_focus_engine.dart';

import '../widgets/light_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/shape_icon_view.dart';
import '../widgets/focus_app_bar.dart';
import 'session_result_screen.dart';

enum GamePhase {
  instruction,
  countdown,
  playing,
  paused,
  feedback,
  completed,
}

class GameScreen extends StatefulWidget {
  final String gameMode; // selective, sustained, distraction_shield, rule_switch, memory, daily
  final double level;
  final SettingsService settings;

  const GameScreen({
    super.key,
    required this.gameMode,
    this.level = 1.0,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late HapticsService _haptics;
  late SyncManager _syncManager;

  GamePhase _phase = GamePhase.instruction;
  int _countdownValue = 3;
  Timer? _countdownTimer;

  // Session state
  late String _sessionId;
  late DateTime _startedAt;
  final List<AttemptRecord> _attempts = [];
  int _currentScore = 0;
  int _currentStreak = 0;

  // Stopwatch for precision RT measurement
  final Stopwatch _reactionStopwatch = Stopwatch();
  final Stopwatch _sessionStopwatch = Stopwatch();

  // Mode Engines
  final SelectiveFocusEngine _selectiveEngine = SelectiveFocusEngine();
  final SustainedFocusEngine _sustainedEngine = SustainedFocusEngine();
  final DistractionShieldEngine _distractionEngine = DistractionShieldEngine();
  final RuleSwitchEngine _ruleSwitchEngine = RuleSwitchEngine();
  final MemoryFocusEngine _memoryEngine = MemoryFocusEngine();

  // Round tracking
  int _currentRound = 1;
  final int _maxRounds = 10;
  String _activeInstruction = '';

  // Mode 1: Selective Focus state
  SelectiveFocusRound? _selectiveRound;

  // Mode 2: Sustained Focus state
  List<SustainedStimulus> _sustainedSequence = [];
  int _sustainedIndex = 0;
  Timer? _sustainedExposureTimer;
  Timer? _sustainedIsiTimer;
  bool _sustainedWaitingForResponse = false;
  SustainedStimulus? _currentSustainedStim;

  // Mode 3: Distraction Shield state
  DistractionShieldRound? _distractionRound;
  late AnimationController _floatingController;

  // Mode 4: Rule Switch state
  RuleSwitchRound? _ruleSwitchRound;

  // Mode 5: Memory Focus state
  MemoryFocusRound? _memoryRound;
  bool _memoryShowingSequence = true;
  int _memoryPresentIndex = 0;
  Timer? _memoryPresentationTimer;
  final List<GameStimulus> _playerMemoryInput = [];

  // Feedback banner state
  bool? _lastAttemptCorrect;
  String _feedbackMessage = '';

  @override
  void initState() {
    super.initState();
    _haptics = HapticsService(widget.settings);
    _syncManager = SyncManager(ApiClient(widget.settings));
    _sessionId = const Uuid().v4();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sustainedExposureTimer?.cancel();
    _sustainedIsiTimer?.cancel();
    _memoryPresentationTimer?.cancel();
    _floatingController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _phase = GamePhase.countdown;
      _countdownValue = 3;
    });

    _haptics.selection();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
        _haptics.selection();
      } else {
        timer.cancel();
        _beginGameplay();
      }
    });
  }

  void _beginGameplay() {
    _startedAt = DateTime.now();
    _sessionStopwatch.reset();
    _sessionStopwatch.start();

    setState(() {
      _phase = GamePhase.playing;
      _currentRound = 1;
    });

    _loadCurrentRound();
  }

  void _loadCurrentRound() {
    final mode = _getEffectiveModeForRound(_currentRound);

    if (mode == 'selective') {
      _selectiveRound = _selectiveEngine.generateRound(
        roundNumber: _currentRound,
        level: widget.level,
      );
      _activeInstruction = _selectiveRound!.instruction;
      _startReactionTimer();
    } else if (mode == 'sustained') {
      _sustainedSequence = _sustainedEngine.generateSequence(
        totalTrials: _maxRounds,
        level: widget.level,
      );
      _sustainedIndex = 0;
      _activeInstruction = 'Tap TRIGGER only when STAR appears!';
      _startSustainedTrial();
    } else if (mode == 'distraction_shield') {
      _distractionRound = _distractionEngine.generateRound(
        roundNumber: _currentRound,
        level: widget.level,
      );
      _activeInstruction = _distractionRound!.realInstruction;
      _startReactionTimer();
    } else if (mode == 'rule_switch') {
      _ruleSwitchRound = _ruleSwitchEngine.generateRound(
        roundNumber: _currentRound,
        level: widget.level,
      );
      _activeInstruction = '${_ruleSwitchRound!.ruleDescription} (${_ruleSwitchRound!.targetCriterion})';
      _startReactionTimer();
    } else if (mode == 'memory') {
      _memoryRound = _memoryEngine.generateRound(
        roundNumber: _currentRound,
        level: widget.level,
      );
      _activeInstruction = 'Memorize the sequence (${_memoryRound!.sequenceLength} items)';
      _startMemoryPresentation();
    }
  }

  String _getEffectiveModeForRound(int round) {
    if (widget.gameMode != 'daily') return widget.gameMode;
    // Daily mode combines all 5 modes across rounds
    final modes = ['selective', 'sustained', 'distraction_shield', 'rule_switch', 'memory'];
    return modes[(round - 1) % modes.length];
  }

  void _startReactionTimer() {
    _reactionStopwatch.reset();
    _reactionStopwatch.start();
  }

  // -------------------------------------------------------------
  // Mode 1: Selective Focus Interaction
  // -------------------------------------------------------------
  void _onSelectiveItemTap(GameStimulus item) {
    if (_phase != GamePhase.playing) return;
    _reactionStopwatch.stop();
    final double rt = _reactionStopwatch.elapsedMilliseconds.toDouble();

    final bool correct = item.isTarget;
    _recordAttempt(
      targetType: '${_selectiveRound!.target.colorName} ${_selectiveRound!.target.shapeName}',
      playerAction: 'hit',
      correct: correct,
      reactionTime: rt,
      distractionPresent: false,
    );

    _showFeedbackAndAdvance(correct, correct ? 'Target located!' : 'Incorrect object selected');
  }

  // -------------------------------------------------------------
  // Mode 2: Sustained Focus Interaction (Go / No-Go)
  // -------------------------------------------------------------
  void _startSustainedTrial() {
    if (_sustainedIndex >= _sustainedSequence.length) {
      _completeSession();
      return;
    }

    final trial = _sustainedSequence[_sustainedIndex];
    setState(() {
      _currentSustainedStim = trial;
      _sustainedWaitingForResponse = true;
    });

    _startReactionTimer();

    _sustainedExposureTimer?.cancel();
    _sustainedExposureTimer = Timer(Duration(milliseconds: trial.durationMs), () {
      if (_sustainedWaitingForResponse) {
        // Window elapsed without tap
        _sustainedWaitingForResponse = false;
        if (trial.isTarget) {
          // Miss (Omission error)
          _recordAttempt(
            targetType: 'STAR',
            playerAction: 'miss',
            correct: false,
            reactionTime: trial.durationMs.toDouble(),
            distractionPresent: false,
          );
          _haptics.error();
        } else {
          // Correct No-Go (withheld response)
          _recordAttempt(
            targetType: trial.stimulus.shapeName,
            playerAction: 'withheld',
            correct: true,
            reactionTime: trial.durationMs.toDouble(),
            distractionPresent: false,
          );
        }
      }

      // Hide stimulus during ISI blank
      setState(() => _currentSustainedStim = null);

      _sustainedIsiTimer?.cancel();
      _sustainedIsiTimer = Timer(Duration(milliseconds: trial.isiMs), () {
        _sustainedIndex++;
        setState(() => _currentRound = _sustainedIndex + 1);
        _startSustainedTrial();
      });
    });
  }

  void _onSustainedTriggerTap() {
    if (_phase != GamePhase.playing || !_sustainedWaitingForResponse || _currentSustainedStim == null) return;
    _sustainedWaitingForResponse = false;
    _reactionStopwatch.stop();
    final double rt = _reactionStopwatch.elapsedMilliseconds.toDouble();

    final trial = _currentSustainedStim!;
    final bool correct = trial.isTarget;

    _recordAttempt(
      targetType: trial.stimulus.shapeName,
      playerAction: 'hit',
      correct: correct,
      reactionTime: rt,
      distractionPresent: !trial.isTarget, // Tapping on non-target is false alarm
    );

    if (correct) {
      _haptics.success();
    } else {
      _haptics.error();
    }

    _updateScoreHud();
  }

  // -------------------------------------------------------------
  // Mode 3: Distraction Shield Interaction
  // -------------------------------------------------------------
  void _onDistractionItemTap(GameStimulus item, {bool isFloating = false}) {
    if (_phase != GamePhase.playing) return;
    _reactionStopwatch.stop();
    final double rt = _reactionStopwatch.elapsedMilliseconds.toDouble();

    final bool correct = item.isTarget;
    _recordAttempt(
      targetType: '${_distractionRound!.target.colorName} ${_distractionRound!.target.shapeName}',
      playerAction: correct ? 'hit' : 'distraction_error',
      correct: correct,
      reactionTime: rt,
      distractionPresent: true,
    );

    _showFeedbackAndAdvance(
      correct,
      correct ? 'Shield held! Focused on true target.' : 'Distraction captured your attention!',
    );
  }

  // -------------------------------------------------------------
  // Mode 4: Rule Switch Interaction
  // -------------------------------------------------------------
  void _onRuleSwitchChoiceTap(int choiceIndex) {
    if (_phase != GamePhase.playing) return;
    _reactionStopwatch.stop();
    final double rt = _reactionStopwatch.elapsedMilliseconds.toDouble();

    final bool correct = choiceIndex == _ruleSwitchRound!.correctChoiceIndex;
    _recordAttempt(
      targetType: _ruleSwitchRound!.ruleDescription,
      playerAction: 'hit',
      correct: correct,
      reactionTime: rt,
      distractionPresent: _ruleSwitchRound!.isSwitchTrial,
    );

    _showFeedbackAndAdvance(
      correct,
      correct ? 'Rule applied successfully!' : 'Incorrect rule match',
    );
  }

  // -------------------------------------------------------------
  // Mode 5: Memory Focus Interaction
  // -------------------------------------------------------------
  void _startMemoryPresentation() {
    setState(() {
      _memoryShowingSequence = true;
      _memoryPresentIndex = 0;
      _playerMemoryInput.clear();
    });

    _memoryPresentationTimer?.cancel();
    _memoryPresentationTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (_memoryPresentIndex < _memoryRound!.sequence.length - 1) {
        setState(() => _memoryPresentIndex++);
        _haptics.selection();
      } else {
        timer.cancel();
        // Presentation complete, transition to recall phase
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _memoryShowingSequence = false;
              _activeInstruction = 'Reproduce the sequence in order';
            });
            _startReactionTimer();
          }
        });
      }
    });
  }

  void _onMemoryInputTap(GameStimulus stimulus) {
    if (_phase != GamePhase.playing || _memoryShowingSequence) return;
    _haptics.selection();

    setState(() {
      _playerMemoryInput.add(stimulus);
    });

    // Check if player completed full sequence input
    if (_playerMemoryInput.length == _memoryRound!.sequenceLength) {
      _reactionStopwatch.stop();
      final double rt = _reactionStopwatch.elapsedMilliseconds.toDouble();

      bool allCorrect = true;
      for (int i = 0; i < _memoryRound!.sequenceLength; i++) {
        final expected = _memoryRound!.sequence[i];
        final actual = _playerMemoryInput[i];
        if (expected.shape != actual.shape || expected.color != actual.color) {
          allCorrect = false;
          break;
        }
      }

      _recordAttempt(
        targetType: 'MEMORY_${_memoryRound!.sequenceLength}_SPAN',
        playerAction: 'recall',
        correct: allCorrect,
        reactionTime: rt,
        distractionPresent: false,
      );

      _showFeedbackAndAdvance(
        allCorrect,
        allCorrect ? 'Perfect recall!' : 'Sequence did not match',
      );
    }
  }

  // -------------------------------------------------------------
  // Universal Attempt Logging & Feedback
  // -------------------------------------------------------------
  void _recordAttempt({
    required String targetType,
    required String playerAction,
    required bool correct,
    required double reactionTime,
    required bool distractionPresent,
  }) {
    final att = AttemptRecord(
      id: const Uuid().v4(),
      sessionId: _sessionId,
      roundNumber: _currentRound,
      targetType: targetType,
      playerAction: playerAction,
      correct: correct,
      reactionTime: reactionTime,
      distractionPresent: distractionPresent,
    );

    _attempts.add(att);

    if (correct) {
      _currentStreak++;
      _haptics.success();
    } else {
      _currentStreak = 0;
      _haptics.error();
    }

    _updateScoreHud();
  }

  void _updateScoreHud() {
    final localResult = LocalScoring.calculate(_attempts, widget.level);
    setState(() {
      _currentScore = localResult.score;
    });
  }

  void _showFeedbackAndAdvance(bool correct, String message) {
    setState(() {
      _phase = GamePhase.feedback;
      _lastAttemptCorrect = correct;
      _feedbackMessage = message;
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (_currentRound < _maxRounds) {
        setState(() {
          _currentRound++;
          _phase = GamePhase.playing;
        });
        _loadCurrentRound();
      } else {
        _completeSession();
      }
    });
  }

  void _completeSession() async {
    _sessionStopwatch.stop();
    final int durationSec = max(1, _sessionStopwatch.elapsed.inSeconds);

    final scoring = LocalScoring.calculate(_attempts, widget.level);

    final session = SessionRecord(
      id: _sessionId,
      userId: 'default_user',
      gameMode: widget.gameMode,
      startedAt: _startedAt,
      completedAt: DateTime.now(),
      duration: durationSec,
      level: widget.level,
      score: scoring.score,
      accuracy: scoring.accuracy,
      averageReactionTime: scoring.averageReactionTime,
      missedTargets: scoring.missedTargets,
      incorrectTargets: scoring.incorrectTargets,
      distractionErrors: scoring.distractionErrors,
      longestStreak: scoring.longestStreak,
      attempts: _attempts,
    );

    // Save locally and sync in background
    final syncResult = await _syncManager.saveAndSyncSession(session);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionResultScreen(
            session: session,
            syncResult: syncResult,
            settings: widget.settings,
          ),
        ),
      );
    }
  }

  void _togglePause() {
    if (_phase == GamePhase.playing) {
      _reactionStopwatch.stop();
      _sessionStopwatch.stop();
      setState(() => _phase = GamePhase.paused);
    } else if (_phase == GamePhase.paused) {
      _reactionStopwatch.start();
      _sessionStopwatch.start();
      setState(() => _phase = GamePhase.playing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FocusAppBar(
        title: _getModeTitle(),
        score: _currentScore,
        streak: _currentStreak,
        onPause: _phase == GamePhase.playing ? _togglePause : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main game area
            Column(
              children: [
                _buildInstructionBanner(),
                Expanded(child: _buildGameContent()),
                _buildFooterStats(),
              ],
            ),

            // Instructional intro overlay
            if (_phase == GamePhase.instruction) _buildInstructionOverlay(),

            // 3-2-1 Countdown overlay
            if (_phase == GamePhase.countdown) _buildCountdownOverlay(),

            // Paused overlay
            if (_phase == GamePhase.paused) _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }

  String _getModeTitle() {
    switch (widget.gameMode) {
      case 'selective':
        return 'Selective Focus';
      case 'sustained':
        return 'Sustained Focus';
      case 'distraction_shield':
        return 'Distraction Shield';
      case 'rule_switch':
        return 'Rule Switch';
      case 'memory':
        return 'Memory Focus';
      case 'daily':
        return 'Daily Training';
      default:
        return 'Focus Training';
    }
  }

  Widget _buildInstructionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _phase == GamePhase.feedback
            ? (_lastAttemptCorrect == true ? AppColors.successLight : AppColors.errorLight)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _phase == GamePhase.feedback
              ? (_lastAttemptCorrect == true ? AppColors.success : AppColors.error)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _phase == GamePhase.feedback
                ? (_lastAttemptCorrect == true ? Icons.check_circle_rounded : Icons.cancel_rounded)
                : Icons.adjust_rounded,
            size: 20,
            color: _phase == GamePhase.feedback
                ? (_lastAttemptCorrect == true ? AppColors.success : AppColors.error)
                : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _phase == GamePhase.feedback ? _feedbackMessage : _activeInstruction,
              style: AppTypography.subhead.copyWith(
                fontWeight: FontWeight.w600,
                color: _phase == GamePhase.feedback
                    ? (_lastAttemptCorrect == true ? AppColors.success : AppColors.error)
                    : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    final mode = _getEffectiveModeForRound(_currentRound);

    switch (mode) {
      case 'selective':
        return _buildSelectiveGrid();
      case 'sustained':
        return _buildSustainedView();
      case 'distraction_shield':
        return _buildDistractionShieldView();
      case 'rule_switch':
        return _buildRuleSwitchView();
      case 'memory':
        return _buildMemoryView();
      default:
        return const Center(child: Text('Loading game mode...'));
    }
  }

  // --- Mode 1 View ---
  Widget _buildSelectiveGrid() {
    if (_selectiveRound == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _selectiveRound!.items.map((stim) {
            return ShapeIconView(
              stimulus: stim,
              size: 64,
              onTap: () => _onSelectiveItemTap(stim),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- Mode 2 View ---
  Widget _buildSustainedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: _currentSustainedStim != null
                ? ShapeIconView(
                    stimulus: _currentSustainedStim!.stimulus,
                    size: 96,
                  )
                : Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: PrimaryButton(
            label: 'TARGET HIT',
            icon: Icons.touch_app_rounded,
            height: 60,
            onPressed: _onSustainedTriggerTap,
          ),
        ),
      ],
    );
  }

  // --- Mode 3 View ---
  Widget _buildDistractionShieldView() {
    if (_distractionRound == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Fake Banner distraction
        Positioned(
          top: 10,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _distractionRound!.fakeInstruction,
                    style: AppTypography.caption.copyWith(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stationary items grid
        Padding(
          padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
          child: Center(
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: _distractionRound!.fieldItems.map((stim) {
                return ShapeIconView(
                  stimulus: stim,
                  size: 60,
                  onTap: () => _onDistractionItemTap(stim),
                );
              }).toList(),
            ),
          ),
        ),

        // Floating Distraction items
        ..._distractionRound!.floatingDistractions.map((floatItem) {
          return AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final double t = _floatingController.value;
              final double dx = (floatItem.initialX + floatItem.speedX * t * 2) % 0.85;
              final double dy = (floatItem.initialY + floatItem.speedY * t * 2) % 0.7 + 0.1;

              return Positioned(
                left: MediaQuery.of(context).size.width * dx,
                top: MediaQuery.of(context).size.height * dy,
                child: Opacity(
                  opacity: 0.75,
                  child: ShapeIconView(
                    stimulus: floatItem.stimulus,
                    size: 44,
                    onTap: () => _onDistractionItemTap(floatItem.stimulus, isFloating: true),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  // --- Mode 4 View ---
  Widget _buildRuleSwitchView() {
    if (_ruleSwitchRound == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_ruleSwitchRound!.isSwitchTrial)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('RULE SWITCHED!', style: AppTypography.footnote),
                ],
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _ruleSwitchRound!.choices.length,
            itemBuilder: (context, index) {
              final stim = _ruleSwitchRound!.choices[index];
              return ShapeIconView(
                stimulus: stim,
                size: 80,
                onTap: () => _onRuleSwitchChoiceTap(index),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Mode 5 View ---
  Widget _buildMemoryView() {
    if (_memoryRound == null) return const SizedBox.shrink();

    if (_memoryShowingSequence) {
      final currentStim = _memoryRound!.sequence[_memoryPresentIndex];
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Item ${_memoryPresentIndex + 1} of ${_memoryRound!.sequenceLength}',
            style: AppTypography.callout,
          ),
          const SizedBox(height: 24),
          ShapeIconView(
            stimulus: currentStim,
            size: 96,
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Sequence entry progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_memoryRound!.sequenceLength, (idx) {
            final bool filled = idx < _playerMemoryInput.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.primary : AppColors.border,
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        // Keypad palette to tap in order
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _memoryRound!.selectablePalette.map((stim) {
            return ShapeIconView(
              stimulus: stim,
              size: 68,
              onTap: () => _onMemoryInputTap(stim),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooterStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ROUND $_currentRound / $_maxRounds',
            style: AppTypography.subhead.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'LEVEL ${widget.level.toStringAsFixed(1)}',
            style: AppTypography.subhead.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --- Overlays ---
  Widget _buildInstructionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: LightCard(
          margin: const EdgeInsets.all(24),
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getModeTitle(), style: AppTypography.title2),
              const SizedBox(height: 12),
              Text(
                _getModeDescription(),
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Begin Round',
                icon: Icons.play_arrow_rounded,
                onPressed: _startCountdown,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModeDescription() {
    switch (widget.gameMode) {
      case 'selective':
        return 'Scan the field rapidly and tap the designated target object while filtering out distractors.';
      case 'sustained':
        return 'Watch the stream of symbols carefully. Tap the TARGET HIT trigger ONLY when a Star appears.';
      case 'distraction_shield':
        return 'Follow the real target rule while ignoring drifting objects, fake instructions, and visual noise.';
      case 'rule_switch':
        return 'Match objects according to the active rule. Adapt swiftly when the rule abruptly switches.';
      case 'memory':
        return 'Memorize the presented sequence of symbols, then enter them back in the exact order.';
      case 'daily':
        return 'A comprehensive 5-stage focus workout exercising all core attention capabilities.';
      default:
        return 'Concentrate and respond accurately to each challenge.';
    }
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      child: Center(
        child: Text(
          '$_countdownValue',
          style: const TextStyle(
            fontSize: 92,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: LightCard(
          margin: const EdgeInsets.all(24),
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Session Paused', style: AppTypography.title2),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Resume',
                icon: Icons.play_arrow_rounded,
                onPressed: _togglePause,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Quit Training',
                isSecondary: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
