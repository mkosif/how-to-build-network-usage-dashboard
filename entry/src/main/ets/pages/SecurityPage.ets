import { hilog } from '@kit.PerformanceAnalysisKit';
import { networkSecurity, http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ArcList, ArcListItem, ComponentContent } from '@kit.ArkUI';
import { formattedTime } from '../utils/NetworkUtils';

const DOMAIN = 0x0003;
const TAG = 'SecurityPage';
const CERT_RESULT_KEY = 'netCertResult';
const CHECK_HOST = 'www.example.com';

// SSL/TLS error codes from the http module
const SSL_ERROR_CODES: number[] = [2300035, 2300058, 2300060, 2300062];

export interface SecurityEntry {
  label: string;
  value: string;
  statusColor: string;
}

@Builder
function HeaderBuilder() {
  Column({ space: 0 }) {
    Text('Certificate Security')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor('#E8E8F0')
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 12, bottom: 4 })

    Text(CHECK_HOST)
      .fontSize(10)
      .fontColor('#8888AA')
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ bottom: 6 })
  }
}

@Component
export struct SecurityPage {
  @State isChecking: boolean = false;
  @State checkedAt: number = 0;
  @State tlsStatus: string = '--';
  @State tlsColor: string = '#8888AA';
  @State cleartextAllowed: boolean = false;
  @State hostCleartextAllowed: boolean = false;
  @State errorMsg: string = '';
  private context: UIContext = this.getUIContext();
  private header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(HeaderBuilder));

  aboutToAppear(): void {
    this.loadCleartextPolicy();
    this.checkTlsConnectivity();
  }

  private loadCleartextPolicy(): void {
    try {
      this.cleartextAllowed = networkSecurity.isCleartextPermitted();
      this.hostCleartextAllowed = networkSecurity.isCleartextPermittedByHostName(CHECK_HOST);
      hilog.info(DOMAIN, TAG, 'cleartext=%{public}s host=%{public}s',
        this.cleartextAllowed.toString(), this.hostCleartextAllowed.toString());
    } catch (err) {
      hilog.info(DOMAIN, TAG, 'isCleartextPermitted: %{public}s', JSON.stringify(err));
    }
  }

  private checkTlsConnectivity(): void {
    this.isChecking = true;
    this.errorMsg = '';

    const req = http.createHttp();
    req.request(
      'https://' + CHECK_HOST,
      {
        method: http.RequestMethod.HEAD,
        connectTimeout: 8000,
        readTimeout: 8000
      }
    ).then(() => {
      this.tlsStatus = 'Valid';
      this.tlsColor = '#00FF88';
      this.checkedAt = Date.now();
      AppStorage.setOrCreate<string>(CERT_RESULT_KEY, 'Valid');
      hilog.info(DOMAIN, TAG, 'TLS check passed for %{public}s', CHECK_HOST);
    }).catch((err: BusinessError) => {
      const code = err.code ?? 0;
      this.checkedAt = Date.now();
      if (SSL_ERROR_CODES.indexOf(code) >= 0) {
        this.tlsStatus = 'Invalid (SSL ' + code.toString() + ')';
        this.tlsColor = '#FF4757';
        AppStorage.setOrCreate<string>(CERT_RESULT_KEY, 'Invalid');
      } else if (code === 2300006 || code === 2300007 || code === 2300028) {
        this.tlsStatus = 'Unreachable';
        this.tlsColor = '#FFB347';
        this.errorMsg = 'Cannot reach ' + CHECK_HOST;
        AppStorage.setOrCreate<string>(CERT_RESULT_KEY, 'Unreachable');
      } else {
        this.tlsStatus = 'Error (' + code.toString() + ')';
        this.tlsColor = '#FF4757';
        AppStorage.setOrCreate<string>(CERT_RESULT_KEY, 'Error');
      }
      hilog.info(DOMAIN, TAG, 'TLS check code=%{public}d msg=%{public}s', code, err.message ?? '');
    }).finally(() => {
      this.isChecking = false;
      req.destroy();
    });
  }

  build() {
    Column({ space: 0 }) {
      if (this.isChecking) {
        Column({ space: 6 }) {
          LoadingProgress()
            .width(32)
            .height(32)
            .color('#00D4FF')
          Text('Checking TLS...')
            .fontSize(11)
            .fontColor('#8888AA')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        ArcList({ header: this.header }) {
          ArcListItem() {
            Column({ space: 6 }) {
              Row({ space: 8 }) {
                Text('TLS Status:')
                  .fontSize(12)
                  .fontColor('#8888AA')
                Text(this.tlsStatus)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.tlsColor)
              }
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .width('100%')

              if (this.errorMsg !== '') {
                Text(this.errorMsg)
                  .fontSize(10)
                  .fontColor('#FFB347')
                  .width('100%')
              }

              Text('Checked: ' + formattedTime(this.checkedAt))
                .fontSize(10)
                .fontColor('#8888AA')
                .width('100%')
            }
            .padding({
              left: 16,
              right: 16,
              top: 10,
              bottom: 8
            })
          }

          ArcListItem() {
            Column({ space: 4 }) {
              Row() {
                Text('Cleartext (all):')
                  .fontSize(11)
                  .fontColor('#8888AA')
                  .layoutWeight(1)
                Text(this.cleartextAllowed ? 'Allowed' : 'Blocked')
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.cleartextAllowed ? '#FFB347' : '#00FF88')
              }
              .width('100%')

              Row() {
                Text('Cleartext (host):')
                  .fontSize(11)
                  .fontColor('#8888AA')
                  .layoutWeight(1)
                Text(this.hostCleartextAllowed ? 'Allowed' : 'Blocked')
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.hostCleartextAllowed ? '#FFB347' : '#00FF88')
              }
              .width('100%')
            }
            .padding({
              left: 16,
              right: 16,
              top: 8,
              bottom: 8
            })
          }

          ArcListItem() {
            Button('Refresh')
              .fontSize(12)
              .height(32)
              .width('80%')
              .backgroundColor('#2A2A4E')
              .fontColor('#00D4FF')
              .onClick(() => {
                this.loadCleartextPolicy();
                this.checkTlsConnectivity();
              })
              .margin({ top: 4, bottom: 8 })
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
