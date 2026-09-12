import type { DashboardResponse, AchievementRecord } from '../types/api';

const DEFAULT_API_BASE = 'https://focusflow-9iqs.onrender.com/api/v1';

export class ApiClient {
  static getBaseUrl(): string {
    return localStorage.getItem('focusflow_api_url') || DEFAULT_API_BASE;
  }

  static setBaseUrl(url: string): void {
    localStorage.setItem('focusflow_api_url', url);
  }

  static async checkHealth(): Promise<boolean> {
    try {
      const res = await fetch(`${this.getBaseUrl()}/health`, { method: 'GET' });
      return res.ok;
    } catch {
      return false;
    }
  }

  static async getDashboard(): Promise<DashboardResponse | null> {
    try {
      const res = await fetch(`${this.getBaseUrl()}/dashboard`);
      if (res.ok) {
        return await res.json();
      }
      return null;
    } catch {
      return null;
    }
  }

  static async getAchievements(): Promise<AchievementRecord[] | null> {
    try {
      const res = await fetch(`${this.getBaseUrl()}/achievements`);
      if (res.ok) {
        return await res.json();
      }
      return null;
    } catch {
      return null;
    }
  }

  static async createSession(data: any): Promise<any> {
    try {
      const res = await fetch(`${this.getBaseUrl()}/sessions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (res.ok) return await res.json();
      return null;
    } catch {
      return null;
    }
  }

  static async completeSession(sessionId: string, data: any): Promise<any> {
    try {
      const res = await fetch(`${this.getBaseUrl()}/sessions/${sessionId}/complete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (res.ok) return await res.json();
      return null;
    } catch {
      return null;
    }
  }
}
