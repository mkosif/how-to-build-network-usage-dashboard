import { hilog } from '@kit.PerformanceAnalysisKit';
import { statistics } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { InterfaceUsageRecord, UsageSnapshot } from '../models/NetworkModel';
import { alertService } from './AlertService';
import { storageService } from './StorageService';

const DOMAIN = 0x0001;
const TAG = 'NetworkMonitorService';

const SNAPSHOT_KEY = 'netSnapshot';
const SNAPSHOT_READY_KEY = 'netSnapshotReady';
const SNAPSHOT_ERROR_KEY = 'netSnapshotError';

const KNOWN_IFACES: string[] = ['wlan0', 'rmnet0', 'eth0', 'lo'];

class NetworkMonitorService {
  private static instance: NetworkMonitorService | null = null;
  private pollTimer: number = -1;

  static getInstance(): NetworkMonitorService {
    if (!NetworkMonitorService.instance) {
      NetworkMonitorService.instance = new NetworkMonitorService();
    }
    return NetworkMonitorService.instance;
  }

  startPolling(intervalSec: number): void {
    if (this.pollTimer >= 0) {
      hilog.info(DOMAIN, TAG, 'Polling already active — skipping start');
      return;
    }
    hilog.info(DOMAIN, TAG, 'Starting network polling every %{public}d seconds', intervalSec);
    this.poll();
    this.pollTimer = setInterval(() => {
      this.poll();
    }, intervalSec * 1000);
  }

  stopPolling(): void {
    if (this.pollTimer >= 0) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
      hilog.info(DOMAIN, TAG, 'Polling stopped');
    }
  }

  getLastSnapshot(): UsageSnapshot {
    const stored = AppStorage.get<UsageSnapshot>(SNAPSHOT_KEY);
    if (stored) {
      return stored;
    }
    return { records: [], capturedAt: Date.now() };
  }

  private poll(): void {
    hilog.info(DOMAIN, TAG, 'Polling network stats');
    this.fetchIfaceStats()
      .then((snapshot: UsageSnapshot) => {
        this.publishSnapshot(snapshot, false);
      })
      .catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'Poll failed: %{public}s', JSON.stringify(err));
        AppStorage.setOrCreate<boolean>(SNAPSHOT_ERROR_KEY, true);
        AppStorage.setOrCreate<boolean>(SNAPSHOT_READY_KEY, false);
      });
  }

  private async fetchIfaceStats(): Promise<UsageSnapshot> {
    const now = Date.now();
    const records: InterfaceUsageRecord[] = [];

    for (const iface of KNOWN_IFACES) {
      try {
        const rxBytes: number = await statistics.getIfaceRxBytes(iface);
        const txBytes: number = await statistics.getIfaceTxBytes(iface);
        if (rxBytes > 0 || txBytes > 0) {
          records.push({
            ifaceName: iface,
            txBytes,
            rxBytes,
            totalBytes: txBytes + rxBytes,
            timestamp: now
          });
          hilog.info(DOMAIN, TAG, 'iface=%{public}s rx=%{public}d tx=%{public}d', iface, rxBytes, txBytes);
        }
      } catch (err) {
        const e = err as BusinessError;
        hilog.info(DOMAIN, TAG, 'iface %{public}s not available: code=%{public}d', iface, e.code ?? 0);
      }
    }

    return { records, capturedAt: now };
  }

  private publishSnapshot(snapshot: UsageSnapshot, hasError: boolean): void {
    AppStorage.setOrCreate<UsageSnapshot>(SNAPSHOT_KEY, snapshot);
    AppStorage.setOrCreate<boolean>(SNAPSHOT_READY_KEY, true);
    AppStorage.setOrCreate<boolean>(SNAPSHOT_ERROR_KEY, hasError);
    hilog.info(DOMAIN, TAG, 'Snapshot published: %{public}d interfaces, capturedAt=%{public}d',
      snapshot.records.length, snapshot.capturedAt);

    storageService.getSettings().then((settings) => {
      const totalBytes = snapshot.records.reduce((acc: number, r: InterfaceUsageRecord) => acc + r.totalBytes, 0);
      const usedMB = totalBytes / (1024 * 1024);
      alertService.checkAndAlert(usedMB, settings.usageLimitMB, settings.notificationsEnabled)
        .catch((err: BusinessError) => {
          hilog.error(DOMAIN, TAG, 'Alert check error: %{public}s', JSON.stringify(err));
        });
    });
  }
}

export const networkMonitorService = NetworkMonitorService.getInstance();
