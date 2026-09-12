class AchievementRecord {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String category;
  final int xpReward;
  final bool unlocked;
  final String? unlockedAt;

  AchievementRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    required this.xpReward,
    required this.unlocked,
    this.unlockedAt,
  });

  factory AchievementRecord.fromJson(Map<String, dynamic> json) {
    return AchievementRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String? ?? 'award',
      category: json['category'] as String? ?? 'general',
      xpReward: json['xp_reward'] as int? ?? 50,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] as String?,
    );
  }
}
