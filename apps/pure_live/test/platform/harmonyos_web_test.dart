import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_core/live_core.dart';
import 'package:pure_live/features/account/account_services.dart';
import 'package:pure_live/features/account/platform_web_session.dart';
import 'package:pure_live/platform/harmony_web.dart';
import 'package:pure_live/shared/in_app_web.dart';

import '../support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('pure_live/ohos_web');

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('official login is available only when native ArkWeb reports support', () async {
    expect(await HarmonyWeb.available(), isFalse);
    messenger.setMockMethodCallHandler(channel, (call) async => true);
    expect(await HarmonyWeb.available(), isTrue);
    messenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'unavailable'));
    expect(await HarmonyWeb.available(), isFalse);
  });

  test('native cookies retain encoded values and equals signs for secure account storage', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'cookies');
      expect(call.arguments, {'url': 'https://passport.bilibili.com'});
      return 'SESSDATA=encoded%2Fvalue==; bili_jct=csrf; malformed; empty=';
    });
    expect(await HarmonyWeb.cookies(Uri.parse('https://passport.bilibili.com')), [
      (name: 'SESSDATA', value: 'encoded%2Fvalue=='),
      (name: 'bili_jct', value: 'csrf'),
      (name: 'empty', value: ''),
    ]);
  });

  test('sign-out clears only the requested platform scope', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    await HarmonyWeb.clearCookies(Uri.parse('https://passport.bilibili.com'), domain: '.bilibili.com');
    expect(calls.single.method, 'clearCookies');
    expect(calls.single.arguments, {'url': 'https://passport.bilibili.com', 'domain': '.bilibili.com'});
  });

  test('native cookie failure is propagated without claiming an empty successful sign-out', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'web_access'));
    await expectLater(HarmonyWeb.clearCookies(Uri.parse('https://www.huya.com')), throwsA(isA<PlatformException>()));
  });

  testWidgets('HarmonyOS offers native login without enabling an unsupported Flutter browser', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'available') return true;
      throw PlatformException(code: 'web_access');
    });
    HarmonyWeb.loginAvailable = await HarmonyWeb.available();
    addTearDown(() => HarmonyWeb.loginAvailable = false);
    expect(InAppWeb.accountLoginAvailable, isTrue);
    expect(InAppWeb.available, isFalse);
    await expectLater(clearWebCookies([Uri.https('passport.douyu.com')], requireClear: true), throwsStateError);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  test('sign-out removes stored credentials before clearing just that platform browser session', () async {
    final services = await testServices();
    addTearDown(services.close);
    final cleared = <String>[];
    final actions = AccountActions(
      services.store,
      clearPlatformWeb: (site) async {
        expect(services.store.secrets.cookieFor(site), isNull);
        cleared.add(site);
      },
    );
    await actions.save(SiteIds.douyin, 'sessionid=test-placeholder');
    await actions.save(SiteIds.huya, 'udb_biztoken=other-placeholder');
    await actions.signOut(SiteIds.douyin);
    expect(cleared, [SiteIds.douyin]);
    expect(actions.cookieOf(SiteIds.huya), 'udb_biztoken=other-placeholder');
  });

  test('native login preserves the official configuration and returns cookies through the private channel', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'login');
      final config = jsonDecode((call.arguments as Map)['config'] as String) as Map;
      expect(config['site'], 'douyu');
      expect(config['url'], 'https://passport.douyu.com/h5/loginActivity');
      return {'action': 'cookie', 'cookie': 'dy_auth=test-placeholder'};
    });
    final result = await HarmonyWeb.login({'site': 'douyu', 'url': 'https://passport.douyu.com/h5/loginActivity'});
    expect(result.cookie, 'dy_auth=test-placeholder');
    expect(result.qr, isFalse);
  });

  test('cancelling native login cannot save visitor cookies and Bilibili can switch back to QR', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await HarmonyWeb.login({'site': 'bilibili'}), (cookie: null, qr: false));
    messenger.setMockMethodCallHandler(channel, (_) async => {'action': 'qr'});
    expect(await HarmonyWeb.login({'site': 'bilibili'}), (cookie: null, qr: true));
  });
}
