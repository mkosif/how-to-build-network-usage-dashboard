import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { UsageHistoryRecord } from '../models/NetworkModel';
import { SettingsModel } from '../models/SettingsModel';

const DOMAIN = 0x0001;
const TAG = 'StorageService';
const STORE_NAME = 'net_usage_prefs';
const KEY_HISTORY = 'usage_history';
const KEY_LIMIT_MB = 'usageLimitMB';
const KEY_INTERVAL_SEC = 'refreshIntervalSec';
const KEY_NOTIFICATIONS = 'notificationsEnabled';
const MAX_HISTORY_DAYS = 7;

export class StorageService {
  private static instance: StorageService | null = null;
  private store: preferences.Preferences | null = null;
  private context: common.UIAbilityContext | null = null;

  static getInstance(): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService();
    }
    return StorageService.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    try {
      this.store = await preferences.getPreferences(context, STORE_NAME);
      hilog.info(DOMAIN, TAG, 'Preferences store initialized');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize preferences: %{public}s', JSON.stringify(err));
    }
  }

  async getSettings(): Promise<SettingsModel> {
    const s = new SettingsModel();
    if (!this.store) {
      hilog.error(DOMAIN, TAG, 'getSettings called before init');
      return s;
    }
    try {
      s.usageLimitMB = (await this.store.get(KEY_LIMIT_MB, s.usageLimitMB)) as number;
      s.refreshIntervalSec = (await this.store.get(KEY_INTERVAL_SEC, s.refreshIntervalSec)) as number;
      s.notificationsEnabled = (await this.store.get(KEY_NOTIFICATIONS, s.notificationsEnabled)) as boolean;
      hilog.info(DOMAIN, TAG, 'Settings loaded: limit=%{public}d MB', s.usageLimitMB);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to load settings: %{public}s', JSON.stringify(err));
    }
    return s;
  }

  async saveSettings(s: SettingsModel): Promise<void> {
    if (!this.store) {
      hilog.error(DOMAIN, TAG, 'saveSettings called before init');
      return;
    }
    try {
      await this.store.put(KEY_LIMIT_MB, s.usageLimitMB);
      await this.store.put(KEY_INTERVAL_SEC, s.refreshIntervalSec);
      await this.store.put(KEY_NOTIFICATIONS, s.notificationsEnabled);
      await this.store.flush();
      hilog.info(DOMAIN, TAG, 'Settings saved: limit=%{public}d MB', s.usageLimitMB);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to save settings: %{public}s', JSON.stringify(err));
    }
  }

  async getUsageHistory(): Promise<UsageHistoryRecord[]> {
    if (!this.store) {
      hilog.error(DOMAIN, TAG, 'getUsageHistory called before init');
      return [];
    }
    try {
      const raw = (await this.store.get(KEY_HISTORY, '[]')) as string;
      const history: UsageHistoryRecord[] = JSON.parse(raw);
      hilog.info(DOMAIN, TAG, 'History loaded: %{public}d records', history.length);
      return history;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to load history: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  async appendUsageRecord(record: UsageHistoryRecord): Promise<void> {
    if (!this.store) {
      hilog.error(DOMAIN, TAG, 'appendUsageRecord called before init');
      return;
    }
    try {
      const history = await this.getUsageHistory();
      const existingIndex = history.findIndex(h => h.date === record.date);
      if (existingIndex >= 0) {
        history[existingIndex] = record;
      } else {
        history.push(record);
      }
      const trimmed = history.slice(-MAX_HISTORY_DAYS);
      await this.store.put(KEY_HISTORY, JSON.stringify(trimmed));
      await this.store.flush();
      hilog.info(DOMAIN, TAG, 'Usage record appended for date: %{public}s', record.date);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to append history record: %{public}s', JSON.stringify(err));
    }
  }

  async clearHistory(): Promise<void> {
    if (!this.store) {
      hilog.error(DOMAIN, TAG, 'clearHistory called before init');
      return;
    }
    try {
      await this.store.put(KEY_HISTORY, '[]');
      await this.store.flush();
      hilog.info(DOMAIN, TAG, 'History cleared');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to clear history: %{public}s', JSON.stringify(err));
    }
  }
}

export const storageService = StorageService.getInstance();
