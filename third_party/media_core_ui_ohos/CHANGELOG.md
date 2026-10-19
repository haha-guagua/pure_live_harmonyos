## 0.1.0

Initial release.

- One line to start: `MediaCorePlayerView` = video surface + controls + pinch zoom + screenshot entry point, so hosts do not have to assemble UI.
- Six design languages: material, cupertino, fluent, macos, yaru and neumorphic share one control layer (state, actions, theme tokens), which is why all six behave identically and differ only in looks.
- Resolved per platform: Android→material, iOS→cupertino, macOS→macos, Windows→fluent, Linux→yaru; a style can also be forced with `PlayerControlsStyle`.
- The lower-level parts are public too: `PlayerControlsController` (state and actions) + `PlayerControlsTheme` (tokens) + `MediaPlayerView` (video only), which together are a custom control set.
- Theme and skin: progress track, thumb shape (`PlayerProgressTrack` / `PlayerProgressThumbShape`), button skin (`PlayerControlButtonSkin`) and double-tap action (`PlayerDoubleTapAction`) are all replaceable.
