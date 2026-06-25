// SHMY 数据模型定义
// MusicModel.ets

// 音源类型
export enum SourceType {
  KG = 'kg',  // 小狗/酷狗
  KW = 'kw',  // 小我/酷我
  WY = 'wy',  // 小云/网易云
  QQ = 'qq',  // 小鹅/QQ音乐
}

// 音源信息项接口
export interface SourceInfoItem {
  name: string
  codeName: string
  color: string
}

// 歌词颜色项接口
export interface LyricsColorItem {
  label: string
  value: string
}

// 音源信息映射
export class SourceInfo {
  static readonly MAP: Record<string, SourceInfoItem> = {
    [SourceType.KG]: { name: '小狗', codeName: '酷狗', color: '#2196F3' },
    [SourceType.KW]: { name: '小我', codeName: '酷我', color: '#FF9800' },
    [SourceType.WY]: { name: '小云', codeName: '网易云', color: '#E53935' },
    [SourceType.QQ]: { name: '小鹅', codeName: 'QQ音乐', color: '#4CAF50' },
  }

  static getName(source: string): string {
    return SourceInfo.MAP[source]?.name ?? source
  }

  static getColor(source: string): string {
    return SourceInfo.MAP[source]?.color ?? '#999999'
  }

  static getCodeName(source: string): string {
    return SourceInfo.MAP[source]?.codeName ?? source
  }
}

// 歌曲信息
export interface SongInfo {
  songId: string
  songName: string
  artist: string
  album: string
  coverUrl: string
  source: string
  playUrl: string
  quality?: string
}

// 搜索结果（同 SongInfo）
export type SearchResult = SongInfo

// 歌词行
export interface LyricLine {
  time: number   // 秒
  text: string
}

// 下载状态
export enum DownloadStatus {
  PENDING = 'pending',
  DOWNLOADING = 'downloading',
  COMPLETED = 'completed',
  FAILED = 'failed',
}

// 下载记录
export interface DownloadItem {
  id: string
  songId: string
  songName: string
  artist: string
  album: string
  coverUrl: string
  source: string
  playUrl: string
  quality: string
  status: string
  progress: number
  createdAt: number
}

// 歌单
export interface Playlist {
  id: string
  name: string
  songCount: number
  createdAt: number
  updatedAt: number
}

// 应用设置
export interface AppSettings {
  theme: string
  customBackground: boolean
  customBackgroundPath: string
  useSystemFont: boolean
  fontSize: string
  autoPlay: boolean
  autoJumpDetail: boolean
  lyricsPosition: string
  rememberProgress: boolean
  autoStopOnOtherAudio: boolean
  desktopLyrics: boolean
  lockDesktopLyrics: boolean
  notificationCard: boolean
  multiLineLyrics: boolean
  lyricsSize: string
  lyricsColor: string
  lyricsBgOpacity: number
}

// 默认设置
export const DEFAULT_SETTINGS: AppSettings = {
  theme: 'light',
  customBackground: false,
  customBackgroundPath: '',
  useSystemFont: false,
  fontSize: 'standard',
  autoPlay: false,
  autoJumpDetail: false,
  lyricsPosition: 'center',
  rememberProgress: false,
  autoStopOnOtherAudio: false,
  desktopLyrics: false,
  lockDesktopLyrics: false,
  notificationCard: false,
  multiLineLyrics: false,
  lyricsSize: 'standard',
  lyricsColor: '#FFFFFF',
  lyricsBgOpacity: 50,
}

// 桌面歌词颜色预设
export const LYRICS_COLORS: LyricsColorItem[] = [
  { label: '白色', value: '#FFFFFF' },
  { label: '天蓝', value: '#64B5F6' },
  { label: '浅绿', value: '#81C784' },
  { label: '暖橙', value: '#FFB74D' },
  { label: '淡粉', value: '#F48FB1' },
]

// 启动弹窗信息
export interface StartupInfo {
  version: string
  updateUrl: string
  updateContent: string[]
}

// 创建空 SongInfo 的辅助函数
export function createEmptySongInfo(): SongInfo {
  return {
    songId: '',
    songName: '',
    artist: '',
    album: '',
    coverUrl: '',
    source: '',
    playUrl: '',
  }
}
