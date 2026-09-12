import type { TargetShape, TargetColor, GameStimulus } from '../types/game';

export type RuleType = 'color' | 'shape' | 'negation';

export interface RuleSwitchRound {
  roundNumber: number;
  ruleType: RuleType;
  ruleDescription: string;
  targetCriterion: string;
  isSwitchTrial: boolean;
  choices: GameStimulus[];
  correctChoiceIndex: number;
}

const SHAPES: TargetShape[] = ['circle', 'triangle', 'square', 'diamond', 'star'];
const COLORS: TargetColor[] = ['blue', 'red', 'green', 'yellow', 'purple', 'orange'];

export class RuleSwitchEngine {
  private currentRule: RuleType = 'color';
  private trialsUnderRule: number = 0;

  generateRound(roundNumber: number, level: number): RuleSwitchRound {
    const shouldSwitch = this.trialsUnderRule >= 2 && (Math.random() > 0.5 || this.trialsUnderRule >= 3);
    const isSwitch = shouldSwitch || roundNumber === 1;

    if (isSwitch && roundNumber > 1) {
      const available: RuleType[] = ['color', 'shape'];
      if (level >= 3.0) available.push('negation');
      const filtered = available.filter(r => r !== this.currentRule);
      this.currentRule = filtered[Math.floor(Math.random() * filtered.length)];
      this.trialsUnderRule = 1;
    } else {
      this.trialsUnderRule++;
    }

    let ruleDescription = '';
    let targetCriterion = '';
    const choices: GameStimulus[] = [];

    if (this.currentRule === 'color') {
      const targetColor = COLORS[Math.floor(Math.random() * COLORS.length)];
      ruleDescription = 'RULE: MATCH COLOR';
      targetCriterion = `Tap ${targetColor.toUpperCase()}`;

      choices.push({
        id: `rs_${roundNumber}_0`,
        shape: SHAPES[Math.floor(Math.random() * SHAPES.length)],
        color: targetColor,
        isTarget: true,
        accessibleLabel: targetColor,
      });

      const wrong = COLORS.filter(c => c !== targetColor).sort(() => Math.random() - 0.5);
      for (let i = 0; i < 3; i++) {
        choices.push({
          id: `rs_${roundNumber}_${i + 1}`,
          shape: SHAPES[Math.floor(Math.random() * SHAPES.length)],
          color: wrong[i],
          isTarget: false,
          accessibleLabel: wrong[i],
        });
      }
    } else if (this.currentRule === 'shape') {
      const targetShape = SHAPES[Math.floor(Math.random() * SHAPES.length)];
      ruleDescription = 'RULE: MATCH SHAPE';
      targetCriterion = `Tap ${targetShape.toUpperCase()}`;

      choices.push({
        id: `rs_${roundNumber}_0`,
        shape: targetShape,
        color: COLORS[Math.floor(Math.random() * COLORS.length)],
        isTarget: true,
        accessibleLabel: targetShape,
      });

      const wrong = SHAPES.filter(s => s !== targetShape).sort(() => Math.random() - 0.5);
      for (let i = 0; i < 3; i++) {
        choices.push({
          id: `rs_${roundNumber}_${i + 1}`,
          shape: wrong[i],
          color: COLORS[Math.floor(Math.random() * COLORS.length)],
          isTarget: false,
          accessibleLabel: wrong[i],
        });
      }
    } else {
      const forbidden = COLORS[Math.floor(Math.random() * COLORS.length)];
      ruleDescription = 'RULE: INHIBITION';
      targetCriterion = `Tap NOT ${forbidden.toUpperCase()}`;

      const safe = COLORS.find(c => c !== forbidden) || 'blue';
      choices.push({
        id: `rs_${roundNumber}_0`,
        shape: SHAPES[Math.floor(Math.random() * SHAPES.length)],
        color: safe,
        isTarget: true,
        accessibleLabel: safe,
      });

      for (let i = 0; i < 3; i++) {
        choices.push({
          id: `rs_${roundNumber}_${i + 1}`,
          shape: SHAPES[Math.floor(Math.random() * SHAPES.length)],
          color: forbidden,
          isTarget: false,
          accessibleLabel: forbidden,
        });
      }
    }

    choices.sort(() => Math.random() - 0.5);
    const correctChoiceIndex = choices.findIndex(c => c.isTarget);

    return {
      roundNumber,
      ruleType: this.currentRule,
      ruleDescription,
      targetCriterion,
      isSwitchTrial: isSwitch,
      choices,
      correctChoiceIndex,
    };
  }
}
