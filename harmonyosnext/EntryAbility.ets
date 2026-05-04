import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'AIStockTrader', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'AIStockTrader', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'AIStockTrader', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err: BusinessError, data: void) => {
      if (err.code) {
        hilog.error(0x0000, 'AIStockTrader', 'Failed to load content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'AIStockTrader', 'Succeeded in loading content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'AIStockTrader', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'AIStockTrader', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'AIStockTrader', '%{public}s', 'Ability onBackground');
  }
}
