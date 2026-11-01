# FFmpeg API and HarmonyOS backend

Vendored pub.dev ffmpeg_kit_extended_flutter 1.0.0 with its original license. The hook skips desktop bundles only for OHOS. Actual OHOS recording uses the separate native session bridge and official OHPM @ohos/ffmpeg-kit 1.0.0, with AKI pinned to1.2.25 as in the previous real-device repair. The Dart FFI FFmpegKit 0.11.2 ABI must never be linked to the OHPM HAR, which has its own API. Other host hooks retain their original behavior.
