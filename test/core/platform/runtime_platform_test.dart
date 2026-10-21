import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/core/platform/runtime_platform.dart';

void main() {
  test('HarmonyOS uses mobile UI without enabling Android/iOS recorder startup', () {
    const platform = RuntimePlatform('ohos');

    expect(platform.isOhos, isTrue);
    expect(platform.isMobile, isTrue);
    expect(platform.isDesktop, isFalse);
    expect(platform.supportsRecorderPrewarm, isFalse);
    expect(platform.supportsSystemMediaSession, isFalse);
    expect(platform.supportsSystemVolume, isFalse);
  });

  for (final os in ['android', 'ios']) {
    test('$os keeps mobile UI and recorder prewarming', () {
      final platform = RuntimePlatform(os);

      expect(platform.isOhos, isFalse);
      expect(platform.isMobile, isTrue);
      expect(platform.isDesktop, isFalse);
      expect(platform.supportsRecorderPrewarm, isTrue);
      expect(platform.supportsSystemMediaSession, isTrue);
      expect(platform.supportsSystemVolume, isTrue);
    });
  }

  for (final os in ['windows', 'linux', 'macos']) {
    test('$os keeps desktop UI without mobile recorder prewarming', () {
      final platform = RuntimePlatform(os);

      expect(platform.isOhos, isFalse);
      expect(platform.isMobile, isFalse);
      expect(platform.isDesktop, isTrue);
      expect(platform.supportsRecorderPrewarm, isFalse);
      expect(platform.supportsSystemMediaSession, isTrue);
      expect(platform.supportsSystemVolume, isFalse);
    });
  }

  test('unknown OS does not inherit native plugin support', () {
    const platform = RuntimePlatform('unknown');

    expect(platform.isOhos, isFalse);
    expect(platform.isMobile, isFalse);
    expect(platform.isDesktop, isFalse);
    expect(platform.supportsRecorderPrewarm, isFalse);
    expect(platform.supportsSystemMediaSession, isFalse);
    expect(platform.supportsSystemVolume, isFalse);
  });
}
