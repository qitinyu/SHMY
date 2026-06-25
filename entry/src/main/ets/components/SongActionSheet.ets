// SHMY 歌曲操作底部弹窗组件
// SongActionSheet.ets
import { SongInfo, SourceInfo, Playlist, createEmptySongInfo } from '../model/MusicModel'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { PlayerStore } from '../utils/PlayerStore'
import { MusicApi } from '../utils/MusicApi'
import { AudioPlayer } from '../utils/AudioPlayer'
import { common } from '@kit.AbilityKit'
import { pasteboard } from '@kit.BasicServicesKit'
import fs from '@ohos.file.fs'
import { http } from '@kit.NetworkKit'

const PRIMARY_COLOR: string = '#007DFF'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'
const CARD_BG: string = '#F5F5F5'

interface ActionItem {
  icon: string
  label: string
  action: string
}

// 完整模式操作列表（轩窗版块用）
const FULL_ACTION_LIST: ActionItem[] = [
  { icon: '\u25B6\uFE0F', label: '\u64AD\u653E', action: 'play' },
  { icon: '\u2764\uFE0F', label: '\u6536\u85CF', action: 'favorite' },
  { icon: '\u23F1', label: '\u7A0D\u540E\u64AD\u653E', action: 'later' },
  { icon: '\uD83D\uDD17', label: '\u5206\u4EAB', action: 'share' },
  { icon: '\uD83C\uDFB5', label: '\u6DFB\u52A0\u5230\u6B4C\u5355', action: 'playlist' },
  { icon: '\uD83D\uDCE5', label: '\u4E0B\u8F7D', action: 'download' },
]

// 搜索模式操作列表（琴瑟版块用）
const SEARCH_ACTION_LIST: ActionItem[] = [
  { icon: '\uD83C\uDFB5', label: '\u52A0\u5165\u6B4C\u5355', action: 'playlist' },
  { icon: '\u2764\uFE0F', label: '\u6DFB\u52A0\u6536\u85CF', action: 'favorite' },
  { icon: '\u23ED', label: '\u4E0B\u66F2\u64AD\u653E', action: 'play_next' },
  { icon: '\uD83D\uDCE5', label: '\u6B4C\u66F2\u4E0B\u8F7D', action: 'auto_download' },
]

// 下载音质选项
interface QualityOption {
  label: string
  value: string
}

const QUALITY_OPTIONS: QualityOption[] = [
  { label: '\u6807\u51C6\u54C1\u8D28 (128kbps)', value: 'standard' },
  { label: '\u9AD8\u54C1\u8D28 (320kbps)', value: 'high' },
  { label: '\u65E0\u635F\u54C1\u8D28 (FLAC)', value: 'lossless' },
]

@Component
export struct SongActionSheet {
  song: SongInfo = createEmptySongInfo()
  visible: boolean = false
  onDismiss?: () => void
  onPlay?: (song: SongInfo) => void
  onAddFavorite?: (song: SongInfo) => void

  // 模式: 'full' = 完整操作（轩窗），'search' = 简化操作（琴瑟）
  mode: string = 'full'

  @State private sheetVisible: boolean = false
  @State private showPlaylistPicker: boolean = false
  @State private showQualityPicker: boolean = false
  @State private showCreatePlaylistInline: boolean = false
  @State private newPlaylistName: string = ''
  @State private playlists: Playlist[] = []
  @State private toastMsg: string = ''
  @State private showToast: boolean = false

  private db: DatabaseHelper = DatabaseHelper.getInstance()

  aboutToAppear(): void {
    this.sheetVisible = this.visible
  }

  aboutToUpdate(): void {
    this.sheetVisible = this.visible
  }

  private async loadPlaylists(): Promise<void> {
    this.playlists = await this.db.getPlaylists()
  }

  private async doAddToPlaylist(playlistId: string): Promise<void> {
    const result = await this.db.addSongToPlaylist(playlistId, this.song)
    if (result) {
      this.showToastMsg('\u5DF2\u6DFB\u52A0\u5230\u6B4C\u5355')
    } else {
      this.showToastMsg('\u6DFB\u52A0\u5931\u8D25\uFF0C\u8BF7\u91CD\u8BD5')
    }
    this.showPlaylistPicker = false
  }

