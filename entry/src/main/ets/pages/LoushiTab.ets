// LX-HM 陋室 Tab - 设置
// LoushiTab.ets
import { AppSettings, DEFAULT_SETTINGS, LYRICS_COLORS, LyricsColorItem } from '../model/MusicModel'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { SettingItem } from '../components/SettingItem'
import { picker } from '@kit.CoreFileKit'
import { promptAction } from '@kit.ArkUI'

const PRIMARY_COLOR: string = '#007DFF'
const BG_COLOR: string = '#F8F8FA'
const CARD_BG: string = '#F5F5F5'
const TEXT_PRIMARY: string = '#1A1A1A'
const TEXT_SECONDARY: string = '#999999'
const DIVIDER_COLOR: string = '#E8E8E8'

type SubPage = 'main' | 'about'

@Component
export struct LoushiTab {
  @State subPage: SubPage = 'main'

  // Settings state
  @State theme: string = DEFAULT_SETTINGS.theme
  @State customBackground: boolean = DEFAULT_SETTINGS.customBackground
  @State customBgPath: string = ''
  @State useSystemFont: boolean = DEFAULT_SETTINGS.useSystemFont
  @State fontSize: string = DEFAULT_SETTINGS.fontSize
  @State autoPlay: boolean = DEFAULT_SETTINGS.autoPlay
  @State autoJumpDetail: boolean = DEFAULT_SETTINGS.autoJumpDetail
  @State lyricsPosition: string = DEFAULT_SETTINGS.lyricsPosition
  @State rememberProgress: boolean = DEFAULT_SETTINGS.rememberProgress
  @State autoStopOnOtherAudio: boolean = DEFAULT_SETTINGS.autoStopOnOtherAudio
  @State desktopLyrics: boolean = DEFAULT_SETTINGS.desktopLyrics
  @State lockDesktopLyrics: boolean = DEFAULT_SETTINGS.lockDesktopLyrics
  @State notificationCard: boolean = DEFAULT_SETTINGS.notificationCard
  @State multiLineLyrics: boolean = DEFAULT_SETTINGS.multiLineLyrics
  @State lyricsSize: string = DEFAULT_SETTINGS.lyricsSize
  @State lyricsColor: string = DEFAULT_SETTINGS.lyricsColor
  @State lyricsBgOpacity: number = DEFAULT_SETTINGS.lyricsBgOpacity

  // Imported sources
  @State importedSources: string[] = []

  // Toast
  @State toastMsg: string = ''
  @State showToast: boolean = false

  private db: DatabaseHelper = DatabaseHelper.getInstance()

  async aboutToAppear() {
    await this.loadSettings()
    await this.loadImportedSources()
  }

  private async loadSettings() {
    this.theme = (await this.db.getSetting('theme')) || DEFAULT_SETTINGS.theme
    this.customBackground = (await this.db.getSetting('customBackground')) === 'true'
    this.customBgPath = (await this.db.getSetting('customBackgroundPath')) || ''
    this.useSystemFont = (await this.db.getSetting('useSystemFont')) === 'true'
    this.fontSize = (await this.db.getSetting('fontSize')) || DEFAULT_SETTINGS.fontSize
    this.autoPlay = (await this.db.getSetting('autoPlay')) === 'true'
    this.autoJumpDetail = (await this.db.getSetting('autoJumpDetail')) === 'true'
    this.lyricsPosition = (await this.db.getSetting('lyricsPosition')) || DEFAULT_SETTINGS.lyricsPosition
    this.rememberProgress = (await this.db.getSetting('rememberProgress')) === 'true'
    this.autoStopOnOtherAudio = (await this.db.getSetting('autoStopOnOtherAudio')) === 'true'
    this.desktopLyrics = (await this.db.getSetting('desktopLyrics')) === 'true'
    this.lockDesktopLyrics = (await this.db.getSetting('lockDesktopLyrics')) === 'true'
    this.notificationCard = (await this.db.getSetting('notificationCard')) === 'true'
    this.multiLineLyrics = (await this.db.getSetting('multiLineLyrics')) === 'true'
    this.lyricsSize = (await this.db.getSetting('lyricsSize')) || DEFAULT_SETTINGS.lyricsSize
    this.lyricsColor = (await this.db.getSetting('lyricsColor')) || DEFAULT_SETTINGS.lyricsColor

    const opacityStr = await this.db.getSetting('lyricsBgOpacity')
    this.lyricsBgOpacity = opacityStr ? parseFloat(opacityStr) : DEFAULT_SETTINGS.lyricsBgOpacity
  }

