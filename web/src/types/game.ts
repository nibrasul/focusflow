export type TargetShape = 'circle' | 'triangle' | 'square' | 'diamond' | 'star';
export type TargetColor = 'blue' | 'red' | 'green' | 'yellow' | 'purple' | 'orange';

export interface GameStimulus {
  id: string;
  shape: TargetShape;
  color: TargetColor;
  size?: number;
  isTarget?: boolean;
  accessibleLabel: string;
}

export interface AttemptRecord {
  id: string;
  sessionId: string;
  roundNumber: number;
  targetType: string;
  playerAction: string; // 'hit' | 'miss' | 'false_alarm' | 'withheld' | 'distraction_error' | 'recall'
  correct: boolean;
  reactionTime: number; // ms
  distractionPresent: boolean;
  timestamp: string;
}

export interface SessionRecord {
  id: string;
  userId: string;
  gameMode: string; // 'selective' | 'sustained' | 'distraction_shield' | 'rule_switch' | 'memory' | 'daily'
  startedAt: string;
  completedAt?: string;
  duration: number; // seconds
  level: number;
  score: number;
  accuracy: number;
  averageReactionTime: number;
  missedTargets: number;
  incorrectTargets: number;
  distractionErrors: number;
  longestStreak: number;
  isSynced: boolean;
  attempts: AttemptRecord[];
}

export interface LocalScoringResult {
  score: number;
  accuracy: number;
  averageReactionTime: number;
  correctCount: number;
  missedTargets: number;
  incorrectTargets: number;
  distractionErrors: number;
  longestStreak: number;
  xpEarned: number;
}