  // 搜索模式：创建新歌单并自动添加歌曲
  private async doCreateAndAdd(): Promise<void> {
    const name = this.newPlaylistName.trim()
    if (!name) {
      this.showToastMsg('\u8BF7\u8F93\u5165\u6B4C\u5355\u540D\u79F0')
      return
    }
    const playlistId = await this.db.createPlaylist(name)
    if (playlistId) {
      await this.db.addSongToPlaylist(playlistId, this.song)
      this.showToastMsg(`\u5DF2\u521B\u5EFA\u6B4C\u5355\u300C${name}\u300D\u5E76\u6DFB\u52A0\u6B4C\u66F2`)
      this.newPlaylistName = ''
      this.showCreatePlaylistInline = false
      this.showPlaylistPicker = false
    } else {
      this.showToastMsg('\u521B\u5EFA\u6B4C\u5355\u5931\u8D25')
    }
  }

  private async doDownload(quality: string): Promise<void> {
    // 检查高品质并发下载限制
    if (quality === 'high' || quality === 'lossless') {
      const downloads = await this.db.getDownloads()
      const activeCount = downloads.filter(d =>
        d.status === 'downloading' || d.status === 'pending'
      ).length
      if (activeCount >= 5) {
        this.showToastMsg('\u9AD8\u54C1\u8D28\u4E0B\u8F7D\u6700\u591A\u540C\u65F6\u8FDB\u884C5\u9996\uFF0C\u8BF7\u7B49\u5F85\u5B8C\u6210')
        return
      }
    }

    const result = await this.db.addDownload(this.song, quality)
    if (result) {
      this.showToastMsg('\u5DF2\u6DFB\u52A0\u5230\u4E0B\u8F7D\u5217\u8868')
      this.executeDownload(result, this.song, quality)
    } else {
      this.showToastMsg('\u4E0B\u8F7D\u4EFB\u52A1\u6DFB\u52A0\u5931\u8D25')
    }
    this.showQualityPicker = false
  }

  // 搜索模式：自动下载普通音质
  private async doAutoDownload(): Promise<void> {
    const result = await this.db.addDownload(this.song, 'standard')
    if (result) {
      this.showToastMsg('\u5DF2\u5F00\u59CB\u4E0B\u8F7D\uFF08\u6807\u51C6\u54C1\u8D28\uFF09')
      this.executeDownload(result, this.song, 'standard')
    } else {
      this.showToastMsg('\u4E0B\u8F7D\u4EFB\u52A1\u6DFB\u52A0\u5931\u8D25')
    }
  }

  // 下曲播放
  private doPlayNext(): void {
    PlayerStore.insertNext(this.song)
    this.showToastMsg('\u5DF2\u6DFB\u52A0\u5230\u4E0B\u4E00\u9996\u64AD\u653E')
  }

  private async executeDownload(downloadId: string, song: SongInfo, quality: string): Promise<void> {
    try {
      await this.db.updateDownloadStatus(downloadId, 'downloading', 0)

      // 获取播放URL
      let playUrl = song.playUrl
      if (!playUrl) {
        playUrl = await MusicApi.getPlayUrl(song.songId, song.source, quality)
      }
      if (!playUrl) {
        await this.db.updateDownloadStatus(downloadId, 'failed', 0)
        return
      }

      // 使用 http 下载文件
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
          if (quality === 'lossless') {
            ext = '.flac'
          }

          // 安全文件名
          const safeName = song.songName.replace(/[\/\\:*?"<>|]/g, '_')
          const fileName = `${safeName} - ${song.artist.replace(/[\/\\:*?"<>|]/g, '_')}${ext}`

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

          await this.db.updateDownloadStatus(downloadId, 'completed', 100)
        } else {
          await this.db.updateDownloadStatus(downloadId, 'failed', 0)
        }
      } catch (_e) {
        console.error('[SongActionSheet] download write failed')
        await this.db.updateDownloadStatus(downloadId, 'failed', 0)
      } finally {
        httpRequest.destroy()
      }
    } catch (e) {
      console.error('[SongActionSheet] executeDownload failed:', e)
      await this.db.updateDownloadStatus(downloadId, 'failed', 0)
    }
  }

