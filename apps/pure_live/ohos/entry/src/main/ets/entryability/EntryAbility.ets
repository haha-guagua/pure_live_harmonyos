import HarmonyRecordingPlugin from '../recording/HarmonyRecordingPlugin';
import HarmonyDeviceControls from '../platform/HarmonyDeviceControls';
import HarmonySecretCipher from '../platform/HarmonySecretCipher';
import HarmonyFiles from '../platform/HarmonyFiles';

import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(new HarmonyRecordingPlugin())
    flutterEngine.getPlugins()?.add(new HarmonyDeviceControls(this.context))
    flutterEngine.getPlugins()?.add(new HarmonySecretCipher())
    flutterEngine.getPlugins()?.add(new HarmonyFiles(this.context))
  }
}
