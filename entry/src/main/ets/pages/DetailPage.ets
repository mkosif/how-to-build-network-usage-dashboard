import { ArcList, ArcListItem } from '@kit.ArkUI';
import { UsageSnapshot, InterfaceUsageRecord } from '../models/NetworkModel';
import { InterfaceRowComponent } from '../components/InterfaceRowComponent';
import { bytesToMB, isWifi, formattedTime } from '../utils/NetworkUtils';
import { BasicDataSource } from '../utils/BasicDataSource';

@Component
export struct DetailPage {
  @StorageProp('netSnapshot') @Watch('onSnapshotChange') snapshot: UsageSnapshot =
    { records: [], capturedAt: 0 };
  @StorageProp('netSnapshotReady') isReady: boolean = false;
  private recordSource: BasicDataSource<InterfaceUsageRecord> =
    new BasicDataSource<InterfaceUsageRecord>([]);

  aboutToAppear(): void {
    this.recordSource.setData(this.snapshot.records);
  }

  onSnapshotChange(): void {
    this.recordSource.setData(this.snapshot.records);
    this.recordSource.notifyDataReload();
  }

  build() {
    Column({ space: 0 }) {
      Text($r('app.string.detail_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8E8F0')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 12, bottom: 8 })

      if (!this.isReady || this.snapshot.records.length === 0) {
        Column() {
          Text($r('app.string.no_data'))
            .fontSize(13)
            .fontColor('#8888AA')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          ArcList() {
            LazyForEach(this.recordSource, (record: InterfaceUsageRecord) => {
              ArcListItem() {
                InterfaceRowComponent({
                  ifaceName: record.ifaceName,
                  rxMB: bytesToMB(record.rxBytes),
                  txMB: bytesToMB(record.txBytes),
                  accentColor: isWifi(record.ifaceName) ? '#00D4FF' : '#FF6B6B'
                })
              }
            }, (record: InterfaceUsageRecord) => record.ifaceName)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }

      Text(`Updated: ${formattedTime(this.snapshot.capturedAt)}`)
        .fontSize(10)
        .fontColor('#8888AA')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A2E')
  }
}
