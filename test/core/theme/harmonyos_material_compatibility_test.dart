import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:pure_live/core/theme/dynamic_color_adapter.dart';
import 'package:pure_live/features/settings/widgets/app_color_picker_dialog.dart';

void main() {
  final touchPlatform = TargetPlatform.values.firstWhere(
    (platform) => platform.name == 'ohos',
    orElse: () => TargetPlatform.android,
  );
  test('custom Material palette preserves user-selected roles', () {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xff1565c0)).copyWith(
      primary: const Color(0xff123456),
      secondary: const Color(0xff654321),
      surfaceContainerHighest: const Color(0xff223344),
      primaryFixed: const Color(0xffabcdef),
    );
    final converted = toMaterialUiColorScheme(scheme);
    expect(converted.primary, scheme.primary);
    expect(converted.secondary, scheme.secondary);
    expect(converted.surfaceContainerHighest, scheme.surfaceContainerHighest);
    expect(converted.primaryFixed, scheme.primaryFixed);
  });

  for (final brightness in Brightness.values) {
    final theme = ThemeData(
      brightness: brightness,
      platform: touchPlatform,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: brightness),
    );
    testWidgets('$brightness theme bridge retains HarmonyOS and dark/light mode', (tester) async {
      material.ThemeData? observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: MaterialUiThemeBridge(
            child: Builder(
              builder: (context) {
                observed = material.Theme.of(context);
                return const Scaffold(body: Text('Theme probe'));
              },
            ),
          ),
        ),
      );
      expect(observed!.brightness, brightness);
      expect(observed!.platform, touchPlatform);
      expect(observed!.colorScheme.primary, theme.colorScheme.primary);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$brightness color picker previews and confirms custom RGB on HarmonyOS', (tester) async {
      Color? selected;
      bool? accepted;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: [material.GlobalMaterialLocalizations.delegate],
          home: MaterialUiThemeBridge(
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    unawaited(
                      showAppColorPickerDialog(
                        context: context,
                        initialColor: Colors.indigo,
                        onColorChanged: (color) => selected = color,
                        title: 'Color probe',
                        labels: buildAppColorPickerLabels(
                          translate: (key) => key,
                          isChinese: false,
                          enableOpacity: false,
                        ),
                        customColorSwatchesAndNames: const {},
                      ).then((result) => accepted = result),
                    );
                  },
                  child: const Text('Open picker'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();
      expect(find.text('Color probe'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byKey(const ValueKey('app-color-picker-code')), '#AABBCC');
      await tester.pump();
      expect(selected, const Color(0xffaabbcc));
      await tester.ensureVisible(find.byKey(const ValueKey('app-color-picker-confirm')));
      await tester.tap(find.byKey(const ValueKey('app-color-picker-confirm')));
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
      expect(selected, const Color(0xffaabbcc));
      expect(tester.takeException(), isNull);
    });
  }
}
