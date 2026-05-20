import { MetricTileComponent } from './MetricTileComponent';

@Component
export struct InterfaceRowComponent {
  @Prop ifaceName: string = '';
  @Prop rxMB: number = 0;
  @Prop txMB: number = 0;
  @Prop accentColor: string = '#00D4FF';

  build() {
    Row({ space: 6 }) {
      Text(this.ifaceName === 'all' ? 'All' : (this.ifaceName === 'app' ? 'App UID' : this.ifaceName))
        .fontSize(13)
        .fontColor('#E8E8F0')
        .fontWeight(FontWeight.Medium)
        .width(60)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      MetricTileComponent({
        label: 'Received',
        value: `${this.rxMB.toFixed(1)} MB`,
        accentColor: this.accentColor
      })

      MetricTileComponent({
        label: 'Sent',
        value: `${this.txMB.toFixed(1)} MB`,
        accentColor: '#8888AA'
      })
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
  }
}
