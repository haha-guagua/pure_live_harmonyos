import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import settings from '@ohos.settings';
import batteryInfo from '@ohos.batteryInfo';
import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';

export const MEDIA_VOLUME_STORAGE = 'pureLiveNextMediaVolume';

class PendingVolume {
  level: number;
  result: MethodResult;
  timer: number = -1;
  constructor(level: number, result: MethodResult) { this.level = level; this.result = result; }
}

// Read and write the device's MEDIA stream, never app-volume percentage or mpv gain.
export default class HarmonyDeviceControls implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private manager: audio.AudioManager = audio.getAudioManager();
  private volume: audio.AudioVolumeManager = this.manager.getVolumeManager();
  private pending: PendingVolume | null = null;
  private listener = (_event: audio.StreamVolumeEvent): void => {
    try {
      const actual = this.readVolume();
      this.channel?.invokeMethod('volumeChanged', actual);
      const level = this.volume.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC);
      AppStorage.setOrCreate<number>(MEDIA_VOLUME_STORAGE, level);
      if (this.pending !== null && level === this.pending.level) this.finishVolume(true);
    } catch (_) { /* Window detached. */ }
  };

  private context: common.UIAbilityContext;
  constructor(context: common.UIAbilityContext) { this.context = context; }
  getUniqueClassName(): string { return 'HarmonyDeviceControls'; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    AppStorage.setOrCreate<number>(MEDIA_VOLUME_STORAGE,
      this.volume.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC));
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'pure_live/device_controls');
    this.channel.setMethodCallHandler({ onMethodCall: (call: MethodCall, result: MethodResult): void => {
      this.handle(call, result).catch(() => result.error('device_controls', 'Device control unavailable', null));
    } });
    try { this.volume.on('streamVolumeChange', audio.StreamUsage.STREAM_USAGE_MUSIC, this.listener); } catch (_) { /* Reads remain available. */ }
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.finishVolume(false);
    try { this.volume.off('streamVolumeChange', this.listener); } catch (_) { /* Already detached. */ }
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  private readVolume(): number {
    const maximum = this.volume.getMaxVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC);
    if (maximum <= 0) throw new Error('Invalid media volume range');
    return Math.min(1, Math.max(0, this.volume.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC) / maximum));
  }

  private finishVolume(applied: boolean): void {
    const pending = this.pending;
    if (pending === null) return;
    this.pending = null;
    if (pending.timer >= 0) clearTimeout(pending.timer);
    if (applied) {
      try { pending.result.success(this.readVolume()); }
      catch (_) { pending.result.error('volume_unavailable', 'System media volume could not be verified', null); }
    } else pending.result.error('volume_not_applied', 'System media volume was not changed', null);
  }

  private async handle(call: MethodCall, result: MethodResult): Promise<void> {
    if (call.method === 'getBattery') { result.success(batteryInfo.batterySOC); return; }
    if (call.method === 'getVolume') { result.success(this.readVolume()); return; }
    if (call.method === 'setVolume') {
      const value = call.argument('value') as number;
      if (!Number.isFinite(value) || value < 0 || value > 1) throw new Error('Invalid media volume');
      const maximum = this.volume.getMaxVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC);
      const level = Math.round(value * maximum);
      if (Math.abs(this.readVolume() * maximum - level) < 0.5) { result.success(this.readVolume()); return; }
      if (this.pending !== null) throw new Error('A media volume request is pending');
      // Index hosts the public AVVolumePanel. Only explicit Flutter gestures,
      // slider changes and mute actions reach this method; startup never writes.
      const pending = new PendingVolume(level, result);
      this.pending = pending;
      pending.timer = setTimeout(() => {
        try {
          const applied = Math.abs(this.readVolume() * maximum - level) < 0.5;
          if (!applied) AppStorage.setOrCreate<number>(MEDIA_VOLUME_STORAGE,
            this.volume.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC));
          this.finishVolume(applied);
        } catch (_) { this.finishVolume(false); }
      }, 1000);
      AppStorage.setOrCreate<number>(MEDIA_VOLUME_STORAGE, level);
      return;
    }
    const main = await window.getLastWindow(this.context);
    switch (call.method) {
      case 'getBrightness': {
        const local = main.getWindowProperties().brightness;
        const setting = local >= 0 ? '' : settings.getValueSync(
          this.context, settings.display.SCREEN_BRIGHTNESS_STATUS, '');
        if (local < 0 && setting.trim().length === 0) throw new Error('System brightness unavailable');
        const raw = local >= 0 ? local : Number(setting) / 255;
        if (!Number.isFinite(raw)) throw new Error('Invalid system brightness');
        result.success(Math.min(1, Math.max(0, raw)));
        return;
      }
      case 'setBrightness': {
        const value = call.argument('value') as number;
        if (!Number.isFinite(value) || value < 0 || value > 1) throw new Error('Invalid brightness');
        await main.setWindowBrightness(value);
        result.success(null);
        return;
      }
      case 'resetBrightness':
        await main.setWindowBrightness(-1);
        result.success(null);
        return;
      default: result.notImplemented();
    }
  }
}
