import { common } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { clearLogin, LoginConfig, loginCookies, parseLoginConfig, webHost } from '../platform/HarmonyWebSession';

const FIT_DESKTOP = `(function(){var m=document.querySelector('meta[name="viewport"]');
if(!m){m=document.createElement('meta');m.name='viewport';document.head.appendChild(m);}
m.content='width=1280, initial-scale='+Math.max(0.2,Math.min(1,screen.width/1280))+
', minimum-scale=0.1, maximum-scale=5, user-scalable=yes';})();`;

let loginStorage = LocalStorage.getShared();

@Entry(loginStorage)
@Component
struct WebLogin {
  @LocalStorageProp('loginConfig') raw: string = '';
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private controller: webview.WebviewController = new webview.WebviewController();
  private config: LoginConfig | null = null;
  private timer: number = -1;
  private done: boolean = false;
  private reading: boolean = false;
  private attached: boolean = false;
  @State prepared: boolean = false;
  @State failed: boolean = false;
  @State progress: number = 0;
  @State titleText: string = '官方登录';
  @State tip: string = '';
  @State errorText: string = '';
  @State bilibili: boolean = false;

  aboutToAppear(): void {
    hilog.info(0, 'PureLiveWeb', 'Native login page configuration length=%{public}d', this.raw.length);
    try {
      this.config = parseLoginConfig(this.raw);
      this.titleText = this.config.title;
      this.tip = this.config.tip;
      this.bilibili = this.config.site === 'bilibili';
      this.prepare();
    } catch (_) { this.errorText = '无法打开登录页面，请返回后重试。'; }
  }

  private async prepare(): Promise<void> {
    if (!this.config || this.done) return;
    this.errorText = '';
    try {
      await clearLogin(this.config);
      if (this.done) return;
      this.prepared = true;
      this.timer = setInterval(() => { this.look(false); }, 1500);
    } catch (_) { this.errorText = '无法清理上次的网页登录状态，请重试。'; }
  }

  aboutToDisappear(): void {
    if (this.timer >= 0) clearInterval(this.timer);
    this.done = true;
    if (this.attached) { try { this.controller.stop(); } catch (_) {} }
  }

  private async finish(action: string, cookie: string = ''): Promise<void> {
    if (this.done) return;
    this.done = true;
    if (this.timer >= 0) clearInterval(this.timer);
    await this.context.terminateSelfWithResult({ resultCode: action === 'cancel' ? -1 : 0,
      want: { parameters: { action: action, cookie: cookie } } });
  }

  private async look(manual: boolean): Promise<void> {
    if (!this.config || !this.prepared || this.done || this.reading) return;
    this.reading = true;
    try {
      const cookie = await loginCookies(this.config);
      if (this.done) return;
      const names = cookie.split(';').map((part: string) => part.split('=')[0].trim());
      if (!manual && !names.some((name: string) => this.config!.signals.includes(name))) return;
      if (!cookie) { this.errorText = '还没有登录信息，请先在官方页面登录。'; return; }
      await this.finish('cookie', cookie);
    } catch (_) { if (!this.done) this.errorText = '无法读取登录状态，请重试。'; }
    finally { this.reading = false; }
  }

  private back(): void {
    if (this.attached && this.controller.accessBackward()) this.controller.backward();
    else this.finish('cancel');
  }

  onBackPress(): boolean { this.back(); return true; }

  build() {
    Column() {
      Row() {
        Button('返回').onClick(() => this.back())
        Text(this.titleText).fontSize(18).fontColor(Color.Black).fontWeight(FontWeight.Medium)
          .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).textAlign(TextAlign.Center)
        if (this.bilibili) { Button('扫码登录').onClick(() => this.finish('qr')) }
        Button('已登录，保存').onClick(() => this.look(true))
      }.width('100%').padding(12)
      Text(this.tip).fontSize(14).fontColor('#333333').padding(12).width('100%').backgroundColor('#F2F3F5')
      if (this.errorText) {
        Row() {
          Text(this.errorText).fontSize(14).fontColor('#B3261E').layoutWeight(1)
          Button('重试').onClick(() => {
            if (!this.prepared) this.prepare();
            else { this.errorText = ''; this.failed = false; this.controller.refresh(); }
          })
        }.padding(12).width('100%')
      }
      if (!this.prepared && !this.errorText) { LoadingProgress().width(40).height(40).margin(24) }
      if (this.prepared && this.config) {
        if (this.progress < 100) { Progress({ value: this.progress, total: 100 }).width('100%') }
        Web({ src: this.config.url, controller: this.controller })
          .width('100%').layoutWeight(1)
          .javaScriptAccess(true).domStorageAccess(true).fileAccess(false)
          .mixedMode(MixedMode.None).multiWindowAccess(false).allowWindowOpenMethod(false)
          .mediaPlayGestureAccess(true).zoomAccess(true).wideViewModeAccess(true).overviewModeAccess(true)
          .onControllerAttached(() => {
            this.attached = true;
            if (this.config!.userAgent) this.controller.setCustomUserAgent(this.config!.userAgent);
            hilog.info(0, 'PureLiveWeb', 'Native login controller attached');
          })
          .onPageBegin(() => { this.progress = 0; this.failed = false; })
          .onProgressChange((event) => { this.progress = event.newProgress; })
          .onPageEnd(() => {
            hilog.info(0, 'PureLiveWeb', 'Native login page loaded');
            if (this.config!.desktop) this.controller.runJavaScript(FIT_DESKTOP).catch(() => {});
            this.look(false);
          })
          .onErrorReceive((event) => {
            if (event.request.isMainFrame()) { this.failed = true; this.errorText = '网页加载失败，请检查网络后重试。'; }
          })
          .onSslErrorEventReceive((event) => {
            event.handler.handleCancel(); this.failed = true; this.errorText = '无法验证网页证书，已停止加载。';
          })
          .onOverrideUrlLoading((request) => {
            const address = request.getRequestUrl();
            if (address === 'about:blank' || address === 'about:srcdoc') return false;
            try { webHost(address, true); return false; } catch (_) { return true; }
          })
      }
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
