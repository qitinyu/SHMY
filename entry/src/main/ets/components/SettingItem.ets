// SHMY 设置项组件
// SettingItem.ets

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

  // 是否显示开关
  hasSwitch: boolean = false

  build() {
    Row({ space: 12 }) {
      // 图标
      Row() {
        if (typeof this.icon === 'string') {
          Text(this.icon)
            .fontSize(18)
            .fontColor(Color.White)
        } else {
          Image(this.icon)
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
      }
      .width(40)
      .height(40)
      .borderRadius(10)
      .backgroundColor(this.iconBgColor)
      .justifyContent(FlexAlign.Center)

      // 标题和描述
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

      // Toggle Switch
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