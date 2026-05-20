import { ArcList, ArcListItem } from '@kit.ArkUI';
import { DailyUsageSummary, UsageSnapshot } from '../models/NetworkModel';
import { storageService } from '../services/StorageService';
import { bytesToMB, isWifi, todayDateString } from '../utils/NetworkUtils';
import { BasicDataSource } from '../utils/BasicDataSource';

@Component
export struct HistoryPage {
  @State @Watch('onDataChange') historyRecords: DailyUsageSummary[] = [];
  @State isLoading: boolean = true;
  @StorageProp('netSnapshot') @Watch('onDataChange') snapshot: UsageSnapshot =
    { records: [], capturedAt: 0 };
  private historySource: BasicDataSource<DailyUsageSummary> =
    new BasicDataSource<DailyUsageSummary>([]);

  aboutToAppear(): void {
    this.historySource.setData(this.allRecords());
    storageService.getDailyHistory().then((records: DailyUsageSummary[]) => {
      this.historyRecords = records;
      this.isLoading = false;
    });
  }

  onDataChange(): void {
    this.historySource.setData(this.allRecords());
    this.historySource.notifyDataReload();
  }

  private allRecords(): DailyUsageSummary[] {
    const todayTotal = this.snapshot.records.reduce((acc, r) => acc + r.totalBytes, 0);
    const wifiTotal = this.snapshot.records
      .filter(r => isWifi(r.ifaceName))
      .reduce((acc, r) => acc + r.totalBytes, 0);

    const todayEntry: DailyUsageSummary = {
      date: todayDateString(),
      totalBytes: todayTotal,
      wifiBytes: wifiTotal,
      mobileBytes: todayTotal - wifiTotal
    };

    const stored = this.historyRecords.filter(r => r.date !== todayDateString());
    return [todayEntry, ...stored].slice(0, 7);
  }

  private maxBytes(): number {
    return this.historySource.totalCount() > 0
      ? this.allRecords().reduce((m, r) => Math.max(m, r.totalBytes), 1)
      : 1;
  }

  build() {
    Column({ space: 0 }) {
      Text($r('app.string.history_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8E8F0')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 12, bottom: 8 })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color('#00D4FF')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.historySource.totalCount() === 0 ||
        this.historySource.getData(0).totalBytes === 0) {
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
            LazyForEach(this.historySource, (record: DailyUsageSummary) => {
              ArcListItem() {
                Column({ space: 3 }) {
                  Row() {
                    Text(record.date)
                      .fontSize(11)
                      .fontColor('#8888AA')
                      .layoutWeight(1)
                    Text(`${bytesToMB(record.totalBytes).toFixed(1)} MB`)
                      .fontSize(12)
                      .fontColor('#E8E8F0')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')

                  Row() {
                    Rect()
                      .width(`${(record.totalBytes / this.maxBytes()) * 100}%`)
                      .height(6)
                      .fill('#00D4FF')
                      .borderRadius(3)
                  }
                  .width('100%')
                  .backgroundColor('#2A2A4E')
                  .borderRadius(3)
                }
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              }
            }, (record: DailyUsageSummary) => record.date)
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
