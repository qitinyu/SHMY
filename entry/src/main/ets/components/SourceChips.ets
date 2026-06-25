// SHMY 音源选择 Chips 组件
// SourceChips.ets - 去掉emoji，单行可滑动

const PRIMARY_COLOR: string = '#007DFF'
const CHIP_BG_UNSELECTED: string = '#F0F0F0'
const CHIP_BG_SELECTED: string = PRIMARY_COLOR

@Component
export struct SourceChips {
  @Prop selected: string = 'all'
  onSelect?: (source: string) => void

  build() {
    Scroll(new Scroller()) {
      Row({ space: 8 }) {
        // 全部
        Text('\u5168\u90E8')
          .fontSize(13)
          .fontColor(this.selected === 'all' ? Color.White : '#666666')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selected === 'all' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
          .onClick(() => { if (this.onSelect) { this.onSelect('all') } })

        // 小狗/酷狗
        Text('\u5C0F\u72D7')
          .fontSize(13)
          .fontColor(this.selected === 'kg' ? Color.White : '#666666')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selected === 'kg' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
          .onClick(() => { if (this.onSelect) { this.onSelect('kg') } })

        // 小我/酷我
        Text('\u5C0F\u6211')
          .fontSize(13)
          .fontColor(this.selected === 'kw' ? Color.White : '#666666')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selected === 'kw' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
          .onClick(() => { if (this.onSelect) { this.onSelect('kw') } })

        // 小云/网易云
        Text('\u5C0F\u4E91')
          .fontSize(13)
          .fontColor(this.selected === 'wy' ? Color.White : '#666666')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selected === 'wy' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
          .onClick(() => { if (this.onSelect) { this.onSelect('wy') } })

        // 小鹅/QQ音乐
        Text('\u5C0F\u9E45')
          .fontSize(13)
          .fontColor(this.selected === 'qq' ? Color.White : '#666666')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selected === 'qq' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
          .onClick(() => { if (this.onSelect) { this.onSelect('qq') } })
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}