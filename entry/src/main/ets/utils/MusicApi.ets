// MusicApi.ets - 音乐搜索/播放/歌词网络请求
// 封装聚合音源API
import { http } from '@kit.NetworkKit'
import type { SongInfo } from '../model/MusicModel'

const OIAPI_AUTH = 'Bearer oiapi-ef6133b7-ac2f-dc7d-878c-d3e207a82575'
const XINGHAI_BASE = 'https://music-api.gdstudio.xyz/api.php'
const MUSIC_DL_BASE = 'https://music-dl.sayqz.com/api/'

// Suyin API 音源映射
class SuyinApiMap {
  static readonly QQ: string = 'https://oiapi.net/api/QQ_Music'
  static readonly WY: string = 'https://oiapi.net/api/Music_163'
  static readonly KW: string = 'https://oiapi.net/api/Kuwo'
}

// 通用 GET 请求
async function httpGet(url: string): Promise<string> {
  try {
    const httpRequest = http.createHttp()
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      readTimeout: 8000,
      connectTimeout: 8000,
    } as http.HttpRequestOptions)
    httpRequest.destroy()
    const result = response.result
    if (typeof result === 'string') {
      return result
    }
    return ''
  } catch (_e) {
    console.error(`[MusicApi] GET ${url} failed`)
    return ''
  }
}

// 通用 POST 请求（Suyin API）
async function httpPost(url: string, body: Record<string, string>): Promise<string> {
  try {
    const headerObj: Record<string, string> = {
      'Content-Type': 'application/json',
      'Authorization': OIAPI_AUTH,
    }
    const httpRequest = http.createHttp()
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: headerObj,
      extraData: JSON.stringify(body),
      readTimeout: 8000,
      connectTimeout: 8000,
    } as http.HttpRequestOptions)
    httpRequest.destroy()
    const result = response.result
    if (typeof result === 'string') {
      return result
    }
    return ''
  } catch (_e) {
    console.error(`[MusicApi] POST ${url} failed`)
    return ''
  }
}

// 从 JSON 数据中安全获取字符串值
function safeString(obj: Record<string, Object>, key: string): string {
  const val = obj[key]
  if (val === undefined || val === null) {
    return ''
  }
  return String(val)
}

// 从 JSON 数据中安全获取子对象
function safeRecord(obj: Record<string, Object>, key: string): Record<string, Object> | null {
  const val = obj[key]
  if (val === undefined || val === null || typeof val !== 'object') {
    return null
  }
  return val as Record<string, Object>
}

// 从 JSON 数据中安全获取数组
function safeArray(obj: Record<string, Object>, key: string): Object[] | null {
  const val = obj[key]
  if (val instanceof Array) {
    return val as Object[]
  }
  return null
}

// 从 JSON 中提取搜索结果列表
function extractResults(data: Object, source: string): SongInfo[] {
  const results: SongInfo[] = []
  let items: Object[] = []

  if (data instanceof Array) {
    items = data as Object[]
  } else if (data !== null && data !== undefined && typeof data === 'object') {
    const obj = data as Record<string, Object>
    // 尝试从各种常见字段中提取列表
    const candidate = safeArray(obj, 'data') ?? safeArray(obj, 'list') ??
      safeArray(obj, 'result') ?? safeArray(obj, 'songs') ?? safeArray(obj, 'results')
    if (candidate !== null) {
      items = candidate
    }
  }

  for (let i = 0; i < items.length; i++) {
    const item = items[i] as Record<string, Object>
    const songId = safeString(item, 'id') || safeString(item, 'songid')
    const songName = safeString(item, 'name')
    const artist = safeString(item, 'singer') || safeString(item, 'artist')
    const album = safeString(item, 'album')
    const coverUrl = safeString(item, 'cover') || safeString(item, 'pic') ||
      safeString(item, 'picurl') || safeString(item, 'albumpic')

    if (songId.length > 0 && songName.length > 0) {
      results.push({ songId, songName, artist, album, coverUrl, source, playUrl: '' })
    }
  }
  return results
}

// 搜索 QQ 音乐
async function searchQQ(keyword: string): Promise<SongInfo[]> {
  const body: Record<string, string> = { 'name': keyword }
  const raw = await httpPost(SuyinApiMap.QQ, body)
  if (raw.length === 0) return []
  const parsed: Object = JSON.parse(raw) as Object
  return extractResults(parsed, 'qq')
}

// 搜索 网易云音乐
async function searchNetEase(keyword: string): Promise<SongInfo[]> {
  const body: Record<string, string> = { 'name': keyword }
  const raw = await httpPost(SuyinApiMap.WY, body)
  if (raw.length === 0) return []
  const parsed: Object = JSON.parse(raw) as Object
  return extractResults(parsed, 'wy')
}

// 搜索 酷我音乐
async function searchKuWo(keyword: string): Promise<SongInfo[]> {
  const body: Record<string, string> = { 'name': keyword }
  const raw = await httpPost(SuyinApiMap.KW, body)
  if (raw.length === 0) return []
  const parsed: Object = JSON.parse(raw) as Object
  return extractResults(parsed, 'kw')
}

