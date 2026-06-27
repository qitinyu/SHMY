// SourceManager.ets - 自定义音源管理器
// 支持导入 JSON 格式的音源配置文件，动态加载搜索/播放/歌词接口

import { http } from '@kit.NetworkKit'
import { util } from '@kit.ArkTS'
import fs from '@ohos.file.fs'
import type { SongInfo } from '../model/MusicModel'

// ==================== 类型定义 ====================

export interface SourceConfig {
  name: string
  type: string
  search: SearchConfig
  play: PlayConfig
  lyric?: LyricConfig
}

export interface SearchConfig {
  url: string
  method: string
  params: Record<string, string>
  headers?: Record<string, string>
  response: SearchResponseConfig
}

export interface SearchResponseConfig {
  listPath: string
  songId: string
  songIdStrip: string
  songName: string
  artist: string
  album: string
  duration: string
  coverUrl: string
  coverPrefix: string
  isPay: string
}

export interface PlayConfig {
  url: string
  method: string
  params: Record<string, string>
  headers?: Record<string, string>
  response: PlayResponseConfig
}

export interface PlayResponseConfig {
  urlPath: string
  codePath: string
  successCode: string
  urlPrefix: string
}

export interface LyricConfig {
  url: string
  method: string
  params: Record<string, string>
  headers?: Record<string, string>
  response: LyricResponseConfig
}

export interface LyricResponseConfig {
  listPath: string
  timeField: string
  textField: string
}

// ==================== SourceManager ====================

const STORAGE_KEY_PREFIX: string = 'custom_source_'
const STORAGE_INDEX_KEY: string = 'custom_source_index'
const UA: string = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

// 数据库操作函数类型
type GetSettingFn = (key: string) => Promise<string>
type SetSettingFn = (key: string, value: string) => Promise<void>

export class SourceManager {
  private static configs: Map<string, SourceConfig> = new Map()
  private static getSettingFn: GetSettingFn | null = null
  private static setSettingFn: SetSettingFn | null = null

  // 注入数据库操作函数
  static setDatabaseOps(getFn: GetSettingFn, setFn: SetSettingFn): void {
    SourceManager.getSettingFn = getFn
    SourceManager.setSettingFn = setFn
  }

  private static async getSetting(key: string): Promise<string> {
    if (SourceManager.getSettingFn) {
      return await SourceManager.getSettingFn(key)
    }
    return ''
  }

  private static async setSetting(key: string, value: string): Promise<void> {
    if (SourceManager.setSettingFn) {
      await SourceManager.setSettingFn(key, value)
    }
  }

