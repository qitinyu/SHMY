// DatabaseHelper.ets - 本地数据库管理
// 基于 @kit.ArkData 的关系型数据库 RDB
import { relationalStore } from '@kit.ArkData'
import type { SongInfo, Playlist, DownloadItem } from '../model/MusicModel'

const DB_NAME = 'lxhm.db'
const DB_VERSION = 1

// 建表 SQL
const SQL_CREATE_FAVORITES = `
  CREATE TABLE IF NOT EXISTS favorite (
    id TEXT PRIMARY KEY,
    songId TEXT NOT NULL,
    songName TEXT NOT NULL,
    artist TEXT DEFAULT '',
    album TEXT DEFAULT '',
    coverUrl TEXT DEFAULT '',
    source TEXT DEFAULT 'kg',
    playUrl TEXT DEFAULT '',
    createdAt INTEGER NOT NULL
  )
`

const SQL_CREATE_PLAYLISTS = `
  CREATE TABLE IF NOT EXISTS playlist (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL
  )
`

const SQL_CREATE_PLAYLIST_SONGS = `
  CREATE TABLE IF NOT EXISTS playlist_song (
    id TEXT PRIMARY KEY,
    playlistId TEXT NOT NULL,
    songId TEXT NOT NULL,
    songName TEXT NOT NULL,
    artist TEXT DEFAULT '',
    album TEXT DEFAULT '',
    coverUrl TEXT DEFAULT '',
    source TEXT DEFAULT 'kg',
    playUrl TEXT DEFAULT '',
    createdAt INTEGER NOT NULL,
    FOREIGN KEY (playlistId) REFERENCES playlist(id) ON DELETE CASCADE
  )
`

const SQL_CREATE_DOWNLOADS = `
  CREATE TABLE IF NOT EXISTS download (
    id TEXT PRIMARY KEY,
    songId TEXT NOT NULL,
    songName TEXT NOT NULL,
    artist TEXT DEFAULT '',
    album TEXT DEFAULT '',
    coverUrl TEXT DEFAULT '',
    source TEXT DEFAULT 'kg',
    playUrl TEXT DEFAULT '',
    quality TEXT DEFAULT 'standard',
    status TEXT DEFAULT 'pending',
    progress REAL DEFAULT 0,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL
  )
`

const SQL_CREATE_SETTINGS = `
  CREATE TABLE IF NOT EXISTS app_setting (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
`