  private saveSetting(key: string, value: string) {
    this.db.setSetting(key, value)
  }

  private async importSource() {
    try {
      const documentSelect = new picker.DocumentViewPicker()
      const selectResult = await documentSelect.select({
        maxSelectNumber: 1,
      })
      if (selectResult && selectResult.length > 0) {
        const fileUri: string = selectResult[0]
        let fileName: string = '\u672A\u77E5\u97F3\u6E90'
        try {
          const decoded: string = decodeURIComponent(fileUri)
          const lastSlash: number = decoded.lastIndexOf('/')
          if (lastSlash >= 0 && lastSlash < decoded.length - 1) {
            fileName = decoded.substring(lastSlash + 1)
          } else {
            fileName = decoded
          }
        } catch (_e) {
          const parts: string[] = fileUri.split('/')
          fileName = parts[parts.length - 1] || '\u672A\u77E5\u97F3\u6E90'
        }
        const dotIdx: number = fileName.lastIndexOf('.')
        if (dotIdx > 0) {
          fileName = fileName.substring(0, dotIdx)
        }
        this.importedSources = [...this.importedSources, fileName]
        const idx: number = this.importedSources.length - 1
        await this.db.setSetting('source_uri_' + idx, fileUri)
        await this.db.setSetting('source_name_' + idx, fileName)
        this.toastMsg = '\u5DF2\u5BFC\u5165: ' + fileName
        this.showToast = true
      }
    } catch (e) {
      console.error('[LoushiTab] Import failed:', e)
      this.toastMsg = '\u5BFC\u5165\u5931\u8D25\uFF0C\u8BF7\u91CD\u8BD5'
      this.showToast = true
    }
  }

