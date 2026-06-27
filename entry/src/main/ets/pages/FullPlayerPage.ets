// SHMY 完整播放器页面
// FullPlayerPage.ets
import router from '@ohos.router'
import { SongInfo, LyricLine } from '../model/MusicModel'
import { AudioPlayer } from '../utils/AudioPlayer'
import { MusicApi } from '../utils/MusicApi'
import { PlayerStore } from '../utils/PlayerStore'
import { DatabaseHelper } from '../database/DatabaseHelper'

const PRIMARY_COLOR: string = '#007DFF'
const BG_COLOR: string = '#F8F8FA'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

@Entry
@Component
struct FullPlayerPage {
  @StorageProp('currentTrack') currentTrack: SongInfo | null = null
  @StorageProp('isPlaying') isPlaying: boolean = false
  @StorageProp('currentTime') currentTime: number = 0
  @StorageProp('duration') duration: number = 0
  @StorageProp('lyrics') lyrics: LyricLine[] = []
  @StorageProp('fullPlayerPage') fullPlayerPage: string = 'cover'

  @State localPage: string = 'cover'
  @State progress: number = 0
  @State rotationAngle: number = 0
  @State currentLyricIndex: number = 0

  private lyricsScroller: Scroller = new Scroller()
  private rotateTimer: number = -1
  private progressTimer: number = -1
  private db: DatabaseHelper = DatabaseHelper.getInstance()

  aboutToAppear(): void {
    this.localPage = this.fullPlayerPage

    // Receive optional params from router
    const params = router.getParams() as Record<string, Object> | undefined
    if (params) {
      const pageVal = params['page']
      if (pageVal !== undefined && pageVal !== null) {
        const page = pageVal as string
        if (page === 'cover' || page === 'lyrics') {
          this.localPage = page
          PlayerStore.setFullPlayerPage(page)
        }
      }
    }

    // Load lyrics for current track
    if (this.currentTrack) {
      this.loadLyrics()
    }

    // Start progress timer
    this.startProgressTimer()
    this.startRotationAnimation()

    // 配置播放器回调
    this.setupPlayerCallbacks()
  }

