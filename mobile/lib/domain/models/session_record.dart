import 'attempt_record.dart';

class SessionRecord {
  final String id;
  final String userId;
  final String gameMode;
  final DateTime startedAt;
  DateTime? completedAt;
  int duration;
  double level;
  int score;
  double accuracy;
  double averageReactionTime;
  int missedTargets;
  int incorrectTargets;
  int distractionErrors;
  int longestStreak;
  bool isSynced;
  List<AttemptRecord> attempts;

  SessionRecord({
    required this.id,
    required this.userId,
    required this.gameMode,
    required this.startedAt,
    this.completedAt,
    this.duration = 0,
    this.level = 1.0,
    this.score = 0,
    this.accuracy = 0.0,
    this.averageReactionTime = 0.0,
    this.missedTargets = 0,
    this.incorrectTargets = 0,
    this.distractionErrors = 0,
    this.longestStreak = 0,
    this.isSynced = false,
    List<AttemptRecord>? attempts,
  }) : attempts = attempts ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'game_mode': gameMode,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'duration': duration,
      'level': level,
      'score': score,
      'accuracy': accuracy,
      'average_reaction_time': averageReactionTime,
      'missed_targets': missedTargets,
      'incorrect_targets': incorrectTargets,
      'distraction_errors': distractionErrors,
      'longest_streak': longestStreak,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory SessionRecord.fromMap(Map<String, dynamic> map, {List<AttemptRecord>? attempts}) {
    return SessionRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'default_user',
      gameMode: map['game_mode'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      duration: map['duration'] as int? ?? 0,
      level: (map['level'] as num?)?.toDouble() ?? 1.0,
      score: map['score'] as int? ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      averageReactionTime: (map['average_reaction_time'] as num?)?.toDouble() ?? 0.0,
      missedTargets: map['missed_targets'] as int? ?? 0,
      incorrectTargets: map['incorrect_targets'] as int? ?? 0,
      distractionErrors: map['distraction_errors'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      attempts: attempts ?? [],
    );
  }

  Map<String, dynamic> toCompleteJson() {
    return {
      'completed_at': (completedAt ?? DateTime.now()).toIso8601String(),
      'duration': duration,
      'level': level,
      'client_score': score,
      'client_accuracy': accuracy,
      'client_avg_reaction_time': averageReactionTime,
      'attempts': attempts.map((a) => a.toJson()).toList(),
    };
  }
}
