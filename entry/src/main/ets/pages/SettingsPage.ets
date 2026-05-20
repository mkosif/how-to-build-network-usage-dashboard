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

  @Builder
  StepButton(label: string, onTap: () => void) {
    Column() {
      Text(label)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#E8E8F0')
        .textAlign(TextAlign.Center)
        .lineHeight(36)
    }
    .width(36)
    .height(36)
    .borderRadius(18)
    .backgroundColor('#2A2A4E')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(onTap)
  }

  build() {
    Column({ space: 0 }) {
      Text($r('app.string.settings_title'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8E8F0')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 10, bottom: 8 })

      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 6 }) {
            Text($r('app.string.label_limit'))
              .fontSize(11)
              .fontColor('#8888AA')
              .width('100%')
              .textAlign(TextAlign.Center)
            Row({ space: 8 }) {
              this.StepButton('−', () => {
                if (this.settings.usageLimitMB > 50) {
                  this.settings.usageLimitMB -= 50;
                  this.saveSettings();
                }
              })

              Text(`${this.settings.usageLimitMB} MB`)
                .fontSize(15)
                .fontColor('#00D4FF')
                .fontWeight(FontWeight.Medium)
                .width(76)
                .textAlign(TextAlign.Center)

              this.StepButton('+', () => {
                this.settings.usageLimitMB += 50;
                this.saveSettings();
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }

          Row() {
            Text('Notifications')
              .fontSize(13)
              .fontColor('#E8E8F0')
              .layoutWeight(1)
              .padding({ left: 12 })
            Toggle({ type: ToggleType.Switch, isOn: this.settings.notificationsEnabled })
              .onChange((isOn: boolean) => {
                this.settings.notificationsEnabled = isOn;
                this.saveSettings();
              })
              .selectedColor('#00D4FF')
              .margin({ right: 12 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Button($r('app.string.label_reset_history'))
            .width('76%')
            .height(36)
            .fontSize(12)
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

          Blank().height(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A2E')
  }
}
