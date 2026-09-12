import type { TargetShape, TargetColor, GameStimulus } from '../types/game';

export interface SustainedTrial {
  stimulus: GameStimulus;
  isTarget: boolean;
  durationMs: number;
  isiMs: number;
}

const SHAPES: TargetShape[] = ['circle', 'triangle', 'square', 'diamond', 'star'];
const COLORS: TargetColor[] = ['blue', 'red', 'green', 'yellow', 'purple', 'orange'];

export class SustainedFocusEngine {
  readonly targetShape: TargetShape = 'star';
  readonly targetColor: TargetColor = 'blue';

  generateSequence(totalTrials: number, level: number): SustainedTrial[] {
    const targetProb = 0.32;
    const baseDuration = Math.max(750, Math.round(1400 - level * 65));
    const trials: SustainedTrial[] = [];

    for (let i = 0; i < totalTrials; i++) {
      const isTarget = Math.random() < targetProb;
      let stim: GameStimulus;

      if (isTarget) {
        stim = {
          id: `sustained_target_${i}`,
          shape: this.targetShape,
          color: this.targetColor,
          isTarget: true,
          accessibleLabel: `${this.targetColor} ${this.targetShape}`,
        };
      } else {
        let s = SHAPES[Math.floor(Math.random() * SHAPES.length)];
        let c = COLORS[Math.floor(Math.random() * COLORS.length)];
        if (s === this.targetShape && c === this.targetColor) {
          s = 'triangle';
        }
        stim = {
          id: `sustained_nontarget_${i}`,
          shape: s,
          color: c,
          isTarget: false,
          accessibleLabel: `${c} ${s}`,
        };
      }

      const isi = 600 + Math.floor(Math.random() * 500);

      trials.push({
        stimulus: stim,
        isTarget,
        durationMs: baseDuration,
        isiMs: isi,
      });
    }

    return trials;
  }
}
