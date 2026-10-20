import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volume_controller/volume_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.kurenai7968.volume_controller.method');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  for (final value in <num>[0, 1, 0.35]) {
    test('accepts native numeric volume $value', () async {
      messenger.setMockMethodCallHandler(channel, (_) async => value);
      expect(await VolumeController.instance.getVolume(), value.toDouble());
    });
  }
  test('propagates native writes instead of pretending a failed gesture succeeded', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => throw PlatformException(code: 'volume_failed'));
    await expectLater(VolumeController.instance.setVolume(0.4), throwsA(isA<PlatformException>()));
  });
}
