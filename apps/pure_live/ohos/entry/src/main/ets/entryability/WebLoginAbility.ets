import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class WebLoginAbility extends UIAbility {
  private storage: LocalStorage = new LocalStorage();
  onCreate(want: Want, _parameter: AbilityConstant.LaunchParam): void {
    const config = (want.parameters?.['loginConfig'] as string) || '';
    this.storage.setOrCreate('loginConfig', config);
    hilog.info(0, 'PureLiveWeb', 'Native login configuration received, length=%{public}d', config.length);
  }
  onWindowStageCreate(stage: window.WindowStage): void {
    stage.loadContent('pages/WebLogin', this.storage).catch(() => this.context.terminateSelf());
  }
}
