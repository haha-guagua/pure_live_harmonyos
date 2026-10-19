import 'package:flutter_test/flutter_test.dart';

import 'package:flame_barrage/src/core/barrage_timeline.dart';
import 'package:flame_barrage/src/core/engine_clock.dart';
import 'package:flame_barrage/src/model/barrage/barrage_item.dart';

BarrageItem _item(String content, {Duration? at, String? id}) {
  return BarrageItem(content: content, at: at, id: id);
}

void main() {
  group('BarrageTimeline', () {
    test('loads only timed items, in time order', () {
      final timeline = BarrageTimeline()
        ..load([
          _item('late', at: const Duration(seconds: 30)),
          _item('untimed'),
          _item('early', at: const Duration(seconds: 5)),
          _item('middle', at: const Duration(seconds: 12)),
        ]);

      // An untimed item is a live message; scheduling it at zero would fire
      // the whole list in the first frame after a seek to the start.
      expect(timeline.length, 3);
      expect(
        timeline.dueBy(const Duration(seconds: 60)).map((i) => i.content),
        ['early', 'middle', 'late'],
      );
    });

    test('releases each item once, when the position reaches it', () {
      final timeline = BarrageTimeline()
        ..load([
          _item('a', at: const Duration(seconds: 1)),
          _item('b', at: const Duration(seconds: 2)),
          _item('c', at: const Duration(seconds: 3)),
        ]);

      expect(
        timeline.dueBy(const Duration(milliseconds: 1500)).map((i) => i.content),
        ['a'],
      );
      expect(timeline.remaining, 2);

      // The same position again releases nothing new.
      expect(timeline.dueBy(const Duration(milliseconds: 1500)), isEmpty);

      expect(
        timeline.dueBy(const Duration(seconds: 3)).map((i) => i.content),
        ['b', 'c'],
      );
      expect(timeline.hasUpcoming, isFalse);
    });

    test('an empty timeline answers without allocating', () {
      final timeline = BarrageTimeline();

      expect(timeline.isEmpty, isTrue);
      expect(timeline.hasUpcoming, isFalse);
      expect(timeline.dueBy(const Duration(seconds: 10)), isEmpty);
      expect(timeline.remaining, 0);
    });

    test('a timeline waiting for its next moment is upcoming work', () {
      final timeline = BarrageTimeline()
        ..load([_item('a', at: const Duration(minutes: 5))]);

      // Nothing has been released, so the dispatch queue is empty — but the
      // engine must not idle-pause, or the clock never reaches five minutes.
      expect(timeline.hasUpcoming, isTrue);
      expect(timeline.dueBy(Duration.zero), isEmpty);
      expect(timeline.hasUpcoming, isTrue);
    });

    test('seeking forward skips what has already gone by', () {
      final timeline = BarrageTimeline()
        ..load([
          _item('a', at: const Duration(seconds: 1)),
          _item('b', at: const Duration(seconds: 2)),
          _item('c', at: const Duration(seconds: 3)),
        ]);

      timeline.seekTo(const Duration(seconds: 2));

      expect(timeline.remaining, 1);
      expect(
        timeline.dueBy(const Duration(seconds: 4)).map((i) => i.content),
        ['c'],
      );
    });

    test('seeking backward replays', () {
      final timeline = BarrageTimeline()
        ..load([
          _item('a', at: const Duration(seconds: 1)),
          _item('b', at: const Duration(seconds: 2)),
        ]);

      expect(timeline.dueBy(const Duration(seconds: 5)), hasLength(2));
      expect(timeline.hasUpcoming, isFalse);

      timeline.seekTo(Duration.zero);

      expect(timeline.remaining, 2);
      expect(
        timeline.dueBy(const Duration(seconds: 5)).map((i) => i.content),
        ['a', 'b'],
      );
    });

    test('a message at exactly the seek position is already past', () {
      final timeline = BarrageTimeline()
        ..load([_item('a', at: const Duration(seconds: 2))]);

      timeline.seekTo(const Duration(seconds: 2));

      expect(timeline.remaining, 0);
    });

    test('retraction removes an unreleased message and keeps the cursor', () {
      final timeline = BarrageTimeline()
        ..load([
          _item('gone', at: const Duration(seconds: 1), id: 'm1'),
          _item('kept', at: const Duration(seconds: 2), id: 'm2'),
          _item('also kept', at: const Duration(seconds: 3), id: 'm3'),
        ]);

      // Release the first, then retract the second: only the unreleased tail
      // is the timeline's to remove, and the cursor restarts on what is left.
      timeline.dueBy(const Duration(seconds: 1));
      final removed = timeline.retractWhere((item) => item.id == 'm2');

      expect(removed, 1);
      expect(timeline.remaining, 1);
      expect(
        timeline.dueBy(const Duration(seconds: 10)).map((i) => i.content),
        ['also kept'],
      );
    });

    test('retracting something already shown reports nothing removed', () {
      final timeline = BarrageTimeline()
        ..load([_item('a', at: const Duration(seconds: 1), id: 'm1')]);

      timeline.dueBy(const Duration(seconds: 5));

      expect(timeline.retractWhere((item) => item.id == 'm1'), 0);
    });

    test('clear empties the timeline', () {
      final timeline = BarrageTimeline()
        ..load([_item('a', at: const Duration(seconds: 1))])
        ..clear();

      expect(timeline.isEmpty, isTrue);
      expect(timeline.dueBy(const Duration(seconds: 9)), isEmpty);
    });

    test('loading again replaces the previous timeline', () {
      final timeline = BarrageTimeline()
        ..load([_item('old', at: const Duration(seconds: 1))])
        ..load([_item('new', at: const Duration(seconds: 1))]);

      expect(timeline.length, 1);
      expect(
        timeline.dueBy(const Duration(seconds: 2)).single.content,
        'new',
      );
    });
  });

  group('EngineClock.seekToMs', () {
    test('moves the logical position a timeline is read against', () {
      final clock = EngineClock();

      clock.seekToMs(90000);

      expect(clock.now(), 90000);
      expect(clock.nowPrecise(), 90000.0);
    });

    test('clamps a negative seek to zero', () {
      final clock = EngineClock()..seekToMs(-500);

      expect(clock.nowPrecise(), 0.0);
    });

    test('keeps advancing at the current rate after a seek', () {
      final clock = EngineClock()
        ..scale = 2.0
        ..seekToMs(1000)
        ..tick(0.5);

      // One half-second step at 2× adds a second of media time.
      expect(clock.nowPrecise(), 2000.0);
    });

    test('a paused seek stays paused', () {
      final clock = EngineClock()
        ..pause()
        ..seekToMs(1000)
        ..tick(1.0);

      expect(clock.isPaused, isTrue);
      expect(clock.nowPrecise(), 1000.0);
    });
  });
}
