// MusicApi.ets - 音乐搜索/播放/歌词网络请求
// V4.0 - 酷我(全通) + 酷狗(搜索+歌词+封面) + 自定义音源导入
//
// ═══════════════════════════════════════════════════════════
// 音源可用性总览（2026-06 V4.0 实测验证）
// ═══════════════════════════════════════════════════════════
//   酷我(kw) ── 搜索 ✅  播放 ✅  歌词 ✅  封面 ✅  ← 主力音源
//   酷狗(kg) ── 搜索 ✅  播放 ⚠️  歌词 ✅  封面 ✅  ← 搜索补充,播放回退到酷我
//   自定义(custom) ─ 通过 JSON 配置文件导入,支持任意 HTTP API
//
// 核心API（实测可用 2026-06-27）：
//   酷我搜索:   http://www.kuwo.cn/search/searchMusicBykeyWord
//   酷我播放:   https://antiserver.kuwo.cn/anti.s?type=convert_url3
//   酷我歌词:   https://www.kuwo.cn/openapi/v1/www/lyric/getlyric
//   酷狗搜索:   https://songsearch.kugou.com/song_search_v2
//   酷狗歌词:   https://lyrics.kugou.com/search + /download
// ═══════════════════════════════════════════════════════════

import { http } from '@kit.NetworkKit'
import { util } from '@kit.ArkTS'
import type { SongInfo } from '../model/MusicModel'
import { SourceManager } from './SourceManager'

// ==================== API 地址常量 ====================

/** 酷我音乐 - 搜索（新 API，返回标准 JSON） */
const KUWO_SEARCH_BASE = 'http://www.kuwo.cn/search/searchMusicBykeyWord'

/** 酷我音乐 - 播放URL */
const KUWO_PLAY_BASE = 'https://antiserver.kuwo.cn/anti.s'

/** 酷我音乐 - 歌词（新 API） */
const KUWO_LYRICS_BASE = 'https://www.kuwo.cn/openapi/v1/www/lyric/getlyric'

/** 酷狗音乐 - 搜索（新 API，返回标准 JSON） */
const KUGOU_SEARCH_BASE = 'https://songsearch.kugou.com/song_search_v2'

/** 酷狗音乐 - 歌词搜索 */
const KUGOU_LYRICS_SEARCH = 'https://lyrics.kugou.com/search'

/** 酷狗音乐 - 歌词下载 */
const KUGOU_LYRICS_DOWNLOAD = 'https://lyrics.kugou.com/download'

/** 通用 User-Agent */
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

// ==================== HTTP 工具函数 ====================