  private async selectBackgroundImage() {
    try {
      const photoSelect = new picker.PhotoViewPicker()
      const options: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
      }
      const result: picker.PhotoSelectResult = await photoSelect.select(options)
      if (result.photoUris && result.photoUris.length > 0) {
        this.customBgPath = result.photoUris[0]
        await this.db.setSetting('customBackgroundPath', result.photoUris[0])
        this.toastMsg = '\u80CC\u666F\u56FE\u5DF2\u8BBE\u7F6E'
        this.showToast = true
      }
    } catch (e) {
      console.error('[LoushiTab] Select background failed:', e)
    }
  }

  private async loadImportedSources() {
    const sources: string[] = []
    let idx: number = 0
    while (true) {
      const name: string = await this.db.getSetting('source_name_' + idx)
      if (name.length === 0) {
        break
      }
      sources.push(name)
      idx++
    }
    this.importedSources = sources
  }

  build() {
    Column() {
      if (this.subPage === 'main') {
        this.MainSettingsContent()
      } else if (this.subPage === 'about') {
        this.AboutContent()
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
  }

  @Builder
  MainSettingsContent() {
    Scroll() {
      Column({ space: 0 }) {
        this.SectionHeader('\u97F3\u6E90')
        this.SourceSection()

        Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 16, right: 16 })

        this.SectionHeader('\u4E2A\u6027\u5316')
        this.PersonalizationSection()

        Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 16, right: 16 })

        this.SectionHeader('\u64AD\u653E\u5668')
        this.PlayerSection()

        Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 16, right: 16 })

        this.SectionHeader('\u684C\u9762\u6B4C\u8BCD')
        this.DesktopLyricsSection()

        Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 16, right: 16 })

        this.SectionHeader('\u5173\u4E8E\u8F6F\u4EF6')
        this.AboutSection()

        Column().height(32)
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
  SectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor(TEXT_SECONDARY)
      .fontWeight(FontWeight.Medium)
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 8 })
  }

  // ===== 音源 Section =====
  @Builder
  SourceSection() {
    Column() {
      Row({ space: 8 }) {
        Text('\uD83D\uDCE5').fontSize(16)
        Text('\u5BFC\u5165\u97F3\u6E90')
          .fontSize(15)
          .fontColor(PRIMARY_COLOR)
          .fontWeight(FontWeight.Medium)
        Text('\u203A').fontSize(16).fontColor(PRIMARY_COLOR)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .onClick(() => { this.importSource() })

      if (this.importedSources.length === 0) {
        Text('\u6682\u65E0\u81EA\u5B9A\u4E49\u97F3\u6E90')
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })
      } else {
        ForEach(this.importedSources, (source: string) => {
          Row({ space: 12 }) {
            Text(source)
              .fontSize(14)
              .fontColor(TEXT_PRIMARY)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: true })
              .selectedColor(PRIMARY_COLOR)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        })
      }
    }
    .width('100%')
  }

  // ===== 个性化 Section (内联按钮确保响应式) =====
  @Builder
  PersonalizationSection() {
    Column() {
      // Theme selector
      this.SettingRow('\uD83C\uDFA8', '#FFF3E0', '\u4E3B\u9898')
      Row({ space: 8 }) {
        // 浅色
        Text('\u6D45\u8272')
          .fontSize(13)
          .fontColor(this.theme === 'light' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.theme === 'light' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: this.theme === 'light' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.theme = 'light'; this.saveSetting('theme', 'light') })
        // 深色
        Text('\u6DF1\u8272')
          .fontSize(13)
          .fontColor(this.theme === 'dark' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.theme === 'dark' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor('#1A1A1A')
          .border({ width: 1, color: this.theme === 'dark' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.theme = 'dark'; this.saveSetting('theme', 'dark') })
        // 跟随系统
        Text('\u8DDF\u968F\u7CFB\u7EDF')
          .fontSize(13)
          .fontColor(this.theme === 'system' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.theme === 'system' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor('#F0F0F0')
          .border({ width: 1, color: this.theme === 'system' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.theme = 'system'; this.saveSetting('theme', 'system') })
      }
      .width('100%')
      .padding({ left: 40, right: 16, bottom: 12 })

      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      // Custom background
      SettingItem({
        icon: '\uD83D\uDDBC\uFE0F',
        iconBgColor: '#E3F2FD',
        title: '\u81EA\u5B9A\u4E49\u80CC\u666F',
        description: this.customBackground ? '\u5DF2\u8BBE\u7F6E\u80CC\u666F\u56FE' : '\u8BBE\u7F6E\u5E94\u7528\u81EA\u5B9A\u4E49\u80CC\u666F\u56FE',
        hasSwitch: true,
        switchChecked: this.customBackground,
        onSwitchChange: (checked: boolean) => {
          this.customBackground = checked
          this.saveSetting('customBackground', String(checked))
          if (checked && this.customBgPath.length === 0) {
            this.selectBackgroundImage()
          }
        },
      })

      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      // System font
      SettingItem({
        icon: '\uD83D\uDD24',
        iconBgColor: '#F3E5F5',
        title: '\u4F7F\u7528\u7CFB\u7EDF\u5B57\u4F53',
        description: '\u4F7F\u7528\u8BBE\u5907\u7CFB\u7EDF\u9ED8\u8BA4\u5B57\u4F53',
        hasSwitch: true,
        switchChecked: this.useSystemFont,
        onSwitchChange: (checked: boolean) => {
          this.useSystemFont = checked
          this.saveSetting('useSystemFont', String(checked))
        },
      })

      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      // Font size - inline to ensure reactivity
      this.SettingRow('\uD83D\uDCDD', '#E8F5E9', '\u5B57\u4F53\u5927\u5C0F')
      Row({ space: 8 }) {
        Text('\u5C0F')
          .fontSize(13)
          .fontColor(this.fontSize === 'small' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.fontSize === 'small' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor(this.fontSize === 'small' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.fontSize === 'small' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.fontSize = 'small'; this.saveSetting('fontSize', 'small') })
        Text('\u6807\u51C6')
          .fontSize(13)
          .fontColor(this.fontSize === 'standard' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.fontSize === 'standard' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor(this.fontSize === 'standard' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.fontSize === 'standard' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.fontSize = 'standard'; this.saveSetting('fontSize', 'standard') })
        Text('\u5927')
          .fontSize(13)
          .fontColor(this.fontSize === 'large' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.fontSize === 'large' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor(this.fontSize === 'large' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.fontSize === 'large' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.fontSize = 'large'; this.saveSetting('fontSize', 'large') })
      }
      .width('100%')
      .padding({ left: 40, right: 16, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(CARD_BG)
    .borderRadius(16)
    .margin({ left: 16, right: 16 })
  }

  // ===== 播放器 Section =====
  @Builder
  PlayerSection() {
    Column() {
      SettingItem({
        icon: '\u25B6\uFE0F', iconBgColor: '#FFF8E1',
        title: '\u81EA\u52A8\u64AD\u653E', description: '\u6253\u5F00\u5E94\u7528\u65F6\u81EA\u52A8\u64AD\u653E\u4E0A\u6B21\u6B4C\u66F2',
        hasSwitch: true, switchChecked: this.autoPlay,
        onSwitchChange: (c: boolean) => { this.autoPlay = c; this.saveSetting('autoPlay', String(c)) },
      })
      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      SettingItem({
        icon: '\uD83D\uDD00', iconBgColor: '#E8EAF6',
        title: '\u81EA\u52A8\u8DF3\u8F6C\u8BE6\u60C5', description: '\u70B9\u51FB\u5E95\u90E8\u64AD\u653E\u5668\u65F6\u6253\u5F00\u5B8C\u6574\u64AD\u653E\u9875',
        hasSwitch: true, switchChecked: this.autoJumpDetail,
        onSwitchChange: (c: boolean) => { this.autoJumpDetail = c; this.saveSetting('autoJumpDetail', String(c)) },
      })
      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      // Lyrics position - inline
      this.SettingRow('\uD83D\uDCCD', '#FCE4EC', '\u6B4C\u8BCD\u4F4D\u7F6E')
      Row({ space: 8 }) {
        Text('\u5DE6')
          .fontSize(13)
          .fontColor(this.lyricsPosition === 'left' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.lyricsPosition === 'left' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor(this.lyricsPosition === 'left' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.lyricsPosition === 'left' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => { this.lyricsPosition = 'left'; this.saveSetting('lyricsPosition', 'left') })
        Text('\u4E2D')
          .fontSize(13)
          .fontColor(this.lyricsPosition === 'center' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.lyricsPosition === 'center' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor(this.lyricsPosition === 'center' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.lyricsPosition === 'center' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => { this.lyricsPosition = 'center'; this.saveSetting('lyricsPosition', 'center') })
        Text('\u53F3')
          .fontSize(13)
          .fontColor(this.lyricsPosition === 'right' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.lyricsPosition === 'right' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor(this.lyricsPosition === 'right' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.lyricsPosition === 'right' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => { this.lyricsPosition = 'right'; this.saveSetting('lyricsPosition', 'right') })
      }
      .width('100%').padding({ left: 40, right: 16, bottom: 12 })

      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      SettingItem({
        icon: '\uD83D\uDCBE', iconBgColor: '#E0F7FA',
        title: '\u8BB0\u4F4F\u64AD\u653E\u8FDB\u5EA6', description: '\u4E0B\u6B21\u6253\u5F00\u65F6\u4ECE\u4E0A\u6B21\u7684\u4F4D\u7F6E\u7EE7\u7EED\u64AD\u653E',
        hasSwitch: true, switchChecked: this.rememberProgress,
        onSwitchChange: (c: boolean) => { this.rememberProgress = c; this.saveSetting('rememberProgress', String(c)) },
      })
      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      SettingItem({
        icon: '\uD83D\uDD07', iconBgColor: '#FFF3E0',
        title: '\u5176\u4ED6\u97F3\u9891\u81EA\u52A8\u6682\u505C', description: '\u68C0\u6D4B\u5230\u5176\u4ED6\u97F3\u9891\u64AD\u653E\u65F6\u81EA\u52A8\u6682\u505C',
        hasSwitch: true, switchChecked: this.autoStopOnOtherAudio,
        onSwitchChange: (c: boolean) => { this.autoStopOnOtherAudio = c; this.saveSetting('autoStopOnOtherAudio', String(c)) },
      })
    }
    .width('100%').backgroundColor(CARD_BG).borderRadius(16).margin({ left: 16, right: 16 })
  }

  // ===== 桌面歌词 Section =====
  @Builder
  DesktopLyricsSection() {
    Column() {
      SettingItem({
        icon: '\uD83C\uDFBC', iconBgColor: '#EDE7F6',
        title: '\u684C\u9762\u6B4C\u8BCD', description: '\u5728\u684C\u9762\u663E\u793A\u60AC\u6D6E\u6B4C\u8BCD',
        hasSwitch: true, switchChecked: this.desktopLyrics,
        onSwitchChange: (c: boolean) => { this.desktopLyrics = c; this.saveSetting('desktopLyrics', String(c)) },
      })
      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })
      SettingItem({
        icon: '\uD83D\uDD12', iconBgColor: '#FFEBEE',
        title: '\u9501\u5B9A\u684C\u9762\u6B4C\u8BCD', description: '\u9501\u5B9A\u6B4C\u8BCD\u4F4D\u7F6E\uFF0C\u9632\u6B62\u8BEF\u89E6\u79FB\u52A8',
        hasSwitch: true, switchChecked: this.lockDesktopLyrics,
        onSwitchChange: (c: boolean) => { this.lockDesktopLyrics = c; this.saveSetting('lockDesktopLyrics', String(c)) },
      })
      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })
      SettingItem({
        icon: '\uD83D\uDCCB', iconBgColor: '#E8F5E9',
        title: '\u901A\u77E5\u5361\u7247', description: '\u5728\u901A\u77E5\u680F\u663E\u793A\u64AD\u653E\u4FE1\u606F\u5361\u7247',
        hasSwitch: true, switchChecked: this.notificationCard,
        onSwitchChange: (c: boolean) => { this.notificationCard = c; this.saveSetting('notificationCard', String(c)) },
      })
      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })
      SettingItem({
        icon: '\uD83D\uDCC4', iconBgColor: '#E3F2FD',
        title: '\u591A\u884C\u6B4C\u8BCD', description: '\u540C\u65F6\u663E\u793A\u591A\u884C\u6B4C\u8BCD\u6587\u672C',
        hasSwitch: true, switchChecked: this.multiLineLyrics,
        onSwitchChange: (c: boolean) => { this.multiLineLyrics = c; this.saveSetting('multiLineLyrics', String(c)) },
      })
      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      // Lyrics size - inline
      this.SettingRow('\uD83D\uDD24', '#FFF8E1', '\u6B4C\u8BCD\u5927\u5C0F')
      Row({ space: 8 }) {
        Text('\u5C0F')
          .fontSize(13)
          .fontColor(this.lyricsSize === 'small' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.lyricsSize === 'small' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(16)
          .backgroundColor(this.lyricsSize === 'small' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.lyricsSize === 'small' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => { this.lyricsSize = 'small'; this.saveSetting('lyricsSize', 'small') })
        Text('\u6807\u51C6')
          .fontSize(13)
          .fontColor(this.lyricsSize === 'standard' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.lyricsSize === 'standard' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(16)
          .backgroundColor(this.lyricsSize === 'standard' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.lyricsSize === 'standard' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => { this.lyricsSize = 'standard'; this.saveSetting('lyricsSize', 'standard') })
        Text('\u5927')
          .fontSize(13)
          .fontColor(this.lyricsSize === 'large' ? PRIMARY_COLOR : TEXT_SECONDARY)
          .fontWeight(this.lyricsSize === 'large' ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(16)
          .backgroundColor(this.lyricsSize === 'large' ? '#E3F2FD' : CARD_BG)
          .border({ width: 1, color: this.lyricsSize === 'large' ? PRIMARY_COLOR : DIVIDER_COLOR })
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => { this.lyricsSize = 'large'; this.saveSetting('lyricsSize', 'large') })
      }
      .width('100%').padding({ left: 40, right: 16, bottom: 12 })

      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      // Lyrics color
      this.SettingRow('\uD83C\uDFA8', '#F3E5F5', '\u6B4C\u8BCD\u989C\u8272')
      Row({ space: 12 }) {
        ForEach(LYRICS_COLORS, (colorItem: LyricsColorItem) => {
          Row() {
            Text(colorItem.label).fontSize(11).fontColor(TEXT_SECONDARY)
          }
          .width(28).height(28).borderRadius(14)
          .backgroundColor(colorItem.value)
          .border({ width: this.lyricsColor === colorItem.value ? 3 : 1,
            color: this.lyricsColor === colorItem.value ? PRIMARY_COLOR : '#CCCCCC' })
          .justifyContent(FlexAlign.Center)
          .shadow({ radius: 4, color: '#00000020', offsetY: 1 })
          .onClick(() => { this.lyricsColor = colorItem.value; this.saveSetting('lyricsColor', colorItem.value) })
        })
      }
      .width('100%').padding({ left: 40, right: 16, bottom: 12 })

      Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 40, right: 16 })

      // Background opacity
      this.SettingRow('\uD83D\uDD39', '#E0F2F1', '\u80CC\u666F\u900F\u660E\u5EA6')
      Row({ space: 12 }) {
        Slider({ value: this.lyricsBgOpacity, min: 0, max: 100, step: 5 })
          .layoutWeight(1).blockColor(PRIMARY_COLOR).selectedColor(PRIMARY_COLOR)
          .trackColor('#E0E0E0').showSteps(false)
          .onChange((value: number, _mode: SliderChangeMode) => {
            this.lyricsBgOpacity = value
            this.saveSetting('lyricsBgOpacity', String(value))
          })
        Text(Math.round(this.lyricsBgOpacity) + '%')
          .fontSize(13).fontColor(TEXT_SECONDARY).width(40).textAlign(TextAlign.End)
      }
      .width('100%').padding({ left: 40, right: 16, bottom: 12 })
    }
    .width('100%').backgroundColor(CARD_BG).borderRadius(16).margin({ left: 16, right: 16 })
  }

  // ===== 关于 Section =====
  @Builder
  AboutSection() {
    Row({ space: 12 }) {
      Row() {
        Text('\u2139\uFE0F').fontSize(18).fontColor(Color.White)
      }
      .width(40).height(40).borderRadius(10).backgroundColor('#E3F2FD').justifyContent(FlexAlign.Center)
      Text('\u5173\u4E8E\u8F6F\u4EF6').fontSize(15).fontColor(TEXT_PRIMARY).fontWeight(FontWeight.Medium).layoutWeight(1)
      Text('\u203A').fontSize(16).fontColor(TEXT_SECONDARY).width(24).textAlign(TextAlign.Center)
    }
    .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(CARD_BG).borderRadius(16).margin({ left: 16, right: 16 })
    .onClick(() => { this.subPage = 'about' })
  }

  // ===== About Page =====
  @Builder
  AboutContent() {
    Column() {
      Row({ space: 12 }) {
        Row() {
          Text('\u2039').fontSize(24).fontColor(TEXT_PRIMARY)
        }
        .width(36).height(36).justifyContent(FlexAlign.Center)
        .onClick(() => { this.subPage = 'main' })
        Text('\u5173\u4E8E\u8F6F\u4EF6').fontSize(17).fontColor(TEXT_PRIMARY).fontWeight(FontWeight.Bold).layoutWeight(1)
      }
      .width('100%').height(56).padding({ left: 8, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 12 }) {
            Row() { Text('\uD83C\uDFB5').fontSize(48) }
              .width(80).height(80).borderRadius(20).backgroundColor('#F0F0F0').justifyContent(FlexAlign.Center)
            Text('LX-HM \u97F3\u4E50\u64AD\u653E\u5668').fontSize(20).fontColor(TEXT_PRIMARY).fontWeight(FontWeight.Bold)
            Text('V1.0.1').fontSize(13).fontColor(TEXT_SECONDARY)
            Text('\u8F69\u7A97 \u00B7 \u7434\u745F \u00B7 \u964B\u5BA4').fontSize(14).fontColor(TEXT_SECONDARY)
          }
          .width('100%').padding({ top: 24, bottom: 24 }).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

          Column() {
            this.AboutLinkRow('\uD83D\uDCD6', '\u8BF4\u660E')
            Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 52, right: 16 })
            this.AboutLinkRow('\uD83D\uDD10', '\u6743\u9650')
            Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 52, right: 16 })
            this.AboutLinkRow('\uD83D\uDC19', 'GitHub')
            Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 52, right: 16 })
            this.AboutLinkRow('\uD83C\uDF10', '\u5B98\u7F51')
            Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 52, right: 16 })
            this.AboutLinkRow('\uD83D\uDCDD', '\u66F4\u65B0\u65E5\u5FD7')
            Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 52, right: 16 })
            this.AboutLinkRow('\uD83D\uDCDC', '\u5F00\u6E90\u534F\u8BAE')
            Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 52, right: 16 })
            this.AboutLinkRow('\uD83D\uDC1B', '\u95EE\u9898\u53CD\u9988')
            Divider().width('100%').color(DIVIDER_COLOR).margin({ left: 52, right: 16 })
            this.AboutLinkRow('\uD83D\uDCE7', '\u90AE\u7BB1\u8054\u7CFB: 484894496@qq.com')
          }
          .width('100%').backgroundColor(CARD_BG).borderRadius(16).margin({ left: 16, right: 16 })
          Column().height(32)
        }
        .width('100%')
      }
      .layoutWeight(1).scrollBar(BarState.Auto)
    }
    .width('100%').height('100%').backgroundColor(BG_COLOR)
  }

  @Builder
  AboutLinkRow(icon: string, title: string) {
    Row({ space: 12 }) {
      Text(icon).fontSize(18)
      Text(title).fontSize(15).fontColor(TEXT_PRIMARY).layoutWeight(1)
      Text('\u203A').fontSize(16).fontColor(TEXT_SECONDARY).width(24).textAlign(TextAlign.Center)
    }
    .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  SettingRow(icon: string, bgColor: string, title: string) {
    Row({ space: 12 }) {
      Row() {
        if (typeof icon === 'string') {
          Text(icon).fontSize(18).fontColor(Color.White)
        }
      }
      .width(40).height(40).borderRadius(10).backgroundColor(bgColor).justifyContent(FlexAlign.Center)
      Text(title).fontSize(15).fontColor(TEXT_PRIMARY).fontWeight(FontWeight.Medium)
    }
    .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 4 }).alignItems(VerticalAlign.Center)
  }
}