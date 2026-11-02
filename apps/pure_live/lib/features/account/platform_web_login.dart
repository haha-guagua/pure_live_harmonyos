import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:live_ui/live_ui.dart';
import 'package:pure_live/features/account/account_platforms.dart';
import 'package:pure_live/features/account/account_widgets.dart';
import 'package:pure_live/features/account/bilibili_web_login.dart' show cookieHeader;
import 'package:pure_live/features/account/platform_web_session.dart';
import 'package:pure_live/i18n/i18n.dart';
import 'package:pure_live/platform/harmony_web.dart';
import 'package:pure_live/routes/app_navigator.dart';
import 'package:pure_live/shared/in_app_web.dart';

export 'package:pure_live/features/account/platform_web_session.dart';

/// Lays a desktop site out 1280 wide and fits it to the screen, still
/// zoomable: the sites ask for the device's width even with a desktop
/// browser's name, so the "登录" in their header was off the screen. The
/// sign-in is the user's tap: the sites ignored a script's click (Douyin,
/// Huya, CC on the K90), a finger's opened it.
const String desktopFitScript = '''
(function () {
  var width = 1280;
  var scale = Math.max(0.2, Math.min(1, screen.width / width));
  var meta = document.querySelector('meta[name="viewport"]');
  if (!meta) {
    meta = document.createElement('meta');
    meta.name = 'viewport';
    (document.head || document.documentElement).appendChild(meta);
  }
  meta.setAttribute('content', 'width=' + width + ', initial-scale=' + scale + ', minimum-scale=0.1, maximum-scale=5, user-scalable=yes');
})();
''';

/// Whether [platform] can sign in on its own page here: it has one and the
/// device has an in-app browser.
bool hasPlatformWebLogin(String platform) => InAppWeb.accountLoginAvailable && platformWebLogins.containsKey(platform);

/// Opens a platform's sign-in page; the cookies of the login, or null when
/// the user left without one. Tests replace it (there is no WebView).
Future<String?> Function(BuildContext context, AccountPlatform platform) openPlatformWebLogin = _openWebLogin;

Future<String?> _openWebLogin(BuildContext context, AccountPlatform platform) async {
  final login = platformWebLogins[platform.id]!;
  if (defaultTargetPlatform == TargetPlatform.ohos) {
    final result = await HarmonyWeb.login({
      'site': platform.id,
      'url': login.page.toString(),
      'domains': login.domains.map((uri) => uri.toString()).toList(),
      'signals': login.signals.toList(),
      'desktop': login.desktop,
      'title': i18n('account_web_login_title', args: {'name': platform.name}),
      'tip': i18n(
        login.tapSignIn ? 'account_web_login_tip_desktop' : 'account_web_login_tip',
        args: {'name': platform.name},
      ),
      'userAgent': login.desktop ? desktopUserAgent : '',
    });
    return result.cookie;
  }
  if (!context.mounted) return null;
  return await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => PlatformWebLoginView(platform: platform, login: login),
    ),
  );
}

/// A platform's official sign-in in the app (K01.3, like Bilibili's web
/// login): the platform's page, where the user signs in with its app's QR
/// code, SMS or password; the moment a sign-in cookie appears (checked on
/// every page and every 1.5 s, as sites sign in inside a dialog) the
/// cookies go back to the cookie page, which checks and stores them as a
/// pasted cookie. "已登录，保存" takes them by hand.
class PlatformWebLoginView extends StatefulWidget {
  /// Creates the page.
  const new({required this.platform, required this.login, super.key});

  /// The platform.
  final AccountPlatform platform;

  /// Its sign-in page.
  final PlatformWebLogin login;

  @override
  State<PlatformWebLoginView> createState() => _PlatformWebLoginViewState();
}

class _PlatformWebLoginViewState extends State<PlatformWebLoginView> {
  InAppWebViewController? _web;
  late Future<void> _cleared = clearWebCookies(widget.login.domains, requireClear: true);
  Timer? _poll;
  bool _done = false;
  bool _reading = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(milliseconds: 1500), (_) => unawaited(_look(manual: false)));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// The desktop sites: fitted to the screen.
  Future<void> _fit() async {
    if (!widget.login.desktop) return;
    try {
      await _web?.evaluateJavascript(source: desktopFitScript);
    } on Object catch (error) {
      log('Fitting the sign-in page failed: $error', name: 'AccountPage');
    }
  }

  Future<void> _look({required bool manual}) async {
    if (_done || _reading) return;
    _reading = true;
    final List<({String name, String value})> cookies;
    try {
      await _cleared;
      if (_done || !mounted) return;
      cookies = await readWebCookies(widget.login.domains);
    } on Object {
      return;
    } finally {
      _reading = false;
    }
    if (_done || !mounted) return;
    final names = cookies.map((cookie) => cookie.name);
    if (!manual && !widget.login.signedIn(names)) return;
    if (cookies.isEmpty) {
      AppNavigator.toast(i18n('account_web_login_none', args: {'name': widget.platform.name}));
      return;
    }
    _done = true;
    _poll?.cancel();
    // `pop`, not `maybePop`: the page's PopScope turns that into a step back.
    Navigator.of(context).pop(cookieHeader(cookies));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(i18n('account_web_login_title', args: {'name': widget.platform.name})),
      actions: [
        TextButton(
          key: const ValueKey('account-web-login-done'),
          onPressed: () => unawaited(_look(manual: true)),
          child: Text(i18n('account_web_login_done')),
        ),
      ],
    ),
    body: Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                const Icon(AppIcons.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    i18n(
                      widget.login.tapSignIn ? 'account_web_login_tip_desktop' : 'account_web_login_tip',
                      args: {'name': widget.platform.name},
                    ),
                    style: context.textStyles.t13,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<void>(
            future: _cleared,
            builder: (context, snapshot) => snapshot.hasError
                ? AccountWebPreparationFailure(
                    onRetry: () => setState(() => _cleared = clearWebCookies(widget.login.domains, requireClear: true)),
                  )
                : snapshot.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : InAppWebPage(
                    initial: widget.login.page,
                    desktopSite: widget.login.desktop,
                    onCreated: (controller) => _web = controller,
                    onPage: (_) {
                      unawaited(_look(manual: false));
                      unawaited(_fit());
                    },
                  ),
          ),
        ),
      ],
    ),
  );
}
