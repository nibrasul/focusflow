import React, { useState, useRef } from 'react';
import { FocusAppBar } from '../components/FocusAppBar';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { ShapeIcon } from '../components/ShapeIcon';
import { soundManager } from '../services/audio';
import { LocalScoring } from '../services/localScoring';
import { StorageService } from '../services/storage';
import type { AttemptRecord, SessionRecord, GameStimulus } from '../types/game';

import { SelectiveFocusEngine } from '../engines/selectiveFocusEngine';
import type { SelectiveFocusRound } from '../engines/selectiveFocusEngine';
import { SustainedFocusEngine } from '../engines/sustainedFocusEngine';
import type { SustainedTrial } from '../engines/sustainedFocusEngine';
import { DistractionShieldEngine } from '../engines/distractionShieldEngine';
import type { DistractionShieldRound } from '../engines/distractionShieldEngine';
import { RuleSwitchEngine } from '../engines/ruleSwitchEngine';
import type { RuleSwitchRound } from '../engines/ruleSwitchEngine';
import { MemoryFocusEngine } from '../engines/memoryFocusEngine';
import type { MemoryFocusRound } from '../engines/memoryFocusEngine';

interface GameScreenProps {
  gameMode: string;
  level: number;
  onFinish: (session: SessionRecord, syncResult: { synced: boolean }) => void;
  onQuit: () => void;
}

type Phase = 'instruction' | 'countdown' | 'playing' | 'paused' | 'feedback';

