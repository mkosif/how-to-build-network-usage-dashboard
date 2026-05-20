export interface InterfaceUsageRecord {
  ifaceName: string;
  txBytes: number;
  rxBytes: number;
  totalBytes: number;
  timestamp: number;
}

export interface UsageHistoryRecord {
  date: string;
  totalBytes: number;
  wifiBytes: number;
  mobileBytes: number;
}

export interface UsageSnapshot {
  records: InterfaceUsageRecord[];
  capturedAt: number;
}
