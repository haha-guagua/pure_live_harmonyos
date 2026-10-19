/// Runtime OS classification shared by layout and platform initialization.
///
/// Flutter OH reports `ohos`; treating it as Android would also select Android
/// native plugins, which are not implementations for HarmonyOS.
class RuntimePlatform {
  const RuntimePlatform(this.operatingSystem);

  final String operatingSystem;

  bool get isOhos => operatingSystem == 'ohos';

  bool get isDesktop => operatingSystem == 'windows' || operatingSystem == 'linux' || operatingSystem == 'macos';

  bool get isMobile => operatingSystem == 'android' || operatingSystem == 'ios' || isOhos;

  // The current FFmpegKit integration has only been enabled for Android/iOS.
  // Mobile UI support must not implicitly opt a new OS into native prewarming.
  bool get supportsRecorderPrewarm => operatingSystem == 'android' || operatingSystem == 'ios';

  // audio_service has no HarmonyOS implementation in the current dependency set.
  bool get supportsSystemMediaSession => operatingSystem == 'android' || operatingSystem == 'ios' || isDesktop;
}
