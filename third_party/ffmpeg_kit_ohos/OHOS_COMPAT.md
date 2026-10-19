# HarmonyOS compatibility checkpoint

Source: pub.dev ffmpeg_kit_extended_flutter 0.6.2, archive SHA-256 verified before extraction.
The original source and license remain in this directory. The SDK lower bound
has been adjusted for validation on Dart 3.11.5 / Flutter OH 3.41. This is a
backport candidate, not evidence that native HarmonyOS functionality works.
Compilation, affected tests and native capability handling remain required.

This override is scoped to the HarmonyOS compatibility workspace. Native FFmpeg is unavailable: the build hook emits no assets, and native entrypoints throw UnsupportedError. Struct layouts and API signatures are preserved. Original bindings/hook are retained as .reference files. No successful recording, remuxing, or FFmpeg runtime support is claimed. The normal application dependency profile is unchanged.
