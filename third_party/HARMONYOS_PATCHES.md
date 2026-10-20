# HarmonyOS compatibility dependencies

These local overrides belong to this HarmonyOS compatibility repository. Current target: arm64 phone; x64 simulator playback is not built or verified.

| Package directory | Source | Change |
| --- | --- | --- |
| flame_barrage_ohos | pub.dev flame_barrage 0.0.9 | Dart SDK floor backport; API retained and application compiled. |
| ffmpeg_kit_ohos | pub.dev ffmpeg_kit_extended_flutter 0.6.2 | Native execution unavailable. Hook emits no native assets; native functions throw UnsupportedError. Original generated bindings and hook retained as .reference files. Recording/remuxing is not supported. |
| flv_lzc_ohos | pinned Git 162030d642857109048a8e6858d502b8d73c754a | SDK floor backport. Android IJK backend is not registered for HarmonyOS. |
| floating_ohos | pinned Git 9a4492893ca5eee8ffac0593d1cd93b1187b6b53 | Flutter SDK floor backport. Android PiP is not enabled for HarmonyOS. |
| flex_color_picker_ohos | pub.dev flex_color_picker 3.8.0 | Explicit HarmonyOS UI switch branches. Color input/confirmation and light/dark rendering tested with production widgets. |
| syncfusion_flutter_sliders_ohos | pub.dev syncfusion_flutter_sliders 34.2.9 | Explicit HarmonyOS touch UI switch branches. |
| media_core_ui_ohos | media_core a13f5c15f90f0180a93a2ab539ea82ef55a7f7fd | Material touch controls for HarmonyOS. Relative monorepo dependency retains the same Git pin. |
| media_kit_ohos | Predidit/media-kit 803c4a27912091db6f839d48d1b984a0d9f588c7 | Detect OpenHarmony compiler despite native-assets target_os=linux; use existing OHOS bundle and matching target/sysroot for event-loop C sources. Correct bundle library name to actual libmpv.so. |
| connectivity_plus_harmonyos | pub.dev 0.0.1, SHA256 184138ba7c4c5c994c887e2e628f18f44dd1dfd1db97d843db7a1237177b3a5f | Sources unchanged, example omitted. Registers the real OHOS connectivity channels; GET_NETWORK_INFO permission added to the app. Verified past default-quality selection on device. |
| sqlite3_ohos | pub.dev sqlite3 3.7.0 | Compile official SQLite 3.53.4 C source with OpenHarmony target/sysroot; correct Windows URI-to-path conversion. Original Dart API retained. |

`compat/material_ui` re-exports Flutter 3.41 Material and localizations for the limited application API, keeping the same framework types. This is not a full reimplementation of the newer standalone Material library.

Native bundle SHA256 and SQLite source provenance are documented in the corresponding package OHOS_COMPAT.md files. The application build entrypoint copies the installed OpenHarmony SDK C++ shared runtime into generated/ignored native library output. SDK, dependency resolution, native compilation, signing, and device acceptance remain separate evidence stages.

The pinned Flutter OH asset-bundle correction is documented in [tool/patches/README.md](../tool/patches/README.md). Real-device playback and remaining limitations are recorded in [docs/HARMONYOS_PORT.md](../docs/HARMONYOS_PORT.md).

## Playback gestures and recording

- `screen_brightness_ohos` 2.1.4: official pub package, vendored with numeric/context/callback fixes; provenance in its `OHOS_COMPAT.md`.
- `volume_controller_ohos`: preserves the public 3.5.0 Dart API, adds CPF-Flutter OH source at `518ee2c810901a93a4d12b04673af06230780149`; provenance in its `OHOS_COMPAT.md`.
- Native recording uses official OHPM `@ohos/ffmpeg-kit` 1.0.0. HAR integrity from registry verified before integration; archive SHA-256 `f72e1ea8343bc30de25d069458ec2f63d5bf26ae0000d7ef075069d0631faf8f`. No HAR/native binary is committed. Package license files are retained by OHPM; upstream source https://gitcode.com/CPF-ApplicationTPC/ohos_ffmpeg_kit. The vendored desktop FFmpeg FFI bindings remain disabled on OH; this is a separate native MethodChannel session backend.

录制引擎的 AKI C++ 桥接运行库固定为 `@ohos/aki` `1.2.25`（工程级 `overrides`），不沿用包中 `^1.2.25` 自动升级到 1.3.x 的解析结果。升级原生桥接依赖前必须重新实机验证会话创建、停止及回放。
