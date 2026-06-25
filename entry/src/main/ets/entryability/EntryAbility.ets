// SHMY 入口 Ability
// EntryAbility.ets
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { DatabaseHelper } from '../database/DatabaseHelper'

export default class EntryAbility extends UIAbility {
  private db: DatabaseHelper = DatabaseHelper.getInstance()

  async onCreate(want: Want, param: AbilityConstant.LaunchParam): Promise<void> {
    console.info('[EntryAbility] onCreate')
    try {
      await this.db.init(this.context)
      console.info('[EntryAbility] Database initialized')
    } catch (e) {
      console.error('[EntryAbility] Database init failed:', e)
    }
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    console.info('[EntryAbility] onWindowStageCreate')
    try {
      const windowClass = await windowStage.loadContent('pages/Index')
      console.info('[EntryAbility] Window content loaded')

      const mainWindow = await windowStage.getMainWindow()
      if (mainWindow) {
        // Ensure window is NOT full screen so status bar is visible
        await mainWindow.setWindowLayoutFullScreen(false)

        // Set system bar properties
        const systemBarProperties: window.SystemBarProperties = {
          statusBarColor: '#FFFFFF',
          navigationBarColor: '#FFFFFF',
          statusBarContentColor: '#1A1A1A',
          navigationBarContentColor: '#1A1A1A',
        }
        try {
          mainWindow.setWindowSystemBarProperties(systemBarProperties)
          console.info('[EntryAbility] System bar properties set')
        } catch (err) {
          console.error('[EntryAbility] setWindowSystemBarProperties failed:', err)
        }
      }
    } catch (e) {
      console.error('[EntryAbility] onWindowStageCreate failed:', e)
    }
  }

  async onWindowStageDestroy(): Promise<void> {
    console.info('[EntryAbility] onWindowStageDestroy')
  }

  async onForeground(): Promise<void> {
    console.info('[EntryAbility] onForeground')
  }

  async onBackground(): Promise<void> {
    console.info('[EntryAbility] onBackground')
  }

  async onDestroy(): Promise<void> {
    console.info('[EntryAbility] onDestroy')
  }
}