// SHMY 搜索栏组件
// SearchBar.ets

const PRIMARY_COLOR: string = '#007DFF'
const SEARCH_BG: string = '#F0F0F0'

@Component
export struct SearchBar {
  @Prop keyword: string = ''
  onKeywordChange?: (keyword: string) => void
  onSearch?: (keyword: string) => void
  onClear?: () => void

  build() {
    Row({ space: 8 }) {
      // 搜索图标
      Text('\uD83D\uDD0D')
        .fontSize(16)
        .margin({ left: 12 })

      // 搜索输入框
      TextInput({ placeholder: '\u641C\u7D22\u6B4C\u66F2\u3001\u6B4C\u624B', text: this.keyword })
        .layoutWeight(1)
        .height(36)
        .backgroundColor(Color.Transparent)
        .fontSize(14)
        .fontColor('#1A1A1A')
        .placeholderColor('#999999')
        .placeholderFont({ size: 14 })
        .onChange((value: string) => {
          if (this.onKeywordChange) {
            this.onKeywordChange(value)
          }
        })
        .onSubmit(() => {
          if (this.onSearch && this.keyword.trim().length > 0) {
            this.onSearch(this.keyword.trim())
          }
        })

      // 清除按钮
      if (this.keyword.length > 0) {
        Text('\u2715')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 4 })
          .onClick(() => {
            if (this.onClear) {
              this.onClear()
            }
          })
      }

      // 搜索按钮
      Button('\u641C\u7D22')
        .height(32)
        .padding({ left: 14, right: 14 })
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor(PRIMARY_COLOR)
        .borderRadius(16)
        .margin({ right: 4 })
        .onClick(() => {
          if (this.onSearch && this.keyword.trim().length > 0) {
            this.onSearch(this.keyword.trim())
          }
        })
    }
    .height(40)
    .backgroundColor(SEARCH_BG)
    .borderRadius(20)
    .padding({ left: 4, right: 4 })
  }
}