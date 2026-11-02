import 'dart:developer';

import 'package:pure_live/shared/in_app_web.dart';

/// The Bilibili addresses whose in-app browser cookies make up a login.
final List<Uri> bilibiliWebDomains = [
  Uri.https('www.bilibili.com'),
  Uri.https('passport.bilibili.com'),
  Uri.https('m.bilibili.com'),
];

/// Removes Bilibili's cookies from the in-app browser, so a signed-out
/// account is not picked up again by the web login (3.x
/// `BiliBiliAccountService._clearBrowserCookies` removed every site's;
/// only Bilibili's here). Nothing happens without a WebView; failures are
/// logged; sign-in preparation sets [requireClear] to refuse a stale session.
Future<void> clearBilibiliWebCookies({bool requireClear = false}) async {
  if (!InAppWeb.accountLoginAvailable) return;
  var failed = false;
  for (final url in bilibiliWebDomains) {
    try {
      await InAppWeb.clearCookies(url, domain: '.bilibili.com');
      await InAppWeb.clearCookies(url);
    } on Object catch (error) {
      // The other domains are still cleared.
      failed = true;
      log('Clearing the Bilibili web cookies failed: ${error.runtimeType}', name: 'AccountPage');
    }
  }
  if (failed && requireClear) throw StateError('Web session could not be cleared');
}
