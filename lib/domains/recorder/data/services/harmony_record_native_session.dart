import 'package:flutter/services.dart';
import 'record_native_session.dart';

class HarmonyRecordingBridge {
  HarmonyRecordingBridge({this.channel = const MethodChannel('pure_live/recording')}) {
    channel.setMethodCallHandler(_onMethodCall);
  }
  static final instance = HarmonyRecordingBridge();
  final MethodChannel channel;
  final Map<int, HarmonyRecordNativeSession> _sessions = {};
  int _nextId = 0;
  Future<void> initialize() async {
    await channel.invokeMethod<String>('version');
  }

  HarmonyRecordNativeSession create(List<String> arguments) => HarmonyRecordNativeSession._(this, ++_nextId, arguments);
  Future<void> _onMethodCall(MethodCall call) async {
    if (call.method != 'statistics' || call.arguments is! Map) return;
    final data = Map<Object?, Object?>.from(call.arguments as Map);
    final session = _sessions[data['id']];
    if (session == null) return;
    num number(String key) {
      final value = data[key];
      return value is num && value.isFinite ? value : 0;
    }

    session._statistics?.call(
      RecordNativeStatistics(
        time: number('time').toInt(),
        size: number('size').toInt(),
        bitrate: number('bitrate').toDouble(),
        speed: number('speed').toDouble(),
        videoFrameNumber: number('videoFrameNumber').toInt(),
        videoFps: number('videoFps').toDouble(),
      ),
    );
  }
}

class HarmonyRecordNativeSession implements RecordNativeSession {
  HarmonyRecordNativeSession._(this.bridge, this.id, List<String> arguments) : arguments = List.unmodifiable(arguments);
  final HarmonyRecordingBridge bridge;
  final int id;
  final List<String> arguments;
  int _code = -1;
  String? _logs;
  bool _executed = false;
  void Function(String)? _log;
  void Function(RecordNativeStatistics)? _statistics;
  void Function(RecordNativeSession)? _complete;
  @override
  int getSessionId() => id;
  @override
  int getReturnCode() => _code;
  @override
  String? getLogs() => _logs;
  @override
  void setLogCallback(void Function(String) callback) {
    _log = callback;
  }

  @override
  void setStatisticsCallback(void Function(RecordNativeStatistics) callback) {
    _statistics = callback;
  }

  @override
  void setCompleteCallback(void Function(RecordNativeSession) callback) {
    _complete = callback;
  }

  @override
  Future<void> executeAsync() async {
    if (_executed) throw StateError('Recording session already executed');
    _executed = true;
    bridge._sessions[id] = this;
    try {
      final result = await bridge.channel.invokeMapMethod<String, Object?>('execute', {
        'id': id,
        'arguments': arguments,
      });
      if (result == null || result['code'] is! num) throw StateError('Missing recording return code');
      _code = (result['code'] as num).toInt();
      _logs = result['logs'] as String?;
      if (_logs?.isNotEmpty == true) _log?.call(_logs!);
      _complete?.call(this);
    } finally {
      bridge._sessions.remove(id);
    }
  }

  @override
  Future<void> cancel() async {
    await bridge.channel.invokeMethod<void>('cancel', {'id': id});
  }
}
