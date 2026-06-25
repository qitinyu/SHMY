// SHMY 顶部导航栏组件
// AppHeader.ets - 可见Tab栏，固定顶部

const PRIMARY_COLOR: string = '#007DFF'
const TEXT_PRIMARY: string = '#1A1A1A'

@Component
export struct AppHeader {
  @Prop activeTab: number = 0
  onTabChange?: (index: number) => void

  build() {
    Row() {
      // 左侧：Logo + SHMY MUSIC
      Row({ space: 6 }) {
        Image($r('app.media.logo'))
          .width(28)
          .height(28)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)

        Text('SHMY MUSIC')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
          .letterSpacing(1)
      }
      .margin({ right: 12 })

      // 占位，将Tab推向右侧
      Row()
        .layoutWeight(1)

      // Tab: 轩窗
      Column() {
        Text('\u8F69\u7A97')
          .fontSize(15)
          .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === 0 ? PRIMARY_COLOR : '#666666')
        Row()
          .width(20)
          .height(3)
          .borderRadius(1.5)
          .backgroundColor(this.activeTab === 0 ? PRIMARY_COLOR : Color.Transparent)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 14, right: 14, top: 12, bottom: 8 })
      .onClick(() => {
        if (this.onTabChange) {
          this.onTabChange(0)
        }
      })

      // Tab: 琴瑟
      Column() {
        Text('\u7434\u745F')
          .fontSize(15)
          .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === 1 ? PRIMARY_COLOR : '#666666')
        Row()
          .width(20)
          .height(3)
          .borderRadius(1.5)
          .backgroundColor(this.activeTab === 1 ? PRIMARY_COLOR : Color.Transparent)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 14, right: 14, top: 12, bottom: 8 })
      .onClick(() => {
        if (this.onTabChange) {
          this.onTabChange(1)
        }
      })

      // Tab: 陋室
      Column() {
        Text('\u964B\u5BA4')
          .fontSize(15)
          .fontWeight(this.activeTab === 2 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === 2 ? PRIMARY_COLOR : '#666666')
        Row()
          .width(20)
          .height(3)
          .borderRadius(1.5)
          .backgroundColor(this.activeTab === 2 ? PRIMARY_COLOR : Color.Transparent)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 14, right: 14, top: 12, bottom: 8 })
      .onClick(() => {
        if (this.onTabChange) {
          this.onTabChange(2)
        }
      })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius({ bottomLeft: 0, bottomRight: 0 })
    .shadow({ radius: 4, color: '#0000000D', offsetY: 2 })
  }
}