# Desktop native API boundary

Source: pub.dev cnativeapi 0.5.2, original license retained. The hook skips compilation only when the real OpenHarmony compiler/target is selected: tray/window APIs are guarded off on the OHOS phone. Normal Windows/Linux/macOS hooks and native bindings are preserved, including those used by host tests. This does not implement desktop APIs on a phone or substitute Linux binaries.
