import { hilog } from '@kit.PerformanceAnalysisKit';
import { connection } from '@kit.NetworkKit';
import { policy } from '@kit.NetworkKit';
import { ArcList, ArcListItem, ComponentContent } from '@kit.ArkUI';
import { BasicDataSource } from '../utils/BasicDataSource';
import { deviceInfo } from '@kit.BasicServicesKit';

const DOMAIN = 0x0002;
const TAG = 'PolicyPage';
const POLICY_COUNT_KEY = 'netPolicyCount';

export interface NetworkCapEntry {
  label: string;
  value: string;
  highlight: boolean;
}

@Builder
function PolicyHeaderBuilder() {
  Text('Network Policy')
    .fontSize(16)
    .fontWeight(FontWeight.Bold)
    .fontColor('#E8E8F0')
    .textAlign(TextAlign.Center)
    .width('100%')
}

@Component
export struct PolicyPage {
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State isMetered: boolean = false;
  @State @Watch('onEntriesChange') capEntries: NetworkCapEntry[] = [];
  private capSource: BasicDataSource<NetworkCapEntry> = new BasicDataSource<NetworkCapEntry>([]);
  private context: UIContext = this.getUIContext();
  private header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(PolicyHeaderBuilder));

  aboutToAppear(): void {
    this.loadNetworkPolicy();
  }

  onEntriesChange(): void {
    this.capSource.setData(this.capEntries);
    this.capSource.notifyDataReload();
  }

  private loadNetworkPolicy(): void {
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
            value: (caps.linkUpBandwidthKbps / 1000).toFixed(1) + ' Mbps',
            highlight: false
          });
        }
        if (caps.linkDownBandwidthKbps !== undefined && caps.linkDownBandwidthKbps > 0) {
          entries.push({
            label: 'Down',
            value: (caps.linkDownBandwidthKbps / 1000).toFixed(1) + ' Mbps',
            highlight: false
          });
        }

        entries.push({
          label: 'Policy',
          value: notMetered ? 'Unrestricted' : (this.isMetered ? 'Metered' : 'Standard'),
          highlight: this.isMetered && !notMetered
        });

        this.capEntries = entries;
        AppStorage.setOrCreate<number>(POLICY_COUNT_KEY, entries.length);
        this.isLoading = false;
        hilog.info(DOMAIN, TAG, 'Network policy loaded: metered=%{public}s bearers=%{public}s',
          this.isMetered.toString(), bearerLabels.join(','));
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN, TAG, 'loadNetworkPolicy failed: %{public}s', JSON.stringify(err));
        this.hasError = true;
        this.errorMsg = 'Cannot read network capabilities';
        this.isLoading = false;
        AppStorage.setOrCreate<number>(POLICY_COUNT_KEY, 0);
      });
  }

  private openNetworkSettings(): void {
    policy.showAppNetPolicySettings(this.context.getHostContext())
      .catch((err: Error) => {
        hilog.info(DOMAIN, TAG, 'showAppNetPolicySettings: %{public}s', JSON.stringify(err));
      });
  }

  build() {
    Column({ space: 0 }) {
      if (this.isLoading) {
        Column({ space: 6 }) {
          LoadingProgress()
            .width(32)
            .height(32)
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
          Button('Retry')
            .fontSize(12)
            .height(32)
            .backgroundColor('#2A2A4E')
            .fontColor('#00D4FF')
            .onClick(() => {
              this.loadNetworkPolicy();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        ArcList({ header: this.header }) {
          LazyForEach(this.capSource, (entry: NetworkCapEntry) => {
            ArcListItem() {
              Row() {
                Text(entry.label)
                  .fontSize(11)
                  .fontColor('#8888AA')
                  .textAlign(TextAlign.Start)
                Text(entry.value)
                  .fontSize(12)
                  .textAlign(TextAlign.End)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(entry.highlight ? '#FF6B6B' : '#E8E8F0')
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.SpaceEvenly)
              .padding({
                left: 16,
                right: 16,
                top: 8,
                bottom: 8
              })
            }
          }, (entry: NetworkCapEntry) => entry.label)

          ArcListItem() {
            Button('Network Settings')
              .fontSize(11)
              .height(32)
              .width('80%')
              .backgroundColor('#2A2A4E')
              .fontColor('#00D4FF')
              .onClick(() => {
                this.openNetworkSettings();
              })
              .margin({ top: 4, bottom: 4 })
          }

          ArcListItem() {
            Button('Refresh')
              .fontSize(11)
              .height(32)
              .width('80%')
              .backgroundColor('#2A2A4E')
              .fontColor('#8888AA')
              .onClick(() => {
                this.loadNetworkPolicy();
              })
              .margin({ bottom: 8 })
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
