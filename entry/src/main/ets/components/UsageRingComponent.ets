/**
 * UsageRingComponent — circular progress ring for wearable usage display.
 * Shows used/limit ratio with a colour-coded arc and centre label.
 */
@Component
export struct UsageRingComponent {
  @Prop usedMB: number = 0;
  @Prop limitMB: number = 500;
  @Prop label: string = 'MB';

  private ringSize: number = 120;

  private get ratio(): number {
    if (this.limitMB <= 0) {
      return 1;
    }
    return Math.min(this.usedMB / this.limitMB, 1);
  }

  private get ringColor(): string {
    if (this.ratio >= 1) {
      return '#FF4757'; // accent_red
    }
    if (this.ratio >= 0.8) {
      return '#00FF94'; // accent_green
    }
    return '#00D4FF'; // ring_active
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Progress arc — ring style with track colour as background
      Progress({ value: this.ratio * 100, total: 100, type: ProgressType.Ring })
        .width(this.ringSize)
        .height(this.ringSize)
        .style({
          strokeWidth: 10,
          enableScanEffect: false
        })
        .color(this.ringColor)
        .backgroundColor('#2A2A4E')

      // Centre label — value
      Column() {
        Text(this.usedMB.toFixed(1))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8E8F0')
        Text(this.label)
          .fontSize(11)
          .fontColor('#8888AA')
      }
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
}
