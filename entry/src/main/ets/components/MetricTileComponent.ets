/**
 * MetricTileComponent — compact label + value tile for wearable dashboards.
 */
@Component
export struct MetricTileComponent {
  @Prop label: string = '';
  @Prop value: string = '0';
  @Prop accentColor: string = '#E8E8F0';

  build() {
    Column({ space: 2 }) {
      Text(this.label)
        .fontSize(11)
        .fontColor('#8888AA')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.accentColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(100)
    .height(56)
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
    .backgroundColor('#16213E')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
