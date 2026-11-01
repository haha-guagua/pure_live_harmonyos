import 'dart:io';

import 'package:flutter/services.dart';

/// User-initiated file selection and sharing through HarmonyOS system UI.
abstract final class HarmonyFiles {
  static const MethodChannel _channel = MethodChannel('pure_live/ohos_files');

  /// Copies a selected document into the private import cache. A document URI
  /// must not be handed to Dart IO or FFmpeg as if it were a local file path.
  static Future<File?> pickFile() async {
    final path = await _channel.invokeMethod<String>('pickFile');
    return path == null ? null : File(path);
  }

  /// Opens the system text share sheet.
  static Future<bool> shareText(String text) async =>
      await _channel.invokeMethod<bool>('shareText', {'text': text}) ?? false;

  /// Opens the system file share sheet.
  static Future<bool> shareFile(File file) async =>
      await _channel.invokeMethod<bool>('shareFile', {'path': file.path}) ?? false;

  /// Hands an application video to a system viewer.
  static Future<bool> openFile(String path) async =>
      await _channel.invokeMethod<bool>('openFile', {'path': path}) ?? false;
}
