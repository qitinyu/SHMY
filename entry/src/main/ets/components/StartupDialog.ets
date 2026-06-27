// SHMY 开屏弹窗组件
// StartupDialog.ets - V1.0.2

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
    '\u4FEE\u590D\u5168\u97F3\u6E90\u641C\u7D22\u529F\u80FD\uFF0C\u652F\u6301\u9177\u72D7/\u9177\u6211/\u7F51\u6613\u4E91/QQ\u97F3\u4E50',
    '\u641C\u7D22\u7ED3\u679C\u53CC\u51FB\u5373\u53EF\u64AD\u653E',
    '\u957F\u6309\u6B4C\u66F2\u5F39\u51FA\u7CBE\u7B80\u64CD\u4F5C\u83DC\u5355',
    '\u5168\u65B0\u5361\u7247\u5F0F\u641C\u7D22\u7ED3\u679C\u5C55\u793A',
    '\u6536\u85CF\u4E0E\u6B4C\u5355\u4F4D\u7F6E\u4F18\u5316\uFF0C\u652F\u6301\u6298\u53E0',
    '\u5F00\u5C4F\u5F39\u7A97\u5168\u65B0\u8BBE\u8BA1',
    '\u5168\u5C40\u56FE\u6807\u66FF\u6362\u4E3A\u534E\u4E3A\u98CE\u683C',
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
          // 渐变头部 - 水平排列
          Row({ space: 14 }) {
            // 左侧：Logo
            Image($r('app.media.logo'))
              .width(48)
              .height(48)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
              .shadow({ radius: 10, color: '#00000040', offsetY: 3 })

            // 右侧：软件名 + 标语
            Column({ space: 4 }) {
              Text('SHMY')
                .fontSize(20)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
                .letterSpacing(1)

              Text('\u542C\u4F60\u60F3\u542C \u00B7 \u56DE\u5F52\u97F3\u4E50\u672C\u8D28')
                .fontSize(12)
                .fontColor('#FFFFFFB3')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .alignItems(VerticalAlign.Center)
          .width('100%')
          .padding({ top: 24, bottom: 20, left: 24, right: 24 })
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [[PRIMARY_COLOR, 0], ['#0059B3', 1]],
          })

          // 版本信息
          Row() {
            Text('\u6700\u65B0\u7248\u672C')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
              .layoutWeight(1)

            Text('V1.0.2')
              .fontSize(14)
              .fontColor(TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 20 })

          // 更新地址
          Row() {
            Text('\u66F4\u65B0\u5730\u5740')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
              .layoutWeight(1)

            Text('github.com/SHMY/releases')
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
          Text('V1.0.2 \u66F4\u65B0\u5185\u5BB9')
            .fontSize(15)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 24, right: 24, top: 16, bottom: 12 })

          // 更新内容列表 - 可滑动
          Scroll() {
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
          }
          .constraintSize({ maxHeight: '35%' })
          .scrollBar(BarState.Auto)
          .width('100%')

          // 底部操作区
          Column({ space: 12 }) {
            // 开始使用按钮
            Button('\u5F00\u59CB\u4F7F\u7528')
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

              Text('\u4ECA\u65E5\u4E0D\u518D\u5F39\u51FA')
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