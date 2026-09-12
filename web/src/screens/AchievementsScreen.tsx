import React, { useEffect, useState } from 'react';
import { ArrowLeft, Award, CheckCircle2, Lock, Zap, Sparkles } from 'lucide-react';
import { Card } from '../components/Card';
import { ApiClient } from '../services/api';
import { StorageService } from '../services/storage';
import type { AchievementRecord } from '../types/api';

interface AchievementsScreenProps {
  onBack: () => void;
}

const DEFAULT_ACHIEVEMENTS: AchievementRecord[] = [
  {
    id: 'first_step',
    title: 'First Step',
    description: 'Complete your first cognitive training session.',
    iconName: 'play',
    category: 'milestone',
    xpReward: 50,
    unlocked: false,
  },
  {
    id: 'speed_demon',
    title: 'Speed Demon',
    description: 'Achieve an average reaction time below 450ms in any session.',
    iconName: 'zap',
    category: 'speed',
    xpReward: 150,
    unlocked: false,
  },
  {
    id: 'laser_focus',
    title: 'Laser Focus',
    description: 'Finish a training session with 95% or higher accuracy.',
    iconName: 'target',
    category: 'accuracy',
    xpReward: 200,
    unlocked: false,
  },
  {
    id: 'shield_master',
    title: 'Distraction Shield Master',
    description: 'Survive a Distraction Shield round with 0 distraction errors.',
    iconName: 'shield',
    category: 'shield',
    xpReward: 175,
    unlocked: false,
  },
  {
    id: 'streak_3',
    title: 'Consistent Mind',
    description: 'Maintain a 3-day training streak.',
    iconName: 'flame',
    category: 'streak',
    xpReward: 250,
    unlocked: false,
  },
  {
    id: 'memory_ace',
    title: 'Working Memory Ace',
    description: 'Reach Level 4 or higher in the Memory Focus task.',
    iconName: 'layers',
    category: 'memory',
    xpReward: 300,
    unlocked: false,
  },
];

export const AchievementsScreen: React.FC<AchievementsScreenProps> = ({ onBack }) => {
  const [achievements, setAchievements] = useState<AchievementRecord[]>(DEFAULT_ACHIEVEMENTS);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    loadAchievements();
  }, []);

  const loadAchievements = async () => {
    setLoading(true);
    const remote = await ApiClient.getAchievements();
    const sessions = StorageService.getLocalSessions();
    const profile = StorageService.getLocalProfile();

    if (remote && remote.length > 0) {
      setAchievements(remote);
    } else {
      // Evaluate achievements locally from stored sessions
      const updated = DEFAULT_ACHIEVEMENTS.map(ach => {
        let isUnlocked = false;
        if (ach.id === 'first_step' && sessions.length > 0) isUnlocked = true;
        if (ach.id === 'speed_demon' && sessions.some(s => s.averageReactionTime > 0 && s.averageReactionTime < 450)) isUnlocked = true;
        if (ach.id === 'laser_focus' && sessions.some(s => s.accuracy >= 95)) isUnlocked = true;
        if (ach.id === 'shield_master' && sessions.some(s => s.gameMode === 'distraction_shield' && s.distractionErrors === 0)) isUnlocked = true;
        if (ach.id === 'streak_3' && profile.currentStreak >= 3) isUnlocked = true;
        if (ach.id === 'memory_ace' && sessions.some(s => s.gameMode === 'memory' && s.level >= 4.0)) isUnlocked = true;

        return { ...ach, unlocked: isUnlocked };
      });
      setAchievements(updated);
    }
    setLoading(false);
  };

  const unlockedCount = achievements.filter(a => a.unlocked).length;
  const progressPct = Math.round((unlockedCount / achievements.length) * 100);

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
        <h1 style={{ fontSize: 20, fontWeight: 700, margin: 0 }}>Achievements</h1>
      </div>

      {/* Hero Card */}
      <Card style={{ padding: '20px', background: 'linear-gradient(135deg, #EFF6FF 0%, #FFFFFF 100%)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: 22,
                background: 'var(--primary)',
                color: '#FFFFFF',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Award size={24} />
            </div>
            <div>
              <div style={{ fontSize: 16, fontWeight: 700 }}>Milestones Unlocked</div>
              <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                {unlockedCount} of {achievements.length} Completed
              </div>
            </div>
          </div>
          <span style={{ fontSize: 18, fontWeight: 800, color: 'var(--primary)' }}>
            {progressPct}%
          </span>
        </div>

        {/* Progress Bar */}
        <div style={{ width: '100%', height: 8, background: 'var(--border)', borderRadius: 4, overflow: 'hidden' }}>
          <div
            style={{
              width: `${progressPct}%`,
              height: '100%',
              background: 'var(--primary)',
              borderRadius: 4,
              transition: 'width 0.4s ease',
            }}
          />
        </div>
      </Card>

      {/* Achievement List */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: '24px', color: 'var(--text-muted)' }}>Loading achievements...</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {achievements.map((ach) => (
            <Card
              key={ach.id}
              style={{
                padding: '16px',
                opacity: ach.unlocked ? 1 : 0.75,
                borderColor: ach.unlocked ? 'var(--primary-light)' : 'var(--border)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
                <div
                  style={{
                    width: 40,
                    height: 40,
                    borderRadius: 12,
                    background: ach.unlocked ? 'var(--primary-light)' : 'var(--bg-secondary)',
                    color: ach.unlocked ? 'var(--primary)' : 'var(--text-muted)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  {ach.unlocked ? <Sparkles size={20} /> : <Lock size={18} />}
                </div>

                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, marginBottom: 4 }}>
                    <h4 style={{ fontSize: 14, fontWeight: 700, margin: 0, color: 'var(--text-primary)' }}>
                      {ach.title}
                    </h4>
                    <span
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: 4,
                        fontSize: 11,
                        fontWeight: 700,
                        color: 'var(--primary)',
                        background: 'var(--primary-light)',
                        padding: '2px 8px',
                        borderRadius: 10,
                      }}
                    >
                      <Zap size={12} />
                      +{ach.xpReward} XP
                    </span>
                  </div>
                  <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0, lineHeight: 1.4 }}>
                    {ach.description}
                  </p>
                  {ach.unlocked && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 8, fontSize: 11, color: 'var(--success)', fontWeight: 600 }}>
                      <CheckCircle2 size={13} />
                      <span>Unlocked</span>
                    </div>
                  )}
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
};

