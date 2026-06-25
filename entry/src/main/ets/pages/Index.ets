// SHMY 主页面 - Index
// Index.ets
import { SongInfo } from '../model/MusicModel'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { AppHeader } from '../components/AppHeader'
import { BottomPlayer } from '../components/BottomPlayer'
import { StartupDialog } from '../components/StartupDialog'
import { XuanchuangTab } from './XuanchuangTab'
import { QinseTab } from './QinseTab'
import { LoushiTab } from './LoushiTab'
import router from '@ohos.router'

const BG_COLOR: string = '#F8F8FA'

@Entry
@Component
struct Index {
  @State activeTab: number = 0
  @StorageProp('currentTrack') currentTrack: SongInfo | null = null
  @StorageProp('showFullPlayer') @Watch('onShowFullPlayerChange') showFullPlayer: boolean = false
  @StorageProp('fullPlayerPage') fullPlayerPage: string = 'cover'
  @StorageProp('autoJumpDetail') autoJumpDetail: boolean = false

  private db: DatabaseHelper = DatabaseHelper.getInstance()
  private isNavigating: boolean = false

  aboutToAppear(): void {
    // Synchronously show dialog on first frame, then check date async
    AppStorage.setOrCreate('showStartup', true)
    this.checkAnnouncementDate()
    this.loadAutoJumpSetting()
  }

  private async checkAnnouncementDate(): Promise<void> {
    const lastDate: string = await this.db.getSetting('announcementDismissedDate')
    if (lastDate === this.getTodayStr()) {
      AppStorage.setOrCreate('showStartup', false)
    }
  }

  private async loadAutoJumpSetting(): Promise<void> {
    const val = await this.db.getSetting('autoJumpDetail')
    if (val === 'true') {
      AppStorage.setOrCreate('autoJumpDetail', true)
    }
  }

  private getTodayStr(): string {
    const d = new Date()
    const year: number = d.getFullYear()
    const month: string = (d.getMonth() + 1).toString().padStart(2, '0')
    const day: string = d.getDate().toString().padStart(2, '0')
    return year + '-' + month + '-' + day
  }

  private onTabChange(index: number): void {
    this.activeTab = index
  }

  private async handleStartupDismiss(dontShowToday: boolean): Promise<void> {
    if (dontShowToday) {
      await this.db.setSetting('announcementDismissedDate', this.getTodayStr())
    }
  }

  private onShowFullPlayerChange(): void {
    if (this.showFullPlayer) {
      this.navigateToFullPlayer()
    }
  }

  private navigateToFullPlayer(): void {
    if (this.isNavigating) {
      return
    }
    this.isNavigating = true
    router.pushUrl({
      url: 'pages/FullPlayerPage',
      params: { 'page': this.fullPlayerPage }
    }).then(() => {
      AppStorage.setOrCreate('showFullPlayer', false)
      this.isNavigating = false
    }).catch((err: Error) => {
      console.error('[Index] navigate to FullPlayerPage failed:', err)
      this.isNavigating = false
    })
  }

  build() {
    Stack() {
      // Main content column (header + tab content)
      Column() {
        // Fixed header at top
        AppHeader({
          activeTab: this.activeTab,
          onTabChange: (index: number) => {
            this.onTabChange(index)
          },
        })

        // Tab content area fills remaining space
        Column() {
          if (this.activeTab === 0) {
            XuanchuangTab()
          } else if (this.activeTab === 1) {
            QinseTab()
          } else if (this.activeTab === 2) {
            LoushiTab()
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_COLOR)

      // Bottom player (positioned at bottom, above content)
      BottomPlayer()

      // Announcement popup overlay - always mounted, controls own visibility
      StartupDialog({
        onDismiss: (dontShowToday: boolean) => {
          this.handleStartupDismiss(dontShowToday)
        },
      })
    }
    .width('100%')
    .height('100%')
  }
}