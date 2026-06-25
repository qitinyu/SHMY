// AudioPlayer.ets - 音频播放器
// 基于 @ohos.multimedia.media 的 AVPlayer
import { media } from '@kit.MediaKit'
import type { SongInfo } from '../model/MusicModel'

export class AudioPlayer {
  private static instance: AudioPlayer | null = null
  private avPlayer: media.AVPlayer | null = null
  private currentUrl: string = ''
  private _isPlaying: boolean = false

  // 回调
  onTimeUpdate?: (time: number) => void
  onDurationUpdate?: (duration: number) => void
  onPlayEnd?: () => void
  onError?: (error: string) => void

  static getInstance(): AudioPlayer {
    if (!AudioPlayer.instance) {
      AudioPlayer.instance = new AudioPlayer()
    }
    return AudioPlayer.instance
  }

  // 初始化播放器
  private async initPlayer(): Promise<boolean> {
    try {
      this.avPlayer = await media.createAVPlayer()
      this.setupListeners()
      return true
    } catch (_e) {
      console.error('[AudioPlayer] create failed')
      this.onError?.('播放器初始化失败')
      return false
    }
  }

  // 设置事件监听
  private setupListeners(): void {
    if (!this.avPlayer) return

    this.avPlayer.on('timeUpdate', (time: number) => {
      // AVPlayer 回调的 time 是毫秒
      this.onTimeUpdate?.(time / 1000)
    })

    this.avPlayer.on('durationUpdate', (duration: number) => {
      this.onDurationUpdate?.(duration / 1000)
    })

    this.avPlayer.on('stateChange', (state: string) => {
      if (state === 'completed') {
        this._isPlaying = false
        this.onPlayEnd?.()
      } else if (state === 'error') {
        this._isPlaying = false
        this.onError?.('播放出错')
      }
    })
  }

  // 播放
  async play(url: string): Promise<void> {
    if (!url) {
      this.onError?.('播放链接为空')
      return
    }

    // 同一个URL，继续播放
    if (url === this.currentUrl && this.avPlayer) {
      try {
        await this.avPlayer.play()
        this._isPlaying = true
        return
      } catch (_e) {
        console.error('[AudioPlayer] resume failed')
      }
    }

    // 新URL，重新初始化
    try {
      if (this.avPlayer) {
        try {
          await this.avPlayer.release()
        } catch (_ignore) {
          // ignore release error
        }
      }
      if (!await this.initPlayer()) return

      this.avPlayer!.url = url
      this.currentUrl = url
      this._isPlaying = true

      await this.avPlayer!.prepare()
      await this.avPlayer!.play()
    } catch (_e) {
      console.error('[AudioPlayer] play failed')
      this._isPlaying = false
      this.onError?.('播放失败')
    }
  }

  // 暂停
  async pause(): Promise<void> {
    if (this.avPlayer && this._isPlaying) {
      try {
        await this.avPlayer.pause()
        this._isPlaying = false
      } catch (_e) {
        console.error('[AudioPlayer] pause failed')
      }
    }
  }

  // 恢复播放
  async resume(): Promise<void> {
    if (this.avPlayer && !this._isPlaying) {
      try {
        await this.avPlayer.play()
        this._isPlaying = true
      } catch (_e) {
        console.error('[AudioPlayer] resume failed')
      }
    }
  }

  // 跳转
  async seekTo(timeSeconds: number): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.seek(timeSeconds * 1000)
      } catch (_e) {
        console.error('[AudioPlayer] seek failed')
      }
    }
  }

  // 设置音量 0~1
  async setVolume(volume: number): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.setVolume(Math.max(0, Math.min(1, volume)))
      } catch (_e) {
        console.error('[AudioPlayer] setVolume failed')
      }
    }
  }

  // 停止
  async stop(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.stop()
        this._isPlaying = false
      } catch (_e) {
        console.error('[AudioPlayer] stop failed')
      }
    }
  }

  // 释放资源
  async release(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.release()
      } catch (_ignore) {
        // ignore
      }
      this.avPlayer = null
    }
    this._isPlaying = false
    this.currentUrl = ''
  }

  get isPlaying(): boolean {
    return this._isPlaying
  }

  get playingUrl(): string {
    return this.currentUrl
  }
}
