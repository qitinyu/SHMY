// PlayerStore.ets - 全局播放器状态管理
// 使用 AppStorage 实现跨组件状态共享
import type { SongInfo, LyricLine } from '../model/MusicModel'

// 播放器状态 Key 常量
export class PlayerKeys {
  static readonly CURRENT_TRACK: string = 'currentTrack'
  static readonly IS_PLAYING: string = 'isPlaying'
  static readonly CURRENT_TIME: string = 'currentTime'
  static readonly DURATION: string = 'duration'
  static readonly VOLUME: string = 'volume'
  static readonly QUEUE: string = 'queue'
  static readonly QUEUE_INDEX: string = 'queueIndex'
  static readonly LYRICS: string = 'lyrics'
  static readonly LYRICS_RAW: string = 'lyricsRaw'
  static readonly SHOW_FULL_PLAYER: string = 'showFullPlayer'
  static readonly FULL_PLAYER_PAGE: string = 'fullPlayerPage'
}

// 安全获取 AppStorage 中的 boolean 值
function getStorageBool(key: string): boolean {
  const val: Object | undefined = AppStorage.get(key)
  if (typeof val === 'boolean') {
    return val
  }
  return false
}

// 安全获取 AppStorage 中的 number 值
function getStorageNum(key: string): number {
  const val: Object | undefined = AppStorage.get(key)
  if (typeof val === 'number') {
    return val
  }
  return 0
}

export class PlayerStore {

  // 播放
  static play(track: SongInfo): void {
    AppStorage.setOrCreate(PlayerKeys.CURRENT_TRACK, track)
    AppStorage.setOrCreate(PlayerKeys.IS_PLAYING, true)
  }

  // 暂停
  static pause(): void {
    AppStorage.setOrCreate(PlayerKeys.IS_PLAYING, false)
  }

  // 恢复
  static resume(): void {
    AppStorage.setOrCreate(PlayerKeys.IS_PLAYING, true)
  }

  // 切换播放/暂停
  static togglePlay(): void {
    const playing = getStorageBool(PlayerKeys.IS_PLAYING)
    AppStorage.setOrCreate(PlayerKeys.IS_PLAYING, !playing)
  }

  // 下一首
  static next(): void {
    const queue = AppStorage.get(PlayerKeys.QUEUE) as SongInfo[]
    const index = getStorageNum(PlayerKeys.QUEUE_INDEX)
    if (!queue || queue.length === 0) return
    const nextIndex = index + 1
    if (nextIndex >= queue.length) return
    AppStorage.setOrCreate(PlayerKeys.QUEUE_INDEX, nextIndex)
    PlayerStore.play(queue[nextIndex])
  }

  // 上一首
  static previous(): void {
    const queue = AppStorage.get(PlayerKeys.QUEUE) as SongInfo[]
    const index = getStorageNum(PlayerKeys.QUEUE_INDEX)
    if (!queue || queue.length === 0) return
    const prevIndex = index - 1
    if (prevIndex < 0) return
    AppStorage.setOrCreate(PlayerKeys.QUEUE_INDEX, prevIndex)
    PlayerStore.play(queue[prevIndex])
  }

  // 更新当前时间
  static updateTime(time: number): void {
    AppStorage.setOrCreate(PlayerKeys.CURRENT_TIME, time)
  }

  // 更新总时长
  static updateDuration(duration: number): void {
    AppStorage.setOrCreate(PlayerKeys.DURATION, duration)
  }

  // 设置队列
  static setQueue(tracks: SongInfo[]): void {
    AppStorage.setOrCreate(PlayerKeys.QUEUE, tracks)
    AppStorage.setOrCreate(PlayerKeys.QUEUE_INDEX, 0)
  }

  // 添加到队列
  static addToQueue(track: SongInfo): void {
    const queue = AppStorage.get(PlayerKeys.QUEUE) as SongInfo[]
    if (queue) {
      const newQueue: SongInfo[] = queue.slice()
      newQueue.push(track)
      AppStorage.setOrCreate(PlayerKeys.QUEUE, newQueue)
    }
  }

  // 设置歌词
  static setLyrics(lyrics: LyricLine[], raw: string): void {
    AppStorage.setOrCreate(PlayerKeys.LYRICS, lyrics)
    AppStorage.setOrCreate(PlayerKeys.LYRICS_RAW, raw)
  }

  // 显示完整播放器
  static showFullPlayer(): void {
    AppStorage.setOrCreate(PlayerKeys.SHOW_FULL_PLAYER, true)
  }

  // 隐藏完整播放器
  static hideFullPlayer(): void {
    AppStorage.setOrCreate(PlayerKeys.SHOW_FULL_PLAYER, false)
  }

  // 切换播放器页面
  static setFullPlayerPage(page: string): void {
    AppStorage.setOrCreate(PlayerKeys.FULL_PLAYER_PAGE, page)
  }

  // 获取当前曲目
  static getCurrentTrack(): SongInfo | undefined {
    return AppStorage.get(PlayerKeys.CURRENT_TRACK) as SongInfo | undefined
  }

  // 获取队列
  static getQueue(): SongInfo[] {
    const queue = AppStorage.get(PlayerKeys.QUEUE) as SongInfo[]
    return queue ?? []
  }

  // 获取歌词
  static getLyrics(): LyricLine[] {
    const lyrics = AppStorage.get(PlayerKeys.LYRICS) as LyricLine[]
    return lyrics ?? []
  }

  // 解析 LRC 歌词
  static parseLrc(raw: string): LyricLine[] {
    if (!raw || raw.length === 0) return []
    const lines = raw.split('\n')
    const result: LyricLine[] = []

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]
      const match = line.match(/\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)/)
      if (match && match.length >= 5) {
        const min = parseInt(match[1])
        const sec = parseInt(match[2])
        const ms = parseInt(match[3].padEnd(3, '0'))
        const time = min * 60 + sec + ms / 1000
        const text = match[4].trim()
        if (text.length > 0) {
          result.push({ time: time, text: text })
        }
      }
    }
    result.sort((a: LyricLine, b: LyricLine) => a.time - b.time)
    return result
  }
}