export const GameScreen: React.FC<GameScreenProps> = ({
  gameMode,
  level,
  onFinish,
  onQuit,
}) => {
  const [phase, setPhase] = useState<Phase>('instruction');
  const [countdown, setCountdown] = useState<number>(3);
  const [currentRound, setCurrentRound] = useState<number>(1);
  const maxRounds = 10;

  const [score, setScore] = useState<number>(0);
  const [streak, setStreak] = useState<number>(0);
  const [attempts, setAttempts] = useState<AttemptRecord[]>([]);

  // Performance timers
  const startTimeRef = useRef<number>(0);
  const roundStartTimeRef = useRef<number>(0);
  const sessionIdRef = useRef<string>(`session_${Date.now()}`);

  // Engine instances
  const selectiveEngine = useRef(new SelectiveFocusEngine()).current;
  const sustainedEngine = useRef(new SustainedFocusEngine()).current;
  const distractionEngine = useRef(new DistractionShieldEngine()).current;
  const ruleSwitchEngine = useRef(new RuleSwitchEngine()).current;
  const memoryEngine = useRef(new MemoryFocusEngine()).current;

  // Round states
  const [selectiveData, setSelectiveData] = useState<SelectiveFocusRound | null>(null);
  const sustainedTrialsRef = useRef<SustainedTrial[]>([]);
  const sustainedIndexRef = useRef<number>(0);
  const [currentSustainedStim, setCurrentSustainedStim] = useState<SustainedTrial | null>(null);
  const [distractionData, setDistractionData] = useState<DistractionShieldRound | null>(null);
  const [ruleSwitchData, setRuleSwitchData] = useState<RuleSwitchRound | null>(null);
  const [memoryData, setMemoryData] = useState<MemoryFocusRound | null>(null);
  const [memoryShowing, setMemoryShowing] = useState<boolean>(true);
  const [memoryPresentIdx, setMemoryPresentIdx] = useState<number>(0);
  const [memoryInput, setMemoryInput] = useState<GameStimulus[]>([]);

  const [feedback, setFeedback] = useState<{ correct: boolean; msg: string } | null>(null);
  const [instructionText, setInstructionText] = useState<string>('');

  const getEffectiveMode = (rnd: number): string => {
    if (gameMode !== 'daily') return gameMode;
    const modes = ['selective', 'sustained', 'distraction_shield', 'rule_switch', 'memory'];
    return modes[(rnd - 1) % modes.length];
  };

  const startCountdown = () => {
    setPhase('countdown');
    setCountdown(3);
    soundManager.playTap();

    let c = 3;
    const interval = setInterval(() => {
      c--;
      if (c > 0) {
        setCountdown(c);
        soundManager.playTap();
      } else {
        clearInterval(interval);
        beginGameplay();
      }
    }, 1000);
  };

  const beginGameplay = () => {
    startTimeRef.current = performance.now();
    setCurrentRound(1);
    setPhase('playing');
    loadRound(1);
  };

  const loadRound = (rnd: number) => {
    const mode = getEffectiveMode(rnd);
    setFeedback(null);

    if (mode === 'selective') {
      const data = selectiveEngine.generateRound(rnd, level);
      setSelectiveData(data);
      setInstructionText(data.instruction);
      roundStartTimeRef.current = performance.now();
    } else if (mode === 'sustained') {
      const seq = sustainedEngine.generateSequence(maxRounds, level);
      sustainedTrialsRef.current = seq;
      sustainedIndexRef.current = 0;
      setInstructionText('Tap TARGET HIT only when a Star appears!');
      startSustainedStream(seq, 0);
    } else if (mode === 'distraction_shield') {
      const data = distractionEngine.generateRound(rnd, level);
      setDistractionData(data);
      setInstructionText(data.realInstruction);
      roundStartTimeRef.current = performance.now();
    } else if (mode === 'rule_switch') {
      const data = ruleSwitchEngine.generateRound(rnd, level);
      setRuleSwitchData(data);
      setInstructionText(`${data.ruleDescription} (${data.targetCriterion})`);
      roundStartTimeRef.current = performance.now();
    } else if (mode === 'memory') {
      const data = memoryEngine.generateRound(rnd, level);
      setMemoryData(data);
      setMemoryInput([]);
      setMemoryShowing(true);
      setMemoryPresentIdx(0);
      setInstructionText(`Memorize the sequence (${data.sequenceLength} items)`);
      presentMemorySequence(data);
    }
  };

  // --- Mode 1: Selective Focus ---
  const handleSelectiveTap = (stim: GameStimulus) => {
    if (phase !== 'playing') return;
    const rt = Math.round(performance.now() - roundStartTimeRef.current);
    const correct = Boolean(stim.isTarget);
    recordAttempt(
      `${selectiveData?.target.color} ${selectiveData?.target.shape}`,
      'hit',
      correct,
      rt,
      false
    );
    showFeedback(correct, correct ? 'Target located!' : 'Incorrect object selected');
  };

  // --- Mode 2: Sustained Focus ---
  const startSustainedStream = (seq: SustainedTrial[], idx: number) => {
    if (idx >= seq.length) {
      finishSession();
      return;
    }
    const trial = seq[idx];
    setCurrentSustainedStim(trial);
    roundStartTimeRef.current = performance.now();

    const timer = setTimeout(() => {
      // Time window elapsed
      if (trial.isTarget) {
        // Miss (omission)
        recordAttempt('STAR', 'miss', false, trial.durationMs, false);
        soundManager.playError();
      } else {
        // Correct withheld response
        recordAttempt(trial.stimulus.shape, 'withheld', true, trial.durationMs, false);
      }
      setCurrentSustainedStim(null);

      setTimeout(() => {
        sustainedIndexRef.current = idx + 1;
        setCurrentRound(idx + 2);
        startSustainedStream(seq, idx + 1);
      }, trial.isiMs);
    }, trial.durationMs);

    return () => clearTimeout(timer);
  };

  const handleSustainedTrigger = () => {
    if (phase !== 'playing' || !currentSustainedStim) return;
    const rt = Math.round(performance.now() - roundStartTimeRef.current);
    const correct = currentSustainedStim.isTarget;

    recordAttempt(
      currentSustainedStim.stimulus.shape,
      'hit',
      correct,
      rt,
      !currentSustainedStim.isTarget
    );

    if (correct) soundManager.playSuccess();
    else soundManager.playError();
    setCurrentSustainedStim(null);
  };

  // --- Mode 3: Distraction Shield ---
  const handleDistractionTap = (stim: GameStimulus) => {
    if (phase !== 'playing') return;
    const rt = Math.round(performance.now() - roundStartTimeRef.current);
    const correct = Boolean(stim.isTarget);
    recordAttempt(
      `${distractionData?.target.color} ${distractionData?.target.shape}`,
      correct ? 'hit' : 'distraction_error',
      correct,
      rt,
      true
    );
    showFeedback(
      correct,
      correct ? 'Shield held! Focused on true target.' : 'Distraction captured your attention!'
    );
  };

  // --- Mode 4: Rule Switch ---
  const handleRuleSwitchChoice = (idx: number) => {
    if (phase !== 'playing' || !ruleSwitchData) return;
    const rt = Math.round(performance.now() - roundStartTimeRef.current);
    const correct = idx === ruleSwitchData.correctChoiceIndex;
    recordAttempt(
      ruleSwitchData.ruleDescription,
      'hit',
      correct,
      rt,
      ruleSwitchData.isSwitchTrial
    );
    showFeedback(correct, correct ? 'Rule matched!' : 'Incorrect rule match');
  };

  // --- Mode 5: Memory Focus ---
  const presentMemorySequence = (round: MemoryFocusRound) => {
    let idx = 0;
    const interval = setInterval(() => {
      idx++;
      if (idx < round.sequence.length) {
        setMemoryPresentIdx(idx);
        soundManager.playTap();
      } else {
        clearInterval(interval);
        setTimeout(() => {
          setMemoryShowing(false);
          setInstructionText('Reproduce the sequence in exact order');
          roundStartTimeRef.current = performance.now();
        }, 600);
      }
    }, 850);
  };

  const handleMemoryInputTap = (stim: GameStimulus) => {
    if (phase !== 'playing' || memoryShowing || !memoryData) return;
    soundManager.playTap();
    const updated = [...memoryInput, stim];
    setMemoryInput(updated);

    if (updated.length === memoryData.sequenceLength) {
      const rt = Math.round(performance.now() - roundStartTimeRef.current);
      let allCorrect = true;
      for (let i = 0; i < memoryData.sequenceLength; i++) {
        if (
          updated[i].shape !== memoryData.sequence[i].shape ||
          updated[i].color !== memoryData.sequence[i].color
        ) {
          allCorrect = false;
          break;
        }
      }
      recordAttempt(
        `MEMORY_${memoryData.sequenceLength}`,
        'recall',
        allCorrect,
        rt,
        false
      );
      showFeedback(allCorrect, allCorrect ? 'Perfect recall!' : 'Sequence did not match');
    }
  };

  // --- General Attempt Logger ---
  const recordAttempt = (
    targetType: string,
    playerAction: string,
    correct: boolean,
    reactionTime: number,
    distractionPresent: boolean
  ) => {
    const attempt: AttemptRecord = {
      id: `att_${Date.now()}_${Math.random()}`,
      sessionId: sessionIdRef.current,
      roundNumber: currentRound,
      targetType,
      playerAction,
      correct,
      reactionTime,
      distractionPresent,
      timestamp: new Date().toISOString(),
    };

    const newAttempts = [...attempts, attempt];
    setAttempts(newAttempts);

    if (correct) {
      setStreak((prev) => prev + 1);
    } else {
      setStreak(0);
    }

    const calc = LocalScoring.calculate(newAttempts, level);
    setScore(calc.score);
  };

  const showFeedback = (correct: boolean, msg: string) => {
    if (correct) soundManager.playSuccess();
    else soundManager.playError();

    setPhase('feedback');
    setFeedback({ correct, msg });

    setTimeout(() => {
      if (currentRound < maxRounds) {
        setCurrentRound((prev) => prev + 1);
        setPhase('playing');
        loadRound(currentRound + 1);
      } else {
        finishSession();
      }
    }, 650);
  };

  const finishSession = async () => {
    const duration = Math.max(1, Math.round((performance.now() - startTimeRef.current) / 1000));
    const calc = LocalScoring.calculate(attempts, level);

    const session: SessionRecord = {
      id: sessionIdRef.current,
      userId: 'default_user',
      gameMode,
      startedAt: new Date(Date.now() - duration * 1000).toISOString(),
      completedAt: new Date().toISOString(),
      duration,
      level,
      score: calc.score,
      accuracy: calc.accuracy,
      averageReactionTime: calc.averageReactionTime,
      missedTargets: calc.missedTargets,
      incorrectTargets: calc.incorrectTargets,
      distractionErrors: calc.distractionErrors,
      longestStreak: calc.longestStreak,
      isSynced: false,
      attempts,
    };

    const syncRes = await StorageService.saveAndSyncSession(session);
    onFinish(session, syncRes);
  };

  const getModeTitle = () => {
    switch (gameMode) {
      case 'selective': return 'Selective Focus';
      case 'sustained': return 'Sustained Focus';
      case 'distraction_shield': return 'Distraction Shield';
      case 'rule_switch': return 'Rule Switch';
      case 'memory': return 'Memory Focus';
      case 'daily': return 'Daily Training';
      default: return 'Attention Training';
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', position: 'relative' }}>
      <FocusAppBar
        title={getModeTitle()}
        score={score}
        streak={streak}
        onPause={phase === 'playing' ? () => setPhase('paused') : undefined}
      />

      {/* Instruction & Feedback Banner */}
      <div style={{ padding: '12px 16px' }}>
        <div
          style={{
            padding: '12px 16px',
            borderRadius: 12,
            border: `1px solid ${feedback ? (feedback.correct ? 'var(--success)' : 'var(--error)') : 'var(--border)'}`,
            background: feedback
              ? (feedback.correct ? 'var(--success-light)' : 'var(--error-light)')
              : 'var(--surface)',
            fontSize: 14,
            fontWeight: 600,
            color: feedback
              ? (feedback.correct ? 'var(--success)' : 'var(--error)')
              : 'var(--text-primary)',
            display: 'flex',
            alignItems: 'center',
            gap: 10,
          }}
        >
          <span>{feedback ? feedback.msg : instructionText}</span>
        </div>
      </div>

      {/* Dynamic Content by Mode */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '16px' }}>
        {getEffectiveMode(currentRound) === 'selective' && selectiveData && (
          <div
            style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: 14,
              justifyContent: 'center',
              alignItems: 'center',
              maxWidth: 420,
              margin: '0 auto',
            }}
          >
            {selectiveData.items.map((stim) => (
              <ShapeIcon
                key={stim.id}
                stimulus={stim}
                size={64}
                onClick={() => handleSelectiveTap(stim)}
              />
            ))}
          </div>
        )}

        {getEffectiveMode(currentRound) === 'sustained' && (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40, flex: 1, justifyContent: 'center' }}>
            <div style={{ height: 120, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {currentSustainedStim ? (
                <ShapeIcon stimulus={currentSustainedStim.stimulus} size={100} />
              ) : (
                <div style={{ width: 24, height: 24, borderRadius: '50%', background: 'var(--border)' }} />
              )}
            </div>
            <div style={{ width: '100%', maxWidth: 320 }}>
              <Button
                onClick={handleSustainedTrigger}
                style={{ height: 60, fontSize: 18, fontWeight: 700, letterSpacing: 0.5 }}
              >
                TARGET HIT (Spacebar)
              </Button>
            </div>
          </div>
        )}

        {getEffectiveMode(currentRound) === 'distraction_shield' && distractionData && (
          <div style={{ position: 'relative', width: '100%', minHeight: 340, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            {/* Fake alert */}
            <div
              style={{
                background: 'var(--warning-light)',
                border: '1px solid var(--warning)',
                color: 'var(--warning)',
                padding: '8px 14px',
                borderRadius: 8,
                fontSize: 12,
                fontWeight: 700,
                marginBottom: 20,
              }}
            >
              {distractionData.fakeInstruction}
            </div>

            {/* Field items */}
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 14, justifyContent: 'center', maxWidth: 380 }}>
              {distractionData.fieldItems.map((stim) => (
                <ShapeIcon
                  key={stim.id}
                  stimulus={stim}
                  size={58}
                  onClick={() => handleDistractionTap(stim)}
                />
              ))}
            </div>

            {/* Drifting floating distractors */}
            {distractionData.floatingDistractions.map((fl) => (
              <div
                key={fl.id}
                className="animate-drift"
                style={{
                  position: 'absolute',
                  left: `${fl.x}%`,
                  top: `${fl.y}%`,
                  opacity: 0.7,
                  pointerEvents: 'auto',
                }}
              >
                <ShapeIcon
                  stimulus={fl.stimulus}
                  size={42}
                  onClick={() => handleDistractionTap(fl.stimulus)}
                />
              </div>
            ))}
          </div>
        )}

        {getEffectiveMode(currentRound) === 'rule_switch' && ruleSwitchData && (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24 }}>
            {ruleSwitchData.isSwitchTrial && (
              <span
                style={{
                  background: 'var(--primary-light)',
                  color: 'var(--primary)',
                  padding: '4px 12px',
                  borderRadius: 16,
                  fontSize: 12,
                  fontWeight: 700,
                }}
              >
                RULE SWITCHED!
              </span>
            )}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              {ruleSwitchData.choices.map((stim, idx) => (
                <ShapeIcon
                  key={stim.id}
                  stimulus={stim}
                  size={76}
                  onClick={() => handleRuleSwitchChoice(idx)}
                />
              ))}
            </div>
          </div>
        )}

        {getEffectiveMode(currentRound) === 'memory' && memoryData && (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 32 }}>
            {memoryShowing ? (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
                <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>
                  Item {memoryPresentIdx + 1} of {memoryData.sequenceLength}
                </span>
                <ShapeIcon stimulus={memoryData.sequence[memoryPresentIdx]} size={96} />
              </div>
            ) : (
              <>
                <div style={{ display: 'flex', gap: 10 }}>
                  {Array.from({ length: memoryData.sequenceLength }).map((_, i) => (
                    <div
                      key={i}
                      style={{
                        width: 20,
                        height: 20,
                        borderRadius: '50%',
                        background: i < memoryInput.length ? 'var(--primary)' : 'var(--border)',
                      }}
                    />
                  ))}
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 14, justifyContent: 'center', maxWidth: 360 }}>
                  {memoryData.selectablePalette.map((stim) => (
                    <ShapeIcon
                      key={stim.id}
                      stimulus={stim}
                      size={64}
                      onClick={() => handleMemoryInputTap(stim)}
                    />
                  ))}
                </div>
              </>
            )}
          </div>
        )}
      </div>

      {/* Footer Round Indicator */}
      <footer
        style={{
          padding: '12px 20px',
          borderTop: '1px solid var(--border)',
          background: 'var(--surface)',
          display: 'flex',
          justifyContent: 'space-between',
          fontSize: 13,
          fontWeight: 700,
        }}
      >
        <span>ROUND {currentRound} / {maxRounds}</span>
        <span style={{ color: 'var(--primary)' }}>LEVEL {level.toFixed(1)}</span>
      </footer>

      {/* Instruction Overlay */}
      {phase === 'instruction' && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: 'rgba(0, 0, 0, 0.4)',
            backdropFilter: 'blur(4px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 20,
            zIndex: 20,
          }}
        >
          <Card style={{ background: '#ffffff', maxWidth: 400, width: '100%', padding: 24 }}>
            <h2 style={{ fontSize: 20, fontWeight: 700, marginBottom: 12 }}>{getModeTitle()}</h2>
            <p style={{ fontSize: 14, color: 'var(--text-secondary)', lineHeight: 1.5, marginBottom: 24 }}>
              Respond accurately and promptly. Reaction latency is tracked with high precision from stimulus rendering to actual touch.
            </p>
            <Button onClick={startCountdown}>Begin Round</Button>
          </Card>
        </div>
      )}

      {/* 3-2-1 Countdown Overlay */}
      {phase === 'countdown' && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: 'rgba(255, 255, 255, 0.92)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 30,
          }}
        >
          <span style={{ fontSize: 96, fontWeight: 800, color: 'var(--primary)' }}>{countdown}</span>
        </div>
      )}

      {/* Pause Overlay */}
      {phase === 'paused' && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: 'rgba(0, 0, 0, 0.4)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 20,
            zIndex: 40,
          }}
        >
          <Card style={{ background: '#ffffff', maxWidth: 340, width: '100%', textAlign: 'center', padding: 24 }}>
            <h3 style={{ fontSize: 20, fontWeight: 700, marginBottom: 16 }}>Session Paused</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <Button onClick={() => setPhase('playing')}>Resume</Button>
              <Button variant="secondary" onClick={onQuit}>Quit Training</Button>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
};
