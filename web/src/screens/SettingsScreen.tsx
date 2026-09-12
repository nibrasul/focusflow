import React, { useState, useEffect } from 'react';
import { ArrowLeft, Volume2, VolumeX, Eye, Server, RefreshCw, Trash2, CheckCircle, AlertTriangle, ShieldCheck } from 'lucide-react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { StorageService } from '../services/storage';
import type { WebSettings } from '../services/storage';
import { ApiClient } from '../services/api';
import { soundManager } from '../services/audio';

interface SettingsScreenProps {
  onBack: () => void;
}

export const SettingsScreen: React.FC<SettingsScreenProps> = ({ onBack }) => {
  const [settings, setSettings] = useState<WebSettings>(StorageService.getSettings());
  const [apiUrl, setApiUrl] = useState<string>(ApiClient.getBaseUrl());
  const [serverOnline, setServerOnline] = useState<boolean | null>(null);
  const [pendingSyncCount, setPendingSyncCount] = useState<number>(StorageService.getSyncQueue().length);
  const [syncing, setSyncing] = useState<boolean>(false);
  const [syncMessage, setSyncMessage] = useState<string | null>(null);

  useEffect(() => {
    checkServer();
  }, []);

  const checkServer = async () => {
    const isHealthy = await ApiClient.checkHealth();
    setServerOnline(isHealthy);
  };

  const handleToggleSound = () => {
    const newVal = !settings.soundEnabled;
    const updated = { ...settings, soundEnabled: newVal };
    setSettings(updated);
    StorageService.saveSettings({ soundEnabled: newVal });
    soundManager.setEnabled(newVal);
    if (newVal) soundManager.playHit();
  };

  const handleToggleMotion = () => {
    const newVal = !settings.reduceMotion;
    const updated = { ...settings, reduceMotion: newVal };
    setSettings(updated);
    StorageService.saveSettings({ reduceMotion: newVal });
  };

  const handleSaveApiUrl = () => {
    ApiClient.setBaseUrl(apiUrl);
    checkServer();
  };

  const handleSyncNow = async () => {
    setSyncing(true);
    setSyncMessage(null);
    const count = await StorageService.syncPendingQueue();
    setPendingSyncCount(StorageService.getSyncQueue().length);
    setSyncMessage(`Successfully synced ${count} sessions to the backend!`);
    setSyncing(false);
  };

  const handleResetData = () => {
    if (window.confirm('Are you sure you want to reset all local training history? This cannot be undone.')) {
      localStorage.clear();
      window.location.reload();
    }
  };

  return (
    <div style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: 20, minHeight: '100vh' }}>
      {/* Top Bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <button
          onClick={onBack}
          style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', color: 'var(--text-primary)' }}
        >
          <ArrowLeft size={22} />
        </button>
        <h1 style={{ fontSize: 20, fontWeight: 700, margin: 0 }}>Settings</h1>
      </div>

      {/* Preferences Section */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', letterSpacing: 0.5 }}>PREFERENCES</span>
        <Card style={{ padding: '4px 16px' }}>
          {/* Sound FX */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 0', borderBottom: '1px solid var(--border)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              {settings.soundEnabled ? <Volume2 size={20} color="var(--primary)" /> : <VolumeX size={20} color="var(--text-muted)" />}
              <div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>Synthesized Audio FX</div>
                <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Zero-latency Web Audio stimuli feedback</div>
              </div>
            </div>
            <input
              type="checkbox"
              checked={settings.soundEnabled}
              onChange={handleToggleSound}
              style={{ width: 18, height: 18, cursor: 'pointer', accentColor: 'var(--primary)' }}
            />
          </div>

          {/* Reduce Motion */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 0' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Eye size={20} color="var(--primary)" />
              <div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>Reduce Motion</div>
                <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Minimize distractor flutters and UI animations</div>
              </div>
            </div>
            <input
              type="checkbox"
              checked={settings.reduceMotion}
              onChange={handleToggleMotion}
              style={{ width: 18, height: 18, cursor: 'pointer', accentColor: 'var(--primary)' }}
            />
          </div>
        </Card>
      </div>

      {/* Server & Connectivity */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', letterSpacing: 0.5 }}>BACKEND CONNECTIVITY</span>
        <Card style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Server size={18} color="var(--primary)" />
              <span style={{ fontSize: 13, fontWeight: 600 }}>FastAPI Server Status</span>
            </div>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                fontSize: 11,
                fontWeight: 700,
                color: serverOnline ? 'var(--success)' : 'var(--danger)',
                background: serverOnline ? '#F0FDF4' : '#FEF2F2',
                padding: '4px 8px',
                borderRadius: 12,
              }}
            >
              {serverOnline ? <CheckCircle size={12} /> : <AlertTriangle size={12} />}
              {serverOnline === null ? 'Checking...' : serverOnline ? 'Online' : 'Offline / Unreachable'}
            </div>
          </div>

          <div>
            <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: 6 }}>
              API Base URL
            </label>
            <div style={{ display: 'flex', gap: 8 }}>
              <input
                type="text"
                value={apiUrl}
                onChange={(e) => setApiUrl(e.target.value)}
                style={{
                  flex: 1,
                  padding: '8px 12px',
                  borderRadius: 8,
                  border: '1px solid var(--border)',
                  fontSize: 13,
                  outline: 'none',
                  fontFamily: 'monospace',
                }}
              />
              <Button variant="secondary" onClick={handleSaveApiUrl} style={{ padding: '8px 14px', fontSize: 12 }}>
                Save
              </Button>
            </div>
          </div>

          {/* Sync Queue */}
          <div style={{ paddingTop: 10, borderTop: '1px solid var(--border)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>Offline Sync Queue</div>
                <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
                  {pendingSyncCount === 0 ? 'All sessions synced with backend.' : `${pendingSyncCount} session(s) pending sync.`}
                </div>
              </div>
              <Button
                variant="primary"
                onClick={handleSyncNow}
                disabled={syncing || pendingSyncCount === 0}
                style={{ fontSize: 12, padding: '6px 12px', display: 'flex', alignItems: 'center', gap: 6 }}
              >
                <RefreshCw size={14} className={syncing ? 'spin' : ''} />
                {syncing ? 'Syncing...' : 'Sync Now'}
              </Button>
            </div>
            {syncMessage && (
              <div style={{ fontSize: 11, color: 'var(--success)', fontWeight: 600 }}>{syncMessage}</div>
            )}
          </div>
        </Card>
      </div>

      {/* Accessibility & Science Compliance */}
      <Card style={{ padding: '14px 16px', borderLeft: '4px solid var(--primary)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
          <ShieldCheck size={18} color="var(--primary)" />
          <h4 style={{ fontSize: 13, fontWeight: 700, margin: 0 }}>Science & Accessibility Standards</h4>
        </div>
        <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0, lineHeight: 1.5 }}>
          Stimuli are engineered using dual-channel redundancy (distinct geometric contour + high-contrast color + accessible semantic labels) ensuring strict compliance for color vision deficiencies.
        </p>
      </Card>

      {/* Danger Zone */}
      <div style={{ marginTop: 'auto', paddingTop: 20 }}>
        <Button
          variant="secondary"
          onClick={handleResetData}
          style={{ width: '100%', color: 'var(--danger)', borderColor: 'var(--danger-light)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
        >
          <Trash2 size={16} />
          Reset Local Training Data
        </Button>
      </div>
    </div>
  );
};
