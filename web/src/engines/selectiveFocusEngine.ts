import type { TargetShape, TargetColor, GameStimulus } from '../types/game';

export interface SelectiveFocusRound {
  roundNumber: number;
  target: GameStimulus;
  items: GameStimulus[];
  instruction: string;
}

const SHAPES: TargetShape[] = ['circle', 'triangle', 'square', 'diamond', 'star'];
const COLORS: TargetColor[] = ['blue', 'red', 'green', 'yellow', 'purple', 'orange'];

export class SelectiveFocusEngine {
  generateRound(roundNumber: number, level: number): SelectiveFocusRound {
    const itemCount = Math.min(20, Math.max(6, Math.round(4 + level * 1.6)));

    const targetShape = SHAPES[Math.floor(Math.random() * SHAPES.length)];
    const targetColor = COLORS[Math.floor(Math.random() * COLORS.length)];

    const target: GameStimulus = {
      id: `target_${roundNumber}`,
      shape: targetShape,
      color: targetColor,
      isTarget: true,
      accessibleLabel: `${targetColor} ${targetShape}`,
    };

    const items: GameStimulus[] = [target];

    for (let i = 1; i < itemCount; i++) {
      let distractorShape: TargetShape;
      let distractorColor: TargetColor;

      const shareShape = Math.random() > 0.5 && level >= 2.5;
      const shareColor = Math.random() > 0.5 && level >= 3.5;

      if (shareShape) {
        distractorShape = targetShape;
        distractorColor = COLORS.filter(c => c !== targetColor)[Math.floor(Math.random() * (COLORS.length - 1))];
      } else if (shareColor) {
        distractorColor = targetColor;
        distractorShape = SHAPES.filter(s => s !== targetShape)[Math.floor(Math.random() * (SHAPES.length - 1))];
      } else {
        distractorShape = SHAPES[Math.floor(Math.random() * SHAPES.length)];
        distractorColor = COLORS[Math.floor(Math.random() * COLORS.length)];
        if (distractorShape === targetShape && distractorColor === targetColor) {
          distractorColor = COLORS[(COLORS.indexOf(targetColor) + 1) % COLORS.length];
        }
      }

      items.push({
        id: `distractor_${roundNumber}_${i}`,
        shape: distractorShape,
        color: distractorColor,
        isTarget: false,
        accessibleLabel: `${distractorColor} ${distractorShape}`,
      });
    }

    // Shuffle
    items.sort(() => Math.random() - 0.5);

    return {
      roundNumber,
      target,
      items,
      instruction: `Find & tap ${targetColor.toUpperCase()} ${targetShape.toUpperCase()}`,
    };
  }
}
