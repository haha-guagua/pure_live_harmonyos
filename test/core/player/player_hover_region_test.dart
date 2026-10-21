import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/core/player/presentation/player_hover_region.dart';

void main() {
  testWidgets('mobile synthetic hover does not consume the reveal tap or reopen hidden bars', (tester) async {
    var visible = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            void reveal() => setState(() => visible = true);
            return Center(
              child: SizedBox(
                width: 400,
                height: 240,
                child: PlayerHoverRegion(
                  enabled: false,
                  onHover: reveal,
                  onExit: reveal,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => visible = !visible),
                    child: Text(visible ? 'visible' : 'hidden'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    final center = tester.getCenter(find.byType(PlayerHoverRegion));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(center);
    await tester.pump();
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 350));
    expect(visible, isTrue, reason: 'One tap reveals both bars even when OH emits a hover first.');
    await tester.pump(const Duration(seconds: 1));
    expect(visible, isTrue);
    await tester.tapAt(center);
    await tester.pump();
    expect(visible, isFalse, reason: 'The next tap hides the bars.');
    await mouse.moveTo(Offset.zero);
    await mouse.removePointer();
    await tester.pump();
    expect(visible, isFalse, reason: 'Synthetic mouse exit must not undo a touch hide.');
  });

  testWidgets('desktop keeps hover and exit callbacks', (tester) async {
    var hovers = 0;
    var exits = 0;
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 400,
          height: 240,
          child: PlayerHoverRegion(
            enabled: true,
            onHover: () => hovers++,
            onExit: () => exits++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(PlayerHoverRegion)));
    await tester.pump();
    expect(hovers, greaterThan(0));
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(exits, 1);
    await mouse.removePointer();
  });
}
