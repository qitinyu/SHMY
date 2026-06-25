// LX-HM 歌曲卡片组件
// SongCard.ets
import { SongInfo, SourceInfo, createEmptySongInfo } from '../model/MusicModel'

const CARD_BG: string = '#F5F5F5'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

@Component
export struct SongCard {
  song: SongInfo = createEmptySongInfo()
  onPlay?: (song: SongInfo) => void
  onMore?: (song: SongInfo) => void

  @State private isPressed: boolean = false

  build() {
    Row({ space: 12 }) {
      // 封面图片
      Image(this.song.coverUrl)
        .width(44)
        .height(44)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#E0E0E0')

      // 歌曲信息
      Column({ space: 4 }) {
        // 歌曲名
        Text(this.song.songName)
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: '70%' })

        // 歌手 + 音源标签
        Row({ space: 6 }) {
          Text(this.song.artist)
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: '50%' })

          // 音源 Badge
          Text(SourceInfo.getName(this.song.source))
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor(SourceInfo.getColor(this.song.source))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 更多按钮
      Text('⋯')
        .fontSize(20)
        .fontColor(TEXT_SECONDARY)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.onMore) {
            this.onMore(this.song)
          }
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(CARD_BG)
    .borderRadius(12)
    .scale({ x: this.isPressed ? 0.97 : 1, y: this.isPressed ? 0.97 : 1 })
    .animation({ duration: 150 })
    .onClick(() => {
      if (this.onPlay) {
        this.onPlay(this.song)
      }
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          if (this.onMore) {
            this.onMore(this.song)
          }
        })
    )
  }
}
