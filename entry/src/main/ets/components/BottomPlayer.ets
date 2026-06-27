// SHMY 底部播放器组件
// BottomPlayer.ets
import { SongInfo } from '../model/MusicModel'
import { PlayerStore } from '../utils/PlayerStore'
import { DatabaseHelper } from '../database/DatabaseHelper'

const PRIMARY_COLOR: string = '#007DFF'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

@Component
export struct BottomPlayer {
  @StorageProp('currentTrack') currentTrack: SongInfo | null = null
  @StorageProp('isPlaying') isPlaying: boolean = false
  @StorageProp('currentTime') currentTime: number = 0
  @StorageProp('duration') duration: number = 0
  @StorageProp('autoJumpDetail') autoJumpDetail: boolean = false

  private progress: number = 0
  private db: DatabaseHelper = DatabaseHelper.getInstance()

  aboutToAppear(): void {
    this.updateProgress()
    this.loadAutoJumpSetting()
  }

  private updateProgress(): void {
    if (this.duration > 0) {
      this.progress = this.currentTime / this.duration
    } else {
      this.progress = 0
    }
  }

  private async loadAutoJumpSetting(): Promise<void> {
    const val = await this.db.getSetting('autoJumpDetail')
    if (val === 'true') {
      AppStorage.setOrCreate('autoJumpDetail', true)
    } else {
      AppStorage.setOrCreate('autoJumpDetail', false)
    }
  }

  // 统一跳转到完整播放器
  private goToFullPlayer(): void {
    PlayerStore.showFullPlayer()
  }

  build() {
    if (!this.currentTrack) {
      Column()
        .height(0)
    } else {
      Column() {
        // 顶部进度条
        Row()
          .width('100%')
          .height(2)
          .backgroundColor('#E8E8E8')
          .borderRadius({ topLeft: 20, topRight: 20 })
        Row()
          .width(`${Math.min(this.progress * 100, 100)}%`)
          .height(2)
          .backgroundColor(PRIMARY_COLOR)
          .position({ x: 0, y: 0 })

        // 播放器内容行
        Row({ space: 12 }) {
          // 封面图
          Image(this.currentTrack!.coverUrl)
            .width(44)
            .height(44)
            .borderRadius(10)
            .objectFit(ImageFit.Cover)
            .backgroundColor('#E0E0E0')

          // 歌曲信息
          Column({ space: 2 }) {
            Text(this.currentTrack!.songName)
              .fontSize(14)
              .fontColor(TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: '60%' })

            Text(this.currentTrack!.artist)
              .fontSize(12)
              .fontColor(TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 上一首按钮
          Row() {
            SymbolGlyph($r('sys.symbol.backward_fill'))
              .fontSize(20)
              .fontColor([TEXT_PRIMARY])
          }
          .width(32)
          .height(32)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            PlayerStore.previous()
          })

          // 播放/暂停按钮
          Row() {
            SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
              .fontSize(16)
              .fontColor([Color.White])
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(PRIMARY_COLOR)
          .justifyContent(FlexAlign.Center)
          .shadow({ radius: 8, color: '#1A80FF40', offsetY: 2 })
          .onClick(() => {
            PlayerStore.togglePlay()
          })

          // 下一首按钮
          Row() {
            SymbolGlyph($r('sys.symbol.forward_end_fill'))
              .fontSize(20)
              .fontColor([TEXT_PRIMARY])
          }
          .width(32)
          .height(32)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            PlayerStore.next()
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20 })
      .shadow({
        radius: 16,
        color: '#00000012',
        offsetY: -4,
      })
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })
      .onClick(() => {
        this.goToFullPlayer()
      })
    }
  }
}