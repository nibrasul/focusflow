import React from 'react';
import { Brain, Filter, Timer, Shield, ArrowRight } from 'lucide-react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { StorageService } from '../services/storage';

interface OnboardingScreenProps {
  onDone: () => void;
}

export const OnboardingScreen: React.FC<OnboardingScreenProps> = ({ onDone }) => {
  const handleStart = () => {
    StorageService.saveSettings({ onboardingCompleted: true });
    onDone();
  };

  return (
    <div style={{ padding: '32px 24px', display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      <div
        style={{
          width: 52,
          height: 52,
          borderRadius: 14,
          background: 'var(--primary-light)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'var(--primary)',
          marginBottom: 20,
        }}
      >
        <Brain size={28} />
      </div>

      <h1 style={{ fontSize: 32, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.2, marginBottom: 12 }}>
        Train Your<br />Concentration.
      </h1>

      <p style={{ color: 'var(--text-secondary)', fontSize: 16, marginBottom: 28 }}>
        Science-inspired cognitive exercises designed to cultivate selective focus, sustained attention, and distraction resistance.
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16, flex: 1, marginBottom: 24 }}>
        <FeatureRow
          icon={<Filter size={20} color="var(--primary)" />}
          title="5 Core Training Modes"
          description="Selective search, sustained vigilance, distraction shield, rule switching, and working memory."
        />
        <FeatureRow
          icon={<Timer size={20} color="var(--primary)" />}
          title="Precision RT Tracking"
          description="Sub-millisecond reaction latency measurement from stimulus display to actual touch/click."
        />
        <FeatureRow
          icon={<Shield size={20} color="var(--primary)" />}
          title="Adaptive Difficulty"
          description="Intelligently scales challenge density based on your actual accuracy and reaction stability."
        />
      </div>

      <Card style={{ background: 'var(--secondary-surface)', marginBottom: 24, padding: 12 }}>
        <p style={{ fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.4 }}>
          <strong>Notice:</strong> Attention and concentration training through interactive gameplay. Not intended as a medical diagnostic tool or clinical treatment.
        </p>
      </Card>

      <Button onClick={handleStart} icon={<ArrowRight size={18} />}>
        Get Started
      </Button>
    </div>
  );
};

const FeatureRow: React.FC<{ icon: React.ReactNode; title: string; description: string }> = ({
  icon,
  title,
  description,
}) => (
  <div style={{ display: 'flex', gap: 14 }}>
    <div
      style={{
        width: 40,
        height: 40,
        borderRadius: 12,
        background: '#ffffff',
        border: '1px solid var(--border)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
      }}
    >
      {icon}
    </div>
    <div>
      <h3 style={{ fontSize: 15, fontWeight: 600 }}>{title}</h3>
      <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 2 }}>{description}</p>
    </div>
  </div>
);
