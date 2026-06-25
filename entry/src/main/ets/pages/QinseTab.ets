// SHMY 琴瑟 Tab - 搜索与播放
// QinseTab.ets
import { SongInfo } from '../model/MusicModel'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { AudioPlayer } from '../utils/AudioPlayer'
import { MusicApi } from '../utils/MusicApi'
import { PlayerStore } from '../utils/PlayerStore'
import { SongCard } from '../components/SongCard'
import { SearchBar } from '../components/SearchBar'
import { SourceChips } from '../components/SourceChips'
import { SongActionSheet } from '../components/SongActionSheet'
import { EmptyState } from '../components/EmptyState'

const PRIMARY_COLOR: string = '#007DFF'
const BG_COLOR: string = '#F8F8FA'
const CARD_BG: string = '#F5F5F5'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'

@Component
export struct QinseTab {
  @State keyword: string = ''
  @State selectedSource: string = 'all'
  @State searchResults: SongInfo[] = []
  @State isLoading: boolean = false
  @State isSearched: boolean = false

  // Action sheet
  @State selectedSong: SongInfo | null = null
  @State showActionSheet: boolean = false

  // Toast message
  @State toastMessage: string = ''
  @State showToast: boolean = false

  // 搜索防抖定时器
  private searchTimer: number = -1

  private db: DatabaseHelper = DatabaseHelper.getInstance()

