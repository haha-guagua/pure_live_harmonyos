import { common } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import { clearCookies, cookieHost, ensureWebEngine, parseLoginConfig } from './HarmonyWebSession';

export default class HarmonyWeb implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext;
  private opening: boolean = false;
  constructor(context: common.UIAbilityContext) { this.context = context; }
  getUniqueClassName(): string { return 'HarmonyWeb'; }
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'pure_live/ohos_web');
    this.channel.setMethodCallHandler({ onMethodCall: (call: MethodCall, result: MethodResult): void => {
      this.handle(call, result).catch(() => result.error('web_access', 'Web operation unavailable', null));
    } });
  }
  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null); this.channel = null;
  }
  private async handle(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'available': result.success(canIUse('SystemCapability.Web.Webview.Core')); return;
      case 'login': {
        if (this.opening) throw new Error('Login already open');
        const raw = call.argument('config') as string;
        parseLoginConfig(raw);
        this.opening = true;
        try {
          const reply = await this.context.startAbilityForResult({ bundleName: this.context.abilityInfo.bundleName,
            abilityName: 'WebLoginAbility', parameters: { loginConfig: raw } });
          const parameters = reply.want?.parameters;
          if (reply.resultCode !== 0 || !parameters) { result.success(null); return; }
          const action = parameters['action'] as string;
          const cookie = parameters['cookie'] as string;
          if (action === 'qr') { result.success(new Map<string, Object>([['action', 'qr']])); return; }
          if (action !== 'cookie' || !cookie || cookie.length > 1048576 || /[\r\n\u0000]/.test(cookie)) {
            result.success(null); return;
          }
          result.success(new Map<string, Object>([['action', 'cookie'], ['cookie', cookie]]));
        } finally { this.opening = false; }
        return;
      }
      case 'cookies': {
        const address = call.argument('url') as string; cookieHost(address);
        ensureWebEngine();
        result.success(await webview.WebCookieManager.fetchCookie(address)); return;
      }
      case 'clearCookies':
        await clearCookies(call.argument('url') as string, call.argument('domain') as string);
        result.success(null); return;
      default: result.notImplemented();
    }
  }
}
