import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The phone's media volume and the window's brightness
/// (`pure_live/device_controls` on Android, iOS and HarmonyOS; 3.x used the
/// volume_controller and screen_brightness plugins). Null where there is
/// no such control (desktop, tests).
abstract final class DeviceControls {
  static const MethodChannel _channel = MethodChannel('pure_live/device_controls');
  static final StreamController<double> _volumeChanges = StreamController<double>.broadcast();
  static bool _listening = false;
  static Future<void> _volumeWrite = Future<void>.value();
  static int _queuedVolumeWrites = 0;

  /// Real system media-volume changes, including the hardware buttons.
  static Stream<double> get volumeChanges {
    _listen();
    return _volumeChanges.stream;
  }

  static void _listen() {
    if (_listening || !available) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'volumeChanged') {
        if (call.arguments case final num value) {
          if (value.isFinite && value >= 0 && value <= 1) _volumeChanges.add(value.toDouble());
        }
      }
    });
  }

  /// Whether the controls exist on this platform.
  static bool get available =>
      debugAvailable ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.ohos));

  /// Replaces [available] (tests answer the channel themselves).
  @visibleForTesting
  static bool? debugAvailable;

  static Future<double?> _get(String method) async {
    if (!available) return null;
    _listen();
    try {
      final value = (await _channel.invokeMethod<num>(method))?.toDouble();
      return value != null && value.isFinite && value >= 0 && value <= 1 ? value : null;
    } on Object {
      return null;
    }
  }

  static Future<void> _set(String method, double value) async {
    if (!available) return;
    try {
      await _channel.invokeMethod<void>(method, {'value': value.clamp(0.0, 1.0)});
    } on Object catch (error) {
      developer.log('$method failed', name: 'LivePlay', error: error);
    }
  }

  /// The media volume, 0 to 1.
  static Future<double?> volume() => _get('getVolume');

  /// Sets the media volume; HarmonyOS retains the system panel's feedback.
  static Future<double?> setVolume(double value) {
    if (!available || !value.isFinite) return Future<double?>.value();
    _listen();
    final result = Completer<double?>();
    // A new idle batch belongs to the caller's zone, rather than retaining a
    // completed future from an earlier widget/test/service lifetime.
    if (_queuedVolumeWrites++ == 0) _volumeWrite = Future<void>.value();
    _volumeWrite = _volumeWrite.then((_) async {
      try {
        final reply = (await _channel.invokeMethod<num>('setVolume', {'value': value.clamp(0.0, 1.0)}))?.toDouble();
        final actual = reply ?? (defaultTargetPlatform == TargetPlatform.ohos ? await volume() : value.clamp(0.0, 1.0));
        result.complete(actual != null && actual.isFinite && actual >= 0 && actual <= 1 ? actual : null);
      } on Object catch (error) {
        developer.log('setVolume failed', name: 'LivePlay', error: error);
        result.complete(await volume());
      } finally {
        _queuedVolumeWrites--;
      }
    });
    return result.future;
  }

  /// The window's brightness, 0 to 1 (the system's when not overridden).
  static Future<double?> brightness() => _get('getBrightness');

  /// Overrides the window's brightness.
  static Future<void> setBrightness(double value) => _set('setBrightness', value);

  /// Gives the brightness back to the system (leaving the room).
  static Future<void> resetBrightness() async {
    if (!available) return;
    try {
      await _channel.invokeMethod<void>('resetBrightness');
    } on Object {
      // The window is gone.
    }
  }
}
