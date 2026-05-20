import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { storageService } from '../services/StorageService';
import { UsageSnapshot, DailyUsageSummary } from '../models/NetworkModel';

const DOMAIN = 0x0000;

function todayDateString(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = (d.getMonth() + 1).toString().padStart(2, '0');
  const day = d.getDate().toString().padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function isWifi(ifaceName: string): boolean {
  return ifaceName.toLowerCase().startsWith('wlan') ||
    ifaceName.toLowerCase().startsWith('wifi') ||
    ifaceName.toLowerCase().startsWith('eth');
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    AppStorage.setOrCreate('abilityContext', this.context);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    storageService.init(this.context).then(() => {
      hilog.info(DOMAIN, 'testTag', 'StorageService initialized in onWindowStageCreate');
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');

    try {
      const snapshot = AppStorage.get<UsageSnapshot>('netSnapshot');
      if (snapshot && snapshot.records.length > 0) {
        const totalBytes = snapshot.records.reduce((acc, r) => acc + r.totalBytes, 0);
        const wifiBytes = snapshot.records
          .filter(r => isWifi(r.ifaceName))
          .reduce((acc, r) => acc + r.totalBytes, 0);

        const record: DailyUsageSummary = {
          date: todayDateString(),
          totalBytes,
          wifiBytes,
          mobileBytes: totalBytes - wifiBytes
        };

        storageService.appendDailyRecord(record).then(() => {
          hilog.info(DOMAIN, 'testTag', 'Daily usage record appended on background: %{public}s', record.date);
        });
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to append daily record on background: %{public}s', JSON.stringify(err));
    }
  }
}
