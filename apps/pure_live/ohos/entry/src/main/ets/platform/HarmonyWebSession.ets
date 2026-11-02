import { webview } from '@kit.ArkWeb';

let engineReady: boolean = false;

// Cookie APIs can initialize ArkWeb on a worker. Initialize synchronously on
// the UI thread first so the browser owns the application's UI event loop.
export function ensureWebEngine(): void {
  if (engineReady) return;
  webview.WebviewController.initializeWebEngine();
  engineReady = true;
}

const COOKIE_SITES: string[] = ['bilibili.com', 'douyu.com', 'huya.com', 'douyin.com', 'kuaishou.com',
  'yy.com', '163.com', 'twitch.tv', 'sooplive.co.kr'];

// No custom schemes, user information, local files or JS URLs enter ArkWeb.
export function webHost(value: string, httpsOnly: boolean = false): string {
  const match = /^(https?):\/\/([a-zA-Z0-9.-]+)(?::[0-9]{1,5})?(?:[/?#]|$)/.exec(value);
  if (!match || (httpsOnly && match[1] !== 'https')) throw new Error('Invalid web address');
  return match[2].toLowerCase();
}

export function cookieHost(value: string): string {
  const host = webHost(value, true);
  if (!COOKIE_SITES.some((site: string) => host === site || host.endsWith('.' + site))) {
    throw new Error('Not an account site');
  }
  return host;
}

export interface LoginConfig {
  site: string;
  url: string;
  domains: string[];
  signals: string[];
  desktop: boolean;
  title: string;
  tip: string;
  userAgent: string;
}

export function parseLoginConfig(raw: string): LoginConfig {
  if (!raw || raw.length > 16384) throw new Error('Invalid login configuration');
  const config = JSON.parse(raw) as LoginConfig;
  const host = cookieHost(config.url);
  if (!config.site || config.title.length > 64 || config.tip.length > 1024 || config.userAgent.length > 1024 ||
      config.domains.length === 0 || config.domains.length > 8 || config.signals.length > 12) {
    throw new Error('Invalid login configuration');
  }
  const root = COOKIE_SITES.find((site: string) => host === site || host.endsWith('.' + site));
  for (const address of config.domains) {
    const domain = cookieHost(address);
    if (domain !== root && !domain.endsWith('.' + root)) throw new Error('Invalid login domain');
  }
  return config;
}

export async function clearCookies(address: string, scope: string): Promise<void> {
  const host = cookieHost(address);
  ensureWebEngine();
  const requested = scope.replace(/^\./, '').toLowerCase();
  if (host !== requested && !host.endsWith('.' + requested)) throw new Error('Invalid cookie scope');
  if (!COOKIE_SITES.some((site: string) => requested === site || requested.endsWith('.' + site))) {
    throw new Error('Invalid cookie scope');
  }
  // Preserve exact domain/path/HttpOnly attributes while expiring only
  // this platform's cookies. Never clear every site's cookie jar.
  const cookies = await webview.WebCookieManager.fetchAllCookies(false);
  for (const cookie of cookies) {
    const domain = cookie.domain.replace(/^\./, '').toLowerCase();
    if (domain !== requested && !domain.endsWith('.' + requested)) continue;
    if (/[;\r\n]/.test(cookie.name + cookie.path + cookie.domain)) throw new Error('Invalid cookie');
    const value = cookie.name + '=; Max-Age=0; Path=' + cookie.path +
      (cookie.domain.startsWith('.') ? '; Domain=' + cookie.domain : '') +
      (cookie.isHttpOnly ? '; HttpOnly' : '') + (cookie.isSecure ? '; Secure' : '');
    webview.WebCookieManager.configCookieSync('https://' + domain + cookie.path, value, false, true);
  }
  await webview.WebCookieManager.saveCookieAsync();
}

export async function clearLogin(config: LoginConfig): Promise<void> {
  const host = cookieHost(config.url);
  const root = COOKIE_SITES.find((site: string) => host === site || host.endsWith('.' + site));
  if (!root) throw new Error('Invalid login site');
  await clearCookies(config.url, root);
}

export async function loginCookies(config: LoginConfig): Promise<string> {
  ensureWebEngine();
  const found = new Map<string, string>();
  for (const address of config.domains) {
    let header = '';
    try { header = await webview.WebCookieManager.fetchCookie(address); } catch (_) { continue; }
    for (const part of header.split(';')) {
      const split = part.indexOf('=');
      if (split <= 0) continue;
      const name = part.slice(0, split).trim();
      if (!found.has(name)) found.set(name, part.slice(split + 1).trim());
    }
  }
  return Array.from(found.entries()).map((entry: [string, string]) => entry[0] + '=' + entry[1]).join('; ');
}