  // 从文件导入音源配置
  static async importFromFile(fileUri: string): Promise<string> {
    try {
      const file: fs.File = fs.openSync(fileUri, fs.OpenMode.READ_ONLY)
      const stat: fs.Stat = fs.statSync(file.fd)
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size)
      fs.readSync(file.fd, buffer)
      fs.closeSync(file)

      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
      const jsonStr: string = decoder.decodeWithStream(new Uint8Array(buffer))

      const config: SourceConfig = SourceManager.parseConfig(jsonStr)
      if (config.name.length === 0 || !config.search || !config.play) {
        return ''
      }

      // 存储到数据库
      const configJson: string = JSON.stringify(config)
      await SourceManager.setSetting(STORAGE_KEY_PREFIX + config.name, configJson)

      // 更新索引
      let indexStr: string = await SourceManager.getSetting(STORAGE_INDEX_KEY)
      let names: string[] = []
      if (indexStr.length > 0) {
        names = JSON.parse(indexStr) as string[]
      }
      let found: boolean = false
      for (let i = 0; i < names.length; i++) {
        if (names[i] === config.name) {
          found = true
          break
        }
      }
      if (!found) {
        names.push(config.name)
      }
      await SourceManager.setSetting(STORAGE_INDEX_KEY, JSON.stringify(names))

      // 加入内存
      SourceManager.configs.set(config.name, config)

      console.info(`[SourceManager] Imported source: ${config.name}`)
      return config.name
    } catch (e) {
      console.error('[SourceManager] importFromFile failed:', e)
      return ''
    }
  }

  // 从数据库加载所有已导入的音源
  static async loadAll(): Promise<void> {
    const indexStr: string = await SourceManager.getSetting(STORAGE_INDEX_KEY)
    if (indexStr.length === 0) return

    const names: string[] = JSON.parse(indexStr) as string[]
    for (let i = 0; i < names.length; i++) {
      const jsonStr: string = await SourceManager.getSetting(STORAGE_KEY_PREFIX + names[i])
      if (jsonStr.length > 0) {
        try {
          const config: SourceConfig = SourceManager.parseConfig(jsonStr)
          SourceManager.configs.set(config.name, config)
        } catch (_e) {
          // 跳过损坏的配置
        }
      }
    }

    console.info(`[SourceManager] Loaded ${SourceManager.configs.size} custom sources`)
  }

  // 删除音源
  static async removeSource(name: string): Promise<void> {
    SourceManager.configs.delete(name)
    await SourceManager.setSetting(STORAGE_KEY_PREFIX + name, '')

    const indexStr: string = await SourceManager.getSetting(STORAGE_INDEX_KEY)
    if (indexStr.length > 0) {
      const names: string[] = JSON.parse(indexStr) as string[]
      const newNames: string[] = []
      for (let i = 0; i < names.length; i++) {
        if (names[i] !== name) {
          newNames.push(names[i])
        }
      }
      await SourceManager.setSetting(STORAGE_INDEX_KEY, JSON.stringify(newNames))
    }
  }

  // 获取所有已加载的音源名
  static getSourceNames(): string[] {
    const names: string[] = []
    SourceManager.configs.forEach((config: SourceConfig) => {
      names.push(config.name)
    })
    return names
  }

  // 获取音源配置
  static getConfig(name: string): SourceConfig | undefined {
    return SourceManager.configs.get(name)
  }

  // 搜索所有自定义音源
  static async searchAll(keyword: string): Promise<SongInfo[]> {
    const names: string[] = SourceManager.getSourceNames()
    let allResults: SongInfo[] = []
    for (let i = 0; i < names.length; i++) {
      const results: SongInfo[] = await SourceManager.search(names[i], keyword)
      allResults = allResults.concat(results)
    }
    return allResults
  }

  // 使用自定义音源搜索
  static async search(sourceName: string, keyword: string): Promise<SongInfo[]> {
    const config: SourceConfig | undefined = SourceManager.configs.get(sourceName)
    if (!config) return []

    try {
      const url: string = SourceManager.buildUrl(config.search.url, config.search.params, keyword, '0')
      const headers: Record<string, string> = config.search.headers ?? (new Object() as Record<string, string>)
      const raw: string = await SourceManager.httpGet(url, headers)

      if (raw.length === 0) return []

      const parsed: Record<string, Object> = JSON.parse(raw) as Record<string, Object>
      const list: Object = SourceManager.getNestedValue(parsed, config.search.response.listPath)
      if (!(list instanceof Array)) return []

      const results: SongInfo[] = []
      const arr: Object[] = list as Object[]

      for (let i = 0; i < arr.length; i++) {
        const item: Record<string, Object> = arr[i] as Record<string, Object>
        let songId: string = String(item[config.search.response.songId] ?? '')
        const strip: string = config.search.response.songIdStrip
        if (strip.length > 0 && songId.startsWith(strip)) {
          songId = songId.substring(strip.length)
        }

        const songName: string = String(item[config.search.response.songName] ?? '')
        const artist: string = String(item[config.search.response.artist] ?? '')
        const album: string = config.search.response.album.length > 0 ? String(item[config.search.response.album] ?? '') : ''

        let coverUrl: string = ''
        if (config.search.response.coverUrl.length > 0) {
          const coverPart: string = String(item[config.search.response.coverUrl] ?? '')
          if (coverPart.length > 0) {
            coverUrl = config.search.response.coverPrefix + coverPart
          }
        }

        let durStr: string = '0'
        if (config.search.response.duration.length > 0) {
          durStr = String(item[config.search.response.duration] ?? '0')
        }
        const durSec: number = parseInt(durStr) || 0
        const durFormatted: string = `${Math.floor(durSec / 60)}:${(durSec % 60).toString().padStart(2, '0')}`

        if (songId.length === 0 || songName.length === 0) continue

        let isPay: boolean = false
        if (config.search.response.isPay.length > 0) {
          isPay = String(item[config.search.response.isPay] ?? '0') === '1'
        }

        const song: SongInfo = {
          songId: songId,
          songName: songName,
          artist: artist,
          album: album,
          coverUrl: coverUrl,
          source: 'custom_' + config.name,
          playUrl: '',
          quality: isPay ? `VIP/${durFormatted}` : `128kbps/${durFormatted}`,
        }
        results.push(song)
      }

      console.info(`[SourceManager] Search "${keyword}" via ${sourceName} => ${results.length} results`)
      return results
    } catch (e) {
      console.error(`[SourceManager] search failed for ${sourceName}:`, e)
      return []
    }
  }

  // 使用自定义音源获取播放 URL
  static async getPlayUrl(sourceName: string, songId: string): Promise<string> {
    const config: SourceConfig | undefined = SourceManager.configs.get(sourceName)
    if (!config) return ''

    try {
      const url: string = SourceManager.buildUrl(config.play.url, config.play.params, songId, '')
      const headers: Record<string, string> = config.play.headers ?? (new Object() as Record<string, string>)
      const raw: string = await SourceManager.httpGet(url, headers)
      if (raw.length === 0) return ''

      const parsed: Record<string, Object> = JSON.parse(raw) as Record<string, Object>

      // 检查成功码
      if (config.play.response.codePath.length > 0) {
        const code: string = String(SourceManager.getNestedValue(parsed, config.play.response.codePath) ?? '')
        const successCode: string = config.play.response.successCode
        if (code !== successCode) {
          console.warn(`[SourceManager] Play URL failed: code=${code}`)
          return ''
        }
      }

      const playUrl: string = String(SourceManager.getNestedValue(parsed, config.play.response.urlPath) ?? '')
      if (playUrl.length > 0 && playUrl.startsWith('http')) {
        return config.play.response.urlPrefix + playUrl
      }

      return ''
    } catch (e) {
      console.error(`[SourceManager] getPlayUrl failed for ${sourceName}:`, e)
      return ''
    }
  }

  // 尝试所有自定义音源获取播放 URL
  static async getPlayUrlFromAny(songId: string, songName: string, artist: string): Promise<string> {
    const names: string[] = SourceManager.getSourceNames()
    for (let i = 0; i < names.length; i++) {
      const url: string = await SourceManager.getPlayUrl(names[i], songId)
      if (url.length > 0) return url
    }
    return ''
  }

  // 使用自定义音源获取歌词
  static async getLyrics(sourceName: string, songId: string): Promise<string> {
    const config: SourceConfig | undefined = SourceManager.configs.get(sourceName)
    if (!config || !config.lyric) return ''

    try {
      const url: string = SourceManager.buildUrl(config.lyric.url, config.lyric.params, songId, '')
      const headers: Record<string, string> = config.lyric.headers ?? (new Object() as Record<string, string>)
      const raw: string = await SourceManager.httpGet(url, headers)
      if (raw.length === 0) return ''

      const parsed: Record<string, Object> = JSON.parse(raw) as Record<string, Object>
      const list: Object = SourceManager.getNestedValue(parsed, config.lyric.response.listPath)
      if (!(list instanceof Array)) return ''

      let lrc: string = ''
      const arr: Object[] = list as Object[]
      for (let i = 0; i < arr.length; i++) {
        const item: Record<string, Object> = arr[i] as Record<string, Object>
        const time: string = String(item[config.lyric.response.timeField] ?? '0:00.00')
        const text: string = String(item[config.lyric.response.textField] ?? '')
        lrc += `[${time}]${text}\n`
      }

      return lrc
    } catch (e) {
      console.error(`[SourceManager] getLyrics failed for ${sourceName}:`, e)
      return ''
    }
  }

  // ==================== 内部工具函数 ====================

  private static parseConfig(jsonStr: string): SourceConfig {
    const raw: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>
    const searchRaw: Object | undefined = raw['search']
    const playRaw: Object | undefined = raw['play']
    const lyricRaw: Object | undefined = raw['lyric']

    const config: SourceConfig = {
      name: String(raw['name'] ?? ''),
      type: String(raw['type'] ?? 'custom'),
      search: searchRaw ? SourceManager.parseSearchConfig(searchRaw) : SourceManager.emptySearchConfig(),
      play: playRaw ? SourceManager.parsePlayConfig(playRaw) : SourceManager.emptyPlayConfig(),
      lyric: lyricRaw ? SourceManager.parseLyricConfig(lyricRaw) : undefined,
    }
    return config
  }

  private static emptySearchConfig(): SearchConfig {
    const emptyParams: Record<string, string> = new Object() as Record<string, string>
    return {
      url: '',
      method: 'GET',
      params: emptyParams,
      response: {
        listPath: '',
        songId: 'songId',
        songIdStrip: '',
        songName: 'songName',
        artist: 'artist',
        album: '',
        duration: '',
        coverUrl: '',
        coverPrefix: '',
        isPay: '',
      },
    }
  }

  private static emptyPlayConfig(): PlayConfig {
    const emptyParams: Record<string, string> = new Object() as Record<string, string>
    return {
      url: '',
      method: 'GET',
      params: emptyParams,
      response: {
        urlPath: 'url',
        codePath: '',
        successCode: '200',
        urlPrefix: '',
      },
    }
  }

  private static parseSearchConfig(raw: Object): SearchConfig {
    const obj: Record<string, Object> = raw as Record<string, Object>
    const respRaw: Object | undefined = obj['response']
    const resp: Record<string, Object> = (respRaw !== undefined && respRaw !== null) ? respRaw as Record<string, Object> : new Object() as Record<string, Object>
    const result: SearchConfig = {
      url: String(obj['url'] ?? ''),
      method: String(obj['method'] ?? 'GET'),
      params: SourceManager.toStringMap(obj['params']),
      headers: obj['headers'] ? SourceManager.toStringMap(obj['headers']) : undefined,
      response: {
        listPath: String(resp['listPath'] ?? ''),
        songId: String(resp['songId'] ?? 'songId'),
        songIdStrip: resp['songIdStrip'] ? String(resp['songIdStrip']) : '',
        songName: String(resp['songName'] ?? 'songName'),
        artist: String(resp['artist'] ?? 'artist'),
        album: resp['album'] ? String(resp['album']) : '',
        duration: resp['duration'] ? String(resp['duration']) : '',
        coverUrl: resp['coverUrl'] ? String(resp['coverUrl']) : '',
        coverPrefix: resp['coverPrefix'] ? String(resp['coverPrefix']) : '',
        isPay: resp['isPay'] ? String(resp['isPay']) : '',
      },
    }
    return result
  }

  private static parsePlayConfig(raw: Object): PlayConfig {
    const obj: Record<string, Object> = raw as Record<string, Object>
    const respRaw: Object | undefined = obj['response']
    const resp: Record<string, Object> = (respRaw !== undefined && respRaw !== null) ? respRaw as Record<string, Object> : new Object() as Record<string, Object>
    const result: PlayConfig = {
      url: String(obj['url'] ?? ''),
      method: String(obj['method'] ?? 'GET'),
      params: SourceManager.toStringMap(obj['params']),
      headers: obj['headers'] ? SourceManager.toStringMap(obj['headers']) : undefined,
      response: {
        urlPath: String(resp['urlPath'] ?? 'url'),
        codePath: resp['codePath'] ? String(resp['codePath']) : '',
        successCode: resp['successCode'] ? String(resp['successCode']) : '200',
        urlPrefix: resp['urlPrefix'] ? String(resp['urlPrefix']) : '',
      },
    }
    return result
  }

  private static parseLyricConfig(raw: Object): LyricConfig {
    const obj: Record<string, Object> = raw as Record<string, Object>
    const respRaw: Object | undefined = obj['response']
    const resp: Record<string, Object> = (respRaw !== undefined && respRaw !== null) ? respRaw as Record<string, Object> : new Object() as Record<string, Object>
    const result: LyricConfig = {
      url: String(obj['url'] ?? ''),
      method: String(obj['method'] ?? 'GET'),
      params: SourceManager.toStringMap(obj['params']),
      headers: obj['headers'] ? SourceManager.toStringMap(obj['headers']) : undefined,
      response: {
        listPath: String(resp['listPath'] ?? 'data.lrclist'),
        timeField: String(resp['timeField'] ?? 'time'),
        textField: String(resp['textField'] ?? 'lineLyric'),
      },
    }
    return result
  }

  private static toStringMap(raw: Object): Record<string, string> {
    const result: Record<string, string> = new Object() as Record<string, string>
    if (raw && typeof raw === 'object') {
      const obj: Record<string, Object> = raw as Record<string, Object>
      const keys: string[] = Object.keys(obj)
      for (let i = 0; i < keys.length; i++) {
        result[keys[i]] = String(obj[keys[i]])
      }
    }
    return result
  }

  // 构建 URL：替换 params 中的 {keyword}、{songId}、{page} 等占位符
  // primaryValue: 当搜索时是 keyword，当播放时是 songId
  static buildUrl(baseUrl: string, params: Record<string, string>, primaryValue: string, page: string): string {
    const parts: string[] = []
    const keys: string[] = Object.keys(params)
    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i]
      let val: string = params[key]
      // 替换占位符 — primaryValue 用于 {keyword} 或 {songId}
      val = val.replace('{keyword}', encodeURIComponent(primaryValue))
      val = val.replace('{songId}', encodeURIComponent(primaryValue))
      val = val.replace('{page}', page)
      parts.push(`${key}=${val}`)
    }

    if (parts.length === 0) return baseUrl
    const separator: string = baseUrl.indexOf('?') >= 0 ? '&' : '?'
    return baseUrl + separator + parts.join('&')
  }

  // 从嵌套路径获取值：如 "data.lrclist"
  private static getNestedValue(obj: Record<string, Object>, path: string): Object {
    const parts: string[] = path.split('.')
    let current: Object = obj
    for (let i = 0; i < parts.length; i++) {
      if (current === null || current === undefined || typeof current !== 'object') {
        return ''
      }
      const record: Record<string, Object> = current as Record<string, Object>
      current = record[parts[i]] ?? ''
    }
    return current
  }

  // HTTP GET
  private static async httpGet(url: string, extraHeaders?: Record<string, string>): Promise<string> {
    try {
      const headerObj: Record<string, string> = { 'User-Agent': UA } as Record<string, string>
      if (extraHeaders) {
        const keys: string[] = Object.keys(extraHeaders)
        for (let i = 0; i < keys.length; i++) {
          headerObj[keys[i]] = extraHeaders[keys[i]]
        }
      }
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: headerObj,
        readTimeout: 10000,
        connectTimeout: 10000,
      } as http.HttpRequestOptions)
      httpRequest.destroy()
      const result = response.result
      if (typeof result === 'string') {
        return result
      }
      const bytes: Uint8Array = result as Uint8Array
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
      return decoder.decodeWithStream(bytes)
    } catch (e) {
      console.error('[SourceManager] httpGet failed:', e)
      return ''
    }
  }
}
