import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/domains/recorder/data/services/harmony_record_native_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('pure_live/recording-test');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late HarmonyRecordingBridge bridge;
  late Completer<Map<String, Object?>> completion;
  late List<MethodCall> calls;
  setUp(() {
    calls = [];
    completion = Completer<Map<String, Object?>>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'execute') return completion.future;
      if (call.method == 'version') return '6.0';
      return null;
    });
    bridge = HarmonyRecordingBridge(channel: channel);
  });
  tearDown(() {
    channel.setMethodCallHandler(null);
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> statistics(Map<String, Object?> values) async {
    final done = Completer<void>();
    // Simulate a native-to-Dart progress message through the real codec.
    // ignore: deprecated_member_use
    messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall('statistics', values)),
      (_) => done.complete(),
    );
    await done.future;
  }

  test('passes argument boundaries and completes exactly once', () async {
    final session = bridge.create(['-i', 'https://example.test/live', '/tmp/path with space/video.mkv']);
    var finished = 0;
    session.setCompleteCallback((_) => finished++);
    final operation = session.executeAsync();
    await Future<void>.delayed(Duration.zero);
    expect(calls.single.arguments['arguments'], session.arguments);
    completion.complete({'code': 0, 'logs': ''});
    await operation;
    expect(finished, 1);
    expect(session.getReturnCode(), 0);
    await expectLater(session.executeAsync(), throwsStateError);
    expect(finished, 1);
  });
  test('routes progress only to the active session and normalizes numbers', () async {
    final session = bridge.create(['-version']);
    final times = <int>[];
    session.setStatisticsCallback((s) {
      times.add(s.time);
      expect(s.videoFps, 0);
    });
    final operation = session.executeAsync();
    await Future<void>.delayed(Duration.zero);
    await statistics({'id': session.id + 1, 'time': 1000});
    await statistics({'id': session.id, 'time': 2000.0, 'size': 42, 'videoFps': double.nan});
    expect(times, [2000]);
    completion.complete({'code': 0});
    await operation;
    await statistics({'id': session.id, 'time': 3000});
    expect(times, [2000]);
  });
  test('cancels only the requested session', () async {
    final session = bridge.create(['-version']);
    final operation = session.executeAsync();
    await Future<void>.delayed(Duration.zero);
    await session.cancel();
    expect(calls.last.method, 'cancel');
    expect(calls.last.arguments, {'id': session.id});
    completion.complete({'code': 255});
    await operation;
    expect(session.getReturnCode(), 255);
  });
  test('native failure is not reported as successful completion', () async {
    final session = bridge.create(['-version']);
    var finished = false;
    session.setCompleteCallback((_) => finished = true);
    final operation = session.executeAsync();
    final failed = expectLater(operation, throwsA(isA<PlatformException>()));
    await Future<void>.delayed(Duration.zero);
    completion.completeError(PlatformException(code: 'native_failure'));
    await failed;
    expect(finished, isFalse);
  });
  test('checks native availability before starting a recording', () async {
    await bridge.initialize();
    expect(calls.single.method, 'version');
  });
}
