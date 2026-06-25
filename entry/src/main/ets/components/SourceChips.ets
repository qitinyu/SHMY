// LX-HM 音源选择 Chips 组件
// SourceChips.ets - 硬编码避免ForEach响应式问题

const PRIMARY_COLOR: string = '#007DFF'
const CHIP_BG_UNSELECTED: string = '#F0F0F0'
const CHIP_BG_SELECTED: string = PRIMARY_COLOR

@Component
export struct SourceChips {
  @Prop selected: string = 'all'
  onSelect?: (source: string) => void

  build() {
    Row({ space: 8 }) {
      // 全部
      Row({ space: 4 }) {
        Text('\uD83D\uDD0D').fontSize(13)
        Text('\u5168\u90E8').fontSize(13)
          .fontColor(this.selected === 'all' ? Color.White : '#666666')
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(this.selected === 'all' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
      .onClick(() => { if (this.onSelect) { this.onSelect('all') } })

      // 小狗/酷狗
      Row({ space: 4 }) {
        Text('\uD83D\uDC36').fontSize(13)
        Text('\u5C0F\u72D7').fontSize(13)
          .fontColor(this.selected === 'kg' ? Color.White : '#666666')
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(this.selected === 'kg' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
      .onClick(() => { if (this.onSelect) { this.onSelect('kg') } })

      // 小我/酷我
      Row({ space: 4 }) {
        Text('\uD83C\uDFB5').fontSize(13)
        Text('\u5C0F\u6211').fontSize(13)
          .fontColor(this.selected === 'kw' ? Color.White : '#666666')
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(this.selected === 'kw' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
      .onClick(() => { if (this.onSelect) { this.onSelect('kw') } })

      // 小云/网易云
      Row({ space: 4 }) {
        Text('\u2601\uFE0F').fontSize(13)
        Text('\u5C0F\u4E91').fontSize(13)
          .fontColor(this.selected === 'wy' ? Color.White : '#666666')
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(this.selected === 'wy' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
      .onClick(() => { if (this.onSelect) { this.onSelect('wy') } })

      // 小鹅/QQ音乐
      Row({ space: 4 }) {
        Text('\uD83E\uDDA2').fontSize(13)
        Text('\u5C0F\u9E45').fontSize(13)
          .fontColor(this.selected === 'qq' ? Color.White : '#666666')
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(this.selected === 'qq' ? CHIP_BG_SELECTED : CHIP_BG_UNSELECTED)
      .onClick(() => { if (this.onSelect) { this.onSelect('qq') } })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }
}