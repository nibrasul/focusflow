import React from 'react';

interface StatPillProps {
  label: string;
  value: string;
  icon?: React.ReactNode;
  color?: string;
}

export const StatPill: React.FC<StatPillProps> = ({
  label,
  value,
  icon,
  color = 'var(--primary)',
}) => {
  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 8,
        padding: '6px 12px',
        borderRadius: 10,
        background: 'var(--surface)',
        border: '1px solid var(--border)',
      }}
    >
      {icon && <span style={{ color, display: 'flex', alignItems: 'center' }}>{icon}</span>}
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        <span style={{ fontSize: 10, color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>
          {label}
        </span>
        <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>
          {value}
        </span>
      </div>
    </div>
  );
};
