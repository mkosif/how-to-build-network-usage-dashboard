import { hilog } from '@kit.PerformanceAnalysisKit';
import { mdns } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { ArcList, ArcListItem } from '@kit.ArkUI';
import { BasicDataSource } from '../utils/BasicDataSource';

const DOMAIN = 0x0004;
const TAG = 'ServicesPage';

const SERVICES_COUNT_KEY = 'netServicesCount';

const SERVICE_TYPES: string[] = ['_http._tcp.local', '_https._tcp.local'];

export interface DiscoveredService {
  serviceType: string;
  serviceName: string;
  host: string;
  port: number;
}

@Component
export struct ServicesPage {
  @State services: DiscoveredService[] = [];
  @State isDiscovering: boolean = false;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  private serviceSource: BasicDataSource<DiscoveredService> =
    new BasicDataSource<DiscoveredService>([]);
  private discoveryInstances: mdns.DiscoveryService[] = [];
  private context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.context = getContext(this) as common.UIAbilityContext;
    this.startDiscovery();
  }

  aboutToDisappear(): void {
    this.stopDiscovery();
  }

  private startDiscovery(): void {
    this.isDiscovering = true;
    this.hasError = false;
    this.discoveryInstances = [];

    for (const serviceType of SERVICE_TYPES) {
      try {
        const ctx = this.context as common.UIAbilityContext;
        const ds: mdns.DiscoveryService = mdns.createDiscoveryService(ctx, serviceType);

        ds.on('serviceFound', (info: mdns.LocalServiceInfo) => {
          hilog.info(DOMAIN, TAG, 'serviceFound: %{public}s', info.serviceName ?? '');
          this.resolveService(info, serviceType);
        });

        ds.on('serviceLost', (info: mdns.LocalServiceInfo) => {
          hilog.info(DOMAIN, TAG, 'serviceLost: %{public}s', info.serviceName ?? '');
          this.removeService(info.serviceName ?? '', serviceType);
        });

        ds.startSearchingMDNS();
        this.discoveryInstances.push(ds);
        hilog.info(DOMAIN, TAG, 'Discovery started for %{public}s', serviceType);
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'Failed to start discovery for %{public}s: %{public}s',
          serviceType, JSON.stringify(err));
        this.hasError = true;
        this.errorMsg = 'mDNS discovery unavailable';
      }
    }
  }

  private stopDiscovery(): void {
    for (const ds of this.discoveryInstances) {
      try {
        ds.stopSearchingMDNS();
      } catch (err) {
        hilog.info(DOMAIN, TAG, 'stopSearchingMDNS: %{public}s', JSON.stringify(err));
      }
    }
    this.discoveryInstances = [];
    this.isDiscovering = false;
    hilog.info(DOMAIN, TAG, 'Discovery stopped');
  }

  private resolveService(info: mdns.LocalServiceInfo, serviceType: string): void {
    const ctx = this.context as common.UIAbilityContext;
    mdns.resolveLocalService(ctx, info)
      .then((resolved: mdns.LocalServiceInfo) => {
        const host = resolved.host?.address ?? '';
        const port = resolved.port ?? 0;
        const name = resolved.serviceName ?? info.serviceName ?? '';
        this.addOrUpdateService({
          serviceType,
          serviceName: name,
          host,
          port
        });
      })
      .catch((err: Error) => {
        hilog.info(DOMAIN, TAG, 'resolveLocalService failed: %{public}s', JSON.stringify(err));
        // Add with unresolved host
        this.addOrUpdateService({
          serviceType,
          serviceName: info.serviceName ?? '',
          host: '(resolving...)',
          port: 0
        });
      });
  }

  private addOrUpdateService(entry: DiscoveredService): void {
    const existing = this.services.findIndex(
      (s: DiscoveredService) => s.serviceName === entry.serviceName && s.serviceType === entry.serviceType
    );
    let updated: DiscoveredService[];
    if (existing >= 0) {
      updated = this.services.map((s: DiscoveredService, i: number) => i === existing ? entry : s);
    } else {
      updated = [...this.services, entry];
    }
    this.services = updated;
    this.serviceSource.setData(updated);
    this.serviceSource.notifyDataReload();
    AppStorage.setOrCreate<number>(SERVICES_COUNT_KEY, updated.length);
  }

  private removeService(serviceName: string, serviceType: string): void {
    const updated = this.services.filter(
      (s: DiscoveredService) => !(s.serviceName === serviceName && s.serviceType === serviceType)
    );
    this.services = updated;
    this.serviceSource.setData(updated);
    this.serviceSource.notifyDataReload();
    AppStorage.setOrCreate<number>(SERVICES_COUNT_KEY, updated.length);
  }

  build() {
    Column({ space: 0 }) {
      Text('Local Services')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8E8F0')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 12, bottom: 4 })

      Row({ space: 6 }) {
        if (this.isDiscovering) {
          LoadingProgress()
            .width(14)
            .height(14)
            .color('#00D4FF')
        }
        Text(this.isDiscovering ? 'Discovering...' : 'Stopped')
          .fontSize(10)
          .fontColor(this.isDiscovering ? '#00D4FF' : '#8888AA')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 6 })

      if (this.hasError) {
        Column() {
          Text(this.errorMsg)
            .fontSize(12)
            .fontColor('#FF4757')
            .textAlign(TextAlign.Center)
            .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.services.length === 0) {
        Column() {
          Text('No services found yet')
            .fontSize(13)
            .fontColor('#8888AA')
            .textAlign(TextAlign.Center)
          Text('Searching for _http._tcp and _https._tcp')
            .fontSize(10)
            .fontColor('#555577')
            .textAlign(TextAlign.Center)
            .padding({ top: 4, left: 16, right: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        ArcList() {
          LazyForEach(this.serviceSource, (entry: DiscoveredService) => {
            ArcListItem() {
              Column({ space: 3 }) {
                Text(entry.serviceName)
                  .fontSize(12)
                  .fontColor('#E8E8F0')
                  .width('100%')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row({ space: 6 }) {
                  Text(entry.serviceType)
                    .fontSize(9)
                    .fontColor('#00D4FF')
                  Text(entry.host + (entry.port > 0 ? ':' + entry.port.toString() : ''))
                    .fontSize(9)
                    .fontColor('#8888AA')
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
              }
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            }
          }, (entry: DiscoveredService) => entry.serviceType + '|' + entry.serviceName)
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
