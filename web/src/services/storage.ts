import type { SessionRecord, AttemptRecord } from '../types/game';
import type { ProfileRecord } from '../types/api';
import { ApiClient } from './api';

const KEY_SESSIONS = 'focusflow_sessions';
const KEY_PROFILE = 'focusflow_profile';
const KEY_QUEUE = 'focusflow_sync_queue';
const KEY_SETTINGS = 'focusflow_settings';

export interface WebSettings {
  soundEnabled: boolean;
  reduceMotion: boolean;
  onboardingCompleted: boolean;
}

export class StorageService {
  static getSettings(): WebSettings {
    const raw = localStorage.getItem(KEY_SETTINGS);
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch (_) {}
    }
    return {
      soundEnabled: true,
      reduceMotion: false,
      onboardingCompleted: false,
    };
  }

  static saveSettings(settings: Partial<WebSettings>): void {
    const current = this.getSettings();
    localStorage.setItem(KEY_SETTINGS, JSON.stringify({ ...current, ...settings }));
  }

  static getLocalSessions(): SessionRecord[] {
    const raw = localStorage.getItem(KEY_SESSIONS);
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch (_) {}
    }
    return [];
  }

  static getLocalProfile(): ProfileRecord {
    const raw = localStorage.getItem(KEY_PROFILE);
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch (_) {}
    }
    return {
      userId: 'default_user',
      displayName: 'Focus Athlete',
      currentLevel: 1,
      totalXp: 0,
      totalSessions: 0,
      totalPlayTime: 0,
      overallAccuracy: 0.0,
      averageReactionTime: 0.0,
      currentStreak: 0,
      bestStreak: 0,
    };
  }

  static async saveAndSyncSession(session: SessionRecord): Promise<{ synced: boolean; serverData?: any }> {
    // 1. Save to local sessions
    const sessions = this.getLocalSessions();
    sessions.unshift(session);
    localStorage.setItem(KEY_SESSIONS, JSON.stringify(sessions.slice(0, 50)));

    // 2. Update local profile
    const profile = this.getLocalProfile();
    profile.totalSessions += 1;
    profile.totalPlayTime += session.duration;
    profile.totalXp += Math.floor(session.score * 0.1);
    profile.currentLevel = Math.floor(profile.totalXp / 500) + 1;
    profile.currentStreak += 1;
    if (profile.currentStreak > profile.bestStreak) {
      profile.bestStreak = profile.currentStreak;
    }

    const allAcc = sessions.map(s => s.accuracy);
    profile.overallAccuracy = Math.round(allAcc.reduce((a, b) => a + b, 0) / allAcc.length * 10) / 10;
    const allRt = sessions.map(s => s.averageReactionTime).filter(rt => rt > 0);
    profile.averageReactionTime = allRt.length > 0
      ? Math.round(allRt.reduce((a, b) => a + b, 0) / allRt.length * 10) / 10
      : 0;

    localStorage.setItem(KEY_PROFILE, JSON.stringify(profile));

    // 3. Attempt sync with server
    const isHealthy = await ApiClient.checkHealth();
    if (!isHealthy) {
      this.enqueueForSync(session);
      return { synced: false };
    }

    try {
      await ApiClient.createSession({
        id: session.id,
        game_mode: session.gameMode,
        started_at: session.startedAt,
        level: session.level,
      });

      const res = await ApiClient.completeSession(session.id, {
        completed_at: session.completedAt || new Date().toISOString(),
        duration: session.duration,
        level: session.level,
        client_score: session.score,
        client_accuracy: session.accuracy,
        client_avg_reaction_time: session.averageReactionTime,
        attempts: session.attempts.map((a: AttemptRecord) => ({
          round_number: a.roundNumber,
          target_type: a.targetType,
          player_action: a.playerAction,
          correct: a.correct,
          reaction_time: a.reactionTime,
          distraction_present: a.distractionPresent,
          timestamp: a.timestamp,
        })),
      });

      if (res) {
        session.isSynced = true;
        localStorage.setItem(KEY_SESSIONS, JSON.stringify(sessions));
        return { synced: true, serverData: res };
      }
    } catch (_) {
      this.enqueueForSync(session);
    }
    return { synced: false };
  }

  private static enqueueForSync(session: SessionRecord): void {
    const queue = this.getSyncQueue();
    queue.push(session);
    localStorage.setItem(KEY_QUEUE, JSON.stringify(queue));
  }

  static getSyncQueue(): SessionRecord[] {
    const raw = localStorage.getItem(KEY_QUEUE);
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch (_) {}
    }
    return [];
  }

  static async syncPendingQueue(): Promise<number> {
    const queue = this.getSyncQueue();
    if (queue.length === 0) return 0;
    const isHealthy = await ApiClient.checkHealth();
    if (!isHealthy) return 0;

    let synced = 0;
    const remaining: SessionRecord[] = [];

    for (const session of queue) {
      try {
        const res = await ApiClient.completeSession(session.id, {
          completed_at: session.completedAt,
          duration: session.duration,
          level: session.level,
          attempts: session.attempts,
        });
        if (res) synced++;
        else remaining.push(session);
      } catch (_) {
        remaining.push(session);
      }
    }

    localStorage.setItem(KEY_QUEUE, JSON.stringify(remaining));
    return synced;
  }
}