export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null
  private store: relationalStore.RdbStore | null = null

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper()
    }
    return DatabaseHelper.instance
  }

  // 初始化数据库（在 EntryAbility.onCreate 中调用）
  async init(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
    }
    this.store = await relationalStore.getRdbStore(context, config)
    await this.createTables()
  }

  private async createTables(): Promise<void> {
    if (!this.store) return
    await this.store.executeSql(SQL_CREATE_FAVORITES)
    await this.store.executeSql(SQL_CREATE_PLAYLISTS)
    await this.store.executeSql(SQL_CREATE_PLAYLIST_SONGS)
    await this.store.executeSql(SQL_CREATE_DOWNLOADS)
    await this.store.executeSql(SQL_CREATE_SETTINGS)
  }

  // ===== 收藏 CRUD =====

  async addFavorite(song: SongInfo): Promise<boolean> {
    if (!this.store) return false
    try {
      // 检查重复
      const predicates = new relationalStore.RdbPredicates('favorite')
      predicates.equalTo('songId', song.songId).equalTo('source', song.source)
      const cursor = await this.store.query(predicates)
      if (cursor.goToFirstRow()) {
        cursor.close()
        return false // 已存在
      }
      cursor.close()

      const valueBucket: relationalStore.ValuesBucket = {
        'id': generateId(),
        'songId': song.songId,
        'songName': song.songName,
        'artist': song.artist,
        'album': song.album,
        'coverUrl': song.coverUrl,
        'source': song.source,
        'playUrl': song.playUrl,
        'createdAt': Date.now(),
      }
      await this.store.insert('favorite', valueBucket)
      return true
    } catch (e) {
      console.error('[DB] addFavorite failed:', e)
      return false
    }
  }

  async getFavorites(): Promise<SongInfo[]> {
    if (!this.store) return []
    try {
      const predicates = new relationalStore.RdbPredicates('favorite')
      predicates.orderByDesc('createdAt')
      const cursor = await this.store.query(predicates)
      const songs: SongInfo[] = []
      while (cursor.goToNextRow()) {
        songs.push({
          songId: cursor.getString(cursor.getColumnIndex('songId')),
          songName: cursor.getString(cursor.getColumnIndex('songName')),
          artist: cursor.getString(cursor.getColumnIndex('artist')),
          album: cursor.getString(cursor.getColumnIndex('album')),
          coverUrl: cursor.getString(cursor.getColumnIndex('coverUrl')),
          source: cursor.getString(cursor.getColumnIndex('source')),
          playUrl: cursor.getString(cursor.getColumnIndex('playUrl')),
        })
      }
      cursor.close()
      return songs
    } catch (e) {
      console.error('[DB] getFavorites failed:', e)
      return []
    }
  }

  async removeFavorite(songId: string, source: string): Promise<void> {
    if (!this.store) return
    try {
      const predicates = new relationalStore.RdbPredicates('favorite')
      predicates.equalTo('songId', songId).equalTo('source', source)
      await this.store.delete(predicates)
    } catch (e) {
      console.error('[DB] removeFavorite failed:', e)
    }
  }

  // ===== 歌单 CRUD =====

  async createPlaylist(name: string): Promise<string | null> {
    if (!this.store) return null
    try {
      const id = generateId()
      const now = Date.now()
      const valueBucket: relationalStore.ValuesBucket = {
        'id': id,
        'name': name,
        'createdAt': now,
        'updatedAt': now,
      }
      await this.store.insert('playlist', valueBucket)
      return id
    } catch (e) {
      console.error('[DB] createPlaylist failed:', e)
      return null
    }
  }

  async getPlaylists(): Promise<Playlist[]> {
    if (!this.store) return []
    try {
      const predicates = new relationalStore.RdbPredicates('playlist')
      predicates.orderByDesc('updatedAt')
      const cursor = await this.store.query(predicates)
      const playlists: Playlist[] = []
      while (cursor.goToNextRow()) {
        const id = cursor.getString(cursor.getColumnIndex('id'))
        playlists.push({
          id,
          name: cursor.getString(cursor.getColumnIndex('name')),
          songCount: await this.getPlaylistSongCount(id),
          createdAt: cursor.getLong(cursor.getColumnIndex('createdAt')),
          updatedAt: cursor.getLong(cursor.getColumnIndex('updatedAt')),
        })
      }
      cursor.close()
      return playlists
    } catch (e) {
      console.error('[DB] getPlaylists failed:', e)
      return []
    }
  }

  async renamePlaylist(id: string, newName: string): Promise<void> {
    if (!this.store) return
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'name': newName,
        'updatedAt': Date.now(),
      }
      const predicates = new relationalStore.RdbPredicates('playlist')
      predicates.equalTo('id', id)
      await this.store.update(valueBucket, predicates)
    } catch (e) {
      console.error('[DB] renamePlaylist failed:', e)
    }
  }

  async deletePlaylist(id: string): Promise<void> {
    if (!this.store) return
    try {
      const predicates = new relationalStore.RdbPredicates('playlist')
      predicates.equalTo('id', id)
      await this.store.delete(predicates)
      // CASCADE 会自动删除关联歌曲
    } catch (e) {
      console.error('[DB] deletePlaylist failed:', e)
    }
  }

  async addSongToPlaylist(playlistId: string, song: SongInfo): Promise<boolean> {
    if (!this.store) return false
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'id': generateId(),
        'playlistId': playlistId,
        'songId': song.songId,
        'songName': song.songName,
        'artist': song.artist,
        'album': song.album,
        'coverUrl': song.coverUrl,
        'source': song.source,
        'playUrl': song.playUrl,
        'createdAt': Date.now(),
      }
      await this.store.insert('playlist_song', valueBucket)
      // 更新歌单的 updatedAt
      const updateBucket: relationalStore.ValuesBucket = { 'updatedAt': Date.now() }
      const updatePred = new relationalStore.RdbPredicates('playlist')
      updatePred.equalTo('id', playlistId)
      await this.store.update(updateBucket, updatePred)
      return true
    } catch (e) {
      console.error('[DB] addSongToPlaylist failed:', e)
      return false
    }
  }

  async getPlaylistSongs(playlistId: string): Promise<SongInfo[]> {
    if (!this.store) return []
    try {
      const predicates = new relationalStore.RdbPredicates('playlist_song')
      predicates.equalTo('playlistId', playlistId).orderByAsc('createdAt')
      const cursor = await this.store.query(predicates)
      const songs: SongInfo[] = []
      while (cursor.goToNextRow()) {
        songs.push({
          songId: cursor.getString(cursor.getColumnIndex('songId')),
          songName: cursor.getString(cursor.getColumnIndex('songName')),
          artist: cursor.getString(cursor.getColumnIndex('artist')),
          album: cursor.getString(cursor.getColumnIndex('album')),
          coverUrl: cursor.getString(cursor.getColumnIndex('coverUrl')),
          source: cursor.getString(cursor.getColumnIndex('source')),
          playUrl: cursor.getString(cursor.getColumnIndex('playUrl')),
        })
      }
      cursor.close()
      return songs
    } catch (e) {
      console.error('[DB] getPlaylistSongs failed:', e)
      return []
    }
  }

  private async getPlaylistSongCount(playlistId: string): Promise<number> {
    if (!this.store) return 0
    try {
      const predicates = new relationalStore.RdbPredicates('playlist_song')
      predicates.equalTo('playlistId', playlistId)
      const cursor = await this.store.query(predicates)
      const count = cursor.rowCount
      cursor.close()
      return count
    } catch (_) { return 0 }
  }

  async removeSongFromPlaylist(playlistId: string, songId: string, source: string): Promise<void> {
    if (!this.store) return
    try {
      const predicates = new relationalStore.RdbPredicates('playlist_song')
      predicates.equalTo('playlistId', playlistId)
        .equalTo('songId', songId)
        .equalTo('source', source)
      await this.store.delete(predicates)
    } catch (e) {
      console.error('[DB] removeSongFromPlaylist failed:', e)
    }
  }

  // ===== 下载 CRUD =====

  async addDownload(song: SongInfo, quality: string): Promise<string | null> {
    if (!this.store) return null
    try {
      const id = generateId()
      const now = Date.now()
      const valueBucket: relationalStore.ValuesBucket = {
        'id': id,
        'songId': song.songId,
        'songName': song.songName,
        'artist': song.artist,
        'album': song.album,
        'coverUrl': song.coverUrl,
        'source': song.source,
        'playUrl': song.playUrl,
        'quality': quality,
        'status': 'pending',
        'progress': 0,
        'createdAt': now,
        'updatedAt': now,
      }
      await this.store.insert('download', valueBucket)
      return id
    } catch (e) {
      console.error('[DB] addDownload failed:', e)
      return null
    }
  }

  async getDownloads(): Promise<DownloadItem[]> {
    if (!this.store) return []
    try {
      const predicates = new relationalStore.RdbPredicates('download')
      predicates.orderByDesc('createdAt')
      const cursor = await this.store.query(predicates)
      const items: DownloadItem[] = []
      while (cursor.goToNextRow()) {
        items.push({
          id: cursor.getString(cursor.getColumnIndex('id')),
          songId: cursor.getString(cursor.getColumnIndex('songId')),
          songName: cursor.getString(cursor.getColumnIndex('songName')),
          artist: cursor.getString(cursor.getColumnIndex('artist')),
          album: cursor.getString(cursor.getColumnIndex('album')),
          coverUrl: cursor.getString(cursor.getColumnIndex('coverUrl')),
          source: cursor.getString(cursor.getColumnIndex('source')),
          playUrl: cursor.getString(cursor.getColumnIndex('playUrl')),
          quality: cursor.getString(cursor.getColumnIndex('quality')),
          status: cursor.getString(cursor.getColumnIndex('status')),
          progress: cursor.getDouble(cursor.getColumnIndex('progress')),
          createdAt: cursor.getLong(cursor.getColumnIndex('createdAt')),
        })
      }
      cursor.close()
      return items
    } catch (e) {
      console.error('[DB] getDownloads failed:', e)
      return []
    }
  }

  async updateDownloadStatus(id: string, status: string, progress: number): Promise<void> {
    if (!this.store) return
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'status': status,
        'progress': progress,
        'updatedAt': Date.now(),
      }
      const predicates = new relationalStore.RdbPredicates('download')
      predicates.equalTo('id', id)
      await this.store.update(valueBucket, predicates)
    } catch (e) {
      console.error('[DB] updateDownloadStatus failed:', e)
    }
  }

  async deleteDownload(id: string): Promise<void> {
    if (!this.store) return
    try {
      const predicates = new relationalStore.RdbPredicates('download')
      predicates.equalTo('id', id)
      await this.store.delete(predicates)
    } catch (e) {
      console.error('[DB] deleteDownload failed:', e)
    }
  }

  // ===== 设置 KV =====

  async getSetting(key: string): Promise<string> {
    if (!this.store) return ''
    try {
      const predicates = new relationalStore.RdbPredicates('app_setting')
      predicates.equalTo('key', key)
      const cursor = await this.store.query(predicates)
      let value = ''
      if (cursor.goToFirstRow()) {
        value = cursor.getString(cursor.getColumnIndex('value'))
      }
      cursor.close()
      return value
    } catch (_) { return '' }
  }

  async setSetting(key: string, value: string): Promise<void> {
    if (!this.store) return
    try {
      const valueBucket: relationalStore.ValuesBucket = { 'key': key, 'value': value }
      await this.store.insert('app_setting', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
    } catch (e) {
      console.error('[DB] setSetting failed:', e)
    }
  }
}

// 生成唯一 ID
function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substring(2, 8)
}
