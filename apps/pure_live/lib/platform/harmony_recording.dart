import 'dart:async';

import 'package:flutter/services.dart';
import 'package:live_record/live_record.dart';

/// FFmpeg sessions of the HarmonyOS host. Arguments remain a list all the
/// way to the native library; the desktop FFmpeg FFI bundle is never loaded.
final class HarmonyFfmpegRunner implements FfmpegRunner {
  /// Creates a runner on the host channel (replaceable in tests).
  new({this._channel = const MethodChannel('pure_live/recording')}) {
    _channel.setMethodCallHandler(_event);
  }

  final MethodChannel _channel;
  final Map<int, _HarmonyExecution> _sessions = {};
  int _nextId = 0;

  Future<void> _event(MethodCall call) async {
    if (call.method != 'statistics' || call.arguments is! Map) return;
    final fields = call.arguments as Map;
    final execution = _sessions[fields['id']];
    if (execution == null) return;
    num value(String key) => fields[key] is num ? fields[key] as num : 0;
    execution.addStatistics(
      FfmpegStatistics(
        time: value('time').toInt(),
        size: value('size').toInt(),
        bitrate: value('bitrate').toDouble(),
        speed: value('speed').toDouble(),
        videoFrame: value('videoFrameNumber').toInt(),
        videoFps: value('videoFps').toDouble(),
      ),
    );
  }

  @override
  Future<FfmpegExecution> start(List<String> arguments) async {
    if (arguments.isEmpty || arguments.any((value) => value.contains('\u0000'))) {
      throw ArgumentError('FFmpeg arguments must be a non-empty argument list without NUL');
    }
    final id = ++_nextId;
    final execution = _HarmonyExecution(() async {
      await _channel.invokeMethod<void>('cancel', {'id': id});
    });
    _sessions[id] = execution;
    unawaited(_execute(id, List<String>.unmodifiable(arguments), execution));
    return execution;
  }

  Future<void> _execute(int id, List<String> arguments, _HarmonyExecution execution) async {
    try {
      final reply = await _channel.invokeMapMethod<String, Object?>('execute', {'id': id, 'arguments': arguments});
      final code = reply?['code'];
      final logs = reply?['logs'];
      if (logs is String) execution.addLog(logs);
      execution.finish(code is num ? code.toInt() : -1);
    } on Object {
      execution
        ..addLog('HarmonyOS FFmpeg session failed')
        ..finish(-1);
    } finally {
      _sessions.remove(id);
    }
  }
}

final class _HarmonyExecution implements FfmpegExecution {
  new(this._cancel);

  final Future<void> Function() _cancel;
  final _logs = StreamController<String>.broadcast(sync: true);
  final _statistics = StreamController<FfmpegStatistics>.broadcast(sync: true);
  final _exit = Completer<int>();
  bool _cancelling = false;

  void addLog(String value) {
    if (!_logs.isClosed) _logs.add(value);
  }

  void addStatistics(FfmpegStatistics value) {
    if (!_statistics.isClosed) _statistics.add(value);
  }

  void finish(int code) {
    if (_exit.isCompleted) return;
    _exit.complete(code);
    unawaited(_logs.close());
    unawaited(_statistics.close());
  }

  @override
  Stream<String> get logs => _logs.stream;
  @override
  Stream<FfmpegStatistics> get statistics => _statistics.stream;
  @override
  Future<int> get exitCode => _exit.future;

  @override
  void cancel() {
    if (_exit.isCompleted || _cancelling) return;
    _cancelling = true;
    unawaited(
      _cancel().catchError((Object _) {
        _cancelling = false;
        addLog('HarmonyOS FFmpeg cancellation failed');
      }),
    );
  }
}
