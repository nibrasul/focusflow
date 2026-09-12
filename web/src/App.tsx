import React, { useState, useEffect } from 'react';
import { StorageService } from './services/storage';
import type { SessionRecord } from './types/game';

// Screens
import { OnboardingScreen } from './screens/OnboardingScreen';
import { DashboardScreen } from './screens/DashboardScreen';
import { TrainingSelectScreen } from './screens/TrainingSelectScreen';
import { GameScreen } from './screens/GameScreen';
import { SessionResultScreen } from './screens/SessionResultScreen';
import { ProgressScreen } from './screens/ProgressScreen';
import { AchievementsScreen } from './screens/AchievementsScreen';
import { SettingsScreen } from './screens/SettingsScreen';

type Screen =
  | 'onboarding'
  | 'dashboard'
  | 'training_select'
  | 'game'
  | 'result'
  | 'progress'
  | 'achievements'
  | 'settings';

export const App: React.FC = () => {
  const [screen, setScreen] = useState<Screen>(() => {
    const settings = StorageService.getSettings();
    return settings.onboardingCompleted ? 'dashboard' : 'onboarding';
  });

  const [activeGameMode, setActiveGameMode] = useState<string>('selective');
  const [activeLevel, setActiveLevel] = useState<number>(1.0);
  const [lastSession, setLastSession] = useState<SessionRecord | null>(null);
  const [lastSyncStatus, setLastSyncStatus] = useState<boolean>(false);

  // Background sync check on mount
  useEffect(() => {
    StorageService.syncPendingQueue();
  }, []);

  const handleStartGame = (mode: string, level: number) => {
    setActiveGameMode(mode);
    setActiveLevel(level);
    setScreen('game');
  };

  const handleGameFinish = (session: SessionRecord, syncResult: { synced: boolean }) => {
    setLastSession(session);
    setLastSyncStatus(syncResult.synced);
    setScreen('result');
  };

  const handleTrainAgain = () => {
    if (lastSession) {
      handleStartGame(lastSession.gameMode, lastSession.level);
    } else {
      setScreen('dashboard');
    }
  };

  return (
    <div style={{ width: '100%', minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {screen === 'onboarding' && (
        <OnboardingScreen onDone={() => setScreen('dashboard')} />
      )}

      {screen === 'dashboard' && (
        <DashboardScreen
          onStartTraining={handleStartGame}
          onOpenTrainingSelect={() => setScreen('training_select')}
          onOpenProgress={() => setScreen('progress')}
          onOpenAchievements={() => setScreen('achievements')}
          onOpenSettings={() => setScreen('settings')}
        />
      )}

      {screen === 'training_select' && (
        <TrainingSelectScreen
          initialLevel={activeLevel}
          onBack={() => setScreen('dashboard')}
          onStartGame={handleStartGame}
        />
      )}

      {screen === 'game' && (
        <GameScreen
          gameMode={activeGameMode}
          level={activeLevel}
          onFinish={handleGameFinish}
          onQuit={() => setScreen('dashboard')}
        />
      )}

      {screen === 'result' && lastSession && (
        <SessionResultScreen
          session={lastSession}
          synced={lastSyncStatus}
          onTrainAgain={handleTrainAgain}
          onGoHome={() => setScreen('dashboard')}
        />
      )}

      {screen === 'progress' && (
        <ProgressScreen onBack={() => setScreen('dashboard')} />
      )}

      {screen === 'achievements' && (
        <AchievementsScreen onBack={() => setScreen('dashboard')} />
      )}

      {screen === 'settings' && (
        <SettingsScreen onBack={() => setScreen('dashboard')} />
      )}
    </div>
  );
};

export default App;