  aboutToDisappear(): void {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer)
    }
  }

  build() {
    Column() {
      // Search bar
      Column({ space: 12 }) {
        SearchBar({
          keyword: this.keyword,
          onKeywordChange: (kw: string) => {
            this.keyword = kw
            // 输入即搜索（防抖500ms）
            this.debouncedSearch(kw)
          },
          onSearch: (kw: string) => {
            this.keyword = kw
            // 清除防抖，立即搜索
            if (this.searchTimer !== -1) {
              clearTimeout(this.searchTimer)
            }
            this.doSearch(kw, this.selectedSource)
          },
          onClear: () => {
            this.keyword = ''
            this.isSearched = false
            this.searchResults = []
            if (this.searchTimer !== -1) {
              clearTimeout(this.searchTimer)
            }
          },
        })

        SourceChips({
          selected: this.selectedSource,
          onSelect: (source: string) => {
            this.selectedSource = source
            if (this.keyword.trim().length > 0) {
              this.doSearch(this.keyword.trim(), source)
            }
          },
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // Content area
      if (this.isLoading) {
        // Loading shimmer skeletons
        this.LoadingSkeleton()
      } else if (this.isSearched) {
        // Search results
        this.SearchResultsContent()
      } else {
        // Empty state before search
        Column() {
          EmptyState({ icon: '\uD83C\uDFB5', title: '\u641C\u7D22\u4F60\u559C\u6B22\u7684\u97F3\u4E50', subtitle: '\u652F\u6301\u9177\u72D7\u3001\u9177\u6211\u3001\u7F51\u6613\u4E91\u3001QQ\u97F3\u4E50' })
        }
        .layoutWeight(1)
      }

      // Action sheet - 搜索模式
      if (this.selectedSong) {
        SongActionSheet({
          song: this.selectedSong!,
          visible: this.showActionSheet,
          mode: 'search',
          onDismiss: () => {
            this.showActionSheet = false
            this.selectedSong = null
          },
          onPlay: (song: SongInfo) => {
            this.playSong(song)
          },
          onAddFavorite: (song: SongInfo) => {
            this.addFavorite(song)
          },
        })
      }

      // Toast overlay (fixed position at top)
      if (this.showToast) {
        Text(this.toastMessage)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#333333CC')
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .borderRadius(20)
          .position({ x: '50%', y: 120 })
          .translate({ x: '-50%' })
          .onClick(() => {
            this.showToast = false
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_COLOR)
  }

  // 防抖搜索
  private debouncedSearch(kw: string): void {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer)
    }
    if (kw.trim().length === 0) {
      this.isSearched = false
      this.searchResults = []
      return
    }
    this.searchTimer = setTimeout(() => {
      this.doSearch(kw.trim(), this.selectedSource)
    }, 500)
  }

  @Builder
  SearchResultsContent() {
    if (this.searchResults.length === 0) {
      Column() {
        EmptyState({ icon: '\uD83D\uDD0D', title: '\u672A\u627E\u5230\u76F8\u5173\u6B4C\u66F2', subtitle: '\u6362\u4E2A\u5173\u952E\u8BCD\u8BD5\u8BD5\u5427' })
      }
      .layoutWeight(1)
    } else {
      Scroll() {
        Column({ space: 8 }) {
          // Result count
          Text(`\u627E\u5230 ${this.searchResults.length} \u9996\u6B4C\u66F2`)
            .fontSize(13)
            .fontColor(TEXT_SECONDARY)
            .width('100%')
            .padding({ left: 4, bottom: 4 })

          // 双击播放提示
          Text('\u53CC\u51FB\u64AD\u653E \u00B7 \u957F\u6309\u66F4\u591A\u64CD\u4F5C')
            .fontSize(11)
            .fontColor(TEXT_SECONDARY)
            .width('100%')
            .padding({ left: 4, bottom: 8 })

          // Song list - 使用双击播放模式
          ForEach(this.searchResults, (song: SongInfo) => {
            SongCard({
              song: song,
              doubleTapToPlay: true,
              onPlay: (s: SongInfo) => {
                this.playSong(s)
              },
              onMore: (s: SongInfo) => {
                this.selectedSong = s
                this.showActionSheet = true
              },
            })
          })

          // Bottom spacing
          Column().height(24)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .scrollBarColor('#CCCCCC')
      .scrollBarWidth(4)
    }
  }

  @Builder
  LoadingSkeleton() {
    Column({ space: 12 }) {
      ForEach([1, 2, 3, 4, 5], (_skelIdx: number) => {
        Row({ space: 12 }) {
          // Cover skeleton
          Column()
            .width(44)
            .height(44)
            .borderRadius(8)
            .backgroundColor('#E0E0E0')

          // Text skeletons
          Column({ space: 8 }) {
            Column()
              .width('60%')
              .height(14)
              .borderRadius(4)
              .backgroundColor('#E0E0E0')
            Column()
              .width('40%')
              .height(10)
              .borderRadius(4)
              .backgroundColor('#ECECEC')
          }
          .layoutWeight(1)

          Column()
            .width(32)
            .height(32)
            .borderRadius(16)
            .backgroundColor('#ECECEC')
        }
        .width('100%')
        .padding(12)
        .backgroundColor(CARD_BG)
        .borderRadius(12)
      })
    }
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 8 })
  }

  private async doSearch(kw: string, source: string) {
    this.keyword = kw
    this.isLoading = true
    this.isSearched = true

    try {
      this.searchResults = await MusicApi.search(kw, source)
    } catch (e) {
      console.error('[QinseTab] search error:', e)
      this.searchResults = []
    }

    this.isLoading = false
  }

  private async playSong(song: SongInfo) {
    // 获取播放链接
    let playUrl = song.playUrl
    if (!playUrl) {
      playUrl = await MusicApi.getPlayUrl(song.songId, song.source)
    }
    if (!playUrl) {
      this.showToastMessage('\u65E0\u6CD5\u83B7\u53D6\u64AD\u653E\u94FE\u63A5')
      return
    }

    // 更新歌曲播放链接
    song.playUrl = playUrl

    // 设置播放器状态和队列
    PlayerStore.play(song, this.searchResults, this.searchResults.indexOf(song))

    // 配置音频播放器回调
    const player = AudioPlayer.getInstance()
    player.onTimeUpdate = (time: number) => {
      PlayerStore.updateTime(time)
    }
    player.onDurationUpdate = (duration: number) => {
      PlayerStore.updateDuration(duration)
    }
    player.onPlayEnd = () => {
      // 歌曲结束自动播下一首
      const nextTrack = PlayerStore.onTrackEnd()
      if (nextTrack) {
        this.playSong(nextTrack)
      } else {
        PlayerStore.pause()
      }
    }
    player.onError = (_error: string) => {
      PlayerStore.pause()
    }

    await player.play(playUrl)
  }

  private async addFavorite(song: SongInfo) {
    const result = await this.db.addFavorite(song)
    if (result) {
      this.showToastMessage('\u5DF2\u6DFB\u52A0\u5230\u6536\u85CF')
    } else {
      this.showToastMessage('\u5DF2\u5728\u6536\u85CF\u4E2D')
    }
  }

  private showToastMessage(message: string) {
    this.toastMessage = message
    this.showToast = true
    setTimeout(() => {
      this.showToast = false
    }, 2000)
  }
}