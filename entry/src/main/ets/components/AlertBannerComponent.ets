/**
 * AlertBannerComponent — full-width alert bar shown when usage exceeds limit.
 * Animates in/out based on the `visible` prop.
 */
@Component
export struct AlertBannerComponent {
  @Prop visible: boolean = false;
  @Prop message: ResourceStr = 'Limit Exceeded';

  build() {
    if (this.visible) {
      Row() {
        Text(this.message)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .height(28)
      .backgroundColor('#FF4757')
      .justifyContent(FlexAlign.Center)
      .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
    }
  }
}
