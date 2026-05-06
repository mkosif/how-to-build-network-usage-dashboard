import { SettingsModel } from '../models/SettingsModel';
import { storageService } from '../services/StorageService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;
const TAG = 'SettingsPage';

@Component
export struct SettingsPage {
  @State settings: SettingsModel = new SettingsModel();
  @State confirmationMessage: string = '';
  @State showConfirmation: boolean = false;
  private confirmationTimer: number = -1;

  aboutToAppear(): void {
    storageService.getSettings().then((s: SettingsModel) => {
      this.settings = s;
    });
  }

  aboutToDisappear(): void {
    if (this.confirmationTimer >= 0) {
      clearTimeout(this.confirmationTimer);
    }
  }

  private saveSettings(): void {
    storageService.saveSettings(this.settings).then(() => {
      hilog.info(DOMAIN, TAG, 'Settings persisted from UI');
    });
  }

  private showBriefMessage(msg: string): void {
    this.confirmationMessage = msg;
    this.showConfirmation = true;
    if (this.confirmationTimer >= 0) {
      clearTimeout(this.confirmationTimer);
    }
    this.confirmationTimer = setTimeout(() => {
      this.showConfirmation = false;
    }, 2000);
  }

  private resetHistory(): void {
    storageService.clearHistory().then(() => {
      hilog.info(DOMAIN, TAG, 'History reset from UI');
      this.showBriefMessage('History cleared');
    });
  }

  build() {
    Column({ space: 0 }) {
      Text($r('app.string.settings_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8E8F0')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 4 }) {
            Text($r('app.string.label_limit'))
              .fontSize(12)
              .fontColor('#8888AA')
              .width('100%')
            Row({ space: 8 }) {
              Button('-')
                .width(36)
                .height(36)
                .fontSize(18)
                .fontColor('#E8E8F0')
                .backgroundColor('#2A2A4E')
                .borderRadius(18)
                .onClick(() => {
                  if (this.settings.dailyLimitMB > 50) {
                    this.settings.dailyLimitMB -= 50;
                    this.saveSettings();
                  }
                })

              Text(this.settings.dailyLimitMB + ' MB')
                .fontSize(16)
                .fontColor('#00D4FF')
                .fontWeight(FontWeight.Medium)
                .width(80)
                .textAlign(TextAlign.Center)

              Button('+')
                .width(36)
                .height(36)
                .fontSize(18)
                .fontColor('#E8E8F0')
                .backgroundColor('#2A2A4E')
                .borderRadius(18)
                .onClick(() => {
                  this.settings.dailyLimitMB += 50;
                  this.saveSettings();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .padding({ left: 12, right: 12 })

          Row() {
            Text('Notifications')
              .fontSize(13)
              .fontColor('#E8E8F0')
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.settings.notificationsEnabled })
              .onChange((isOn: boolean) => {
                this.settings.notificationsEnabled = isOn;
                this.saveSettings();
              })
              .selectedColor('#00D4FF')
          }
          .width('100%')
          .padding({ left: 12, right: 12 })

          Button($r('app.string.label_reset_history'))
            .width('80%')
            .height(40)
            .fontSize(13)
            .fontColor('#FF4757')
            .backgroundColor('#2A2A4E')
            .borderRadius(8)
            .onClick(() => {
              this.resetHistory();
            })

          if (this.showConfirmation) {
            Text(this.confirmationMessage)
              .fontSize(12)
              .fontColor('#00FF94')
              .textAlign(TextAlign.Center)
              .width('100%')
              .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
          }
        }
        .width('100%')
        .padding({ bottom: 16 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A2E')
  }
}
