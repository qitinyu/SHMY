// SHMY 设置项组件
// SettingItem.ets
// 支持 string（文字）、sys.symbol.*（SymbolGlyph）、app.media.*（Image SVG）
// useImage=true 时使用 Image 渲染（用于 SVG 图标），否则使用 SymbolGlyph

const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

@Component
export struct SettingItem {
  icon: ResourceStr = ''
  iconBgColor: string = '#F0F0F0'
  title: string = ''
  description: string = ''
  switchChecked: boolean = false
  onSwitchChange?: (checked: boolean) => void
  hasSwitch: boolean = false
  useImage: boolean = false

  build() {
    Row({ space: 12 }) {
      Row() {
        if (typeof this.icon === 'string') {
          Text(this.icon as string)
            .fontSize(18)
            .fontColor(Color.White)
        } else if (this.useImage) {
          Image(this.icon as Resource)
            .width(20)
            .height(20)
            .fillColor(Color.White)
        } else {
          SymbolGlyph(this.icon as Resource)
            .fontSize(20)
            .fontColor([Color.White])
        }
      }
      .width(40)
      .height(40)
      .borderRadius(10)
      .backgroundColor(this.iconBgColor)
      .justifyContent(FlexAlign.Center)

      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)

        if (this.description.length > 0) {
          Text(this.description)
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.hasSwitch) {
        Toggle({ type: ToggleType.Switch, isOn: this.switchChecked })
          .selectedColor('#007DFF')
          .onChange((isOn: boolean) => {
            if (this.onSwitchChange) {
              this.onSwitchChange(isOn)
            }
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
  }
}
