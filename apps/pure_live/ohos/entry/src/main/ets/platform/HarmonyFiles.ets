import { common, wantConstant } from '@kit.AbilityKit';
import { fileIo as fs, fileUri, picker } from '@kit.CoreFileKit';
import { systemShare } from '@kit.ShareKit';
import { util } from '@kit.ArkTS';
import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';

export default class HarmonyFiles implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext;
  constructor(context: common.UIAbilityContext) { this.context = context; }
  getUniqueClassName(): string { return 'HarmonyFiles'; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'pure_live/ohos_files');
    this.channel.setMethodCallHandler({ onMethodCall: (call: MethodCall, result: MethodResult): void => {
      this.handle(call, result).catch(() => result.error('file_access', 'File operation unavailable', null));
    } });
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  private localPath(call: MethodCall): string {
    const path = call.argument('path') as string;
    if (!path || path.includes('\u0000') || path.split('/').includes('..') ||
      (!path.startsWith(this.context.filesDir + '/') && !path.startsWith(this.context.cacheDir + '/'))) {
      throw new Error('Only application files may be exported');
    }
    return path;
  }

  private mimeType(path: string): string {
    switch (path.slice(path.lastIndexOf('.') + 1).toLowerCase()) {
      case 'mp4':
      case 'm4v': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'mkv': return 'video/x-matroska';
      case 'flv': return 'video/x-flv';
      case 'ts': return 'video/mp2t';
      case 'webm': return 'video/webm';
      case 'json': return 'application/json';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  private async handle(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'pickFile': {
        const options = new picker.DocumentSelectOptions();
        options.maxSelectNumber = 1;
        const files = await new picker.DocumentViewPicker(this.context).select(options);
        if (files.length === 0) { result.success(null); return; }
        const suffix = /\.[a-zA-Z0-9]{1,12}$/.exec(decodeURIComponent(files[0]));
        const directory = this.context.cacheDir + '/imports';
        if (!fs.accessSync(directory)) fs.mkdirSync(directory, true);
        const path = directory + '/' + util.generateRandomUUID() + (suffix ? suffix[0] : '.data');
        const input = fs.openSync(files[0], fs.OpenMode.READ_ONLY);
        try { fs.copyFileSync(input.fd, path); } finally { fs.closeSync(input); }
        result.success(path);
        return;
      }
      case 'shareText': {
        const text = call.argument('text') as string;
        if (!text || text.length > 1048576) throw new Error('Invalid share text');
        const data = new systemShare.SharedData({ utd: 'general.plain-text', content: text });
        await new systemShare.ShareController(data).show(this.context, {
          previewMode: systemShare.SharePreviewMode.DETAIL,
          selectionMode: systemShare.SelectionMode.SINGLE
        });
        result.success(true);
        return;
      }
      case 'shareFile': {
        const path = this.localPath(call);
        const data = new systemShare.SharedData({ utd: 'general.file', uri: fileUri.getUriFromPath(path) });
        await new systemShare.ShareController(data).show(this.context, {
          previewMode: systemShare.SharePreviewMode.DETAIL,
          selectionMode: systemShare.SelectionMode.SINGLE
        });
        result.success(true);
        return;
      }
      case 'openFile': {
        const path = this.localPath(call);
        await this.context.startAbility({ action: 'ohos.want.action.viewData', uri: fileUri.getUriFromPath(path),
          type: this.mimeType(path), flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION });
        result.success(true);
        return;
      }
      default: result.notImplemented();
    }
  }
}
