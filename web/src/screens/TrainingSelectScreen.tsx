import React, { useState } from 'react';
import { ArrowLeft, Play, Filter, Clock, Shield, Shuffle, Layers } from 'lucide-react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';

interface TrainingSelectScreenProps {
  initialLevel: number;
  onBack: () => void;
  onStartGame: (mode: string, level: number) => void;
}

export const TrainingSelectScreen: React.FC<TrainingSelectScreenProps> = ({
  initialLevel,
  onBack,
  onStartGame,
}) => {
  const [level, setLevel] = useState<number>(initialLevel || 1.0);

  const getLevelSummary = (lvl: number) => {
    if (lvl <= 2.0) return 'Introductory: Low distraction density, standard response window.';
    if (lvl <= 5.0) return 'Intermediate: Conjunction distractors, faster exposure pacing.';
    if (lvl <= 8.0) return 'Advanced: High visual noise, reduced response time, longer memory span.';
    return 'Master: Maximum interference density, rapid stimulus streaming.';
  };

  return (
    <div style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: 20 }}>
      {/* Top Bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <button
          onClick={onBack}
          style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center' }}
        >
          <ArrowLeft size={20} />
        </button>
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>Training Modes</h1>
      </div>

      {/* Difficulty Level Slider Card */}
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
          <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)' }}>DIFFICULTY LEVEL</span>
          <span
            style={{
              fontSize: 12,
              fontWeight: 700,
              background: 'var(--primary-light)',
              color: 'var(--primary)',
              padding: '2px 8px',
              borderRadius: 6,
            }}
          >
            Level {level.toFixed(1)}
          </span>
        </div>
        <input
          type="range"
          min="1"
          max="10"
          step="0.5"
          value={level}
          onChange={(e) => setLevel(parseFloat(e.target.value))}
          style={{ width: '100%', accentColor: 'var(--primary)', cursor: 'pointer', marginBottom: 8 }}
        />
        <p style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{getLevelSummary(level)}</p>
      </Card>

      {/* Mode List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <ModeDetailCard
          title="Mode 1: Selective Focus"
          category="Visual Search & Filtering"
          description="Rapidly scan the item field and tap the exact target shape+color while filtering distractors."
          icon={<Filter size={20} color="var(--primary)" />}
          accent="var(--primary)"
          onPlay={() => onStartGame('selective', level)}
        />
        <ModeDetailCard
          title="Mode 2: Sustained Focus"
          category="Continuous Vigilance (CPT)"
          description="Watch the central stimulus stream. Tap TARGET HIT only when a Star appears. Inhibit on non-targets."
          icon={<Clock size={20} color="var(--target-green)" />}
          accent="var(--target-green)"
          onPlay={() => onStartGame('sustained', level)}
        />
        <ModeDetailCard
          title="Mode 3: Distraction Shield"
          category="Interference Resistance"
          description="Locate targets while filtering drifting objects, fake instructional banners, and visual flashes."
          icon={<Shield size={20} color="var(--warning)" />}
          accent="var(--warning)"
          onPlay={() => onStartGame('distraction_shield', level)}
        />
        <ModeDetailCard
          title="Mode 4: Rule Switch"
          category="Cognitive Flexibility"
          description="Match items based on dynamically changing rules (Color vs Shape vs Inhibition). Adapt swiftly."
          icon={<Shuffle size={20} color="var(--target-purple)" />}
          accent="var(--target-purple)"
          onPlay={() => onStartGame('rule_switch', level)}
        />
        <ModeDetailCard
          title="Mode 5: Memory Focus"
          category="Working-Memory Span"
          description="Memorize the presented sequence of visual symbols, then enter them back in exact order."
          icon={<Layers size={20} color="var(--target-blue)" />}
          accent="var(--target-blue)"
          onPlay={() => onStartGame('memory', level)}
        />
      </div>
    </div>
  );
};

const ModeDetailCard: React.FC<{
  title: string;
  category: string;
  description: string;
  icon: React.ReactNode;
  accent: string;
  onPlay: () => void;
}> = ({ title, category, description, icon, accent, onPlay }) => (
  <Card style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <div
        style={{
          width: 40,
          height: 40,
          borderRadius: 10,
          background: `${accent}15`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0,
        }}
      >
        {icon}
      </div>
      <div>
        <h3 style={{ fontSize: 16, fontWeight: 600 }}>{title}</h3>
        <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>{category}</span>
      </div>
    </div>
    <p style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{description}</p>
    <Button variant="secondary" onClick={onPlay} icon={<Play size={16} />} style={{ height: 42 }}>
      Start Exercise
    </Button>
  </Card>
);
