import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'runtime_platform.dart';

class PlatformUtils {
  PlatformUtils._();
  static final _runtime = RuntimePlatform(Platform.operatingSystem);

  static bool get isDesktop => _runtime.isDesktop;

  static bool get isDesktopNotMac => (Platform.isWindows || Platform.isLinux) && !Platform.isMacOS;

  static bool get isMobile => _runtime.isMobile;

  static bool get isOhos => _runtime.isOhos;

  static bool get supportsRecorderPrewarm => _runtime.supportsRecorderPrewarm;

  static bool get supportsSystemMediaSession => _runtime.supportsSystemMediaSession;

  static bool isMobileWidth(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
  }

  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;

  static T select<T>({required T desktop, required T mobile}) {
    return isDesktop ? desktop : mobile;
  }
}
