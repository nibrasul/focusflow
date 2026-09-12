import React, { useEffect, useState } from 'react';
import { Settings, Flame, Play, Filter, Clock, Shield, Shuffle, Layers, BarChart2, Award } from 'lucide-react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { StorageService } from '../services/storage';
import { ApiClient } from '../services/api';
import type { ProfileRecord, DashboardResponse } from '../types/api';

interface DashboardScreenProps {
  onStartTraining: (mode: string, level: number) => void;
  onOpenTrainingSelect: () => void;
  onOpenProgress: () => void;
  onOpenAchievements: () => void;
  onOpenSettings: () => void;
}

export const DashboardScreen: React.FC<DashboardScreenProps> = ({
  onStartTraining,
  onOpenTrainingSelect,
  onOpenProgress,
  onOpenAchievements,
  onOpenSettings,
}) => {
  const [profile, setProfile] = useState<ProfileRecord>(StorageService.getLocalProfile());
  const [dashboardData, setDashboardData] = useState<DashboardResponse | null>(null);

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    const localProf = StorageService.getLocalProfile();
    setProfile(localProf);

    const remote = await ApiClient.getDashboard();
    if (remote) {
      setDashboardData(remote);
      setProfile(remote.profile);
    }
  };

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  };

  const currentLevel = profile.currentLevel || 1;
  const currentXp = profile.totalXp || 0;
  const xpInLevel = currentXp % 500;
  const xpProgress = Math.min(100, Math.round((xpInLevel / 500) * 100));

  const recommendedMode = dashboardData?.recommended_mode || 'selective';
  const recommendedLevel = dashboardData?.recommended_level || 1.0;

  return (
    <div style={{ padding: '24px 20px', display: 'flex', flexDirection: 'column', gap: 20 }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <span style={{ fontSize: 13, color: 'var(--text-secondary)', fontWeight: 500 }}>{getGreeting()}</span>
          <h1 style={{ fontSize: 24, fontWeight: 700, letterSpacing: -0.3 }}>{profile.displayName}</h1>
        </div>
        <button
          onClick={onOpenSettings}
          style={{
            width: 40,
            height: 40,
            borderRadius: 12,
            background: 'var(--surface)',
            border: '1px solid var(--border)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            color: 'var(--text-primary)',
          }}
        >
          <Settings size={20} />
        </button>
      </div>

      {/* Profile & XP Bar */}
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span
              style={{
                background: 'var(--primary-light)',
                color: 'var(--primary)',
                padding: '4px 10px',
                borderRadius: 8,
                fontSize: 13,
                fontWeight: 700,
              }}
            >
              Level {currentLevel}
            </span>
            <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>{currentXp} XP Total</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--warning)', fontWeight: 700, fontSize: 13 }}>
            <Flame size={16} />
            <span>{profile.currentStreak} day streak</span>
          </div>
        </div>

        <div style={{ width: '100%', height: 6, background: 'var(--border)', borderRadius: 4, overflow: 'hidden' }}>
          <div style={{ width: `${xpProgress}%`, height: '100%', background: 'var(--primary)', borderRadius: 4 }} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 11, color: 'var(--text-muted)' }}>
          <span>{500 - xpInLevel} XP to Level {currentLevel + 1}</span>
          <span>{xpProgress}%</span>
        </div>
      </Card>

      {/* Hero Daily Focus Card */}
      <Card style={{ border: '1.5px solid rgba(0, 122, 255, 0.4)', padding: 18 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <span
            style={{
              fontSize: 10,
              fontWeight: 800,
              color: 'var(--primary)',
              background: 'var(--primary-light)',
              padding: '4px 8px',
              borderRadius: 6,
              letterSpacing: 0.5,
            }}
          >
            TODAY'S WORKOUT
          </span>
          <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>5 Modes Chained</span>
        </div>
        <h2 style={{ fontSize: 20, fontWeight: 700, marginBottom: 4 }}>Daily Focus Session</h2>
        <p style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 16 }}>
          A 10-round cognitive routine combining selective search, sustained vigilance, distraction resistance, rule switching, and working memory.
        </p>
        <Button onClick={() => onStartTraining('daily', recommendedLevel)} icon={<Play size={18} />}>
          Start Daily Workout
        </Button>
      </Card>

      {/* Training Modes Section */}
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', letterSpacing: 0.5 }}>
            TRAINING MODES
          </span>
          <button
            onClick={onOpenTrainingSelect}
            style={{ background: 'none', border: 'none', color: 'var(--primary)', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}
          >
            View All (5)
          </button>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <ModeRow
            title="Selective Focus"
            subtitle="Rapid target search amidst feature distractors"
            icon={<Filter size={18} color="var(--primary)" />}
            color="var(--primary)"
            isRecommended={recommendedMode === 'selective'}
            onClick={() => onStartTraining('selective', recommendedLevel)}
          />
          <ModeRow
            title="Sustained Focus"
            subtitle="Continuous Go/No-Go vigilance stream"
            icon={<Clock size={18} color="var(--target-green)" />}
            color="var(--target-green)"
            isRecommended={recommendedMode === 'sustained'}
            onClick={() => onStartTraining('sustained', recommendedLevel)}
          />
          <ModeRow
            title="Distraction Shield"
            subtitle="Resist moving distractors & misleading banners"
            icon={<Shield size={18} color="var(--warning)" />}
            color="var(--warning)"
            isRecommended={recommendedMode === 'distraction_shield'}
            onClick={() => onStartTraining('distraction_shield', recommendedLevel)}
          />
          <ModeRow
            title="Rule Switch"
            subtitle="Cognitive task-switching flexibility"
            icon={<Shuffle size={18} color="var(--target-purple)" />}
            color="var(--target-purple)"
            isRecommended={recommendedMode === 'rule_switch'}
            onClick={() => onStartTraining('rule_switch', recommendedLevel)}
          />
          <ModeRow
            title="Memory Focus"
            subtitle="Working-memory sequence reproduction"
            icon={<Layers size={18} color="var(--target-blue)" />}
            color="var(--target-blue)"
            isRecommended={recommendedMode === 'memory'}
            onClick={() => onStartTraining('memory', recommendedLevel)}
          />
        </div>
      </div>

      {/* Progress & Achievements Shortcuts */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 20 }}>
        <Card onClick={onOpenProgress} className="glass-card-interactive" style={{ padding: 14 }}>
          <BarChart2 size={22} color="var(--primary)" style={{ marginBottom: 8 }} />
          <h3 style={{ fontSize: 15, fontWeight: 600 }}>Progress</h3>
          <p style={{ fontSize: 12, color: 'var(--text-muted)' }}>Charts & trends</p>
        </Card>
        <Card onClick={onOpenAchievements} className="glass-card-interactive" style={{ padding: 14 }}>
          <Award size={22} color="var(--warning)" style={{ marginBottom: 8 }} />
          <h3 style={{ fontSize: 15, fontWeight: 600 }}>Milestones</h3>
          <p style={{ fontSize: 12, color: 'var(--text-muted)' }}>
            {dashboardData?.unlocked_achievements_count ?? 0}/{dashboardData?.total_achievements_count ?? 7} unlocked
          </p>
        </Card>
      </div>
    </div>
  );
};

const ModeRow: React.FC<{
  title: string;
  subtitle: string;
  icon: React.ReactNode;
  color: string;
  isRecommended: boolean;
  onClick: () => void;
}> = ({ title, subtitle, icon, color, isRecommended, onClick }) => (
  <Card onClick={onClick} className="glass-card-interactive" style={{ padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12 }}>
    <div
      style={{
        width: 38,
        height: 38,
        borderRadius: 10,
        background: `${color}15`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
      }}
    >
      {icon}
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <h4 style={{ fontSize: 15, fontWeight: 600 }}>{title}</h4>
        {isRecommended && (
          <span
            style={{
              fontSize: 9,
              fontWeight: 800,
              background: 'var(--primary-light)',
              color: 'var(--primary)',
              padding: '2px 6px',
              borderRadius: 4,
            }}
          >
            ADAPTIVE REC
          </span>
        )}
      </div>
      <p style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
        {subtitle}
      </p>
    </div>
  </Card>
);
