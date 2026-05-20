@Component
export struct UsageRingComponent {
  @Prop usedMB: number = 0;
  @Prop limitMB: number = 500;
  @Prop label: string = 'MB';

  private ringSize: number = 96;

  private get ratio(): number {
    if (this.limitMB <= 0) {
      return 1;
    }
    return Math.min(this.usedMB / this.limitMB, 1);
  }

  private get ringColor(): string {
    if (this.ratio >= 1) {
      return '#FF4757';
    }
    if (this.ratio >= 0.8) {
      return '#00FF94';
    }
    return '#00D4FF';
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Progress({ value: this.ratio * 100, total: 100, type: ProgressType.Ring })
        .width(this.ringSize)
        .height(this.ringSize)
        .style({
          strokeWidth: 8,
          enableScanEffect: false
        })
        .color(this.ringColor)
        .backgroundColor('#2A2A4E')

      Column() {
        Text(this.usedMB.toFixed(1))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8E8F0')
        Text(this.label)
          .fontSize(10)
          .fontColor('#8888AA')
      }
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
}