  aboutToDisappear(): void {
    if (this.rotateTimer !== -1) {
      clearInterval(this.rotateTimer)
    }
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer)
    }
  }

  // 配置音频播放器的回调
  private setupPlayerCallbacks(): void {
    const player = AudioPlayer.getInstance()
    player.onTimeUpdate = (time: number) => {
      PlayerStore.updateTime(time)
    }
    player.onDurationUpdate = (dur: number) => {
      PlayerStore.updateDuration(dur)
    }
    player.onPlayEnd = () => {
      // 歌曲结束自动播下一首
      const nextTrack = PlayerStore.onTrackEnd()
      if (nextTrack) {
        this.playNewTrack(nextTrack)
      } else {
        PlayerStore.pause()
      }
    }
    player.onError = (_error: string) => {
      PlayerStore.pause()
    }
  }

  // 播放新曲目（切歌时调用）
  private async playNewTrack(track: SongInfo): Promise<void> {
    // 获取播放链接
    let playUrl = track.playUrl
    if (!playUrl) {
      playUrl = await MusicApi.getPlayUrl(track)
    }
    if (!playUrl) {
      PlayerStore.pause()
      return
    }

    track.playUrl = playUrl
    PlayerStore.play(track)

    // 加载新歌词
    this.loadLyrics()

    // 重置进度
    this.progress = 0
    this.currentLyricIndex = 0
    this.lyricsScroller.scrollToIndex(0)

    // 播放
    await AudioPlayer.getInstance().play(playUrl)
  }

  private async loadLyrics(): Promise<void> {
    if (!this.currentTrack) return
    try {
      const raw = await MusicApi.getLyrics(this.currentTrack.songId, this.currentTrack.source)
      if (raw && raw.length > 0) {
        const parsed = PlayerStore.parseLrc(raw)
        PlayerStore.setLyrics(parsed, raw)
        this.currentLyricIndex = 0
      }
    } catch (_e) {
      console.error('[FullPlayerPage] loadLyrics failed')
    }
  }

  private startProgressTimer(): void {
    this.progressTimer = setInterval(() => {
      // Update progress from StorageProp
      if (this.duration > 0) {
        this.progress = this.currentTime / this.duration
      } else {
        this.progress = 0
      }
      // Update current lyric index
      this.updateCurrentLyricIndex()
    }, 500)
  }

  private startRotationAnimation(): void {
    this.rotateTimer = setInterval(() => {
      if (this.isPlaying) {
        this.rotationAngle += 0.45
        if (this.rotationAngle >= 360) {
          this.rotationAngle -= 360
        }
      }
    }, 500)
  }

  private updateCurrentLyricIndex(): void {
    if (this.lyrics.length === 0) {
      this.currentLyricIndex = 0
      return
    }
    for (let i = this.lyrics.length - 1; i >= 0; i--) {
      if (this.currentTime >= this.lyrics[i].time) {
        if (i !== this.currentLyricIndex) {
          this.currentLyricIndex = i
          // Auto scroll to current lyric
          this.lyricsScroller.scrollToIndex(i)
        }
        break
      }
    }
  }

  private formatTime(seconds: number): string {
    const min = Math.floor(seconds / 60)
    const sec = Math.floor(seconds % 60)
    return `${min.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`
  }

  private async togglePlayPause(): Promise<void> {
    if (this.isPlaying) {
      await AudioPlayer.getInstance().pause()
      PlayerStore.pause()
    } else {
      await AudioPlayer.getInstance().resume()
      PlayerStore.resume()
    }
  }

  private async seekTo(position: number): Promise<void> {
    const time = position * this.duration
    await AudioPlayer.getInstance().seekTo(time)
    PlayerStore.updateTime(time)
    this.progress = position
  }

  private async handlePrevious(): Promise<void> {
    const track = PlayerStore.previous()
    if (track) {
      await this.playNewTrack(track)
    }
  }

  private async handleNext(): Promise<void> {
    const track = PlayerStore.next()
    if (track) {
      await this.playNewTrack(track)
    }
  }

  // 记忆播放进度
  private async saveProgress(): Promise<void> {
    if (!this.currentTrack) return
    const shouldRemember = await this.db.getSetting('rememberProgress')
    if (shouldRemember === 'true' && this.currentTime > 0) {
      const key = `progress_${this.currentTrack.songId}_${this.currentTrack.source}`
      await this.db.setSetting(key, String(this.currentTime))
    }
  }

  // 恢复播放进度
  private async restoreProgress(): Promise<void> {
    if (!this.currentTrack) return
    const shouldRemember = await this.db.getSetting('rememberProgress')
    if (shouldRemember === 'true') {
      const key = `progress_${this.currentTrack.songId}_${this.currentTrack.source}`
      const savedTime = await this.db.getSetting(key)
      if (savedTime) {
        const time = parseFloat(savedTime)
        if (time > 0 && this.duration > 0) {
          await this.seekTo(time / this.duration)
        }
      }
    }
  }

  build() {
    Stack() {
      // Background gradient
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [[BG_COLOR, 0], ['#E8EEFF', 1]],
        })

      Column() {
        // Top bar with back button
        Row({ space: 12 }) {
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(26)
              .fontColor([TEXT_PRIMARY])
          }
          .width(40)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.saveProgress()
            PlayerStore.hideFullPlayer()
            router.back()
          })

          Text(this.currentTrack?.songName ?? '播放器')
            .fontSize(16)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // Placeholder for symmetry
          Row()
            .width(40)
            .height(40)
        }
        .width('100%')
        .height(56)
        .padding({ left: 8, right: 16 })
        .alignItems(VerticalAlign.Center)

        // Page switcher area (swipe)
        if (this.currentTrack) {
          // Gesture-based page switching
          Row() {
            if (this.localPage === 'cover') {
              this.CoverView()
            } else {
              this.LyricsView()
            }
          }
          .width('100%')
          .layoutWeight(1)
          .gesture(
            PanGesture({ direction: PanDirection.Horizontal })
              .onActionEnd((event: GestureEvent) => {
                const offsetX = event.offsetX
                if (offsetX < -50) {
                  // Swipe left -> lyrics
                  this.localPage = 'lyrics'
                  PlayerStore.setFullPlayerPage('lyrics')
                } else if (offsetX > 50) {
                  // Swipe right -> cover
                  this.localPage = 'cover'
                  PlayerStore.setFullPlayerPage('cover')
                }
              })
          )

          // Bottom control area
          this.ControlBar()
        } else {
          Column() {
            Image($r('app.media.music_note'))
              .width(64)
              .height(64)
              .fillColor(TEXT_SECONDARY)
              .opacity(0.3)
            Text('暂无播放内容')
              .fontSize(15)
              .fontColor(TEXT_SECONDARY)
              .margin({ top: 16 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CoverView() {
    Column({ space: 24 }) {
      // Rotating cover
      Column() {
        Image(this.currentTrack?.coverUrl)
          .width(240)
          .height(240)
          .borderRadius(120)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#E0E0E0')
          .rotate({ angle: this.rotationAngle })
          .border({ width: 6, color: '#FFFFFF40' })
          .shadow({ radius: 30, color: '#007DFF30', offsetY: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 24 })

      // Song info
      Column({ space: 6 }) {
        Text(this.currentTrack?.songName ?? '')
          .fontSize(20)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)

        Text(this.currentTrack?.artist ?? '')
          .fontSize(15)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      // Progress slider
      Column({ space: 8 }) {
        Slider({
          value: this.progress,
          min: 0,
          max: 1,
          step: 0.001,
        })
          .width('100%')
          .blockColor(PRIMARY_COLOR)
          .selectedColor(PRIMARY_COLOR)
          .trackColor('#E0E0E0')
          .showSteps(false)
          .onChange((value: number, _mode: SliderChangeMode) => {
            this.seekTo(value)
          })

        Row() {
          Text(this.formatTime(this.currentTime))
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)

          Blank().layoutWeight(1)

          Text(this.formatTime(this.duration))
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
  }

  @Builder
  LyricsView() {
    if (this.lyrics.length === 0) {
      Column() {
        SymbolGlyph($r('sys.symbol.mic'))
          .fontSize(48)
          .fontColor([TEXT_SECONDARY])
          .opacity(0.3)
        Text('暂无歌词')
          .fontSize(15)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 12 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List({ scroller: this.lyricsScroller }) {
        ForEach(this.lyrics, (line: LyricLine, index?: number) => {
          ListItem() {
            Text(line.text)
              .fontSize(this.currentLyricIndex === index ? 18 : 15)
              .fontColor(this.currentLyricIndex === index ? TEXT_PRIMARY : TEXT_SECONDARY)
              .fontWeight(this.currentLyricIndex === index ? FontWeight.Bold : FontWeight.Normal)
              .opacity(this.currentLyricIndex === index ? 1 : 0.5)
              .width('100%')
              .padding({ left: 32, right: 32, top: 12, bottom: 12 })
              .textAlign(TextAlign.Center)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: 60, bottom: 60 })
      .alignListItem(ListItemAlign.Center)
      .scrollBar(BarState.Off)
      .cachedCount(10)
    }
  }

  @Builder
  ControlBar() {
    Column({ space: 16 }) {
      // Control buttons
      Row({ space: 32 }) {
        // Shuffle
        Row() {
          SymbolGlyph($r('sys.symbol.shuffle'))
            .fontSize(22)
            .fontColor([TEXT_PRIMARY])
            .opacity(0.6)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)

        // Previous
        Row() {
          SymbolGlyph($r('sys.symbol.backward_fill'))
            .fontSize(28)
            .fontColor([TEXT_PRIMARY])
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.handlePrevious()
        })

        // Play/Pause
        Row() {
          SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
            .fontSize(24)
            .fontColor([Color.White])
        }
        .width(60)
        .height(60)
        .borderRadius(30)
        .backgroundColor(PRIMARY_COLOR)
        .justifyContent(FlexAlign.Center)
        .shadow({ radius: 16, color: '#007DFF50', offsetY: 4 })
        .onClick(() => {
          this.togglePlayPause()
        })

        // Next
        Row() {
          SymbolGlyph($r('sys.symbol.forward_end_fill'))
            .fontSize(28)
            .fontColor([TEXT_PRIMARY])
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.handleNext()
        })

        // Repeat
        Row() {
          SymbolGlyph($r('sys.symbol.repeat'))
            .fontSize(22)
            .fontColor([TEXT_PRIMARY])
            .opacity(0.6)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ top: 16, bottom: 40, left: 24, right: 24 })
  }
}