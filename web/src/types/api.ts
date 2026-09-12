export interface ProfileRecord {
  userId: string;
  displayName: string;
  currentLevel: number;
  totalXp: number;
  totalSessions: number;
  totalPlayTime: number;
  overallAccuracy: number;
  averageReactionTime: number;
  currentStreak: number;
  bestStreak: number;
  lastPlayedDate?: string;
}

export interface AchievementRecord {
  id: string;
  title: string;
  description: string;
  iconName: string;
  category: string;
  xpReward: number;
  unlocked: boolean;
  unlockedAt?: string;
}

export interface DayTrend {
  date: string;
  day_label: string;
  accuracy: number | null;
  avg_reaction_time: number | null;
  session_count: number;
  has_data: boolean;
}

export interface DashboardResponse {
  profile: ProfileRecord;
  recommended_mode: string;
  recommended_level: number;
  daily_completed: boolean;
  recent_sessions: any[];
  weekly_accuracy_trend: DayTrend[];
  unlocked_achievements_count: number;
  total_achievements_count: number;
}
