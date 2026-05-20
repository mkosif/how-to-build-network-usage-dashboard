import { hilog } from '@kit.PerformanceAnalysisKit';
import { connection } from '@kit.NetworkKit';

const DOMAIN = 0x0002;
const TAG = 'ConnectionPage';
const STATUS_COUNT_KEY = 'netStatusCount';

export interface NetworkCapEntry {
  label: string;
  value: string;
  highlight: boolean;
}

@Component
export struct PolicyPage {
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State isMetered: boolean = false;
  @State capEntries: NetworkCapEntry[] = [];

  aboutToAppear(): void {
    this.loadConnectionStatus();
  }

  private loadConnectionStatus(): void {
    this.isLoading = true;
    this.hasError = false;

    connection.isDefaultNetMetered()
      .then((metered: boolean) => {
        this.isMetered = metered;
        return connection.getDefaultNet();
      })
      .then((handle: connection.NetHandle) => {
        return connection.getNetCapabilities(handle);
      })
      .then((caps: connection.NetCapabilities) => {
        const entries: NetworkCapEntry[] = [];

        const bearerLabels: string[] = caps.bearerTypes.map((b: connection.NetBearType) => {
          if (b === connection.NetBearType.BEARER_CELLULAR) {
            return 'Cellular';
          }
          if (b === connection.NetBearType.BEARER_WIFI) {
            return 'Wi-Fi';
          }
          if (b === connection.NetBearType.BEARER_ETHERNET) {
            return 'Ethernet';
          }
          if (b === connection.NetBearType.BEARER_BLUETOOTH) {
            return 'Bluetooth';
          }
          if (b === connection.NetBearType.BEARER_VPN) {
            return 'VPN';
          }
          return 'Unknown';
        });

        entries.push({ label: 'Bearer', value: bearerLabels.join(', ') || '--', highlight: false });
        entries.push({ label: 'Metered', value: this.isMetered ? 'Yes' : 'No', highlight: this.isMetered });

        const notMetered = (caps.networkCap ?? []).includes(connection.NetCap.NET_CAPABILITY_NOT_METERED);
        const hasInternet = (caps.networkCap ?? []).includes(connection.NetCap.NET_CAPABILITY_INTERNET);

        entries.push({ label: 'Internet', value: hasInternet ? 'Available' : 'No', highlight: !hasInternet });

        if (caps.linkUpBandwidthKbps !== undefined && caps.linkUpBandwidthKbps > 0) {
          entries.push({
            label: 'Up',
            value: `${(caps.linkUpBandwidthKbps / 1000).toFixed(1)} Mbps`,
            highlight: false
          });
        }
        if (caps.linkDownBandwidthKbps !== undefined && caps.linkDownBandwidthKbps > 0) {
          entries.push({
            label: 'Down',
            value: `${(caps.linkDownBandwidthKbps / 1000).toFixed(1)} Mbps`,
            highlight: false
          });
        }

        entries.push({
          label: 'Cost',
          value: notMetered ? 'Unmetered' : (this.isMetered ? 'Metered' : 'Standard'),
          highlight: this.isMetered && !notMetered
        });

        this.capEntries = entries;
        AppStorage.setOrCreate<number>(STATUS_COUNT_KEY, entries.length);
        this.isLoading = false;
        hilog.info(DOMAIN, TAG, 'Connection status loaded: metered=%{public}s bearers=%{public}s',
          this.isMetered.toString(), bearerLabels.join(','));
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN, TAG, 'loadConnectionStatus failed: %{public}s', JSON.stringify(err));
        this.hasError = true;
        this.errorMsg = 'Cannot read connection status';
        this.isLoading = false;
        AppStorage.setOrCreate<number>(STATUS_COUNT_KEY, 0);
      });
  }

  build() {
    Column({ space: 0 }) {
      Text('Connection')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8E8F0')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 10, bottom: 6 })

      if (this.isLoading) {
        Column({ space: 6 }) {
          LoadingProgress()
            .width(28)
            .height(28)
            .color('#00D4FF')
          Text('Loading...')
            .fontSize(11)
            .fontColor('#8888AA')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column({ space: 8 }) {
          Text(this.errorMsg)
            .fontSize(12)
            .fontColor('#FF4757')
            .textAlign(TextAlign.Center)
            .padding({ left: 16, right: 16 })
          Column() {
            Text('Retry')
              .fontSize(12)
              .fontColor('#00D4FF')
              .textAlign(TextAlign.Center)
          }
          .width(64)
          .height(28)
          .borderRadius(14)
          .backgroundColor('#2A2A4E')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.loadConnectionStatus();
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 0 }) {
            ForEach(this.capEntries, (entry: NetworkCapEntry) => {
              Row() {
                Text(entry.label)
                  .fontSize(11)
                  .fontColor('#8888AA')
                  .textAlign(TextAlign.Start)
                  .layoutWeight(1)
                Text(entry.value)
                  .fontSize(12)
                  .textAlign(TextAlign.End)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(entry.highlight ? '#FF6B6B' : '#E8E8F0')
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding({ left: 20, right: 20, top: 7, bottom: 7 })
            }, (entry: NetworkCapEntry) => entry.label)

            Column() {
              Text('Refresh')
                .fontSize(11)
                .fontColor('#8888AA')
                .textAlign(TextAlign.Center)
            }
            .width(64)
            .height(26)
            .borderRadius(13)
            .backgroundColor('#2A2A4E')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 6, bottom: 28 })
            .onClick(() => {
              this.loadConnectionStatus();
            })
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
