import React from 'react';
import { Flame, Pause, ArrowLeft } from 'lucide-react';

interface FocusAppBarProps {
  title: string;
  onBack?: () => void;
  onPause?: () => void;
  score?: number;
  streak?: number;
}

export const FocusAppBar: React.FC<FocusAppBarProps> = ({
  title,
  onBack,
  onPause,
  score,
  streak,
}) => {
  return (
    <header
      style={{
        height: 56,
        padding: '0 16px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        borderBottom: '1px solid var(--border)',
        background: 'var(--surface-translucent)',
        backdropFilter: 'blur(10px)',
        position: 'sticky',
        top: 0,
        zIndex: 10,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        {onBack && (
          <button
            onClick={onBack}
            style={{
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              color: 'var(--text-primary)',
            }}
          >
            <ArrowLeft size={20} />
          </button>
        )}
        {onPause && (
          <button
            onClick={onPause}
            style={{
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              color: 'var(--text-primary)',
            }}
          >
            <Pause size={20} />
          </button>
        )}
        <h2 style={{ fontSize: 17, fontWeight: 600 }}>{title}</h2>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {streak !== undefined && streak > 0 && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 4,
              padding: '4px 8px',
              borderRadius: 8,
              background: 'var(--warning-light)',
              color: 'var(--warning)',
              fontSize: 12,
              fontWeight: 700,
            }}
          >
            <Flame size={14} />
            <span>{streak}</span>
          </div>
        )}
        {score !== undefined && (
          <div
            style={{
              padding: '4px 10px',
              borderRadius: 8,
              background: 'var(--primary-light)',
              color: 'var(--primary)',
              fontSize: 12,
              fontWeight: 700,
            }}
          >
            {score} pts
          </div>
        )}
      </div>
    </header>
  );
};
