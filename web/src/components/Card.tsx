import React from 'react';

interface CardProps {
  children: React.ReactNode;
  onClick?: () => void;
  className?: string;
  style?: React.CSSProperties;
}

export const Card: React.FC<CardProps> = ({ children, onClick, className = '', style }) => {
  return (
    <div
      onClick={onClick}
      className={`glass-card ${onClick ? 'glass-card-interactive' : ''} ${className}`}
      style={style}
    >
      {children}
    </div>
  );
};
