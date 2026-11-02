import common from '@ohos.app.ability.common';
import { audio, AVVolumePanel } from '@kit.AudioKit';
import { FlutterPage } from '@ohos/flutter_ohos';
import { MEDIA_VOLUME_STORAGE } from '../platform/HarmonyDeviceControls';

let storage = LocalStorage.getShared();
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext;
  @LocalStorageLink('viewId') viewId: string = '';
  @StorageLink(MEDIA_VOLUME_STORAGE) mediaVolume: number = audio.getAudioManager()
    .getVolumeManager().getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC);

  build() {
    Stack() {
      // The system panel remains visible at its default position when the user
      // changes volume. Its transparent UIExtension must not cover Flutter's
      // input surface; hit testing belongs on the native container, since the
      // custom component does not forward that modifier to its UIExtension.
      Stack() {
        AVVolumePanel({ volumeLevel: this.mediaVolume })
      }
        .width(1).height(1)
        .position({ x: 0, y: 0 })
        .hitTestBehavior(HitTestMode.None)
        .focusable(false)
      FlutterPage({ viewId: this.viewId }).width('100%').height('100%')
    }.width('100%').height('100%')
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS);
    return true;
  }
}
