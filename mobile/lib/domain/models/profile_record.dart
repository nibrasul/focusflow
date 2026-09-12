class ProfileRecord {
  final String userId;
  final String displayName;
  final int currentLevel;
  final int totalXp;
  final int totalSessions;
  final int totalPlayTime;
  final double overallAccuracy;
  final double averageReactionTime;
  final int currentStreak;
  final int bestStreak;
  final String? lastPlayedDate;

  ProfileRecord({
    required this.userId,
    required this.displayName,
    this.currentLevel = 1,
    this.totalXp = 0,
    this.totalSessions = 0,
    this.totalPlayTime = 0,
    this.overallAccuracy = 0.0,
    this.averageReactionTime = 0.0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastPlayedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'current_level': currentLevel,
      'total_xp': totalXp,
      'total_sessions': totalSessions,
      'total_play_time': totalPlayTime,
      'overall_accuracy': overallAccuracy,
      'average_reaction_time': averageReactionTime,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'last_played_date': lastPlayedDate,
    };
  }

  factory ProfileRecord.fromMap(Map<String, dynamic> map) {
    return ProfileRecord(
      userId: map['user_id'] as String,
      displayName: map['display_name'] as String? ?? 'Player',
      currentLevel: map['current_level'] as int? ?? 1,
      totalXp: map['total_xp'] as int? ?? 0,
      totalSessions: map['total_sessions'] as int? ?? 0,
      totalPlayTime: map['total_play_time'] as int? ?? 0,
      overallAccuracy: (map['overall_accuracy'] as num?)?.toDouble() ?? 0.0,
      averageReactionTime: (map['average_reaction_time'] as num?)?.toDouble() ?? 0.0,
      currentStreak: map['current_streak'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      lastPlayedDate: map['last_played_date'] as String?,
    );
  }

  factory ProfileRecord.fromJson(Map<String, dynamic> json) {
    return ProfileRecord(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? 'Player',
      currentLevel: json['current_level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalPlayTime: json['total_play_time'] as int? ?? 0,
      overallAccuracy: (json['overall_accuracy'] as num?)?.toDouble() ?? 0.0,
      averageReactionTime: (json['average_reaction_time'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      lastPlayedDate: json['last_played_date'] as String?,
    );
  }
}
