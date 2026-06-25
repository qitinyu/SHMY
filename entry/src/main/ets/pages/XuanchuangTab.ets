// LX-HM 轩窗 Tab - 我的音乐
// XuanchuangTab.ets
import { SongInfo, Playlist, DownloadItem, DownloadStatus, SourceInfo } from '../model/MusicModel'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { AudioPlayer } from '../utils/AudioPlayer'
import { MusicApi } from '../utils/MusicApi'
import { PlayerStore } from '../utils/PlayerStore'
import { SongCard } from '../components/SongCard'
import { EmptyState } from '../components/EmptyState'

const PRIMARY_COLOR: string = '#007DFF'
const BG_COLOR: string = '#F8F8FA'
const CARD_BG: string = '#F5F5F5'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'
const DIVIDER_COLOR: string = '#E8E8E8'

type SubPage = 'main' | 'playlistDetail' | 'downloadDetail'

@Component
export struct XuanchuangTab {
  @State favorites: SongInfo[] = []
  @State playlists: Playlist[] = []
  @State downloads: DownloadItem[] = []
  @State subPage: SubPage = 'main'

  // Playlist detail
  @State selectedPlaylist: Playlist | null = null
  @State playlistSongs: SongInfo[] = []

  // Download stats
  @State downloadingCount: number = 0
  @State pendingCount: number = 0
  @State completedCount: number = 0
  @State failedCount: number = 0

  // Dialogs
  @State showCreatePlaylistDialog: boolean = false
  @State newPlaylistName: string = ''
  @State showRenameDialog: boolean = false
  @State renamePlaylistId: string = ''
  @State renameValue: string = ''

  // Expanding playlists section
  @State playlistsExpanded: boolean = true

  private db: DatabaseHelper = DatabaseHelper.getInstance()

  async aboutToAppear() {
    await this.loadAllData()
  }

  private async loadAllData() {
    await Promise.all([
      this.loadFavorites(),
      this.loadPlaylists(),
      this.loadDownloads(),
    ])
  }

  private async loadFavorites() {
    this.favorites = await this.db.getFavorites()
  }

  private async loadPlaylists() {
    this.playlists = await this.db.getPlaylists()
  }

  private async loadDownloads() {
    this.downloads = await this.db.getDownloads()
    this.computeDownloadStats()
  }

  private computeDownloadStats() {
    this.downloadingCount = this.downloads.filter(d => d.status === DownloadStatus.DOWNLOADING).length
    this.pendingCount = this.downloads.filter(d => d.status === DownloadStatus.PENDING).length
    this.completedCount = this.downloads.filter(d => d.status === DownloadStatus.COMPLETED).length
    this.failedCount = this.downloads.filter(d => d.status === DownloadStatus.FAILED).length
  }

  // Play a song
  private async playSong(song: SongInfo) {
    // Get play URL if not available
    if (!song.playUrl) {
      song.playUrl = await MusicApi.getPlayUrl(song.songId, song.source)
    }
    if (!song.playUrl) return

    PlayerStore.play(song)
    AudioPlayer.getInstance().onTimeUpdate = (time: number) => {
      PlayerStore.updateTime(time)
    }
    AudioPlayer.getInstance().onDurationUpdate = (duration: number) => {
      PlayerStore.updateDuration(duration)
    }
    AudioPlayer.getInstance().onPlayEnd = () => {
      PlayerStore.pause()
    }
    AudioPlayer.getInstance().onError = (_error: string) => {
      PlayerStore.pause()
    }
    await AudioPlayer.getInstance().play(song.playUrl)
  }

  // Remove favorite
  private async removeFavorite(song: SongInfo) {
    await this.db.removeFavorite(song.songId, song.source)
    await this.loadFavorites()
  }

  // Create playlist
  private async doCreatePlaylist() {
    if (!this.newPlaylistName.trim()) return
    await this.db.createPlaylist(this.newPlaylistName.trim())
    this.newPlaylistName = ''
    this.showCreatePlaylistDialog = false
    await this.loadPlaylists()
  }

  // Rename playlist
  private async doRenamePlaylist() {
    if (!this.renameValue.trim()) return
    await this.db.renamePlaylist(this.renamePlaylistId, this.renameValue.trim())
    this.renameValue = ''
    this.showRenameDialog = false
    await this.loadPlaylists()
  }

