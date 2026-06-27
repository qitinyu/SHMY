// SHMY 歌曲卡片组件
// SongCard.ets
import { SongInfo, SourceInfo, createEmptySongInfo } from '../model/MusicModel'

const CARD_BG: string = '#F5F5F5'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

@Component
export struct SongCard {
  song: SongInfo = createEmptySongInfo()
  onPlay: (song: SongInfo) => void = (_s: SongInfo) => {}
  onMore: (song: SongInfo) => void = (_s: SongInfo) => {}

  // 保留字段以兼容现有调用，但不再影响手势行为
  doubleTapToPlay: boolean = false

  build() {
    Row({ space: 10 }) {
      // 左侧封面图片 48x48
      Image(this.song.coverUrl)
        .width(48)
        .height(48)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#E0E0E0')
        .flexShrink(0)
        .alt($r('app.media.music_note'))

      // 右侧信息区 — 点击播放
      Column({ space: 3 }) {
        Text(this.song.songName)
          .fontSize(14)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 6 }) {
          Text(this.song.artist)
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // 音源标签
          Text(SourceInfo.getCodeName(this.song.source))
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor(SourceInfo.getColor(this.song.source))
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .borderRadius(4)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => {
        this.onPlay(this.song)
      })

      // 右侧更多按钮
      Row() {
        Image($r('app.media.icon_ellipsis'))
          .width(18)
          .height(18)
          .fillColor(TEXT_SECONDARY)
      }
      .width(36)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.onMore(this.song)
      })
    }
    .width('100%')
    .padding({ left: 12, right: 8, top: 8, bottom: 8 })
    .borderRadius(10)
    .backgroundColor(CARD_BG)
  }
}
