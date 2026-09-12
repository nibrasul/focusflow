import type { TargetShape, TargetColor, GameStimulus } from '../types/game';

export interface MemoryFocusRound {
  roundNumber: number;
  sequenceLength: number;
  sequence: GameStimulus[];
  selectablePalette: GameStimulus[];
}

const SHAPES: TargetShape[] = ['circle', 'triangle', 'square', 'diamond', 'star'];
const COLORS: TargetColor[] = ['blue', 'red', 'green', 'yellow', 'purple', 'orange'];

export class MemoryFocusEngine {
  generateRound(roundNumber: number, level: number): MemoryFocusRound {
    let length = 3;
    if (level >= 7.0) length = 6;
    else if (level >= 5.0) length = 5;
    else if (level >= 3.0) length = 4;

    const palette: GameStimulus[] = [];
    const paletteSize = Math.min(6, length + 1);

    for (let i = 0; i < paletteSize; i++) {
      palette.push({
        id: `palette_${i}`,
        shape: SHAPES[i % SHAPES.length],
        color: COLORS[i % COLORS.length],
        accessibleLabel: `${COLORS[i % COLORS.length]} ${SHAPES[i % SHAPES.length]}`,
      });
    }

    const sequence: GameStimulus[] = [];
    for (let i = 0; i < length; i++) {
      sequence.push(palette[Math.floor(Math.random() * palette.length)]);
    }

    return {
      roundNumber,
      sequenceLength: length,
      sequence,
      selectablePalette: palette,
    };
  }
}