  // Delete playlist
  private async deletePlaylist(id: string) {
    await this.db.deletePlaylist(id)
    await this.loadPlaylists()
  }

  // Navigate to playlist detail
  private async openPlaylistDetail(playlist: Playlist) {
    this.selectedPlaylist = playlist
    this.playlistSongs = await this.db.getPlaylistSongs(playlist.id)
    this.subPage = 'playlistDetail'
  }

  // Remove song from playlist
  private async removeSongFromPlaylist(song: SongInfo) {
    if (!this.selectedPlaylist) return
    await this.db.removeSongFromPlaylist(this.selectedPlaylist.id, song.songId, song.source)
    this.playlistSongs = await this.db.getPlaylistSongs(this.selectedPlaylist.id)
    await this.loadPlaylists()
  }

  // Delete download
  private async removeDownload(id: string) {
    await this.db.deleteDownload(id)
    await this.loadDownloads()
  }

  // Format time
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hour = date.getHours().toString().padStart(2, '0')
    const min = date.getMinutes().toString().padStart(2, '0')
    return `${month}-${day} ${hour}:${min}`
  }

  // Status label
  private getStatusLabel(status: string): string {
    switch (status) {
      case DownloadStatus.PENDING: return '等待中'
      case DownloadStatus.DOWNLOADING: return '下载中'
      case DownloadStatus.COMPLETED: return '已完成'
      case DownloadStatus.FAILED: return '失败'
      default: return status
    }
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case DownloadStatus.PENDING: return '#FF9800'
      case DownloadStatus.DOWNLOADING: return PRIMARY_COLOR
      case DownloadStatus.COMPLETED: return '#4CAF50'
      case DownloadStatus.FAILED: return '#F44336'
      default: return '#999999'
    }
  }

  build() {
    Column() {
      if (this.subPage === 'main') {
        this.MainContent()
      } else if (this.subPage === 'playlistDetail') {
        this.PlaylistDetailContent()
      } else if (this.subPage === 'downloadDetail') {
        this.DownloadDetailContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_COLOR)
    // Create playlist dialog
    .bindSheet($$this.showCreatePlaylistDialog, this.CreatePlaylistSheet(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: false,
      showClose: false,
      backgroundColor: '#FFFFFF',
    })
    // Rename dialog
    .bindSheet($$this.showRenameDialog, this.RenamePlaylistSheet(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: false,
      showClose: false,
      backgroundColor: '#FFFFFF',
    })
  }

  @Builder
  MainContent() {
    Scroll() {
      Column({ space: 16 }) {
        // Section: 个人收藏
        this.FavoritesSection()

        Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 16, right: 16 })

        // Section: 自建歌单
        this.PlaylistsSection()

        Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 16, right: 16 })

        // Section: 下载列表
        this.DownloadsSection()

        // Bottom spacing
        Column().height(24)
      }
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .scrollBarColor('#CCCCCC')
    .scrollBarWidth(4)
  }

  @Builder
  FavoritesSection() {
    Column({ space: 12 }) {
      // Section header
      Row() {
        Text('个人收藏')
          .fontSize(18)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)

        Text(`${this.favorites.length} 首`)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      if (this.favorites.length === 0) {
        Column({ space: 8 }) {
          Text('❤️')
            .fontSize(36)
            .opacity(0.4)
          Text('还没有收藏歌曲')
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
          Text('在琴瑟页面搜索并收藏喜欢的音乐')
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 16, right: 16 })
      } else {
        Column({ space: 8 }) {
          ForEach(this.favorites, (song: SongInfo) => {
            Row() {
              SongCard({
                song: song,
                onPlay: (s: SongInfo) => {
                  this.playSong(s)
                },
                onMore: (_s: SongInfo) => {
                  // Context menu via long press on SongCard is handled inline
                }
              })
            }
            .bindMenu([
              { value: '播放', action: () => { this.playSong(song) } },
              { value: '取消收藏', action: () => { this.removeFavorite(song) } },
            ])
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
  }

  @Builder
  PlaylistsSection() {
    Column({ space: 12 }) {
      // Section header with expand/collapse
      Row() {
        Row({ space: 8 }) {
          Text('自建歌单')
            .fontSize(18)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)

          Text(`${this.playlists.length} 个`)
            .fontSize(13)
            .fontColor(TEXT_SECONDARY)
        }
        .layoutWeight(1)

        // Expand/Collapse arrow
        Row() {
          Text(this.playlistsExpanded ? '\u25B2' : '\u25BC')
            .fontSize(12)
            .fontColor(PRIMARY_COLOR)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor('#F0F0F0')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.playlistsExpanded = !this.playlistsExpanded
        })

        // Add button
        Row() {
          Text('+')
            .fontSize(18)
            .fontColor(Color.White)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor(PRIMARY_COLOR)
        .justifyContent(FlexAlign.Center)
        .margin({ left: 12 })
        .onClick(() => {
          this.showCreatePlaylistDialog = true
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      if (this.playlistsExpanded) {
        if (this.playlists.length === 0) {
          Column({ space: 8 }) {
            Text('🎵')
              .fontSize(36)
              .opacity(0.4)
            Text('还没有创建歌单')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
          }
          .width('100%')
          .height(100)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 16, right: 16 })
        } else {
          Column({ space: 8 }) {
            ForEach(this.playlists, (playlist: Playlist) => {
              Row({ space: 12 }) {
                // Playlist icon
                Row() {
                  Text('🎼')
                    .fontSize(20)
                }
                .width(44)
                .height(44)
                .borderRadius(10)
                .backgroundColor(CARD_BG)
                .justifyContent(FlexAlign.Center)

                // Playlist info
                Column({ space: 2 }) {
                  Text(playlist.name)
                    .fontSize(15)
                    .fontColor(TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(`${playlist.songCount} 首`)
                    .fontSize(12)
                    .fontColor(TEXT_SECONDARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // Rename icon
                Text('✏️')
                  .fontSize(16)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .hitTestBehavior(HitTestMode.Block)
                  .onClick(() => {
                    this.renamePlaylistId = playlist.id
                    this.renameValue = playlist.name
                    this.showRenameDialog = true
                  })

                // Delete icon
                Text('🗑️')
                  .fontSize(16)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .hitTestBehavior(HitTestMode.Block)
                  .onClick(() => {
                    this.deletePlaylist(playlist.id)
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(CARD_BG)
              .borderRadius(12)
              .onClick(() => {
                this.openPlaylistDetail(playlist)
              })
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
      }
    }
    .width('100%')
  }

  @Builder
  DownloadsSection() {
    Column({ space: 12 }) {
      // Section header
      Row() {
        Text('下载列表')
          .fontSize(18)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)

        Text(`${this.downloads.length} 首`)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // Stats bar
      Row({ space: 16 }) {
        this.StatBadge('下载中', this.downloadingCount, PRIMARY_COLOR)
        this.StatBadge('等待中', this.pendingCount, '#FF9800')
        this.StatBadge('已完成', this.completedCount, '#4CAF50')
        this.StatBadge('失败', this.failedCount, '#F44336')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      if (this.downloads.length === 0) {
        Column({ space: 8 }) {
          Text('📥')
            .fontSize(36)
            .opacity(0.4)
          Text('暂无下载任务')
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
          Text('在琴瑟页面搜索并下载喜欢的音乐')
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // Card to navigate to download detail
        Row({ space: 8 }) {
          Text('查看全部下载')
            .fontSize(14)
            .fontColor(PRIMARY_COLOR)
            .fontWeight(FontWeight.Medium)

          Text('›')
            .fontSize(16)
            .fontColor(PRIMARY_COLOR)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(CARD_BG)
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.subPage = 'downloadDetail'
        })
      }
    }
    .width('100%')
  }

  @Builder
  StatBadge(label: string, count: number, color: string) {
    Row({ space: 4 }) {
      Text(`${count}`)
        .fontSize(16)
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(12)
        .fontColor(TEXT_SECONDARY)
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(CARD_BG)
    .borderRadius(8)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  PlaylistDetailContent() {
    Column() {
      // Top bar
      Row({ space: 12 }) {
        Row() {
          Text('‹')
            .fontSize(24)
            .fontColor(TEXT_PRIMARY)
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.subPage = 'main'
        })

        Column({ space: 2 }) {
          Text(this.selectedPlaylist?.name ?? '歌单详情')
            .fontSize(17)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${this.playlistSongs.length} 首`)
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 16 })
      .alignItems(VerticalAlign.Center)

      // Song list
      if (this.playlistSongs.length === 0) {
        EmptyState({ icon: '🎼', title: '歌单是空的', subtitle: '在琴瑟页面搜索并添加歌曲' })
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.playlistSongs, (song: SongInfo) => {
              Row() {
                SongCard({
                  song: song,
                  onPlay: (s: SongInfo) => {
                    this.playSong(s)
                  },
                })
              }
              .bindMenu([
                { value: '播放', action: () => { this.playSong(song) } },
                { value: '从歌单移除', action: () => { this.removeSongFromPlaylist(song) } },
              ])
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_COLOR)
  }

  @Builder
  DownloadDetailContent() {
    Column() {
      // Top bar
      Row({ space: 12 }) {
        Row() {
          Text('‹')
            .fontSize(24)
            .fontColor(TEXT_PRIMARY)
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.subPage = 'main'
        })

        Text('下载列表')
          .fontSize(17)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 16 })
      .alignItems(VerticalAlign.Center)

      // Download list
      if (this.downloads.length === 0) {
        EmptyState({ icon: '📥', title: '暂无下载', subtitle: '去琴瑟页面搜索并下载音乐吧' })
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.downloads, (item: DownloadItem) => {
              Row({ space: 12 }) {
                // Cover
                Image(item.coverUrl)
                  .width(44)
                  .height(44)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#E0E0E0')

                // Info
                Column({ space: 4 }) {
                  Text(item.songName)
                    .fontSize(14)
                    .fontColor(TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: '60%' })

                  Row({ space: 8 }) {
                    Text(item.artist)
                      .fontSize(12)
                      .fontColor(TEXT_SECONDARY)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(SourceInfo.getName(item.source))
                      .fontSize(10)
                      .fontColor(Color.White)
                      .backgroundColor(SourceInfo.getColor(item.source))
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                      .borderRadius(3)
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // Status badge
                Text(this.getStatusLabel(item.status))
                  .fontSize(11)
                  .fontColor(Color.White)
                  .backgroundColor(this.getStatusColor(item.status))
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(10)

                // Delete
                Text('✕')
                  .fontSize(16)
                  .fontColor(TEXT_SECONDARY)
                  .width(28)
                  .height(28)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.removeDownload(item.id)
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(CARD_BG)
              .borderRadius(12)
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_COLOR)
  }

  @Builder
  CreatePlaylistSheet() {
    Column({ space: 20 }) {
      Text('新建歌单')
        .fontSize(17)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      TextInput({ placeholder: '输入歌单名称', text: this.newPlaylistName })
        .width('100%')
        .height(48)
        .fontSize(15)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F0F0F0')
        .borderRadius(12)
        .onChange((value: string) => {
          this.newPlaylistName = value
        })

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(CARD_BG)
          .borderRadius(22)
          .onClick(() => {
            this.showCreatePlaylistDialog = false
          })

        Button('创建')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(PRIMARY_COLOR)
          .borderRadius(22)
          .onClick(() => {
            this.doCreatePlaylist()
          })
      }
      .width('100%')
    }
    .padding(24)
  }

  @Builder
  RenamePlaylistSheet() {
    Column({ space: 20 }) {
      Text('重命名歌单')
        .fontSize(17)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      TextInput({ placeholder: '输入新名称', text: this.renameValue })
        .width('100%')
        .height(48)
        .fontSize(15)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F0F0F0')
        .borderRadius(12)
        .onChange((value: string) => {
          this.renameValue = value
        })

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(CARD_BG)
          .borderRadius(22)
          .onClick(() => {
            this.showRenameDialog = false
          })

        Button('确定')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(PRIMARY_COLOR)
          .borderRadius(22)
          .onClick(() => {
            this.doRenamePlaylist()
          })
      }
      .width('100%')
    }
    .padding(24)
  }
}
