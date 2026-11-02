import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:live_core/live_core.dart';
import 'package:pure_live/shared/in_app_web.dart';

/// A platform's own sign-in page in the app (K01.3): where it is, whose
/// cookies make up the login, and which of them say someone signed in.
@immutable
final class PlatformWebLogin {
  /// Creates the description.
  const new({
    required this.page,
    required this.domains,
    required this.signals,
    this.desktop = false,
    this.tapSignIn = false,
  });

  /// The sign-in page (or the site, whose own button opens the sign-in).
  final Uri page;

  /// The addresses whose cookies are read.
  final List<Uri> domains;

  /// Cookie names any of which means someone has signed in; empty: only
  /// "已登录，保存" takes the cookies.
  final Set<String> signals;

  /// The desktop site, laid out at its width and zoomable: the platform has
  /// no sign-in on its phone pages.
  final bool desktop;

  /// The sign-in opens from a "登录" at the top right of the page, which
  /// the user taps (the page says so).
  final bool tapSignIn;

  /// Whether [cookies] (names) show a sign-in.
  bool signedIn(Iterable<String> cookies) => cookies.any(signals.contains);
}

/// The platforms with an official sign-in in the app, by id (Bilibili has
/// its own pages: the QR code and `BilibiliWebLoginView`). Each page was
/// opened in the app's WebView on the K90 (2026-10-16): a phone sign-in
/// where the platform has one (Douyu's, YY's security centre, Twitch's,
/// SOOP's: password or SMS, which a phone can use itself), else the
/// desktop site, whose sign-in offers the platform app's QR code (for a
/// tablet or a second phone) and SMS or password. Huya's and Kuaishou's
/// phone pages only send to their apps; www.yy.com refuses the WebView.
final Map<String, PlatformWebLogin> platformWebLogins = {
  SiteIds.douyu: PlatformWebLogin(
    page: Uri.https('passport.douyu.com', '/h5/loginActivity'),
    domains: [Uri.https('passport.douyu.com'), Uri.https('www.douyu.com'), Uri.https('m.douyu.com')],
    signals: const {'acf_auth', 'dy_auth'},
  ),
  SiteIds.huya: PlatformWebLogin(
    page: Uri.https('www.huya.com', '/'),
    domains: [Uri.https('www.huya.com'), Uri.https('udblgn.huya.com')],
    signals: const {'udb_biztoken', 'yyuid'},
    desktop: true,
    tapSignIn: true,
  ),
  SiteIds.douyin: PlatformWebLogin(
    page: Uri.https('live.douyin.com', '/'),
    domains: [Uri.https('live.douyin.com'), Uri.https('www.douyin.com')],
    signals: const {'sessionid', 'sessionid_ss'},
    desktop: true,
    tapSignIn: true,
  ),
  SiteIds.kuaishou: PlatformWebLogin(
    page: Uri.https('passport.kuaishou.com', '/pc/account/login/', {
      'sid': 'kuaishou.live.web',
      'callback': 'https://live.kuaishou.com/',
    }),
    domains: [Uri.https('live.kuaishou.com'), Uri.https('passport.kuaishou.com'), Uri.https('id.kuaishou.com')],
    signals: const {'kuaishou.live.web_st', 'userId'},
    desktop: true,
  ),
  SiteIds.yy: PlatformWebLogin(
    page: Uri.https('aq.yy.com', '/'),
    domains: [Uri.https('aq.yy.com'), Uri.https('www.yy.com')],
    signals: const {'udb_biztoken', 'yyuid'},
  ),
  SiteIds.cc: PlatformWebLogin(
    page: Uri.https('cc.163.com', '/'),
    domains: [Uri.https('cc.163.com'), Uri.https('www.163.com')],
    signals: const {},
    desktop: true,
    tapSignIn: true,
  ),
  SiteIds.twitch: PlatformWebLogin(
    page: Uri.https('www.twitch.tv', '/login'),
    domains: [Uri.https('www.twitch.tv')],
    signals: const {'auth-token'},
  ),
  SiteIds.soop: PlatformWebLogin(
    page: Uri.https('login.sooplive.co.kr', '/afreeca/login.php'),
    domains: [Uri.https('login.sooplive.co.kr'), Uri.https('www.sooplive.co.kr')],
    signals: const {'AuthTicket'},
  ),
};

/// Reads the cookies of [domains] from the in-app browser.
Future<List<({String name, String value})>> readWebCookies(List<Uri> domains) async {
  final found = <({String name, String value})>[];
  for (final url in domains) {
    try {
      found.addAll(await InAppWeb.cookies(url));
    } on Object {
      // Read what the other addresses have.
    }
  }
  return found;
}

/// The site [host] belongs to, whose cookies its pages share:
/// `passport.douyu.com` → `douyu.com`, `login.sooplive.co.kr` →
/// `sooplive.co.kr`.
String siteDomain(String host) {
  final labels = host.toLowerCase().split('.');
  final keep = labels.length > 2 && labels[labels.length - 2].length <= 3 && labels.last.length == 2 ? 3 : 2;
  return labels.length <= keep ? labels.join('.') : labels.sublist(labels.length - keep).join('.');
}

/// Removes the cookies of [domains] from the in-app browser, so an account
/// signed out of the app is not picked up again; failures are logged.
Future<void> clearWebCookies(List<Uri> domains, {bool requireClear = false}) async {
  var failed = false;
  for (final url in domains) {
    try {
      await InAppWeb.clearCookies(url, domain: '.${siteDomain(url.host)}');
      await InAppWeb.clearCookies(url);
    } on Object catch (error) {
      failed = true;
      log('Clearing web cookies failed: ${error.runtimeType}', name: 'AccountPage');
    }
  }
  if (failed && requireClear) throw StateError('Web session could not be cleared');
}
