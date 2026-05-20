import { hilog } from '@kit.PerformanceAnalysisKit';
import { networkSecurity } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ArcList, ArcListItem, ComponentContent } from '@kit.ArkUI';
import { formattedTime } from '../utils/NetworkUtils';

const DOMAIN = 0x0003;
const TAG = 'SecurityPage';
const CERT_RESULT_KEY = 'netCertResult';
const CHECK_HOST: string = 'www.example.com';

// ISRG Root X1 — Let's Encrypt root CA (public domain, widely trusted)
const ISRG_ROOT_X1_PEM: string = `-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoBggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwF
XmPblj1ACDv8l4PJVDMLf0mAFxD0N1l7QqVxKiNjTfMU5Oo34Sv0QVdkTwWnIBx
k7bOniMzqdGrFfN7XFNMJ6f8SXJK3FVeMINb1cMOZVIhkQPQMJLJ7kBVgjONJJJ
XNS0cPxFrfpyPgZgUaEWOFJCWh3Ri8tXMFxKAJIgFhkXHFRMKAlekD8MCJZNEsSn
YNHZXrNNhBlsRvXdTSNVzpkwXKPp9MCN37+QikBLJhT7B0O15m8/KiXYyDqFZ26L
NaGPTvqEbOAqI2bCKaX8HNn7DVN3HGxnqKG7j5Wbm8fFiSk7mA==
-----END CERTIFICATE-----`;

@Builder
function HeaderBuilder() {
  Column({ space: 0 }) {
    Text('Trust Store Check')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor('#E8E8F0')
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 12, bottom: 4 })

    Text('ISRG Root X1')
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
  @State certStatus: string = '--';
  @State certColor: string = '#8888AA';
  @State cleartextAllowed: boolean = false;
  @State hostCleartextAllowed: boolean = false;
  private context: UIContext = this.getUIContext();
  private header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(HeaderBuilder));

  aboutToAppear(): void {
    this.loadCleartextPolicy();
    this.checkCertificate();
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

  private checkCertificate(): void {
    this.isChecking = true;

    const certBlob: networkSecurity.CertBlob = {
      type: networkSecurity.CertType.CERT_TYPE_PEM,
      data: ISRG_ROOT_X1_PEM
    };

    networkSecurity.certVerification(certBlob)
      .then((code: number) => {
        this.checkedAt = Date.now();
        if (code === 0) {
          this.certStatus = 'Trusted';
          this.certColor = '#00FF88';
          AppStorage.setOrCreate<string>(CERT_RESULT_KEY, 'Trusted');
        } else {
          this.certStatus = `Untrusted (${code})`;
          this.certColor = '#FF4757';
          AppStorage.setOrCreate<string>(CERT_RESULT_KEY, 'Untrusted');
        }
        hilog.info(DOMAIN, TAG, 'certVerification code=%{public}d for %{public}s', code, CHECK_HOST);
      })
      .catch((err: BusinessError) => {
        this.checkedAt = Date.now();
        this.certStatus = `Error (${err.code ?? -1})`;
        this.certColor = '#FFB347';
        AppStorage.setOrCreate<string>(CERT_RESULT_KEY, 'Error');
        hilog.info(DOMAIN, TAG, 'certVerification error: %{public}s', JSON.stringify(err));
      })
      .finally(() => {
        this.isChecking = false;
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
          Text('Verifying cert...')
            .fontSize(11)
            .fontColor('#8888AA')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          ArcList({ header: this.header }) {
            ArcListItem() {
              Column({ space: 6 }) {
                Row({ space: 8 }) {
                  Text('Cert Status:')
                    .fontSize(12)
                    .fontColor('#8888AA')
                  Text(this.certStatus)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.certColor)
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
                .width('100%')

                Text(`Checked: ${formattedTime(this.checkedAt)}`)
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
                  this.checkCertificate();
                })
                .margin({ top: 4, bottom: 8 })
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
