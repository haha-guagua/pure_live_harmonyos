import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart' show IconData, Icons;

/// The glyphs a control set draws.
///
/// Icons are the one part of a design language a host may already own: an app
/// that uses `fluent_ui`, `macos_ui` or `yaru` has that package's icon font
/// loaded and expects its player to match. So the set is data, not hardcoded
/// glyphs — each style ships a faithful default and a host can replace it:
///
/// ```dart
/// PlayerControlsTheme.fluent(icons: myFluentIcons)
/// ```
///
/// Responsibilities:
///
/// - name every glyph a control bar can need
/// - provide faithful defaults per design language
///
/// It does not:
///
/// - draw anything
/// - know which controls a style shows
final class PlayerControlIcons {
  /// Creates an icon set.
  const PlayerControlIcons({
    required this.play,
    required this.pause,
    required this.stop,
    required this.skipBack,
    required this.skipForward,
    required this.rewind,
    required this.forward,
    required this.volumeUp,
    required this.volumeMuted,
    required this.fullscreen,
    required this.exitFullscreen,
    required this.pictureInPicture,
    required this.floatingWindow,
    required this.screenshot,
    required this.loop,
    required this.speed,
    required this.more,
    required this.settings,
  });

  /// Apple's SF-like set, shipped with Flutter as Cupertino icons.
  ///
  /// The skip glyphs for 10/15/30/45 seconds exist in this font; the control
  /// sets pass the closest one, so the set accepts an explicit icon for the
  /// configured step:
  /// [`rewind`] and [`forward`] are the generic fallbacks.
  const PlayerControlIcons.cupertino()
    : play = CupertinoIcons.play_fill,
      pause = CupertinoIcons.pause_fill,
      stop = CupertinoIcons.stop_fill,
      skipBack = CupertinoIcons.gobackward,
      skipForward = CupertinoIcons.goforward,
      rewind = CupertinoIcons.gobackward_15,
      forward = CupertinoIcons.goforward_15,
      volumeUp = CupertinoIcons.speaker_2_fill,
      volumeMuted = CupertinoIcons.speaker_slash_fill,
      fullscreen = CupertinoIcons.arrow_up_left_arrow_down_right,
      exitFullscreen = CupertinoIcons.arrow_down_right_arrow_up_left,
      pictureInPicture = CupertinoIcons.rectangle_on_rectangle_angled,
      floatingWindow = CupertinoIcons.rectangle_on_rectangle,
      screenshot = CupertinoIcons.camera,
      loop = CupertinoIcons.repeat,
      speed = CupertinoIcons.speedometer,
      more = CupertinoIcons.ellipsis,
      settings = CupertinoIcons.gear;

  /// Material glyphs.
  const PlayerControlIcons.material()
    : play = Icons.play_arrow,
      pause = Icons.pause,
      stop = Icons.stop,
      skipBack = Icons.skip_previous,
      skipForward = Icons.skip_next,
      rewind = Icons.replay_10,
      forward = Icons.forward_10,
      volumeUp = Icons.volume_up,
      volumeMuted = Icons.volume_off,
      fullscreen = Icons.fullscreen,
      exitFullscreen = Icons.fullscreen_exit,
      pictureInPicture = Icons.picture_in_picture_alt_outlined,
      floatingWindow = Icons.picture_in_picture_outlined,
      screenshot = Icons.photo_camera_outlined,
      loop = Icons.repeat,
      speed = Icons.speed,
      more = Icons.more_vert,
      settings = Icons.settings_outlined;

  /// Fluent-style glyphs.
  ///
  /// The Fluent icon font ships with `fluent_ui`; the defaults here are the
  /// closest Material shapes (thin outlined strokes, which is what makes a
  /// Windows 11 toolbar read as Fluent). Replace with `FluentIcons` when the
  /// host already depends on that package.
  const PlayerControlIcons.fluent()
    : play = Icons.play_arrow_outlined,
      pause = Icons.pause_outlined,
      stop = Icons.stop_outlined,
      skipBack = Icons.skip_previous_outlined,
      skipForward = Icons.skip_next_outlined,
      rewind = Icons.replay_10_outlined,
      forward = Icons.forward_10_outlined,
      volumeUp = Icons.volume_up_outlined,
      volumeMuted = Icons.volume_off_outlined,
      fullscreen = Icons.fullscreen_outlined,
      exitFullscreen = Icons.fullscreen_exit_outlined,
      pictureInPicture = Icons.picture_in_picture_alt_outlined,
      floatingWindow = Icons.picture_in_picture_outlined,
      screenshot = Icons.photo_camera_outlined,
      loop = Icons.repeat_outlined,
      speed = Icons.speed_outlined,
      more = Icons.more_horiz,
      settings = Icons.settings_outlined;

  /// macOS glyphs: compact, mostly filled, like the system player.
  const PlayerControlIcons.macos()
    : play = CupertinoIcons.play_fill,
      pause = CupertinoIcons.pause_fill,
      stop = CupertinoIcons.stop_fill,
      skipBack = CupertinoIcons.gobackward,
      skipForward = CupertinoIcons.goforward,
      rewind = CupertinoIcons.gobackward_15,
      forward = CupertinoIcons.goforward_15,
      volumeUp = CupertinoIcons.speaker_2_fill,
      volumeMuted = CupertinoIcons.speaker_slash_fill,
      fullscreen = CupertinoIcons.arrow_up_left_arrow_down_right,
      exitFullscreen = CupertinoIcons.arrow_down_right_arrow_up_left,
      pictureInPicture = CupertinoIcons.rectangle_on_rectangle_angled,
      floatingWindow = CupertinoIcons.rectangle_on_rectangle,
      screenshot = CupertinoIcons.camera,
      loop = CupertinoIcons.repeat,
      speed = CupertinoIcons.speedometer,
      more = CupertinoIcons.ellipsis,
      settings = CupertinoIcons.gear;

