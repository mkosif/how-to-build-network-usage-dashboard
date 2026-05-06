export interface InterfaceUsageRecord {
  ifaceName: string;
  txBytes: number;
  rxBytes: number;
  totalBytes: number;
  timestamp: number; // unix ms
}

export interface DailyUsageSummary {
  date: string; // YYYY-MM-DD
  totalBytes: number;
  wifiBytes: number;
  mobileBytes: number;
}

export interface UsageSnapshot {
  records: InterfaceUsageRecord[];
  capturedAt: number; // unix ms
}

export interface AppUsageRecord {
  uid: number;
  appName: string;
  txBytes: number;
  rxBytes: number;
  totalBytes: number;
}
