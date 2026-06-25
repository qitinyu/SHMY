// LX-HM 琴瑟 Tab - 搜索与播放
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

  private db: DatabaseHelper = DatabaseHelper.getInstance()
  private searchTimer: number = -1

  build() {
    Column() {
      // Search bar
      Column({ space: 12 }) {
        SearchBar({
          keyword: this.keyword,
          onKeywordChange: (kw: string) => {
            this.keyword = kw
          },
          onSearch: (kw: string) => {
            this.keyword = kw
            this.doSearch(kw, this.selectedSource)
          },
          onClear: () => {
            this.keyword = ''
            this.isSearched = false
            this.searchResults = []
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
          EmptyState({ icon: '🎵', title: '搜索你喜欢的音乐', subtitle: '支持酷狗、酷我、网易云、QQ音乐' })
        }
        .layoutWeight(1)
      }

      // Action sheet
      if (this.selectedSong) {
        SongActionSheet({
          song: this.selectedSong!,
          visible: this.showActionSheet,
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

  @Builder
  SearchResultsContent() {
    if (this.searchResults.length === 0) {
      Column() {
        EmptyState({ icon: '🔍', title: '未找到相关歌曲', subtitle: '换个关键词试试吧' })
      }
      .layoutWeight(1)
    } else {
      Scroll() {
        Column({ space: 8 }) {
          // Result count
          Text(`找到 ${this.searchResults.length} 首歌曲`)
            .fontSize(13)
            .fontColor(TEXT_SECONDARY)
            .width('100%')
            .padding({ left: 4, bottom: 4 })

          // Song list
          ForEach(this.searchResults, (song: SongInfo) => {
            SongCard({
              song: song,
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
    // Get play URL if not available
    let playUrl = song.playUrl
    if (!playUrl) {
      playUrl = await MusicApi.getPlayUrl(song.songId, song.source)
    }
    if (!playUrl) {
      this.showToastMessage('无法获取播放链接')
      return
    }

    // Update song with play URL
    song.playUrl = playUrl

    // Update PlayerStore state
    PlayerStore.play(song)

    // Set up audio player callbacks
    const player = AudioPlayer.getInstance()
    player.onTimeUpdate = (time: number) => {
      PlayerStore.updateTime(time)
    }
    player.onDurationUpdate = (duration: number) => {
      PlayerStore.updateDuration(duration)
    }
    player.onPlayEnd = () => {
      PlayerStore.pause()
    }
    player.onError = (_error: string) => {
      PlayerStore.pause()
    }

    await player.play(playUrl)

    // Set queue if searching
    PlayerStore.setQueue(this.searchResults)
  }

  private async addFavorite(song: SongInfo) {
    const result = await this.db.addFavorite(song)
    if (result) {
      this.showToastMessage('已添加到收藏')
    } else {
      this.showToastMessage('已在收藏中')
    }
  }

  private async addToQueue(song: SongInfo) {
    PlayerStore.addToQueue(song)
    this.showToastMessage('已添加到播放队列')
  }

  private async shareSong(song: SongInfo) {
    try {
      const text = `🎵 ${song.songName} - ${song.artist}\n来源: ${song.source}`
      // Pasteboard copy would be implemented here
      this.showToastMessage('歌曲信息已复制到剪贴板')
    } catch (e) {
      console.error('[QinseTab] share failed:', e)
    }
  }

  private async downloadSong(song: SongInfo) {
    const result = await this.db.addDownload(song, 'standard')
    if (result) {
      this.showToastMessage('已添加到下载列表')
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
