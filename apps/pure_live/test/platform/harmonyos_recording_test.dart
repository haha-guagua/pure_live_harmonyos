import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/platform/harmony_recording.dart';
import 'package:pure_live/platform/recording_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/harmony_recording');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('HarmonyOS has its native recording engine', () => expect(hasBundledFfmpeg('ohos'), isTrue));

  test('arguments preserve spaces and signed headers without shell joining', () async {
    final arguments = ['-headers', 'X-Test: a b\r\n', '-i', 'https://example.invalid/a?x=1&y=2', '/cache/a b.mp4'];
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'execute');
      expect((call.arguments as Map<Object?, Object?>)['arguments'], arguments);
      return {'code': 0, 'logs': ''};
    });
    final execution = await HarmonyFfmpegRunner(channel: channel).start(arguments);
    expect(await execution.exitCode, 0);
  });

  test('cancelling a session does not cancel another session', () async {
    final replies = <int, Completer<Map<String, Object?>>>{};
    final cancelled = <int>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      final id = (call.arguments as Map<Object?, Object?>)['id']! as int;
      if (call.method == 'cancel') {
        cancelled.add(id);
        return null;
      }
      final reply = Completer<Map<String, Object?>>();
      replies[id] = reply;
      return await reply.future;
    });
    final runner = HarmonyFfmpegRunner(channel: channel);
    final first = await runner.start(['-i', 'first']);
    final second = await runner.start(['-i', 'second']);
    await Future<void>.delayed(const Duration(seconds: 1));
    first
      ..cancel()
      ..cancel();
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(cancelled, [1]);
    replies[1]!.complete({'code': 255});
    replies[2]!.complete({'code': 0});
    expect(await first.exitCode, 255);
    expect(await second.exitCode, 0);
  });

  test('native failure completes rather than leaving a recording pending', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => throw PlatformException(code: 'native_failed'));
    final execution = await HarmonyFfmpegRunner(channel: channel).start(['-i', 'sample']);
    expect(await execution.exitCode, -1);
  });
}