  private async doShare(): Promise<void> {
    try {
      let shareText = `\uD83C\uDFB5 ${this.song.songName} - ${this.song.artist}`
      if (this.song.playUrl) {
        shareText += `\n\u64AD\u653E\u94FE\u63A5: ${this.song.playUrl}`
      }
      shareText += `\n\u6765\u6E90: ${SourceInfo.getCodeName(this.song.source)}`

      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shareText)
      const systemPasteboard = pasteboard.getSystemPasteboard()
      await systemPasteboard.setDataSync(pasteData)
      this.showToastMsg('\u6B4C\u66F2\u4FE1\u606F\u5DF2\u590D\u5236\u5230\u526A\u8D34\u677F')
    } catch (e) {
      console.error('[SongActionSheet] share failed:', e)
      this.showToastMsg('\u5206\u4EAB\u5931\u8D25')
    }
  }

  private doPlayLater(): void {
    PlayerStore.addToQueue(this.song)
    this.showToastMsg('\u5DF2\u6DFB\u52A0\u5230\u7A0D\u540E\u64AD\u653E\u961F\u5217')
  }

  private showToastMsg(msg: string): void {
    this.toastMsg = msg
    this.showToast = true
    setTimeout(() => {
      this.showToast = false
    }, 2000)
  }

  private dismiss(): void {
    this.sheetVisible = false
    if (this.onDismiss) {
      this.onDismiss()
    }
  }

  // 获取当前模式的操作列表
  private getActionList(): ActionItem[] {
    if (this.mode === 'search') {
      return SEARCH_ACTION_LIST
    }
    return FULL_ACTION_LIST
  }

  build() {
    Stack() {
      Column() {
        // 主操作面板
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

        // 歌单选择面板
        Row()
          .width(1)
          .height(1)
          .bindSheet($$this.showPlaylistPicker, this.PlaylistPickerContent(), {
            height: SheetSize.FIT_CONTENT,
            dragBar: true,
            showClose: true,
            backgroundColor: '#FFFFFF',
            onDisappear: () => {
              this.showPlaylistPicker = false
              this.showCreatePlaylistInline = false
            },
          })

        // 音质选择面板（仅完整模式）
        if (this.mode === 'full') {
          Row()
            .width(1)
            .height(1)
            .bindSheet($$this.showQualityPicker, this.QualityPickerContent(), {
              height: SheetSize.FIT_CONTENT,
              dragBar: true,
              showClose: true,
              backgroundColor: '#FFFFFF',
              onDisappear: () => {
                this.showQualityPicker = false
              },
            })
        }
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
        ForEach(this.getActionList(), (item: ActionItem) => {
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

  @Builder
  PlaylistPickerContent() {
    Column() {
      Text('\u9009\u62E9\u6B4C\u5355')
        .fontSize(17)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 24, right: 24, top: 16, bottom: 12 })

      if (this.playlists.length === 0 && !this.showCreatePlaylistInline) {
        // 无歌单时显示创建入口
        Column({ space: 12 }) {
          Text('\u6682\u65E0\u6B4C\u5355\uFF0C\u8BF7\u5148\u521B\u5EFA\u4E00\u4E2A')
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
            .width('100%')
            .textAlign(TextAlign.Center)

          // 内联创建歌单
          if (this.showCreatePlaylistInline) {
            Column({ space: 12 }) {
              TextInput({ placeholder: '\u8F93\u5165\u6B4C\u5355\u540D\u79F0', text: this.newPlaylistName })
                .width('100%')
                .height(44)
                .fontSize(15)
                .padding({ left: 16, right: 16 })
                .backgroundColor('#F0F0F0')
                .borderRadius(10)
                .onChange((value: string) => {
                  this.newPlaylistName = value
                })

              Row({ space: 12 }) {
                Button('\u53D6\u6D88')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(14)
                  .fontColor(TEXT_PRIMARY)
                  .backgroundColor(CARD_BG)
                  .borderRadius(20)
                  .onClick(() => {
                    this.showCreatePlaylistInline = false
                    this.newPlaylistName = ''
                  })

                Button('\u521B\u5EFA\u5E76\u6DFB\u52A0')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(14)
                  .fontColor(Color.White)
                  .backgroundColor(PRIMARY_COLOR)
                  .borderRadius(20)
                  .onClick(() => {
                    this.doCreateAndAdd()
                  })
              }
              .width('100%')
            }
            .padding({ left: 24, right: 24, top: 4 })
          } else {
            Button('\u65B0\u5EFA\u6B4C\u5355')
              .width('80%')
              .height(40)
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor(PRIMARY_COLOR)
              .borderRadius(20)
              .onClick(() => {
                this.showCreatePlaylistInline = true
              })
          }
        }
        .padding(24)
      } else {
        // 歌单列表
        ForEach(this.playlists, (playlist: Playlist) => {
          Row({ space: 12 }) {
            Row() {
              Text('\uD83C\uDFB5')
                .fontSize(18)
            }
            .width(36)
            .height(36)
            .borderRadius(8)
            .backgroundColor(CARD_BG)
            .justifyContent(FlexAlign.Center)

            Column({ space: 2 }) {
              Text(playlist.name)
                .fontSize(15)
                .fontColor(TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              Text(`${playlist.songCount} \u9996`)
                .fontSize(12)
                .fontColor(TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('+')
              .fontSize(20)
              .fontColor(PRIMARY_COLOR)
              .width(32)
              .height(32)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => {
            this.doAddToPlaylist(playlist.id)
          })
        })

        // 搜索模式下始终显示创建新歌单入口
        if (this.mode === 'search') {
          if (this.showCreatePlaylistInline) {
            Column({ space: 12 }) {
              Divider().width('100%').color('#E8E8E8')

              Text('\u65B0\u5EFA\u6B4C\u5355')
                .fontSize(15)
                .fontColor(TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
                .width('100%')

              TextInput({ placeholder: '\u8F93\u5165\u6B4C\u5355\u540D\u79F0', text: this.newPlaylistName })
                .width('100%')
                .height(44)
                .fontSize(15)
                .padding({ left: 16, right: 16 })
                .backgroundColor('#F0F0F0')
                .borderRadius(10)
                .onChange((value: string) => {
                  this.newPlaylistName = value
                })

              Row({ space: 12 }) {
                Button('\u53D6\u6D88')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(14)
                  .fontColor(TEXT_PRIMARY)
                  .backgroundColor(CARD_BG)
                  .borderRadius(20)
                  .onClick(() => {
                    this.showCreatePlaylistInline = false
                    this.newPlaylistName = ''
                  })

                Button('\u521B\u5EFA\u5E76\u6DFB\u52A0')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(14)
                  .fontColor(Color.White)
                  .backgroundColor(PRIMARY_COLOR)
                  .borderRadius(20)
                  .onClick(() => {
                    this.doCreateAndAdd()
                  })
              }
              .width('100%')
            }
            .padding({ left: 24, right: 24, top: 12 })
          } else {
            Row({ space: 8 }) {
              Text('+')
                .fontSize(16)
                .fontColor(PRIMARY_COLOR)
              Text('\u65B0\u5EFA\u6B4C\u5355')
                .fontSize(14)
                .fontColor(PRIMARY_COLOR)
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 16, bottom: 8 })
            .onClick(() => {
              this.showCreatePlaylistInline = true
            })
          }
        }
      }

      Column().height(16)
    }
  }

  @Builder
  QualityPickerContent() {
    Column() {
      Text('\u9009\u62E9\u4E0B\u8F7D\u97F3\u8D28')
        .fontSize(17)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 24, right: 24, top: 16, bottom: 12 })

      ForEach(QUALITY_OPTIONS, (option: QualityOption) => {
        Row({ space: 12 }) {
          Text(option.label)
            .fontSize(15)
            .fontColor(TEXT_PRIMARY)
            .layoutWeight(1)

          Text('\u27A4')
            .fontSize(16)
            .fontColor(TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 14, bottom: 14 })
        .onClick(() => {
          this.doDownload(option.value)
        })
      })

      if (QUALITY_OPTIONS.some(q => q.value === 'high' || q.value === 'lossless')) {
        Text('\u9AD8\u54C1\u8D28\u97F3\u4E50\u4E00\u6B21\u81F3\u591A\u4E0B\u8F7D5\u9996')
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 16 })
      }

      Column().height(8)
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
      case 'later':
        this.doPlayLater()
        break
      case 'share':
        this.doShare()
        break
      case 'playlist':
        this.loadPlaylists().then(() => {
          this.showCreatePlaylistInline = false
          this.showPlaylistPicker = true
        })
        break
      case 'download':
        this.showQualityPicker = true
        break
      case 'play_next':
        this.doPlayNext()
        break
      case 'auto_download':
        this.doAutoDownload()
        break
      default:
        break
    }
    // 非弹窗操作时关闭主面板
    if (action !== 'playlist' && action !== 'download') {
      this.dismiss()
    }
  }
}