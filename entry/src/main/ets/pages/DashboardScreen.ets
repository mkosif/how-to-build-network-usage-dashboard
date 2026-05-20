import { storageService } from '../services/StorageService';
import { UsageSnapshot } from '../models/NetworkModel';
import { SettingsModel } from '../models/SettingsModel';
import { UsageRingComponent } from '../components/UsageRingComponent';
import { MetricTileComponent } from '../components/MetricTileComponent';
import { AlertBannerComponent } from '../components/AlertBannerComponent';
import { bytesToMB, isWifi, formattedTime } from '../utils/NetworkUtils';
import { ArcList, ArcListItem, ComponentContent } from '@kit.ArkUI';

@Builder
function HeaderBuilder() {
  Text($r('app.string.dashboard_title'))
    .fontSize(14)
    .fontWeight(FontWeight.Bold)
    .fontColor('#E8E8F0')
    .textAlign(TextAlign.Center)
    .width('100%')
}

@Component
export struct DashboardScreen {
  @StorageProp('netSnapshot') snapshot: UsageSnapshot = { records: [], capturedAt: 0 };
  @StorageProp('netSnapshotReady') isReady: boolean = false;
  @StorageProp('netSnapshotError') hasError: boolean = false;
  @State settings: SettingsModel = new SettingsModel();
  private context: UIContext = this.getUIContext();
  private header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(HeaderBuilder))

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
    return this.settings.usageLimitMB > 0 && this.totalMB() >= this.settings.usageLimitMB;
  }

  build() {
    Column({ space: 0 }) {
      AlertBannerComponent({
        visible: this.isOverLimit(),
        message: $r('app.string.alert_over_limit')
      })

      if (!this.isReady && !this.hasError) {
        Column({ space: 6 }) {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#00D4FF')
          Text('Loading...')
            .fontSize(11)
            .fontColor('#8888AA')
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
        Column() {
          ArcList({ header: this.header }) {
            ArcListItem() {
              Column({ space: 4 }) {

                UsageRingComponent({
                  usedMB: this.totalMB(),
                  limitMB: this.settings.usageLimitMB,
                  label: 'MB'
                })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .padding({ top: 8, bottom: 4 })
            }

            ArcListItem() {
              Row({ space: 8 }) {
                MetricTileComponent({
                  label: 'Wi-Fi',
                  value: `${this.wifiMB().toFixed(1)} MB`,
                  accentColor: '#00D4FF'
                })
                MetricTileComponent({
                  label: 'Mobile',
                  value: `${this.mobileMB().toFixed(1)} MB`,
                  accentColor: '#FF6B6B'
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({
                left: 8,
                right: 8,
                top: 4,
                bottom: 4
              })
            }

            ArcListItem() {
              Text(`Updated: ${formattedTime(this.snapshot.capturedAt)}`)
                .fontSize(10)
                .fontColor('#8888AA')
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ top: 4, bottom: 8 })
            }
          }
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
