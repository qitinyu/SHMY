// LX-HM 歌曲操作底部弹窗组件
// SongActionSheet.ets
import { SongInfo, SourceInfo, createEmptySongInfo } from '../model/MusicModel'

const PRIMARY_COLOR: string = '#007DFF'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

interface ActionItem {
  icon: string
  label: string
  action: string
}

const ACTION_LIST: ActionItem[] = [
  { icon: '▶️', label: '播放', action: 'play' },
  { icon: '❤️', label: '收藏', action: 'favorite' },
  { icon: '⏱', label: '稍后播放', action: 'later' },
  { icon: '🔗', label: '分享', action: 'share' },
  { icon: '📋', label: '添加到歌单', action: 'playlist' },
  { icon: '📥', label: '下载', action: 'download' },
]

@Component
export struct SongActionSheet {
  song: SongInfo = createEmptySongInfo()
  visible: boolean = false
  onDismiss?: () => void
  onPlay?: (song: SongInfo) => void
  onAddFavorite?: (song: SongInfo) => void

  @State private sheetVisible: boolean = false

  aboutToAppear(): void {
    this.sheetVisible = this.visible
  }

  aboutToUpdate(): void {
    this.sheetVisible = this.visible
  }

  build() {
    Column() {
      // 触发区域 (空，仅用于绑定 bindSheet)
      Row()
        .width(1)
        .height(1)
        .bindSheet($$this.sheetVisible, this.SheetContent(), {
          height: SheetSize.LARGE,
          dragBar: true,
          showClose: true,
          backgroundColor: '#F8F8FA',
          onDisappear: () => {
            this.visible = false
            this.sheetVisible = false
            if (this.onDismiss) {
              this.onDismiss()
            }
          },
        })
    }
  }

  @Builder
  SheetContent() {
    Column() {
      // 顶部歌曲信息
      Row({ space: 12 }) {
        Image(this.song.coverUrl)
          .width(52)
          .height(52)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#E0E0E0')

        Column({ space: 4 }) {
          Text(this.song.songName)
            .fontSize(16)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: 6 }) {
            Text(this.song.artist)
              .fontSize(13)
              .fontColor(TEXT_SECONDARY)

            Text(SourceInfo.getName(this.song.source))
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor(SourceInfo.getColor(this.song.source))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 16 })

      // 分隔线
      Divider()
        .width('100%')
        .color('#E8E8E8')

      // 操作按钮网格 (2列)
      GridRow({ columns: 2, gutter: { x: 12, y: 12 } }) {
        ForEach(ACTION_LIST, (item: ActionItem) => {
          GridCol() {
            Row({ space: 8 }) {
              Text(item.icon)
                .fontSize(18)

              Text(item.label)
                .fontSize(14)
                .fontColor(TEXT_PRIMARY)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor('#F0F0F0')
            .borderRadius(12)
            .onClick(() => {
              this.handleAction(item.action)
            })
          }
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 40 })
    }
  }

  private handleAction(action: string): void {
    switch (action) {
      case 'play':
        if (this.onPlay) {
          this.onPlay(this.song)
        }
        break
      case 'favorite':
        if (this.onAddFavorite) {
          this.onAddFavorite(this.song)
        }
        break
      default:
        break
    }
    this.sheetVisible = false
    if (this.onDismiss) {
      this.onDismiss()
    }
  }
}