// 搜索 酷狗音乐
async function searchKuGou(keyword: string): Promise<SongInfo[]> {
  const params = `use_xbridge3=true&loader_name=forest&need_sec_link=1&sec_link_scene=im&theme=light&msg=${encodeURIComponent(keyword)}`
  const raw = await httpGet(`${XINGHAI_BASE}?${params}`)
  if (raw.length === 0) return []
  const parsed: Object = JSON.parse(raw) as Object
  return extractResults(parsed, 'kg')
}

export class MusicApi {

  /**
   * 搜索音乐
   * @param keyword 关键词
   * @param source 音源: 'all' | 'kg' | 'kw' | 'wy' | 'qq'
   * @returns 搜索结果
   */
  static async search(keyword: string, source: string = 'all'): Promise<SongInfo[]> {
    if (!keyword || keyword.trim().length === 0) return []

    try {
      let allResults: SongInfo[] = []

      if (source === 'all') {
        const r1 = await searchQQ(keyword)
        const r2 = await searchNetEase(keyword)
        const r3 = await searchKuWo(keyword)
        const r4 = await searchKuGou(keyword)
        allResults = r1.concat(r2).concat(r3).concat(r4)
      } else if (source === 'qq') {
        allResults = await searchQQ(keyword)
      } else if (source === 'wy') {
        allResults = await searchNetEase(keyword)
      } else if (source === 'kw') {
        allResults = await searchKuWo(keyword)
      } else if (source === 'kg') {
        allResults = await searchKuGou(keyword)
      }

      return allResults
    } catch (_e) {
      console.error('[MusicApi] search failed')
      return []
    }
  }

  /**
   * 获取播放链接
   * @param songId 歌曲 ID
   * @param source 音源
   * @param quality 音质 (可选)
   * @returns 播放 URL
   */
  static async getPlayUrl(songId: string, source: string, quality?: string): Promise<string> {
    try {
      if (source === 'kg') {
        const raw = await httpGet(`${MUSIC_DL_BASE}?id=${songId}`)
        if (raw.length === 0) return ''
        const data: Object = JSON.parse(raw) as Object
        return extractPlayUrl(data) ?? ''
      } else {
        let apiUrl = ''
        if (source === 'qq') {
          apiUrl = SuyinApiMap.QQ
        } else if (source === 'wy') {
          apiUrl = SuyinApiMap.WY
        } else if (source === 'kw') {
          apiUrl = SuyinApiMap.KW
        }
        if (apiUrl.length === 0) return ''
        const body: Record<string, string> = { 'id': songId }
        if (quality !== undefined && quality.length > 0) {
          body['quality'] = quality
        }
        const raw = await httpPost(apiUrl, body)
        if (raw.length === 0) return ''
        const data: Object = JSON.parse(raw) as Object
        return extractPlayUrl(data) ?? ''
      }
    } catch (_e) {
      console.error('[MusicApi] getPlayUrl failed')
      return ''
    }
  }

  /**
   * 获取歌词
   * @param songId 歌曲 ID
   * @param source 音源
   * @returns 歌词原始文本
   */
  static async getLyrics(songId: string, source: string): Promise<string> {
    try {
      const params = `use_xbridge3=true&loader_name=forest&type=lyr&id=${songId}`
      const raw = await httpGet(`${XINGHAI_BASE}?${params}`)
      if (raw.length === 0) return ''
      const data: Object = JSON.parse(raw) as Object
      return extractLyrics(data)
    } catch (_e) {
      console.error('[MusicApi] getLyrics failed')
      return ''
    }
  }
}

// 从各种响应格式中提取播放URL
function extractPlayUrl(data: Object): string | undefined {
  if (typeof data === 'string') {
    const s = data as string
    if (s.startsWith('http')) return s
    return undefined
  }
  if (data === null || data === undefined || typeof data !== 'object') {
    return undefined
  }
  const record = data as Record<string, Object>
  const topKeys: string[] = ['url', 'music_url', 'playUrl', 'play_url', 'src', 'data']
  for (let i = 0; i < topKeys.length; i++) {
    const val = record[topKeys[i]]
    if (typeof val === 'string' && (val as string).startsWith('http')) {
      return val as string
    }
  }
  // 嵌套 data 对象
  const nested = safeRecord(record, 'data')
  if (nested !== null) {
    const nestedKeys: string[] = ['url', 'music_url', 'playUrl', 'play_url', 'src']
    for (let i = 0; i < nestedKeys.length; i++) {
      const val = nested[nestedKeys[i]]
      if (typeof val === 'string' && (val as string).startsWith('http')) {
        return val as string
      }
    }
  }
  return undefined
}

// 从各种响应格式中提取歌词
function extractLyrics(data: Object): string {
  if (typeof data === 'string') {
    return data as string
  }
  if (data === null || data === undefined || typeof data !== 'object') {
    return ''
  }
  const record = data as Record<string, Object>
  const topKeys: string[] = ['lyrics', 'lyr', 'lrc', 'data', 'content']
  for (let i = 0; i < topKeys.length; i++) {
    const val = record[topKeys[i]]
    if (typeof val === 'string') {
      return val as string
    }
  }
  // 嵌套 data 对象
  const nested = safeRecord(record, 'data')
  if (nested !== null) {
    const nestedKeys: string[] = ['lyrics', 'lyr', 'lrc', 'content']
    for (let i = 0; i < nestedKeys.length; i++) {
      const val = nested[nestedKeys[i]]
      if (typeof val === 'string') {
        return val as string
      }
    }
  }
  return ''
}
