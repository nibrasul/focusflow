class AttemptRecord {
  final String id;
  final String sessionId;
  final int roundNumber;
  final String targetType;
  final String playerAction; // hit, miss, false_alarm, timeout
  final bool correct;
  final double reactionTime; // ms
  final bool distractionPresent;
  final DateTime timestamp;

  AttemptRecord({
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    required this.targetType,
    required this.playerAction,
    required this.correct,
    required this.reactionTime,
    this.distractionPresent = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'round_number': roundNumber,
      'target_type': targetType,
      'player_action': playerAction,
      'correct': correct ? 1 : 0,
      'reaction_time': reactionTime,
      'distraction_present': distractionPresent ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AttemptRecord.fromMap(Map<String, dynamic> map) {
    return AttemptRecord(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      roundNumber: map['round_number'] as int,
      targetType: map['target_type'] as String,
      playerAction: map['player_action'] as String,
      correct: (map['correct'] as int) == 1,
      reactionTime: (map['reaction_time'] as num).toDouble(),
      distractionPresent: (map['distraction_present'] as int) == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round_number': roundNumber,
      'target_type': targetType,
      'player_action': playerAction,
      'correct': correct,
      'reaction_time': reactionTime,
      'distraction_present': distractionPresent,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
