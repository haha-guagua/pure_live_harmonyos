import 'dart:convert';

import 'package:flutter/services.dart';

/// ArkWeb operations on the app's private Flutter channel, never a JS bridge.
abstract final class HarmonyWeb {
  /// The native login window is independent of Flutter's embedded browser.
  static bool loginAvailable = false;

  /// Opens an app-private native ability; credentials stay on the official page.
  static Future<({String? cookie, bool qr})> login(Map<String, Object> config) async {
    final result = await _channel.invokeMapMethod<String, dynamic>('login', {'config': jsonEncode(config)});
    return (cookie: result?['cookie'] as String?, qr: result?['action'] == 'qr');
  }

  static const MethodChannel _channel = MethodChannel('pure_live/ohos_web');

  /// Whether the native view and cookie handler are registered.
  static Future<bool> available() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Reads native cookies, including HttpOnly values, for one official site.
  static Future<List<({String name, String value})>> cookies(Uri uri) async {
    final header = await _channel.invokeMethod<String>('cookies', {'url': uri.toString()}) ?? '';
    return [
      for (final part in header.split(';'))
        if (part.indexOf('=') case final split when split > 0)
          (name: part.substring(0, split).trim(), value: part.substring(split + 1).trim()),
    ];
  }

  /// Clears only this site's cookies, retaining other platform sign-ins.
  static Future<void> clearCookies(Uri uri, {String? domain}) =>
      _channel.invokeMethod<void>('clearCookies', {'url': uri.toString(), 'domain': domain ?? uri.host});
}
