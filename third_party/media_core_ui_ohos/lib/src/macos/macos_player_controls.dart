import 'package:flutter/material.dart';

import 'package:media_core_ui/src/common/player_control_buttons.dart';
import 'package:media_core_ui/src/common/player_controls_controller.dart';
import 'package:media_core_ui/src/common/player_controls_theme.dart';
import 'package:media_core_ui/src/common/player_progress_bar.dart';
import 'package:media_core_ui/src/fluent/fluent_player_controls.dart' show FluentOverflowMenu;

/// Control set in the macOS (Big Sur and later) idiom.
///
/// What makes it read as macOS:
///
/// - the controls live in **one floating pill** at the bottom of the picture,
///   not in full-width bars: QuickTime and the system player both float their
///   chrome over the video and keep the rest untouched;
/// - the pill is heavily translucent and blurred, which is the material macOS
///   windows and their player use;
/// - everything is compact — 15 px glyphs, 3 px track, 11 px time — because a
///   viewer sits close to a large picture;
/// - the title rides *inside* the pill, truncated, instead of on its own bar;
/// - no title bar buttons: a macOS player's fullscreen is a window behaviour,
///   and its traffic lights belong to the window, not to the video.
///
/// ```dart
/// MediaCorePlayerView(handle: handle, style: PlayerControlsStyle.macos)
/// ```
final class MacosPlayerControls extends StatelessWidget {
  /// Creates the macOS control set.
  const MacosPlayerControls({
    required this.controller,
    super.key,
    this.theme,
    this.showTitle = true,
    this.showVolumeSlider = true,
    this.showMenu = true,
    this.bottomSpacing = 18,
    this.padding = EdgeInsets.zero,
  });

  /// Playback state and actions.
  final PlayerControlsController controller;

  /// Colors and metrics; defaults to [PlayerControlsTheme.macos].
  final PlayerControlsTheme? theme;

  /// Whether the title is shown inside the pill.
  final bool showTitle;

  /// Whether a volume slider is offered.
  ///
  /// On by default, because the language declares one: macOS players expose a
  /// volume control next to mute. A host that wants the pill as small as
  /// possible turns it off and keeps the mute button, which is always there.
  final bool showVolumeSlider;

  /// Whether the overflow menu is offered inside the pill.
  final bool showMenu;

  /// Distance between the pill and the bottom of the picture.
  final double bottomSpacing;

  /// Padding around the whole set.
  final EdgeInsets padding;

  PlayerControlsTheme get _theme => theme ?? const PlayerControlsTheme.macos();

  @override
  Widget build(BuildContext context) {
    final theme = _theme;

    return Material(
      type: MaterialType.transparency,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Padding(
            padding: padding,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomSpacing),
                child: PlayerControlsPanel(
                  theme: theme,
                  radius: 10,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (showTitle && controller.title != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              controller.title!,
                              style: theme.titleTextStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (controller.canSeek)
                          PlayerTimeline(controller: controller, theme: theme, hoverable: true, barHeight: 16),
                        _PillRow(
                          controller: controller,
                          theme: theme,
                          showVolumeSlider: showVolumeSlider,
                          showMenu: showMenu,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

final class _PillRow extends StatelessWidget {
  const _PillRow({
    required this.controller,
    required this.theme,
    required this.showVolumeSlider,
    required this.showMenu,
  });

  final PlayerControlsController controller;
  final PlayerControlsTheme theme;
  final bool showVolumeSlider;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    final icons = theme.icons;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PlayerIconButton(
          icon: icons.skipBack,
          theme: theme,
          tooltip: 'Back 15s',
          onPressed: () => controller.seekBy(-const Duration(seconds: 15)),
        ),
        PlayerIconButton(
          icon: icons.transportFor(playing: controller.isPlaying),
          theme: theme,
          size: theme.primaryIconSize,
          tooltip: controller.isPlaying ? 'Pause (space)' : 'Play (space)',
          onPressed: controller.togglePlayPause,
        ),
        PlayerIconButton(
          icon: icons.skipForward,
          theme: theme,
          tooltip: 'Forward 15s',
          onPressed: () => controller.seekBy(const Duration(seconds: 15)),
        ),
        const SizedBox(width: 6),
        PlayerIconButton(
          icon: icons.volumeFor(muted: controller.isMuted),
          theme: theme,
          tooltip: controller.isMuted ? 'Unmute (m)' : 'Mute (m)',
          onPressed: controller.toggleMute,
        ),
        if (showVolumeSlider)
          SizedBox(
            width: 70,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 9),
                activeTrackColor: theme.accent,
                inactiveTrackColor: theme.progressTrack,
                thumbColor: theme.progressThumb,
              ),
              child: Slider(
                value: controller.isMuted ? 0 : controller.volume.clamp(0.0, 1.0),
                onChanged: controller.setVolume,
              ),
            ),
          ),
        if (controller.actions.canEnterPip)
          PlayerIconButton(
            icon: icons.pictureInPicture,
            theme: theme,
            tooltip: 'Picture in picture',
            onPressed: controller.enterPip,
          ),
        PlayerIconButton(
          icon: icons.fullscreenFor(active: controller.actions.canExitFullscreen),
          theme: theme,
          tooltip: controller.actions.canExitFullscreen ? 'Leave fullscreen (esc)' : 'Fullscreen (f)',
          onPressed: controller.actions.canExitFullscreen
              ? controller.exitFullscreen
              : (controller.actions.canEnterFullscreen ? controller.enterFullscreen : null),
        ),
        if (showMenu) FluentOverflowMenu(controller: controller, theme: theme),
      ],
    );
  }
}
