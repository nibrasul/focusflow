import React from 'react';
import { soundManager } from '../services/audio';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary';
  icon?: React.ReactNode;
  loading?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  icon,
  loading = false,
  onClick,
  className = '',
  disabled,
  ...props
}) => {
  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    soundManager.playTap();
    if (onClick) onClick(e);
  };

  return (
    <button
      onClick={handleClick}
      disabled={disabled || loading}
      className={`${variant === 'primary' ? 'btn-primary' : 'btn-secondary'} ${className}`}
      {...props}
    >
      {loading ? (
        <span>Loading...</span>
      ) : (
        <>
          {icon && <span style={{ display: 'inline-flex', alignItems: 'center' }}>{icon}</span>}
          <span>{children}</span>
        </>
      )}
    </button>
  );
};
