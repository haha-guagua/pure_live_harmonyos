import { FlutterPlugin, FlutterPluginBinding, MethodChannel, MethodCall, MethodResult, MethodCallHandler } from '@ohos/flutter_ohos';
import { ffmpegSession, ffmpegSessionExecute, abstractSessionGetReturnCode,
  abstractSessionGetAllLogsAsString, cancelSession, getFFmpegVersion,
  enableStatistics, enableStatisticsCallback, StatisticsObject } from '@ohos/ffmpeg-kit';

export default class HarmonyRecordingPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private sessions: Map<number, number> = new Map();
  getUniqueClassName(): string { return 'HarmonyRecordingPlugin'; }
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'pure_live/recording');
    this.channel.setMethodCallHandler(this);
    enableStatistics();
    enableStatisticsCallback((value: ESObject) => {
      const statistics = value as StatisticsObject;
      this.sessions.forEach((nativeId: number, id: number) => {
        if (statistics.sessionId === nativeId) {
          this.channel?.invokeMethod('statistics', new Map<string, number>([
            ['id', id], ['time', statistics.time ?? 0], ['size', statistics.size ?? 0],
            ['bitrate', statistics.bitrate ?? 0], ['speed', statistics.speed ?? 0],
            ['videoFrameNumber', statistics.videoFrameNumber ?? 0], ['videoFps', statistics.videoFps ?? 0]
          ]));
        }
      });
    });
  }
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.sessions.forEach((nativeId: number) => cancelSession(nativeId));
    this.sessions.clear();
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }
  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      switch (call.method) {
        case 'version':
          result.success(getFFmpegVersion());
          break;
        case 'cancel': {
          const id: number = call.argument('id') as number;
          const nativeId = this.sessions.get(id);
          if (nativeId !== undefined) cancelSession(nativeId);
          result.success(null);
          break;
        }
        case 'execute': {
          const id: number = call.argument('id') as number;
          const args: Array<string> = call.argument('arguments') as Array<string>;
          if (!Number.isFinite(id) || !args || args.length === 0 || this.sessions.has(id)) {
            result.error('invalid_recording', 'Invalid or duplicate recording request', null);
            return;
          }
          const created: Map<string, ESObject> = ffmpegSession(args);
          const nativeId = created.get('sessionId') as number;
          if (!Number.isFinite(nativeId)) throw new Error('Native recording session unavailable');
          this.sessions.set(id, nativeId);
          ffmpegSessionExecute(nativeId, () => {
            try {
              const code = abstractSessionGetReturnCode(nativeId);
              // Keep diagnostics bounded. Dart's recorder sanitizes URL/header data.
              const logs = abstractSessionGetAllLogsAsString(nativeId, 1000).slice(-12000);
              result.success(new Map<string, Object>([['code', code], ['logs', logs]]));
            } catch (error) {
              result.error('recording_completion', 'Unable to obtain recording result', null);
            } finally {
              this.sessions.delete(id);
            }
          });
          break;
        }
        default: result.notImplemented();
      }
    } catch (error) {
      result.error('recording_native', 'Native recording operation failed', null);
    }
  }
}
