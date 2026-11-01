import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_ui/live_ui.dart';
import 'package:pure_live/features/live_play/logic/room_controller.dart';
import 'package:pure_live/features/live_play/player/player_controls.dart';
import 'package:pure_live/features/live_play/player/player_gestures.dart';
import 'package:pure_live/platform/device_controls.dart';

final class _Room implements LiveRoomController {
  const new();
  @override
  double get volume => 1;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('pure_live/device_controls');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('HarmonyOS is mobile without enabling Android capabilities', (tester) async {
    const platform = RoomPlatform(TargetPlatform.ohos);
    expect(platform.mobile, isTrue);
    expect(platform.desktop, isFalse);
    expect(platform.android, isFalse);
    expect(DeviceControls.available, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('system media 20 percent is read independently of player 100 percent', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async => call.method == 'getVolume' ? 0.2 : null);
    expect(await DeviceControls.volume(), 0.2);
    expect(const _Room().volume, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('native write returns the applied hardware step, not the requested fraction', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setVolume') return 3 / 15;
      return null;
    });
    expect(await DeviceControls.setVolume(0.21), 0.2);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('failed media write re-reads actual volume instead of claiming success', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setVolume') throw PlatformException(code: 'write_denied');
      return call.method == 'getVolume' ? 0.2 : null;
    });
    expect(await DeviceControls.setVolume(0.8), 0.2);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('rapid native volume writes are serialized', (tester) async {
    final firstGate = Completer<void>();
    final writes = <double>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      final value = ((call.arguments as Map<Object?, Object?>)['value']! as num).toDouble();
      writes.add(value);
      if (writes.length == 1) await firstGate.future;
      return value;
    });
    final first = DeviceControls.setVolume(0.2);
    final second = DeviceControls.setVolume(0.4);
    await tester.pump();
    expect(writes, [0.2]);
    firstGate.complete();
    expect(await first, 0.2);
    expect(await second, 0.4);
    expect(writes, [0.2, 0.4]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  Future<GlobalKey<PlayerGestureLayerState>> picture(WidgetTester tester) async {
    final key = GlobalKey<PlayerGestureLayerState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: const LiveTheme().light,
        home: PlayerGestureLayer(key: key, controller: const _Room(), child: const SizedBox.expand()),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });
    return key;
  }

  testWidgets('first adjustment shows actual 20 percent and hardware changes follow', (tester) async {
    final writes = <double>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVolume') return 0.2;
      if (call.method == 'setVolume') {
        final value = ((call.arguments as Map<Object?, Object?>)['value']! as num).toDouble();
        writes.add(value);
        return value;
      }
      return null;
    });
    final key = await picture(tester);
    expect(writes, isEmpty, reason: 'Entering a room must not change device volume');
    await key.currentState!.nudgeVolume(0);
    await tester.pump();
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    final delivered = Completer<void>();
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('volumeChanged', 0.4)),
      (_) => delivered.complete(),
    );
    await delivered.future;
    await tester.pump();
    expect(find.text('40%'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('slow volume drags accumulate across discrete hardware steps', (tester) async {
    var actual = 0.2;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVolume') return actual;
      if (call.method == 'setVolume') {
        final value = ((call.arguments as Map<Object?, Object?>)['value']! as num).toDouble();
        return actual = (value * 15).round() / 15;
      }
      return null;
    });
    await picture(tester);
    final rect = tester.getRect(find.byType(PlayerGestureLayer));
    final gesture = await tester.startGesture(Offset(rect.right - 100, rect.center.dy));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await tester.pump();
    final afterSlop = actual;
    for (var i = 0; i < 30; i++) {
      await gesture.moveBy(const Offset(0, -2));
      await tester.pump();
      await tester.pump();
    }
    await gesture.up();
    expect(actual, greaterThan(afterSlop + 0.05));
    expect(find.text('${(actual * 100).round()}%'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('unreadable system volume never falls back to player 100 percent', (tester) async {
    var writes = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVolume') throw PlatformException(code: 'unavailable');
      if (call.method == 'setVolume') writes++;
      return null;
    });
    final key = await picture(tester);
    await key.currentState!.nudgeVolume(0.05);
    await tester.pump();
    expect(writes, 0);
    expect(find.text('100%'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('unreadable brightness cannot start a drag from an invented level', (tester) async {
    var writes = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getBrightness') throw PlatformException(code: 'unavailable');
      if (call.method == 'setBrightness') writes++;
      return null;
    });
    await picture(tester);
    final rect = tester.getRect(find.byType(PlayerGestureLayer));
    final gesture = await tester.startGesture(Offset(rect.left + 100, rect.center.dy));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await gesture.up();
    expect(writes, 0);
    expect(find.byKey(const ValueKey('gesture-level-brightness')), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));
}
