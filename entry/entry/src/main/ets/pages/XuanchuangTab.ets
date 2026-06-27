// SHMY 轩窗 Tab - 我的音乐
// XuanchuangTab.ets
import { SongInfo, Playlist, DownloadItem, DownloadStatus, SourceInfo } from '../model/MusicModel'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { AudioPlayer } from '../utils/AudioPlayer'
import { MusicApi } from '../utils/MusicApi'
import { PlayerStore } from '../utils/PlayerStore'
import { SongCard } from '../components/SongCard'
import { SongActionSheet } from '../components/SongActionSheet'
import { EmptyState } from '../components/EmptyState'
import fs from '@ohos.file.fs'
import { http } from '@kit.NetworkKit'
import { picker } from '@kit.CoreFileKit'
import { promptAction } from '@kit.ArkUI'
import { util } from '@kit.ArkTS'

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

  // Download detail - filter
  @State downloadFilter: string = 'all'

  // Dialogs
  @State showCreatePlaylistDialog: boolean = false
  @State newPlaylistName: string = ''
  @State showRenameDialog: boolean = false
  @State renamePlaylistId: string = ''
  @State renameValue: string = ''

  // Export dialog
  @State showExportDialog: boolean = false
  @State exportPlaylistTarget: Playlist | null = null

  // Batch mode for downloads
  @State batchMode: boolean = false
  @State selectedDownloadIds: Set<string> = new Set()

  // Action sheet
  @State selectedSong: SongInfo | null = null
  @State showSongActionSheet: boolean = false

  // Toast
  @State toastMsg: string = ''
  @State showToast: boolean = false

  // Expanding sections
  @State playlistsExpanded: boolean = true
  @State favoritesExpanded: boolean = false

  private db: DatabaseHelper = DatabaseHelper.getInstance()

  async aboutToAppear() {
    await this.loadAllData()
  }

  // 页面重新显示时刷新数据
  async onPageShow(): Promise<void> {
    await this.loadAllData()
  }

  private async loadAllData() {
    await this.loadFavorites()
    await this.loadPlaylists()
    await this.loadDownloads()
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
    // 自动执行等待中的下载
    this.processPendingDownloads()
  }

  private computeDownloadStats() {
    this.downloadingCount = this.downloads.filter(d => d.status === DownloadStatus.DOWNLOADING).length
    this.pendingCount = this.downloads.filter(d => d.status === DownloadStatus.PENDING).length
    this.completedCount = this.downloads.filter(d => d.status === DownloadStatus.COMPLETED).length
    this.failedCount = this.downloads.filter(d => d.status === DownloadStatus.FAILED).length
  }

  // 处理等待中的下载任务
  private async processPendingDownloads(): Promise<void> {
    const pendingItems = this.downloads.filter(d => d.status === DownloadStatus.PENDING)
    // 高品质最多同时下载5首
    const activeCount = this.downloadingCount

    for (let i = 0; i < pendingItems.length; i++) {
      const item = pendingItems[i]
      const isHighQuality = item.quality === 'high' || item.quality === 'lossless'
      if (isHighQuality && (activeCount + i) >= 5) {
        break // 高品质并发限制
      }
      this.executeDownload(item)
    }
  }

  // 执行单个下载任务
  private async executeDownload(item: DownloadItem): Promise<void> {
    try {
      await this.db.updateDownloadStatus(item.id, 'downloading', 0)

      // 获取播放URL
      let playUrl = item.playUrl
      if (!playUrl) {
        const songForUrl: SongInfo = {
          songId: item.songId,
          songName: item.songName,
          artist: item.artist,
          album: item.album,
          coverUrl: item.coverUrl,
          source: item.source,
          playUrl: item.playUrl,
        }
        playUrl = await MusicApi.getPlayUrl(songForUrl)
      }
      if (!playUrl) {
        await this.db.updateDownloadStatus(item.id, 'failed', 0)
        return
      }

      const httpRequest = http.createHttp()
      try {
        const response = await httpRequest.request(playUrl, {
          method: http.RequestMethod.GET,
          readTimeout: 120000,
          connectTimeout: 15000,
        } as http.HttpRequestOptions)

        if (response.responseCode === 200 && response.result) {
          // 确定文件扩展名
          let ext: string = '.mp3'
          if (item.quality === 'lossless') {
            ext = '.flac'
          }

          // 安全文件名
          const safeName = item.songName.replace(/[\/\\:*?"<>|]/g, '_')
          const safeArtist = item.artist.replace(/[\/\\:*?"<>|]/g, '_')
          const fileName = `${safeName} - ${safeArtist}${ext}`

          // 确保目录存在
          const dirPath = '/SHMY/Music/'
          try {
            fs.mkdir(dirPath, true)
          } catch (_e) {
            // 目录可能已存在
          }

          const filePath: string = dirPath + fileName

          // 写入文件
          if (typeof response.result === 'string') {
            const file: fs.File = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
            fs.writeSync(file.fd, response.result)
            fs.closeSync(file)
          }

          await this.db.updateDownloadStatus(item.id, 'completed', 100)
        } else {
          await this.db.updateDownloadStatus(item.id, 'failed', 0)
        }
      } catch (_e) {
        console.error('[XuanchuangTab] download write failed')
        await this.db.updateDownloadStatus(item.id, 'failed', 0)
      } finally {
        httpRequest.destroy()
      }

      // 刷新下载列表
      await this.loadDownloads()
    } catch (e) {
      console.error('[XuanchuangTab] executeDownload failed:', e)
      await this.db.updateDownloadStatus(item.id, 'failed', 0)
    }
  }

  // ===== 播放歌曲 =====
  private async playSong(song: SongInfo) {
    // 获取播放链接
    if (!song.playUrl) {
        song.playUrl = await MusicApi.getPlayUrl(song)
    }
    if (!song.playUrl) return

    // 设置队列 - 优先使用当前列表
    let queue = this.playlistSongs.length > 0 ? this.playlistSongs : this.favorites
    let idx = queue.findIndex(s => s.songId === song.songId && s.source === song.source)
    if (idx < 0) idx = 0

    PlayerStore.play(song, queue, idx)

    // 配置播放器回调
    const player = AudioPlayer.getInstance()
    player.onTimeUpdate = (time: number) => {
      PlayerStore.updateTime(time)
    }
    player.onDurationUpdate = (duration: number) => {
      PlayerStore.updateDuration(duration)
    }
    player.onPlayEnd = () => {
      const nextTrack = PlayerStore.onTrackEnd()
      if (nextTrack) {
        this.playSong(nextTrack)
      } else {
        PlayerStore.pause()
      }
    }
    player.onError = (_error: string) => {
      PlayerStore.pause()
      this.showToastMsg('播放失败，可能该歌曲暂不可用')
    }

    await player.play(song.playUrl)
  }

  // ===== 顺序播放 / 随机播放 / 导入歌单 =====
  private async playSequential(): Promise<void> {
    if (this.playlistSongs.length === 0) {
      this.showToastMsg('歌单为空')
      return
    }
    await this.playSong(this.playlistSongs[0])
  }

  private async playShuffle(): Promise<void> {
    if (this.playlistSongs.length === 0) {
      this.showToastMsg('歌单为空')
      return
    }
    const shuffled: SongInfo[] = [...this.playlistSongs]
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const tmp = shuffled[i]
      shuffled[i] = shuffled[j]
      shuffled[j] = tmp
    }
    this.playlistSongs = shuffled
    await this.playSong(shuffled[0])
  }

  private async importPlaylist(): Promise<void> {
    try {
      const options = new picker.DocumentSelectOptions()
      options.maxSelectNumber = 1
      options.fileSuffixFilters = ['.json', '.lxmc']
      const documentPicker = new picker.DocumentViewPicker()
      const uris: string[] = await documentPicker.select(options)
      if (!uris || uris.length === 0) return

      const fileUri: string = uris[0]
      const file: fs.File = fs.openSync(fileUri, fs.OpenMode.READ_ONLY)
      const stat: fs.Stat = fs.statSync(file.fd)
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size)
      fs.readSync(file.fd, buffer)
      fs.closeSync(file)

      const textDecoder: util.TextDecoder = util.TextDecoder.create('utf-8')
      const content: string = textDecoder.decodeWithStream(new Uint8Array(buffer))

      // 去除 LXMC 头
      let jsonStr: string = content
      if (jsonStr.startsWith('LXMC_')) {
        const newlineIdx: number = jsonStr.indexOf('\n')
        if (newlineIdx > 0) {
          jsonStr = jsonStr.substring(newlineIdx + 1)
        }
      }

      const parsed: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>
      const songsRaw: Object = parsed['songs']
      if (!(songsRaw instanceof Array) || songsRaw.length === 0) {
        this.showToastMsg('文件中无歌曲数据')
        return
      }

      if (!this.selectedPlaylist) {
        this.showToastMsg('请先选择歌单')
        return
      }

      let count: number = 0
      const songsArr: Object[] = songsRaw as Object[]
      for (let i = 0; i < songsArr.length; i++) {
        const item: Record<string, Object> = songsArr[i] as Record<string, Object>
        const song: SongInfo = {
          songId: String(item['songId'] ?? ''),
          songName: String(item['songName'] ?? ''),
          artist: String(item['artist'] ?? ''),
          album: String(item['album'] ?? ''),
          coverUrl: String(item['coverUrl'] ?? ''),
          source: String(item['source'] ?? ''),
          playUrl: String(item['playUrl'] ?? ''),
        }
        if (song.songId.length > 0) {
          const result: boolean = await this.db.addSongToPlaylist(this.selectedPlaylist.id, song)
          if (result) count++
        }
      }

      this.playlistSongs = await this.db.getPlaylistSongs(this.selectedPlaylist.id)
      await this.loadPlaylists()
      this.showToastMsg(`已导入 ${count} 首歌曲`)
    } catch (e) {
      console.error('[XuanchuangTab] import failed:', e)
      this.showToastMsg('导入失败')
    }
  }

  // ===== 收藏 =====
  private async removeFavorite(song: SongInfo) {
    await this.db.removeFavorite(song.songId, song.source)
    await this.loadFavorites()
  }

  // ===== 歌单 CRUD =====
  private async doCreatePlaylist() {
    if (!this.newPlaylistName.trim()) return
    await this.db.createPlaylist(this.newPlaylistName.trim())
    this.newPlaylistName = ''
    this.showCreatePlaylistDialog = false
    await this.loadPlaylists()
  }

  private async doRenamePlaylist() {
    if (!this.renameValue.trim()) return
    await this.db.renamePlaylist(this.renamePlaylistId, this.renameValue.trim())
    this.renameValue = ''
    this.showRenameDialog = false
    await this.loadPlaylists()
  }

  private async deletePlaylist(id: string) {
    await this.db.deletePlaylist(id)
    await this.loadPlaylists()
  }

  private async openPlaylistDetail(playlist: Playlist) {
    this.selectedPlaylist = playlist
    this.playlistSongs = await this.db.getPlaylistSongs(playlist.id)
    this.subPage = 'playlistDetail'
  }

  private async removeSongFromPlaylist(song: SongInfo) {
    if (!this.selectedPlaylist) return
    await this.db.removeSongFromPlaylist(this.selectedPlaylist.id, song.songId, song.source)
    this.playlistSongs = await this.db.getPlaylistSongs(this.selectedPlaylist.id)
    await this.loadPlaylists()
  }

  // ===== 歌单导出 =====
  private async exportPlaylist(playlist: Playlist, format: string): Promise<void> {
    try {
      const songs = await this.db.getPlaylistSongs(playlist.id)

      // 确保导出目录存在
      const exportDir = '/SHMY/Playlist/'
      try {
        fs.mkdir(exportDir, true)
      } catch (_e) {
        // 目录可能已存在
      }

      const safeName = playlist.name.replace(/[\/\\:*?"<>|]/g, '_')

      if (format === 'json') {
        // JSON 格式导出
        const jsonStr: string = JSON.stringify({
          name: playlist.name,
          exportTime: new Date().toISOString(),
          songCount: songs.length,
          songs: songs,
        })
        const jsonFilePath: string = exportDir + safeName + '.json'
        const jsonFile: fs.File = fs.openSync(jsonFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC)
        fs.writeSync(jsonFile.fd, jsonStr)
        fs.closeSync(jsonFile)
        this.showToastMsg(`已导出: ${exportDir}${safeName}.json`)
      } else if (format === 'lxmc') {
        // LXMC 自定义格式 (JSON + 自定义头)
        const header: string = 'LXMC_V1.0.0'
        const lxmcJson: string = JSON.stringify({
          name: playlist.name,
          exportTime: new Date().toISOString(),
          songCount: songs.length,
          songs: songs,
        })
        const lxmcContent: string = header + '\n' + lxmcJson
        const lxmcFilePath: string = exportDir + safeName + '.lxmc'
        const lxmcFile: fs.File = fs.openSync(lxmcFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC)
        fs.writeSync(lxmcFile.fd, lxmcContent)
        fs.closeSync(lxmcFile)
        this.showToastMsg(`已导出: ${exportDir}${safeName}.lxmc`)
      }

      this.showExportDialog = false
    } catch (e) {
      console.error('[XuanchuangTab] exportPlaylist failed:', e)
      this.showToastMsg('导出失败，请检查存储权限')
    }
  }

  // ===== 下载操作 =====
  private async removeDownload(id: string) {
    await this.db.deleteDownload(id)
    await this.loadDownloads()
  }

  // 批量删除已完成或失败的下载
  private async batchDeleteSelected(): Promise<void> {
    const ids = Array.from(this.selectedDownloadIds)
    for (let i = 0; i < ids.length; i++) {
      await this.db.deleteDownload(ids[i])
    }
    this.selectedDownloadIds = new Set()
    this.batchMode = false
    await this.loadDownloads()
    this.showToastMsg(`已删除 ${ids.length} 个下载任务`)
  }

  // 批量添加到歌单
  private async batchAddToPlaylist(playlistId: string): Promise<void> {
    let count = 0
    for (let i = 0; i < this.downloads.length; i++) {
      const item = this.downloads[i]
      if (this.selectedDownloadIds.has(item.id)) {
        const song: SongInfo = {
          songId: item.songId,
          songName: item.songName,
          artist: item.artist,
          album: item.album,
          coverUrl: item.coverUrl,
          source: item.source,
          playUrl: item.playUrl,
        }
        const result = await this.db.addSongToPlaylist(playlistId, song)
        if (result) count++
      }
    }
    this.selectedDownloadIds = new Set()
    this.batchMode = false
    this.showToastMsg(`已添加 ${count} 首到歌单`)
  }

  // 重试失败任务
  private async retryFailed(): Promise<void> {
    const failedItems = this.downloads.filter(d => d.status === DownloadStatus.FAILED)
    for (let i = 0; i < failedItems.length; i++) {
      await this.db.updateDownloadStatus(failedItems[i].id, 'pending', 0)
    }
    if (failedItems.length > 0) {
      this.showToastMsg(`已重试 ${failedItems.length} 个失败任务`)
      await this.loadDownloads()
    }
  }

  // 过滤后的下载列表
  private getFilteredDownloads(): DownloadItem[] {
    if (this.downloadFilter === 'all') return this.downloads
    return this.downloads.filter(d => d.status === this.downloadFilter)
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

  private showToastMsg(msg: string): void {
    this.toastMsg = msg
    this.showToast = true
    setTimeout(() => {
      this.showToast = false
    }, 2000)
  }

  build() {
    Stack() {
      Column() {
        if (this.subPage === 'main') {
          this.MainContent()
        } else if (this.subPage === 'playlistDetail') {
          this.PlaylistDetailContent()
        } else if (this.subPage === 'downloadDetail') {
          this.DownloadDetailContent()
        }

        // Toast overlay
        if (this.showToast) {
          Text(this.toastMsg)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor('#333333CC')
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .borderRadius(20)
            .position({ x: '50%', y: 120 })
            .translate({ x: '-50%' })
            .onClick(() => { this.showToast = false })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_COLOR)

      // Sheet trigger: 创建歌单
      Row()
        .width(1)
        .height(1)
        .bindSheet($$this.showCreatePlaylistDialog, this.CreatePlaylistSheet(), {
          height: SheetSize.FIT_CONTENT,
          dragBar: true,
          showClose: true,
          backgroundColor: '#FFFFFF',
          onDisappear: () => {
            this.showCreatePlaylistDialog = false
          },
        })

      // Sheet trigger: 重命名歌单
      Row()
        .width(1)
        .height(1)
        .bindSheet($$this.showRenameDialog, this.RenamePlaylistSheet(), {
          height: SheetSize.FIT_CONTENT,
          dragBar: true,
          showClose: true,
          backgroundColor: '#FFFFFF',
          onDisappear: () => {
            this.showRenameDialog = false
          },
        })

      // Sheet trigger: 导出歌单
      Row()
        .width(1)
        .height(1)
        .bindSheet($$this.showExportDialog, this.ExportPlaylistSheet(), {
          height: SheetSize.FIT_CONTENT,
          dragBar: true,
          showClose: true,
          backgroundColor: '#FFFFFF',
          onDisappear: () => {
            this.showExportDialog = false
          },
        })

      // Song action sheet for playlist songs
      if (this.selectedSong) {
        SongActionSheet({
          song: this.selectedSong!,
          visible: this.showSongActionSheet,
          onDismiss: () => {
            this.showSongActionSheet = false
            this.selectedSong = null
          },
          onPlay: (song: SongInfo) => {
            this.playSong(song)
          },
          onAddFavorite: (song: SongInfo) => {
            this.db.addFavorite(song).then((result) => {
              if (result) {
                this.showToastMsg('已添加到收藏')
              } else {
                this.showToastMsg('已在收藏中')
              }
            })
          },
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MainContent() {
    Scroll() {
      Column({ space: 16 }) {
        // Section: 自建歌单
        this.PlaylistsSection()

        Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 16, right: 16 })

        // Section: 个人收藏
        this.FavoritesSection()

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
      // Section header with expand/collapse
      Row() {
        Row({ space: 8 }) {
          Text('个人收藏')
            .fontSize(18)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)

          Text(`${this.favorites.length} 首`)
            .fontSize(13)
            .fontColor(TEXT_SECONDARY)
        }
        .layoutWeight(1)

        // Expand/Collapse arrow
        Row() {
          Text(this.favoritesExpanded ? '\u25B2' : '\u25BC')
            .fontSize(12)
            .fontColor(PRIMARY_COLOR)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor('#F0F0F0')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.favoritesExpanded = !this.favoritesExpanded
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      if (this.favoritesExpanded) {
        if (this.favorites.length === 0) {
          Column({ space: 8 }) {
            Text('还没有收藏歌曲')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
            Text('在琴瑟页面搜索并收藏喜欢的音乐')
              .fontSize(12)
              .fontColor(TEXT_SECONDARY)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
        } else {
          Column({ space: 8 }) {
            ForEach(this.favorites, (song: SongInfo) => {
              Row() {
                SongCard({
                  song: song,
                  onPlay: (s: SongInfo) => {
                    this.playSong(s)
                  },
                  onMore: (s: SongInfo) => {
                    this.selectedSong = s
                    this.showSongActionSheet = true
                  },
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
            Text('还没有创建歌单')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
        } else {
          Column({ space: 8 }) {
            ForEach(this.playlists, (playlist: Playlist) => {
              Row({ space: 12 }) {
                // Playlist icon
                Row() {
                  Image($r('app.media.music_note'))
                    .width(22)
                    .height(22)
                    .fillColor(PRIMARY_COLOR)
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

                // Three-dots menu trigger
                Row() {
                  Image($r('app.media.icon_ellipsis'))
                    .width(20)
                    .height(20)
                    .fillColor(TEXT_SECONDARY)
                }
                .width(36)
                .height(36)
                .justifyContent(FlexAlign.Center)
                .hitTestBehavior(HitTestMode.Block)
                .bindMenu([
                  { value: '命名歌单', action: () => {
                    this.renamePlaylistId = playlist.id
                    this.renameValue = playlist.name
                    this.showRenameDialog = true
                  } },
                  { value: '删除歌单', action: () => {
                    this.deletePlaylist(playlist.id)
                  } },
                  { value: '导出歌单', action: () => {
                    this.exportPlaylistTarget = playlist
                    this.showExportDialog = true
                  } },
                ])
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
      Row({ space: 8 }) {
        this.StatBadge('下载中', this.downloadingCount, PRIMARY_COLOR)
        this.StatBadge('等待中', this.pendingCount, '#FF9800')
        this.StatBadge('已完成', this.completedCount, '#4CAF50')
        this.StatBadge('失败', this.failedCount, '#F44336')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      if (this.downloads.length === 0) {
        Column({ space: 8 }) {
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

          Text('\u203A')
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
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
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
          Text('\u2039')
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

        // Three-dots menu in detail
        Row() {
          Image($r('app.media.icon_ellipsis'))
            .width(22)
            .height(22)
            .fillColor(TEXT_PRIMARY)
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .hitTestBehavior(HitTestMode.Block)
        .bindMenu([
          { value: '顺序播放', action: () => { this.playSequential() } },
          { value: '随机播放', action: () => { this.playShuffle() } },
          { value: '导入歌单', action: () => { this.importPlaylist() } },
        ])
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 16 })
      .alignItems(VerticalAlign.Center)

      // Song list
      if (this.playlistSongs.length === 0) {
        EmptyState({ icon: $r('app.media.music_note'), title: '歌单是空的', subtitle: '在琴瑟页面搜索并添加歌曲' })
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
                  onMore: (s: SongInfo) => {
                    this.selectedSong = s
                    this.showSongActionSheet = true
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
        .align(Alignment.Top)
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
          Text('\u2039')
            .fontSize(24)
            .fontColor(TEXT_PRIMARY)
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.subPage = 'main'
          this.batchMode = false
          this.selectedDownloadIds = new Set()
        })

        Text('下载列表')
          .fontSize(17)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        // Batch mode toggle
        Text(this.batchMode ? '完成' : '管理')
          .fontSize(14)
          .fontColor(PRIMARY_COLOR)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor('#E3F2FD')
          .onClick(() => {
            if (this.batchMode) {
              // 退出批量模式
              this.batchMode = false
              this.selectedDownloadIds = new Set()
            } else {
              this.batchMode = true
              this.selectedDownloadIds = new Set()
            }
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 16 })
      .alignItems(VerticalAlign.Center)

      // Filter tabs
      Row({ space: 8 }) {
        this.FilterChip('全部', 'all')
        this.FilterChip('下载中', 'downloading')
        this.FilterChip('等待中', 'pending')
        this.FilterChip('已完成', 'completed')
        this.FilterChip('失败', 'failed')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // Batch action bar
      if (this.batchMode && this.selectedDownloadIds.size > 0) {
        Row({ space: 12 }) {
          Text(`已选 ${this.selectedDownloadIds.size} 项`)
            .fontSize(14)
            .fontColor(TEXT_PRIMARY)
            .layoutWeight(1)

          Button('删除选中')
            .height(32)
            .fontSize(13)
            .fontColor(Color.White)
            .backgroundColor('#F44336')
            .borderRadius(16)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.batchDeleteSelected()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 8 })
        .backgroundColor('#FFF5F5')
      }

      // Batch actions for non-batch mode
      if (!this.batchMode) {
        Row({ space: 12 }) {
          if (this.failedCount > 0) {
            Button('重试失败')
              .height(32)
              .fontSize(13)
              .fontColor(PRIMARY_COLOR)
              .backgroundColor('#E3F2FD')
              .borderRadius(16)
              .padding({ left: 12, right: 12 })
              .onClick(() => {
                this.retryFailed()
              })
          }

          Blank().layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      // Download list
      if (this.getFilteredDownloads().length === 0) {
        EmptyState({ icon: '', title: '暂无下载', subtitle: '去琴瑟页面搜索并下载音乐吧' })
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.getFilteredDownloads(), (item: DownloadItem) => {
              Row({ space: 12 }) {
                // Checkbox in batch mode
                if (this.batchMode) {
                  Row() {
                    if (this.selectedDownloadIds.has(item.id)) {
                      Text('\u2713')
                        .fontSize(12)
                        .fontColor(Color.White)
                    }
                  }
                  .width(22)
                  .height(22)
                  .borderRadius(11)
                  .border({ width: 1.5, color: this.selectedDownloadIds.has(item.id) ? PRIMARY_COLOR : '#CCCCCC' })
                  .backgroundColor(this.selectedDownloadIds.has(item.id) ? PRIMARY_COLOR : Color.White)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    const newSet = new Set(this.selectedDownloadIds)
                    if (newSet.has(item.id)) {
                      newSet.delete(item.id)
                    } else {
                      newSet.add(item.id)
                    }
                    this.selectedDownloadIds = newSet
                  })
                }

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
                    .constraintSize({ maxWidth: '50%' })

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

                    if (item.quality !== 'standard') {
                      Text(item.quality === 'lossless' ? '无损' : '高品质')
                        .fontSize(10)
                        .fontColor(PRIMARY_COLOR)
                    }
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

                // Delete button (non-batch mode)
                if (!this.batchMode) {
                  Text('\u2715')
                    .fontSize(16)
                    .fontColor(TEXT_SECONDARY)
                    .width(28)
                    .height(28)
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.removeDownload(item.id)
                    })
                }
              }
              .width('100%')
              .padding(12)
              .backgroundColor(CARD_BG)
              .borderRadius(12)
              .onClick(() => {
                // 点击已完成的下载项 → 播放
                if (item.status === DownloadStatus.COMPLETED || item.status === DownloadStatus.DOWNLOADING) {
                  const song: SongInfo = {
                    songId: item.songId,
                    songName: item.songName,
                    artist: item.artist,
                    album: item.album,
                    coverUrl: item.coverUrl,
                    source: item.source,
                    playUrl: item.playUrl,
                  }
                  this.playSong(song)
                }
              })
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
  FilterChip(label: string, filter: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.downloadFilter === filter ? Color.White : TEXT_SECONDARY)
      .fontWeight(this.downloadFilter === filter ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(this.downloadFilter === filter ? PRIMARY_COLOR : CARD_BG)
      .onClick(() => {
        this.downloadFilter = filter
      })
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

  @Builder
  ExportPlaylistSheet() {
    Column({ space: 20 }) {
      Text('导出歌单')
        .fontSize(17)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text(`将歌单「${this.exportPlaylistTarget?.name ?? ''}」导出到 /SHMY/Playlist/`)
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .width('100%')

      // JSON export
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('JSON')
            .fontSize(18)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text('通用格式，便于跨平台')
            .fontSize(11)
            .fontColor(TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding(16)
        .backgroundColor(CARD_BG)
        .borderRadius(12)
        .onClick(() => {
          if (this.exportPlaylistTarget) {
            this.exportPlaylist(this.exportPlaylistTarget, 'json')
          }
        })
      }

      // LXMC export
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('LXMC')
            .fontSize(18)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text('应用专用格式')
            .fontSize(11)
            .fontColor(TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding(16)
        .backgroundColor(CARD_BG)
        .borderRadius(12)
        .onClick(() => {
          if (this.exportPlaylistTarget) {
            this.exportPlaylist(this.exportPlaylistTarget, 'lxmc')
          }
        })
      }

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(CARD_BG)
          .borderRadius(22)
          .onClick(() => {
            this.showExportDialog = false
          })
      }
      .width('100%')
    }
    .padding(24)
  }
}