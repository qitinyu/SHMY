// SHMY 音源选择 Chips 组件
// SourceChips.ets - 单行可滑动
//
// 音源可用性（2026-06 V4.0）：
//   全部  - 搜索酷我+酷狗
//   小我  - 酷我（搜索+播放+歌词+封面）
//   小狗  - 酷狗（搜索+歌词+封面，播放回退酷我）

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
        Text('全部')
          .fontSize(13)
          .fontColor(this.selected === 'all' ? Color.White : '#666666')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selected === 'all' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
          .onClick(() => { if (this.onSelect) { this.onSelect('all') } })

        // 小我/酷我
        Text('小我')
          .fontSize(13)
          .fontColor(this.selected === 'kw' ? Color.White : '#666666')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selected === 'kw' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
          .onClick(() => { if (this.onSelect) { this.onSelect('kw') } })

        // 小狗/酷狗
        Text('小狗')
          .fontSize(13)
          .fontColor(this.selected === 'kg' ? Color.White : '#666666')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.selected === 'kg' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
          .onClick(() => { if (this.onSelect) { this.onSelect('kg') } })
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}
