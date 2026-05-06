import { networkMonitorService } from '../services/NetworkMonitorService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DashboardScreen } from './DashboardScreen';
import { DetailPage } from './DetailPage';
import { HistoryPage } from './HistoryPage';
import { SettingsPage } from './SettingsPage';
import { PolicyPage } from './PolicyPage';
import { SecurityPage } from './SecurityPage';
import { ServicesPage } from './ServicesPage';
import { ArcSwiper } from '@kit.ArkUI';

const DOMAIN = 0x0000;
const TAG = 'Index';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'App starting — starting network polling');
    networkMonitorService.startPolling(30);
  }

  aboutToDisappear(): void {
    networkMonitorService.stopPolling();
    hilog.info(DOMAIN, TAG, 'App stopping — polling stopped');
  }

  build() {
    Column({ space: 0 }) {
      ArcSwiper() {
        DashboardScreen()
        DetailPage()
        HistoryPage()
        SettingsPage()
        PolicyPage()
        SecurityPage()
        ServicesPage()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A2E')
  }
}
