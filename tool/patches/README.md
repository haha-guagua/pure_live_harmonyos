# Flutter OH native-assets bundle correction

Target SDK: `3.41.10-ohos-1.0.1`, framework commit
`adaf911c35c9136a7d18fc424d714c9ec7724e60`.

A real HarmonyOS API26 run failed to initialize MPV with
`No asset with id 'package:media_kit/libmpv' found. No available native assets.`
The generated `native_assets.json` correctly listed the three OHOS libraries,
but the signed HAP omitted `NativeAssetsManifest.json`.

The patch adds the same `copyAssets(additionalContent: ...)` mapping already
used by this pinned SDK's Android/Linux targets. It includes Flutter's
`devfs.dart` import and changes only the OHOS asset bundle target. The code
remains under Flutter's BSD-style license. It is independently reproduced from
those local upstream targets rather than copied from an unverified patch.

References:

- https://dart.googlesource.com/external/github.com/flutter/flutter/+/4aa2caef20a9d4c930a53ad04f0791e907b63815
- Related OHOS packaging report: https://gitcode.com/fangxiang_1995/flutter-ohos-native-assets/tree/main
- Player adaptation history: https://github.com/media-kit/media-kit/pull/1326

`build_harmonyos.ps1` invokes `apply_harmonyos_sdk_patch.ps1` within the shared
heavy-task lease before Flutter runs. It checks the complete original source
SHA256, applies the minimal change, verifies the resulting SHA256, and backs
up the original source and Flutter tool snapshot/stamp before invalidating the
snapshot. The standard Flutter bootstrap then rebuilds the tool.

Backup directory is a sibling of the SDK:
`FlutterOH-compat-backups/native-assets-3.41.10-ohos-1.0.1/`.
Restore its `ohos.dart` to `packages/flutter_tools/lib/src/build_system/targets/`
and its original snapshot/stamp to `bin/cache/` to revert the toolchain fix.
The application build entrypoint will apply it again while this compatibility
branch requires the correction.

Before source SHA256: `feaa1158fdc3cb365349c103f7c69ac549fa2813e37179dad4c8c95875b99be9`.
After source SHA256: `e3f23b9cdfbe6a35a45d6db1a18f9edb8acffe50ebe389cb4b1e280e0aeea70b`.
