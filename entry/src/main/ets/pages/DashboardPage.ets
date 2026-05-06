import { storageService } from '../services/StorageService';
import { UsageSnapshot } from '../models/NetworkModel';
import { SettingsModel } from '../models/SettingsModel';
import { UsageRingComponent } from '../components/UsageRingComponent';
import { MetricTileComponent } from '../components/MetricTileComponent';
import { AlertBannerComponent } from '../components/AlertBannerComponent';
import { bytesToMB, isWifi, formattedTime } from '../utils/NetworkUtils';

@Component
export struct DashboardPage {
  @StorageProp('netSnapshot') snapshot: UsageSnapshot = { records: [], capturedAt: 0 };
  @StorageProp('netSnapshotReady') isReady: boolean = false;
  @StorageProp('netSnapshotError') hasError: boolean = false;
  @StorageProp('netPolicyCount') policyCount: number = 0;
  @StorageProp('netCertResult') certResult: string = '--';
  @StorageProp('netServicesCount') servicesCount: number = 0;
  @State settings: SettingsModel = new SettingsModel();

  aboutToAppear(): void {
    storageService.getSettings().then((s: SettingsModel) => {
      this.settings = s;
    });
  }

  private totalMB(): number {
    return bytesToMB(this.snapshot.records.reduce((acc, r) => acc + r.totalBytes, 0));
  }

  private wifiMB(): number {
    return bytesToMB(
      this.snapshot.records
        .filter(r => isWifi(r.ifaceName))
        .reduce((acc, r) => acc + r.totalBytes, 0)
    );
  }

  private mobileMB(): number {
    return bytesToMB(
      this.snapshot.records
        .filter(r => !isWifi(r.ifaceName))
        .reduce((acc, r) => acc + r.totalBytes, 0)
    );
  }

  private isOverLimit(): boolean {
    return this.settings.dailyLimitMB > 0 && this.totalMB() >= this.settings.dailyLimitMB;
  }

  private certStatusColor(): string {
    if (this.certResult === 'Valid') {
      return '#00FF88';
    }
    if (this.certResult === 'Expired') {
      return '#FFB347';
    }
    if (this.certResult === '--') {
      return '#8888AA';
    }
    return '#FF4757';
  }

  build() {
    Column({ space: 0 }) {
      AlertBannerComponent({
        visible: this.isOverLimit(),
        message: $r('app.string.alert_over_limit')
      })

      if (!this.isReady && !this.hasError) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#00D4FF')
          Text('Loading...')
            .fontSize(11)
            .fontColor('#8888AA')
            .margin({ top: 6 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column() {
          Text('Unable to read network stats')
            .fontSize(12)
            .fontColor('#FF4757')
            .textAlign(TextAlign.Center)
            .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            Text($r('app.string.dashboard_title'))
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E8E8F0')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 6, bottom: 2 })

            UsageRingComponent({
              usedMB: this.totalMB(),
              limitMB: this.settings.dailyLimitMB,
              label: 'MB'
            })

            Row({ space: 8 }) {
              MetricTileComponent({
                label: 'Wi-Fi',
                value: this.wifiMB().toFixed(1) + ' MB',
                accentColor: '#00D4FF'
              })
              MetricTileComponent({
                label: 'Mobile',
                value: this.mobileMB().toFixed(1) + ' MB',
                accentColor: '#FF6B6B'
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)

            Divider()
              .color('#2A2A4E')
              .width('80%')

            Text('Network Status')
              .fontSize(11)
              .fontColor('#8888AA')
              .textAlign(TextAlign.Center)
              .width('100%')

            Row({ space: 8 }) {
              MetricTileComponent({
                label: 'Policies',
                value: this.policyCount.toString(),
                accentColor: '#A78BFA'
              })
              MetricTileComponent({
                label: 'Services',
                value: this.servicesCount.toString(),
                accentColor: '#34D399'
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)

            Row({ space: 6 }) {
              Text('Cert:')
                .fontSize(10)
                .fontColor('#8888AA')
              Text(this.certResult)
                .fontSize(10)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.certStatusColor())
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)

            Text('Updated: ' + formattedTime(this.snapshot.capturedAt))
              .fontSize(10)
              .fontColor('#8888AA')
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ bottom: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A2E')
  }
}