  /// Yaru glyphs.
  ///
  /// Yaru ships its own icon set with the `yaru` package; these are the closest
  /// Material shapes. Replace with `YaruIcons` when the host depends on it.
  const PlayerControlIcons.yaru()
    : play = Icons.play_arrow_rounded,
      pause = Icons.pause_rounded,
      stop = Icons.stop_rounded,
      skipBack = Icons.skip_previous_rounded,
      skipForward = Icons.skip_next_rounded,
      rewind = Icons.replay_10_rounded,
      forward = Icons.forward_10_rounded,
      volumeUp = Icons.volume_up_rounded,
      volumeMuted = Icons.volume_off_rounded,
      fullscreen = Icons.fullscreen_rounded,
      exitFullscreen = Icons.fullscreen_exit_rounded,
      pictureInPicture = Icons.picture_in_picture_alt_rounded,
      floatingWindow = Icons.picture_in_picture_rounded,
      screenshot = Icons.camera_alt_outlined,
      loop = Icons.repeat_rounded,
      speed = Icons.speed_rounded,
      more = Icons.more_vert,
      settings = Icons.settings;

  /// Soft-UI glyphs: rounded and monochrome, so they melt into the surface.
  const PlayerControlIcons.neumorphic()
    : play = Icons.play_arrow_rounded,
      pause = Icons.pause_rounded,
      stop = Icons.stop_rounded,
      skipBack = Icons.replay_10_rounded,
      skipForward = Icons.forward_10_rounded,
      rewind = Icons.replay_10_rounded,
      forward = Icons.forward_10_rounded,
      volumeUp = Icons.volume_up_rounded,
      volumeMuted = Icons.volume_off_rounded,
      fullscreen = Icons.fullscreen_rounded,
      exitFullscreen = Icons.fullscreen_exit_rounded,
      pictureInPicture = Icons.picture_in_picture_alt_rounded,
      floatingWindow = Icons.picture_in_picture_rounded,
      screenshot = Icons.camera_alt_rounded,
      loop = Icons.repeat_rounded,
      speed = Icons.speed_rounded,
      more = Icons.more_horiz_rounded,
      settings = Icons.settings_rounded;

  /// Primary transport glyph while playing.
  final IconData play;

  /// Primary transport glyph while paused.
  final IconData pause;

  /// Stop.
  final IconData stop;

  /// "Previous" / generic backward jump.
  final IconData skipBack;

  /// "Next" / generic forward jump.
  final IconData skipForward;

  /// Backward jump of the configured step.
  final IconData rewind;

  /// Forward jump of the configured step.
  final IconData forward;

  /// Audible output.
  final IconData volumeUp;

  /// Muted output.
  final IconData volumeMuted;

  /// Enter fullscreen.
  final IconData fullscreen;

  /// Leave fullscreen.
  final IconData exitFullscreen;

  /// Picture-in-picture.
  final IconData pictureInPicture;

  /// Floating in-app window.
  final IconData floatingWindow;

  /// Capture the current frame.
  final IconData screenshot;

  /// Repeat playback.
  final IconData loop;

  /// Playback rate.
  final IconData speed;

  /// Overflow menu.
  final IconData more;

  /// Settings.
  final IconData settings;

  /// Creates a set with some glyphs replaced.
  ///
  /// The point of the set being data: a host that already loads Fluent,
  /// macOS or Yaru icons swaps them in without forking a control bar.
  PlayerControlIcons copyWith({
    IconData? play,
    IconData? pause,
    IconData? stop,
    IconData? skipBack,
    IconData? skipForward,
    IconData? rewind,
    IconData? forward,
    IconData? volumeUp,
    IconData? volumeMuted,
    IconData? fullscreen,
    IconData? exitFullscreen,
    IconData? pictureInPicture,
    IconData? floatingWindow,
    IconData? screenshot,
    IconData? loop,
    IconData? speed,
    IconData? more,
    IconData? settings,
  }) {
    return PlayerControlIcons(
      play: play ?? this.play,
      pause: pause ?? this.pause,
      stop: stop ?? this.stop,
      skipBack: skipBack ?? this.skipBack,
      skipForward: skipForward ?? this.skipForward,
      rewind: rewind ?? this.rewind,
      forward: forward ?? this.forward,
      volumeUp: volumeUp ?? this.volumeUp,
      volumeMuted: volumeMuted ?? this.volumeMuted,
      fullscreen: fullscreen ?? this.fullscreen,
      exitFullscreen: exitFullscreen ?? this.exitFullscreen,
      pictureInPicture: pictureInPicture ?? this.pictureInPicture,
      floatingWindow: floatingWindow ?? this.floatingWindow,
      screenshot: screenshot ?? this.screenshot,
      loop: loop ?? this.loop,
      speed: speed ?? this.speed,
      more: more ?? this.more,
      settings: settings ?? this.settings,
    );
  }

  /// The fullscreen glyph for a state.
  IconData fullscreenFor({required bool active}) => active ? exitFullscreen : fullscreen;

  /// The volume glyph for a state.
  IconData volumeFor({required bool muted}) => muted ? volumeMuted : volumeUp;

  /// The transport glyph for a state.
  IconData transportFor({required bool playing}) => playing ? pause : play;
}
