# HarmonyOS compatibility sources

- Public Dart API: volume_controller 3.5.0 (upstream MIT license retained).
- OH implementation: CPF-Flutter/fluttertpc_volume_controller, tag 3.4.0-ohos-1.0.0, commit 518ee2c810901a93a4d12b04673af06230780149 (Apache-2.0 file headers retained).
- Local changes: native getVolume returns a number; writes propagate failures; listener unregisters its own callback and honors fetchInitialVolume; Dart accepts int/double numeric channel values.
- Runtime app volume is separate from MPV gain; opening a room adopts the current native app-volume percentage.

The original system-volume setter requires privileged ACCESS_NOTIFICATION_POLICY. OH uses the ordinary-app public AudioVolumeManager.get/setAppVolumePercentage APIs (API 19+) instead. This controls this application's sound; hardware buttons keep controlling global media volume. Writes are serialized, actual quantized values are reported, and only our own observers are removed. No protected system-volume permission is requested.
