import React, { useEffect, useState } from 'react';
import { ArrowLeft, TrendingUp, Calendar, Target, Timer, Flame, Layers } from 'lucide-react';
import { Card } from '../components/Card';
import { StorageService } from '../services/storage';
import { ApiClient } from '../services/api';
import type { SessionRecord } from '../types/game';
import type { ProfileRecord, DayTrend } from '../types/api';

interface ProgressScreenProps {
  onBack: () => void;
}

export const ProgressScreen: React.FC<ProgressScreenProps> = ({ onBack }) => {
  const [profile, setProfile] = useState<ProfileRecord>(StorageService.getLocalProfile());
  const [sessions, setSessions] = useState<SessionRecord[]>(StorageService.getLocalSessions());
  const [weeklyTrend, setWeeklyTrend] = useState<DayTrend[]>([]);

  useEffect(() => {
    loadProgressData();
  }, []);

  const loadProgressData = async () => {
    const localProf = StorageService.getLocalProfile();
    const localSess = StorageService.getLocalSessions();
    setProfile(localProf);
    setSessions(localSess);

    const remote = await ApiClient.getDashboard();
    if (remote) {
      setProfile(remote.profile);
      if (remote.weekly_accuracy_trend) {
        setWeeklyTrend(remote.weekly_accuracy_trend);
      }
    }
  };

  const getModeLabel = (mode: string) => {
    switch (mode) {
      case 'selective': return 'Selective Focus';
      case 'sustained': return 'Sustained Focus';
      case 'distraction_shield': return 'Distraction Shield';
      case 'rule_switch': return 'Rule Switch';
      case 'memory': return 'Memory Focus';
      case 'daily': return 'Daily Workout';
      default: return mode;
    }
  };

  return (
    <div style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: 20, minHeight: '100vh' }}>
      {/* Top Bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <button
          onClick={onBack}
          style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', color: 'var(--text-primary)' }}
        >
          <ArrowLeft size={22} />
        </button>
        <h1 style={{ fontSize: 20, fontWeight: 700, margin: 0 }}>Cognitive Progress</h1>
      </div>

      {/* Hero Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 }}>
        <Card style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
            <Target size={16} color="var(--primary)" />
            <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-muted)' }}>Overall Accuracy</span>
          </div>
          <div style={{ fontSize: 22, fontWeight: 700 }}>
            {profile.overallAccuracy > 0 ? `${profile.overallAccuracy.toFixed(1)}%` : '--'}
          </div>
        </Card>

        <Card style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
            <Timer size={16} color="var(--warning)" />
            <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-muted)' }}>Avg Reaction Time</span>
          </div>
          <div style={{ fontSize: 22, fontWeight: 700 }}>
            {profile.averageReactionTime > 0 ? `${Math.round(profile.averageReactionTime)} ms` : '--'}
          </div>
        </Card>

        <Card style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
            <Flame size={16} color="var(--accent)" />
            <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-muted)' }}>Best Streak</span>
          </div>
          <div style={{ fontSize: 22, fontWeight: 700 }}>
            {profile.bestStreak} {profile.bestStreak === 1 ? 'day' : 'days'}
          </div>
        </Card>

        <Card style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
            <Layers size={16} color="var(--success)" />
            <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-muted)' }}>Total Sessions</span>
          </div>
          <div style={{ fontSize: 22, fontWeight: 700 }}>
            {profile.totalSessions}
          </div>
        </Card>
      </div>

      {/* 7-Day Accuracy Trend SVG Chart */}
      <Card>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <TrendingUp size={18} color="var(--primary)" />
            <h3 style={{ fontSize: 14, fontWeight: 700, margin: 0 }}>7-Day Accuracy Trend</h3>
          </div>
          <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>Target: 85%+</span>
        </div>

        {weeklyTrend.length > 0 ? (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', height: 120, padding: '0 8px', gap: 8 }}>
              {weeklyTrend.map((day, idx) => {
                const heightPct = day.accuracy ? Math.max(15, Math.min(100, day.accuracy)) : 0;
                return (
                  <div key={idx} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, height: '100%', justifyContent: 'flex-end' }}>
                    {day.has_data && (
                      <span style={{ fontSize: 10, fontWeight: 600, color: 'var(--text-primary)' }}>
                        {Math.round(day.accuracy!)}%
                      </span>
                    )}
                    <div
                      style={{
                        width: '100%',
                        maxWidth: 28,
                        height: `${heightPct}%`,
                        background: day.has_data ? 'var(--primary)' : 'var(--border)',
                        borderRadius: '4px 4px 0 0',
                        transition: 'height 0.3s ease',
                      }}
                    />
                    <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 500 }}>
                      {day.day_label}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: '24px 0', color: 'var(--text-muted)', fontSize: 13 }}>
            Complete training sessions to generate your weekly cognitive trend curve.
          </div>
        )}
      </Card>

      {/* Recent Training History */}
      <Card>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
          <Calendar size={18} color="var(--primary)" />
          <h3 style={{ fontSize: 14, fontWeight: 700, margin: 0 }}>Recent Activity</h3>
        </div>

        {sessions.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '24px 0', color: 'var(--text-muted)', fontSize: 13 }}>
            No sessions completed yet. Start your first session from the dashboard!
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {sessions.slice(0, 10).map((sess) => {
              const dateStr = new Date(sess.startedAt).toLocaleDateString(undefined, {
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
              });

              return (
                <div
                  key={sess.id}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 12px',
                    borderRadius: 10,
                    background: 'var(--bg-secondary)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>{getModeLabel(sess.gameMode)}</div>
                    <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{dateStr} • Lvl {sess.level.toFixed(1)}</div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--primary)' }}>
                      {sess.score.toLocaleString()} pts
                    </div>
                    <div style={{ fontSize: 11, color: 'var(--text-secondary)' }}>
                      {sess.accuracy.toFixed(1)}% • {sess.averageReactionTime > 0 ? `${Math.round(sess.averageReactionTime)}ms` : '--'}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </Card>
    </div>
  );
};
