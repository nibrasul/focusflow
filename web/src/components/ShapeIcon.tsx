import React from 'react';
import type { GameStimulus } from '../types/game';

interface ShapeIconProps {
  stimulus: GameStimulus;
  size?: number;
  onClick?: () => void;
  highlighted?: boolean;
}

const COLOR_HEX_MAP: Record<string, string> = {
  blue: '#2563EB',
  red: '#DC2626',
  green: '#16A34A',
  yellow: '#CA8A04',
  purple: '#9333EA',
  orange: '#EA580C',
};

export const ShapeIcon: React.FC<ShapeIconProps> = ({
  stimulus,
  size = 60,
  onClick,
  highlighted = false,
}) => {
  const color = COLOR_HEX_MAP[stimulus.color] || '#2563EB';

  const renderShape = () => {
    switch (stimulus.shape) {
      case 'circle':
        return (
          <div
            style={{
              width: size * 0.72,
              height: size * 0.72,
              borderRadius: '50%',
              backgroundColor: color,
            }}
          />
        );
      case 'square':
        return (
          <div
            style={{
              width: size * 0.7,
              height: size * 0.7,
              borderRadius: 6,
              backgroundColor: color,
            }}
          />
        );
      case 'diamond':
        return (
          <div
            style={{
              width: size * 0.6,
              height: size * 0.6,
              borderRadius: 4,
              backgroundColor: color,
              transform: 'rotate(45deg)',
            }}
          />
        );
      case 'triangle':
        return (
          <svg width={size * 0.75} height={size * 0.75} viewBox="0 0 24 24">
            <polygon points="12,2 22,22 2,22" fill={color} />
          </svg>
        );
      case 'star':
        return (
          <svg width={size * 0.8} height={size * 0.8} viewBox="0 0 24 24">
            <polygon
              points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"
              fill={color}
            />
          </svg>
        );
      default:
        return null;
    }
  };

  return (
    <div
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      aria-label={stimulus.accessibleLabel}
      className="stimulus-box"
      style={{
        width: size,
        height: size,
        borderColor: highlighted ? 'var(--primary)' : 'var(--border)',
        borderWidth: highlighted ? 2.5 : 1,
      }}
    >
      {renderShape()}
    </div>
  );
};
