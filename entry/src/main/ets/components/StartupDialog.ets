// LX-HM 公告弹窗组件 - 悬浮卡片样式
// StartupDialog.ets

const PRIMARY_COLOR: string = '#007DFF'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

@Component
export struct StartupDialog {
  @StorageProp('showStartup') showStartup: boolean = true
  onDismiss?: (dontShowToday: boolean) => void

  @State dontShowToday: boolean = false

  // 更新内容
  private updateContents: string[] = [
    '全新 HarmonyOS 原生体验，流畅如丝',
    '多音源聚合搜索，一键找到想听的歌',
    '支持酷狗、酷我、网易云音乐、QQ音乐',
    '沉浸式歌词显示，桌面歌词模式',
    '离线下载，随时随地畅听',
    '个性化设置，定制你的播放器',
  ]

  build() {
    if (!this.showStartup) {
      Column()
        .height(0)
        .width(0)
    } else {
      Stack() {
        // 半透明遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#0000004D')

        // 悬浮卡片
        Column() {
          // 渐变头部
          Stack() {
            Column({ space: 6 }) {
              // 音乐符号图标
              Text('\u266A')
                .fontSize(28)
                .fontColor('#FFFFFF')

              Text('LX-HM 音乐播放器')
                .fontSize(20)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)

              Text('轩窗 \u00B7 琴瑟 \u00B7 陋室')
                .fontSize(13)
                .fontColor('#FFFFFFB3')
            }
            .alignItems(HorizontalAlign.Center)

            // 关闭按钮
            Text('\u2715')
              .fontSize(20)
              .fontColor('#FFFFFFCC')
              .width(36)
              .height(36)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.doDismiss()
              })
          }
          .width('100%')
          .padding({ top: 28, bottom: 24, left: 20, right: 20 })
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [[PRIMARY_COLOR, 0], ['#0059B3', 1]],
          })

          // 版本信息
          Row() {
            Text('最新版本')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
              .layoutWeight(1)

            Text('V1.0.1')
              .fontSize(14)
              .fontColor(TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 20 })

          // 更新地址
          Row() {
            Text('更新地址')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
              .layoutWeight(1)

            Text('github.com/LX-HM/releases')
              .fontSize(12)
              .fontColor(PRIMARY_COLOR)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: '55%' })
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 12 })

          // 分割线
          Row()
            .width('100%')
            .height(1)
            .backgroundColor('#F0F0F0')
            .margin({ top: 16, bottom: 4 })

          // 更新内容标题
          Text('V1.0.1 更新内容')
            .fontSize(15)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 24, right: 24, top: 16, bottom: 12 })

          // 更新内容列表
          Column({ space: 0 }) {
            ForEach(this.updateContents, (item: string) => {
              Row({ space: 10 }) {
                Text('\u2022')
                  .fontSize(14)
                  .fontColor(PRIMARY_COLOR)
                  .width(16)

                Text(item)
                  .fontSize(14)
                  .fontColor('#444444')
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 7, bottom: 7 })
              .alignItems(VerticalAlign.Top)
            })
          }
          .width('100%')
          .padding({ left: 24, right: 24 })

          // 底部操作区
          Column({ space: 12 }) {
            // 开始使用按钮
            Button('开始使用')
              .width('100%')
              .height(46)
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(PRIMARY_COLOR)
              .borderRadius(23)
              .onClick(() => {
                this.doDismiss()
              })

            // 今日不再弹出
            Row({ space: 8 }) {
              // 自定义复选框
              Row() {
                if (this.dontShowToday) {
                  Text('\u2713')
                    .fontSize(11)
                    .fontColor(Color.White)
                }
              }
              .width(18)
              .height(18)
              .borderRadius(4)
              .border({ width: 1.5, color: this.dontShowToday ? PRIMARY_COLOR : '#CCCCCC' })
              .backgroundColor(this.dontShowToday ? PRIMARY_COLOR : Color.White)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.dontShowToday = !this.dontShowToday
              })

              Text('今日不再弹出')
                .fontSize(13)
                .fontColor(TEXT_SECONDARY)
            }
            .onClick(() => {
              this.dontShowToday = !this.dontShowToday
            })
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 16, bottom: 28 })
        }
        .width('82%')
        .constraintSize({ maxHeight: '80%' })
        .backgroundColor(Color.White)
        .borderRadius(16)
        .clip(true)
        .shadow({ radius: 30, color: '#00000026', offsetY: 8 })
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
  }

  private doDismiss(): void {
    AppStorage.setOrCreate('showStartup', false)
    this.showStartup = false
    if (this.onDismiss) {
      this.onDismiss(this.dontShowToday)
    }
  }
}