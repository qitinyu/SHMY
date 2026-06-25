// LX-HM 空状态占位组件
// EmptyState.ets

const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

@Component
export struct EmptyState {
  icon: ResourceStr = '🔍'
  title: string = '暂无内容'
  subtitle: string = ''

  build() {
    Column({ space: 12 }) {
      // 大图标
      if (typeof this.icon === 'string') {
        Text(this.icon)
          .fontSize(64)
          .opacity(0.4)
      } else {
        Image(this.icon)
          .width(64)
          .height(64)
          .objectFit(ImageFit.Contain)
          .opacity(0.4)
          .fillColor(TEXT_SECONDARY)
      }

      // 标题
      Text(this.title)
        .fontSize(16)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)

      // 副标题
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(40)
  }
}