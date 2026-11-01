# HarmonyOS dependency provenance

- Package: `connectivity_plus_harmonyos` 0.0.1, MIT.
- Source: https://pub.dev/api/archives/connectivity_plus_harmonyos-0.0.1.tar.gz
- Archive SHA256: `184138ba7c4c5c994c887e2e628f18f44dd1dfd1db97d843db7a1237177b3a5f`.
- Repository: https://github.com/Wayaer/harmony_flutter_packages/tree/main/connectivity_plus_harmonyos
- Package sources are unchanged; the example app is omitted.
- Registers the method/event channels used by connectivity_plus_platform_interface 2.x.
- The app declares `ohos.permission.GET_NETWORK_INFO` as well as INTERNET.
- Added after a real Mate 90 Pro run raised MissingPluginException from
  MethodChannelConnectivity.checkConnectivity during default quality selection.
- This reports network bearer types; it does not prove Internet reachability.
