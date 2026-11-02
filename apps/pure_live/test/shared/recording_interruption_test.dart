import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_core/live_core.dart';
import 'package:live_media/live_media.dart';
import 'package:live_player/live_player.dart';
import 'package:pure_live/app/services.dart';
import 'package:pure_live/shared/record/recording_player_page.dart';
import 'package:pure_live/shared/remote/playback_target.dart';

import '../features/live_play/live_play_support.dart';
import '../support.dart';

final class _TrackedEngine implements PlayerEngine {
  new(this.name, this.timeline);

  final String name;
  final List<String> timeline;
  final List<EngineMedia> opens = [];
  final StreamController<EngineEvent> _events = StreamController.broadcast(sync: true);
  Completer<void>? pauseGate;
  Completer<void>? disposeGate;

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  bool get reportsFrames => false;

  @override
  Future<void> open(EngineMedia media) async {
    opens.add(media);
    _events
      ..add(const EngineBuffering(buffering: false))
      ..add(const EnginePlaying(playing: true));
  }

  @override
  Future<void> pause() async {
    timeline.add('$name:pause');
    await pauseGate?.future;
  }

  @override
  Future<void> play() async {
    timeline.add('$name:play');
    _events.add(const EnginePlaying(playing: true));
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setAudioOnly({required bool enabled}) async {}

  @override
  Future<void> dispose() async {
    timeline.add('$name:dispose-start');
    await disposeGate?.future;
    await _events.close();
    timeline.add('$name:disposed');
  }
}

PlaybackSession _session(_TrackedEngine engine) => PlaybackSession(engine: () async => engine, opener: MediaOpener());

Future<void> _drain(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pump();
}

void main() {
  for (final scenario in ['playing', 'paused', 'removed', 'dismissed', 'idle', 'stopped']) {
    testWidgets('recording playback interrupts a $scenario live room without overlapping players', (tester) async {
      await tester.runAsync(loadStrings);
      final services = (await tester.runAsync(testServices))!;
      final events = <String>[];
      final liveEngine = _TrackedEngine('live', events);
      final recordingEngine = _TrackedEngine('recording', events);
      final live = _session(liveEngine);
      var resumes = 0;
      final target = playbackRemoteTarget(
        // The recording centre covers the live route; it is still audible.
        available: () => false,
        room: liveRoom,
        session: () => live,
        refresh: () async {
          resumes++;
          await live.resume();
        },
        volume: live.setVolume,
        navigation: {},
      );
      services.remoteControl.register(target);
      if (scenario != 'idle') {
        await tester.runAsync(
          () => live.open(
            PlaybackRequest(
              site: SiteIds.bilibili,
              plan: PlaybackPlan.of(LivePlayUrlResolution(urls: const ['https://stream.example/live.flv'])),
            ),
          ),
        );
      }
      if (scenario == 'paused') await tester.runAsync(live.pause);
      if (scenario == 'stopped') await tester.runAsync(live.stop);
      events.clear();
      final pauseGate = scenario == 'playing' || scenario == 'dismissed' ? Completer<void>() : null;
      final disposeGate = Completer<void>();
      liveEngine.pauseGate = pauseGate;
      recordingEngine.disposeGate = disposeGate;
      addTearDown(() async {
        if (pauseGate != null && !pauseGate.isCompleted) pauseGate.complete();
        if (!disposeGate.isCompleted) disposeGate.complete();
        await tester.pumpWidget(const SizedBox.shrink());
        await _drain(tester);
        services.remoteControl.unregister(target);
        await tester.runAsync(live.dispose);
        await tester.runAsync(services.close);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(services),
            playbackSessionFactoryProvider.overrideWithValue(({config}) => _session(recordingEngine)),
          ],
          child: const MaterialApp(home: RecordingPlayerPage(files: ['/recording/a.mp4'], index: 0)),
        ),
      );
      await _drain(tester);
      if (pauseGate != null) {
        expect(events, contains('live:pause'));
        expect(recordingEngine.opens, isEmpty, reason: 'wait for native pause before opening the recording');
        if (scenario == 'dismissed') {
          await tester.pumpWidget(const SizedBox.shrink());
          await _drain(tester);
          expect(resumes, 0);
          pauseGate.complete();
          await _drain(tester);
          expect(recordingEngine.opens, isEmpty);
          expect(resumes, 1);
          await tester.runAsync(live.dispose);
          return;
        }
        pauseGate.complete();
        await _drain(tester);
      }
      expect(recordingEngine.opens, hasLength(1));
      final expectedLive = switch (scenario) {
        'idle' => PlaybackStatus.idle,
        'stopped' => PlaybackStatus.stopped,
        _ => PlaybackStatus.paused,
      };
      expect(live.state.status, expectedLive);
      if (scenario == 'paused') expect(events, isNot(contains('live:pause')));
      if (scenario == 'removed') services.remoteControl.unregister(target);

      await tester.pumpWidget(const SizedBox.shrink());
      await _drain(tester);
      expect(resumes, 0, reason: 'the recording must release its player before the live room can resume');
      disposeGate.complete();
      await _drain(tester);
      expect(resumes, scenario == 'playing' ? 1 : 0);
      if (scenario == 'playing') {
        expect(events.indexOf('recording:disposed'), lessThan(events.indexOf('live:play')));
      } else {
        expect(live.state.status, expectedLive);
      }
      await tester.runAsync(live.dispose);
    });
  }
}
