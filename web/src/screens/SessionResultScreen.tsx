import React from 'react';
import { Award, CheckCircle2, Cloud, CloudOff, RotateCcw, Home, Zap, Target, ShieldAlert, Timer } from 'lucide-react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import type { SessionRecord } from '../types/game';

interface SessionResultScreenProps {
  session: SessionRecord;
  synced: boolean;
  onTrainAgain: () => void;
  onGoHome: () => void;
}

export const SessionResultScreen: React.FC<SessionResultScreenProps> = ({
  session,
  synced,
  onTrainAgain,
  onGoHome,
}) => {
  const getModeTitle = (mode: string) => {
    switch (mode) {
      case 'selective': return 'Selective Focus';
      case 'sustained': return 'Sustained Focus';
      case 'distraction_shield': return 'Distraction Shield';
      case 'rule_switch': return 'Rule Switch';
      case 'memory': return 'Memory Focus';
      case 'daily': return 'Daily Cognitive Workout';
      default: return 'Training Session';
    }
  };

  const xpEarned = Math.max(10, Math.floor(session.score * 0.1));

  return (
    <div style={{ padding: '24px 20px', display: 'flex', flexDirection: 'column', gap: 20, minHeight: '100vh', boxSizing: 'border-box' }}>
      {/* Header */}
      <div style={{ textAlign: 'center', marginTop: 12 }}>
        <div
          style={{
            width: 56,
            height: 56,
            borderRadius: 28,
            background: 'var(--primary-light)',
            color: 'var(--primary)',
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: 12,
          }}
        >
          <Award size={32} />
        </div>
        <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Session Completed</h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: 14, marginTop: 4, margin: 0 }}>
          {getModeTitle(session.gameMode)} • Level {session.level.toFixed(1)}
        </p>
      </div>

      {/* Sync Status Banner */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 8,
          fontSize: 12,
          fontWeight: 600,
          color: synced ? 'var(--success)' : 'var(--text-muted)',
          padding: '6px 12px',
          background: synced ? '#F0FDF4' : 'var(--bg-secondary)',
          borderRadius: 20,
          alignSelf: 'center',
        }}
      >
        {synced ? <Cloud size={14} /> : <CloudOff size={14} />}
        <span>{synced ? 'Authoritatively Scored & Synced' : 'Saved Locally (Sync Queued)'}</span>
      </div>

      {/* Primary Score Hero Card */}
      <Card style={{ textAlign: 'center', padding: '24px 16px', background: 'linear-gradient(180deg, #FFFFFF 0%, var(--bg-secondary) 100%)' }}>
        <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-muted)', letterSpacing: 0.5 }}>FINAL SCORE</span>
        <div style={{ fontSize: 44, fontWeight: 800, color: 'var(--primary)', margin: '4px 0' }}>
          {session.score.toLocaleString()}
        </div>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: 'var(--primary-light)', padding: '4px 12px', borderRadius: 12 }}>
          <Zap size={14} color="var(--primary)" />
          <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--primary)' }}>+{xpEarned} XP Earned</span>
        </div>
      </Card>

      {/* Metric Breakdown Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        <Card style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <Target size={18} color="var(--primary)" />
            <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-muted)' }}>Accuracy</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-primary)' }}>
            {session.accuracy.toFixed(1)}%
          </div>
          <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>Target selection rate</span>
        </Card>

        <Card style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <Timer size={18} color="var(--warning)" />
            <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-muted)' }}>Reaction Speed</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-primary)' }}>
            {session.averageReactionTime > 0 ? `${Math.round(session.averageReactionTime)} ms` : '--'}
          </div>
          <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>Mean response latency</span>
        </Card>

        <Card style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <CheckCircle2 size={18} color="var(--success)" />
            <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-muted)' }}>Best Streak</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-primary)' }}>
            {session.longestStreak}
          </div>
          <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>Consecutive correct</span>
        </Card>

        <Card style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <ShieldAlert size={18} color="var(--danger)" />
            <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-muted)' }}>Distractions</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-primary)' }}>
            {session.distractionErrors}
          </div>
          <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>Fails under interference</span>
        </Card>
      </div>

      {/* Summary Advice */}
      <Card style={{ borderLeft: '4px solid var(--primary)', padding: '14px 16px' }}>
        <h4 style={{ fontSize: 13, fontWeight: 700, margin: '0 0 4px 0' }}>Cognitive Feedback</h4>
        <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0, lineHeight: 1.5 }}>
          {session.accuracy >= 85
            ? 'Excellent visual gating and sustained attention. Your consistency is ready for higher stimulus density.'
            : session.accuracy >= 70
            ? 'Solid attention baseline. Focus on withholding taps when distractors present overlapping features.'
            : 'Take a deep breath and maintain steady gaze pacing. Precision yields higher multipliers than rushing.'}
        </p>
      </Card>

      {/* Action Buttons */}
      <div style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: 10, paddingTop: 16 }}>
        <Button variant="primary" onClick={onTrainAgain} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <RotateCcw size={18} />
          Train Again
        </Button>
        <Button variant="secondary" onClick={onGoHome} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <Home size={18} />
          Return to Dashboard
        </Button>
      </div>
    </div>
  );
};