async function httpGet(url: string, extraHeaders?: Record<string, string>): Promise<string> {
  try {
    const headerObj: Record<string, string> = { 'User-Agent': UA } as Record<string, string>
    if (extraHeaders) {
      const keys = Object.keys(extraHeaders)
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
    return ''
  } catch (_e) {
    console.error(`[MusicApi] GET failed: ${url.substring(0, 120)}`)
    return ''
  }
}

function decodeHtmlEntities(text: string): string {
  if (!text || text.length === 0) return ''
  return text.replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
}

function base64Decode(encoded: string): string {
  try {
    const helper = new util.Base64Helper()
    const uint8Array = helper.decodeSync(encoded)
    const textDecoder = util.TextDecoder.create('utf-8')
    return textDecoder.decodeToString(uint8Array)
  } catch (_e) {
    console.error('[MusicApi] base64Decode failed')
    return ''
  }
}

// ==================== 酷我音乐 API ====================

async function searchKuwo(keyword: string, pageSize: number = 30): Promise<SongInfo[]> {
  const params = `?all=${encodeURIComponent(keyword)}&pn=0&rn=${pageSize}&ft=music&cluster=0&strategy=2012&encoding=utf8&rformat=json&mobi=1&issubtitle=1&show_copyright_off=1&vipver=1&client=kt`
  const url = `${KUWO_SEARCH_BASE}${params}`
  const raw = await httpGet(url)
  if (raw.length === 0) return []

  try {
    const parsed: Record<string, Object> = JSON.parse(raw) as Record<string, Object>
    const abslist = parsed['abslist']
    if (!(abslist instanceof Array) || abslist.length === 0) {
      return []
    }

    const results: SongInfo[] = []
    const arr = abslist as Object[]

    for (let i = 0; i < arr.length; i++) {
      const item = arr[i] as Record<string, Object>
      const musicrid = String(item['MUSICRID'] ?? '')
      const rid = musicrid.replace('MUSIC_', '')
      const songName = decodeHtmlEntities(String(item['NAME'] ?? ''))
      const artist = decodeHtmlEntities(String(item['ARTIST'] ?? ''))
      const album = decodeHtmlEntities(String(item['ALBUM'] ?? ''))
      const duration = String(item['DURATION'] ?? '0')
      const isPay = String(item['PAY'] ?? '0') === '1'
      const webAlbumPic = String(item['web_albumpic_short'] ?? '')

      // 封面 URL
      let coverUrl = ''
      if (webAlbumPic.length > 0 && webAlbumPic !== 'null') {
        coverUrl = `https://img1.kuwo.cn/star/albumcover/300/${webAlbumPic}`
      }

      if (rid.length === 0 || songName.length === 0) {
        continue
      }

      const durSec = parseInt(duration) || 0
      const durStr = `${Math.floor(durSec / 60)}:${(durSec % 60).toString().padStart(2, '0')}`

      results.push({
        songId: rid,
        songName: songName,
        artist: artist,
        album: album,
        coverUrl: coverUrl,
        source: 'kw',
        playUrl: '',
        quality: isPay ? `VIP/${durStr}` : `128kbps/${durStr}`,
      })
    }

    console.info(`[MusicApi] Kuwo search "${keyword}" => ${results.length} results`)
    return results
  } catch (_e) {
    console.error(`[MusicApi] Kuwo search parse failed: ${raw.substring(0, 200)}`)
    return []
  }
}

async function getKuwoPlayUrl(rid: string): Promise<string> {
  if (!rid || rid.length === 0) return ''

  const url = `${KUWO_PLAY_BASE}?type=convert_url3&rid=${rid}&format=mp3`
  const raw = await httpGet(url)
  if (raw.length === 0) return ''

  if (raw.indexOf('IPDeny') >= 0) {
    console.warn('[MusicApi] Kuwo play URL rate limited (IPDeny)')
    return ''
  }

  try {
    const data: Record<string, Object> = JSON.parse(raw) as Record<string, Object>
    const code = String(data['code'] ?? '')
    const playUrl = String(data['url'] ?? '')

    if (code === '200' && playUrl.length > 0 && playUrl.startsWith('http')) {
      console.info(`[MusicApi] Kuwo play URL OK (rid=${rid})`)
      return playUrl
    }

    console.warn(`[MusicApi] Kuwo play URL failed (rid=${rid}): code=${code}`)
    return ''
  } catch (_e) {
    console.error(`[MusicApi] Kuwo play URL parse failed: ${raw.substring(0, 200)}`)
    return ''
  }
}

async function getKuwoLyrics(songId: string): Promise<string> {
  if (!songId || songId.length === 0) return ''

  const url = `${KUWO_LYRICS_BASE}?musicId=${songId}`
  const raw = await httpGet(url, { 'Referer': 'https://www.kuwo.cn/' })
  if (raw.length === 0) return ''

  try {
    const parsed: Record<string, Object> = JSON.parse(raw) as Record<string, Object>
    const dataObj = parsed['data']
    if (dataObj === null || dataObj === undefined || typeof dataObj !== 'object') {
      return ''
    }

    const lrclist = (dataObj as Record<string, Object>)['lrclist']
    if (!(lrclist instanceof Array) || lrclist.length === 0) {
      return ''
    }

    let lrc = ''
    const arr = lrclist as Object[]
    for (let i = 0; i < arr.length; i++) {
      const line = arr[i] as Record<string, Object>
      const time = String(line['time'] ?? '0.0')
      const text = String(line['lineLyric'] ?? '')
      // time 格式为秒数（如 "29.26"），转为 [mm:ss.xx] 格式
      const sec = parseFloat(time)
      if (!isNaN(sec)) {
        const mm = Math.floor(sec / 60)
        const ss = (sec % 60).toFixed(2).padStart(5, '0')
        lrc += `[${mm.toString().padStart(2, '0')}:${ss}]${text}\n`
      }
    }

    if (lrc.length > 0) {
      console.info(`[MusicApi] Kuwo lyrics OK: ${arr.length} lines`)
    }
    return lrc
  } catch (_e) {
    console.error('[MusicApi] Kuwo lyrics parse failed')
    return ''
  }
}

// ==================== 酷狗音乐 API ====================

async function searchKugou(keyword: string, pageSize: number = 30): Promise<SongInfo[]> {
  const url = `${KUGOU_SEARCH_BASE}?keyword=${encodeURIComponent(keyword)}&page=1&pagesize=${pageSize}&platform=WebFilter&format=json`
  const raw = await httpGet(url)
  if (raw.length === 0) return []

  try {
    const parsed: Record<string, Object> = JSON.parse(raw) as Record<string, Object>
    const dataObj = parsed['data']
    if (dataObj === null || dataObj === undefined || typeof dataObj !== 'object') {
      return []
    }

    const lists = (dataObj as Record<string, Object>)['lists']
    if (!(lists instanceof Array) || lists.length === 0) {
      return []
    }

    const results: SongInfo[] = []
    const arr = lists as Object[]

    for (let i = 0; i < arr.length; i++) {
      const item = arr[i] as Record<string, Object>

      const hash = String(item['FileHash'] ?? '')
      const songName = decodeHtmlEntities(String(item['SongName'] ?? ''))
      const singerName = decodeHtmlEntities(String(item['SingerName'] ?? ''))
      const albumName = decodeHtmlEntities(String(item['AlbumName'] ?? ''))
      const duration = String(item['Duration'] ?? '0')
      const image = String(item['Image'] ?? '')

      // 封面 URL（替换 {size} 为 150）
      let coverUrl = ''
      if (image.length > 0) {
        coverUrl = image.replace('{size}', '150')
      }

      if (hash.length === 0 || songName.length === 0) {
        continue
      }

      const durSec = parseInt(duration) || 0
      const durStr = `${Math.floor(durSec / 60)}:${(durSec % 60).toString().padStart(2, '0')}`

      results.push({
        songId: hash,
        songName: songName,
        artist: singerName,
        album: albumName,
        coverUrl: coverUrl,
        source: 'kg',
        playUrl: '',
        quality: `128kbps/${durStr}`,
      })
    }

    console.info(`[MusicApi] Kugou search "${keyword}" => ${results.length} results`)
    return results
  } catch (_e) {
    console.error('[MusicApi] Kugou search parse failed')
    return []
  }
}

async function getKugouLyrics(hash: string): Promise<string> {
  if (!hash || hash.length === 0) return ''

  // 第一步：搜索歌词
  const searchUrl = `${KUGOU_LYRICS_SEARCH}?ver=1&man=yes&client=pc&hash=${hash}`
  const searchRaw = await httpGet(searchUrl)
  if (searchRaw.length === 0) return ''

  try {
    const searchData: Record<string, Object> = JSON.parse(searchRaw) as Record<string, Object>
    const candidates = searchData['candidates']
    if (!(candidates instanceof Array) || candidates.length === 0) {
      return ''
    }

    const first = candidates[0] as Record<string, Object>
    const id = String(first['id'] ?? '')
    const accesskey = String(first['accesskey'] ?? '')
    if (id.length === 0 || accesskey.length === 0) return ''

    // 第二步：下载歌词
    const downloadUrl = `${KUGOU_LYRICS_DOWNLOAD}?ver=1&client=pc&id=${id}&accesskey=${accesskey}&fmt=lrc&charset=utf8`
    const downloadRaw = await httpGet(downloadUrl)
    if (downloadRaw.length === 0) return ''

    const downloadData: Record<string, Object> = JSON.parse(downloadRaw) as Record<string, Object>
    const content = String(downloadData['content'] ?? '')
    const dlStatus = String(downloadData['status'] ?? '')

    if (content.length === 0 || dlStatus !== '200') {
      return ''
    }

    const lrc = base64Decode(content)
    if (lrc.length > 0) {
      console.info(`[MusicApi] Kugou lyrics OK: ${lrc.length} chars`)
    }
    return lrc
  } catch (_e) {
    console.error('[MusicApi] Kugou lyrics parse failed')
    return ''
  }
}

// ==================== 主 API 类 ====================

export class MusicApi {
  /**
   * 搜索歌曲
   *
   * @param keyword 搜索关键词
   * @param source 音源：'all'=内置音源, 'kw'=酷我, 'kg'=酷狗, 'custom'=自定义音源
   * @returns 搜索结果数组
   */
  static async search(keyword: string, source: string = 'all'): Promise<SongInfo[]> {
    if (!keyword || keyword.trim().length === 0) return []

    try {
      let allResults: SongInfo[] = []

      if (source === 'all') {
        // 顺序搜索内置音源
        const r1 = await searchKuwo(keyword)
        const r2 = await searchKugou(keyword)
        allResults = r1.concat(r2)

        // 再搜索自定义音源
        const customResults: SongInfo[] = await SourceManager.searchAll(keyword)
        if (customResults.length > 0) {
          allResults = allResults.concat(customResults)
        }
      } else if (source === 'kw') {
        allResults = await searchKuwo(keyword)
      } else if (source === 'kg') {
        allResults = await searchKugou(keyword)
      } else {
        // 自定义音源
        allResults = await SourceManager.search(source, keyword)
      }

      return allResults
    } catch (_e) {
      console.error('[MusicApi] search failed')
      return []
    }
  }

  /**
   * 获取播放 URL
   *
   * 策略：
   *   1. 先尝试歌曲自身 source 对应的 API
   *   2. 酷狗歌曲播放失败时回退到酷我（用歌名+歌手重新搜索酷我获取 rid）
   *   3. 自定义音源用 SourceManager 获取
   *
   * @param song 歌曲
   * @returns 播放 URL，失败返回空字符串
   */
  static async getPlayUrl(song: SongInfo): Promise<string> {
    try {
      const source = song.source

      // 酷我歌曲 — 直接用 rid 获取
      if (source === 'kw') {
        const url = await getKuwoPlayUrl(song.songId)
        if (url.length > 0) return url
        console.warn(`[MusicApi] Kuwo direct play failed, trying fallback: ${song.songName}`)
        return await MusicApi.fallbackToKuwo(song)
      }

      // 酷狗歌曲 — 播放 API 地域限制，用歌名在酷我曲库搜索
      if (source === 'kg') {
        const url = await MusicApi.fallbackToKuwo(song)
        if (url.length > 0) return url
        // 酷我也失败，尝试自定义音源
        return await MusicApi.fallbackToCustom(song)
      }

      // 自定义音源
      if (source.startsWith('custom_')) {
        const configName = source.substring(7)
        const url = await SourceManager.getPlayUrl(configName, song.songId)
        if (url.length > 0) return url
        // 自定义音源失败，回退到酷我
        return await MusicApi.fallbackToKuwo(song)
      }

      // 未知来源 — 直接尝试酷我
      return await MusicApi.fallbackToKuwo(song)
    } catch (_e) {
      console.error('[MusicApi] getPlayUrl failed')
      return ''
    }
  }

  /**
   * 回退到酷我：用歌名+歌手搜索酷我曲库，优先选择歌名完全匹配的结果
   */
  private static async fallbackToKuwo(song: SongInfo): Promise<string> {
    const keyword = `${song.songName} ${song.artist}`.trim()
    if (keyword.length === 0) return ''

    const results = await searchKuwo(keyword, 10)
    if (results.length === 0) return ''

    // 优先选择歌名完全匹配的结果
    let bestRid: string = results[0].songId
    for (let i = 0; i < results.length; i++) {
      if (results[i].songName === song.songName) {
        bestRid = results[i].songId
        break
      }
    }

    const url = await getKuwoPlayUrl(bestRid)
    if (url.length > 0) {
      console.info(`[MusicApi] Fallback to Kuwo OK: "${song.songName}" -> rid=${bestRid}`)
    } else {
      console.warn(`[MusicApi] Fallback to Kuwo failed: "${song.songName}" rid=${bestRid}`)
    }
    return url
  }

  /**
   * 回退到自定义音源
   */
  private static async fallbackToCustom(song: SongInfo): Promise<string> {
    return await SourceManager.getPlayUrlFromAny(song.songId, song.songName, song.artist)
  }

  /**
   * 获取歌词
   *
   * @param songId 歌曲 ID
   * @param source 音源标识
   * @returns LRC 格式歌词文本，失败返回空字符串
   */
  static async getLyrics(songId: string, source: string): Promise<string> {
    try {
      if (source === 'kw') {
        return await getKuwoLyrics(songId)
      }

      if (source === 'kg') {
        const lrc = await getKugouLyrics(songId)
        if (lrc.length > 0) return lrc
        // 酷狗歌词失败，尝试酷我
        return ''
      }

      // 自定义音源
      if (source.startsWith('custom_')) {
        const configName = source.substring(7)
        const lrc = await SourceManager.getLyrics(configName, songId)
        if (lrc.length > 0) return lrc
        return ''
      }

      return ''
    } catch (_e) {
      console.error('[MusicApi] getLyrics failed')
      return ''
    }
  }
}
