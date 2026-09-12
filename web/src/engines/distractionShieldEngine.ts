import type { TargetShape, TargetColor, GameStimulus } from '../types/game';

export interface FloatingDistraction {
  id: string;
  stimulus: GameStimulus;
  x: number;
  y: number;
}

export interface DistractionShieldRound {
  roundNumber: number;
  target: GameStimulus;
  fieldItems: GameStimulus[];
  floatingDistractions: FloatingDistraction[];
  fakeInstruction: string;
  realInstruction: string;
}

const SHAPES: TargetShape[] = ['circle', 'triangle', 'square', 'diamond', 'star'];
const COLORS: TargetColor[] = ['blue', 'red', 'green', 'yellow', 'purple', 'orange'];
const FAKE_ALERTS = [
  'ALERT: TAP THE RED CIRCLE!',
  'OVERRIDE: SWITCH TO BLUE!',
  'ATTENTION: TAP FLASHING OBJECT!',
  'NEW RULE: IGNORE SQUARES!',
  'SYSTEM PROMPT: TAP YELLOW!',
];

export class DistractionShieldEngine {
  generateRound(roundNumber: number, level: number): DistractionShieldRound {
    const targetShape = SHAPES[Math.floor(Math.random() * SHAPES.length)];
    const targetColor = COLORS[Math.floor(Math.random() * COLORS.length)];

    const target: GameStimulus = {
      id: `distract_target_${roundNumber}`,
      shape: targetShape,
      color: targetColor,
      isTarget: true,
      accessibleLabel: `${targetColor} ${targetShape}`,
    };

    const fieldCount = Math.min(16, Math.max(8, Math.round(6 + level * 1.2)));
    const fieldItems: GameStimulus[] = [target];

    for (let i = 1; i < fieldCount; i++) {
      const s = SHAPES[Math.floor(Math.random() * SHAPES.length)];
      let c = COLORS[Math.floor(Math.random() * COLORS.length)];
      if (s === targetShape && c === targetColor) {
        c = COLORS[(COLORS.indexOf(targetColor) + 1) % COLORS.length];
      }
      fieldItems.push({
        id: `field_distract_${roundNumber}_${i}`,
        shape: s,
        color: c,
        isTarget: false,
        accessibleLabel: `${c} ${s}`,
      });
    }
    fieldItems.sort(() => Math.random() - 0.5);

    const floatingCount = Math.min(5, Math.max(2, Math.round(1 + level * 0.6)));
    const floatingDistractions: FloatingDistraction[] = [];
    for (let i = 0; i < floatingCount; i++) {
      const s = SHAPES[Math.floor(Math.random() * SHAPES.length)];
      const c = COLORS[Math.floor(Math.random() * COLORS.length)];
      floatingDistractions.push({
        id: `float_${roundNumber}_${i}`,
        stimulus: {
          id: `float_stim_${roundNumber}_${i}`,
          shape: s,
          color: c,
          isTarget: false,
          accessibleLabel: `Floating ${c} ${s}`,
        },
        x: Math.random() * 80 + 10,
        y: Math.random() * 60 + 20,
      });
    }

    const fakeAlert = FAKE_ALERTS[Math.floor(Math.random() * FAKE_ALERTS.length)];

    return {
      roundNumber,
      target,
      fieldItems,
      floatingDistractions,
      fakeInstruction: fakeAlert,
      realInstruction: `REAL TARGET: ${targetColor.toUpperCase()} ${targetShape.toUpperCase()}`,
    };
  }
}
