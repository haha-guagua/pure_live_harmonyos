import 'package:flutter/widgets.dart';

import 'package:media_core_ui/src/common/player_control_icons.dart';
import 'package:media_core_ui/src/common/player_controls_style.dart';

/// How a control button answers the pointer.
///
/// The reaction is as much a part of a design language as the color: Material
/// ripples, Apple dips in opacity, Fluent and Yaru highlight on hover, and soft
/// UI presses the button *into* the surface.
enum PlayerControlButtonSkin {
  /// Material ink ripple.
  ripple,

  /// Apple-style opacity dip, no background change.
  translucent,

  /// A background highlight while hovered or pressed.
  hover,

  /// Flat with a hairline border (GTK/Yaru).
  flat,

  /// Extruded out of the surface, pressed inwards (neumorphism).
  soft,
}

/// Shape of the progress bar's thumb.
enum PlayerProgressThumb {
  /// No thumb at all: the played part ends in a rounded cap (Cupertino).
  none,

  /// A full circle, the classic player knob.
  circle,

  /// A small dot that grows while the track is hovered or dragged (Fluent).
  dot,
}

/// How the progress track is drawn.
enum PlayerProgressTrack {
  /// A rounded bar on top of the surface.
  plain,

  /// A groove pressed into the surface (neumorphism).
  inset,
}

/// Colors, metrics and glyphs of a control set.
///
/// A theme holds the tokens a style needs, and nothing else: no widget decides
/// its own colors, so a host that wants a branded player overrides the theme
/// instead of forking a style. The named constructors are the design languages
/// themselves — the hairline track and countdown time of
/// [PlayerControlsTheme.cupertino], the extruded monochrome surfaces of
/// [PlayerControlsTheme.neumorphic].
///
/// ```dart
/// MediaCorePlayerView(
///   handle: handle,
///   theme: PlayerControlsTheme.yaru().copyWith(accent: const Color(0xFF77216F)),
/// )
/// ```
final class PlayerControlsTheme {
  /// Creates a theme.
  const PlayerControlsTheme({
    required this.foreground,
    required this.foregroundMuted,
    required this.scrim,
    required this.accent,
    required this.progressTrack,
    required this.progressBuffered,
    required this.progressPlayed,
    required this.progressThumb,
    required this.iconSize,
    required this.primaryIconSize,
    required this.compactIconSize,
    required this.trackHeight,
    required this.trackHeightWhileDragging,
    required this.thumbRadius,
    required this.contentPadding,
    required this.barGap,
    required this.controlButtonRadius,
    required this.titleTextStyle,
    required this.timeTextStyle,
    required this.hideDelay,
    this.icons = const PlayerControlIcons.material(),
    this.buttonSkin = PlayerControlButtonSkin.ripple,
    this.progressThumbShape = PlayerProgressThumb.circle,
    this.progressTrackShape = PlayerProgressTrack.plain,
    this.hoverHighlight,
    this.surface,
    this.border,
    this.blur,
    this.shadowLight,
    this.shadowDark,
    this.shadowDepth = 4,
    this.pillPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  /// Material Design: scrim panels, thick slider, ripple.
  const PlayerControlsTheme.material()
    : foreground = const Color(0xFFFFFFFF),
      foregroundMuted = const Color(0xB3FFFFFF),
      scrim = const Color(0x99000000),
      accent = const Color(0xFFFF0033),
      progressTrack = const Color(0x40FFFFFF),
      progressBuffered = const Color(0x66FFFFFF),
      progressPlayed = const Color(0xFFFF0033),
      progressThumb = const Color(0xFFFF0033),
      iconSize = 24,
      primaryIconSize = 44,
      compactIconSize = 20,
      trackHeight = 4,
      trackHeightWhileDragging = 6,
      thumbRadius = 9,
      contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      barGap = 8,
      controlButtonRadius = 24,
      titleTextStyle = const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)),
      timeTextStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xE6FFFFFF)),
      hideDelay = const Duration(seconds: 3),
      icons = const PlayerControlIcons.material(),
      buttonSkin = PlayerControlButtonSkin.ripple,
      progressThumbShape = PlayerProgressThumb.circle,
      progressTrackShape = PlayerProgressTrack.plain,
      hoverHighlight = null,
      surface = null,
      border = null,
      blur = null,
      shadowLight = null,
      shadowDark = null,
      shadowDepth = 4,
      pillPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  /// Cupertino: gradient scrims, hairline track, countdown time.
  const PlayerControlsTheme.cupertino()
    : foreground = const Color(0xFFFFFFFF),
      foregroundMuted = const Color(0xB3FFFFFF),
      scrim = const Color(0x00000000),
      accent = const Color(0xFFFFFFFF),
      progressTrack = const Color(0x4DFFFFFF),
      progressBuffered = const Color(0x80FFFFFF),
      progressPlayed = const Color(0xFFFFFFFF),
      progressThumb = const Color(0xFFFFFFFF),
      iconSize = 22,
      primaryIconSize = 48,
      compactIconSize = 18,
      trackHeight = 2.5,
      trackHeightWhileDragging = 5.5,
      thumbRadius = 7,
      contentPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      barGap = 10,
      controlButtonRadius = 22,
      titleTextStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)),
      timeTextStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xCCFFFFFF)),
      hideDelay = const Duration(seconds: 4),
      icons = const PlayerControlIcons.cupertino(),
      buttonSkin = PlayerControlButtonSkin.translucent,
      progressThumbShape = PlayerProgressThumb.none,
      progressTrackShape = PlayerProgressTrack.plain,
      hoverHighlight = null,
      surface = null,
      border = null,
      blur = 18,
      shadowLight = null,
      shadowDark = null,
      shadowDepth = 4,
      pillPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// Fluent: translucent acrylic panel, thin track with a growing dot.
  const PlayerControlsTheme.fluent()
    : foreground = const Color(0xFFF3F3F3),
      foregroundMuted = const Color(0xA6F3F3F3),
      scrim = const Color(0xCC1A1A1A),
      accent = const Color(0xFF60CDFF),
      progressTrack = const Color(0x33FFFFFF),
      progressBuffered = const Color(0x4DFFFFFF),
      progressPlayed = const Color(0xFF60CDFF),
      progressThumb = const Color(0xFFF3F3F3),
      iconSize = 16,
      primaryIconSize = 26,
      compactIconSize = 14,
      trackHeight = 3,
      trackHeightWhileDragging = 5,
      thumbRadius = 6,
      contentPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      barGap = 6,
      controlButtonRadius = 4,
      titleTextStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFF3F3F3)),
      timeTextStyle = const TextStyle(fontSize: 12, color: Color(0xCCF3F3F3)),
      hideDelay = const Duration(seconds: 2),
      icons = const PlayerControlIcons.fluent(),
      buttonSkin = PlayerControlButtonSkin.hover,
      progressThumbShape = PlayerProgressThumb.dot,
      progressTrackShape = PlayerProgressTrack.plain,
      hoverHighlight = const Color(0x1FFFFFFF),
      surface = const Color(0xE61C1C1C),
      border = const Color(0x1FFFFFFF),
      blur = 24,
      shadowLight = null,
      shadowDark = null,
      shadowDepth = 4,
      pillPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5);

  /// macOS: a floating translucent pill, very compact.
  const PlayerControlsTheme.macos()
    : foreground = const Color(0xFFFFFFFF),
      foregroundMuted = const Color(0xB3FFFFFF),
      scrim = const Color(0x00000000),
      accent = const Color(0xFFFFFFFF),
      progressTrack = const Color(0x40FFFFFF),
      progressBuffered = const Color(0x66FFFFFF),
      progressPlayed = const Color(0xFFFFFFFF),
      progressThumb = const Color(0xFFFFFFFF),
      iconSize = 15,
      primaryIconSize = 22,
      compactIconSize = 13,
      trackHeight = 3,
      trackHeightWhileDragging = 4,
      thumbRadius = 5.5,
      contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      barGap = 8,
      controlButtonRadius = 6,
      titleTextStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xE6FFFFFF)),
      timeTextStyle = const TextStyle(fontSize: 11, color: Color(0xB3FFFFFF)),
      hideDelay = const Duration(seconds: 3),
      icons = const PlayerControlIcons.macos(),
      buttonSkin = PlayerControlButtonSkin.translucent,
      progressThumbShape = PlayerProgressThumb.circle,
      progressTrackShape = PlayerProgressTrack.plain,
      hoverHighlight = const Color(0x1FFFFFFF),
      surface = const Color(0x801F1F1F),
      border = const Color(0x24FFFFFF),
      blur = 30,
      shadowLight = null,
      shadowDark = null,
      shadowDepth = 4,
      pillPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  /// Yaru: Ubuntu's header bar and flat, bordered controls.
  const PlayerControlsTheme.yaru()
    : foreground = const Color(0xFFF6F5F4),
      foregroundMuted = const Color(0xA6F6F5F4),
      scrim = const Color(0xE6333333),
      accent = const Color(0xFFE95420),
      progressTrack = const Color(0x3DFFFFFF),
      progressBuffered = const Color(0x61FFFFFF),
      progressPlayed = const Color(0xFFE95420),
      progressThumb = const Color(0xFFF6F5F4),
      iconSize = 18,
      primaryIconSize = 30,
      compactIconSize = 16,
      trackHeight = 5,
      trackHeightWhileDragging = 7,
      thumbRadius = 8,
      contentPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      barGap = 8,
      controlButtonRadius = 6,
      titleTextStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF6F5F4)),
      timeTextStyle = const TextStyle(fontSize: 12, color: Color(0xCCF6F5F4)),
      hideDelay = const Duration(seconds: 3),
      icons = const PlayerControlIcons.yaru(),
      buttonSkin = PlayerControlButtonSkin.flat,
      progressThumbShape = PlayerProgressThumb.circle,
      progressTrackShape = PlayerProgressTrack.plain,
      hoverHighlight = const Color(0x1FFFFFFF),
      surface = const Color(0xF2333333),
      border = const Color(0x33FFFFFF),
      blur = null,
      shadowLight = null,
      shadowDark = null,
      shadowDepth = 4,
      pillPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5);

  /// Neumorphism: one surface color, extruded controls, an inset track.
  const PlayerControlsTheme.neumorphic()
    : foreground = const Color(0xFF6B6B70),
      foregroundMuted = const Color(0xFF9A9AA0),
      scrim = const Color(0x00000000),
      accent = const Color(0xFF5B6BFF),
      progressTrack = const Color(0xFFD3D5DB),
      progressBuffered = const Color(0xFFC3C6CE),
      progressPlayed = const Color(0xFF5B6BFF),
      progressThumb = const Color(0xFFEDEFF4),
      iconSize = 20,
      primaryIconSize = 32,
      compactIconSize = 18,
      trackHeight = 8,
      trackHeightWhileDragging = 10,
      thumbRadius = 8,
      contentPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      barGap = 10,
      controlButtonRadius = 24,
      titleTextStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5A5A60)),
      timeTextStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8A8A90)),
      hideDelay = const Duration(seconds: 4),
      icons = const PlayerControlIcons.neumorphic(),
      buttonSkin = PlayerControlButtonSkin.soft,
      progressThumbShape = PlayerProgressThumb.circle,
      progressTrackShape = PlayerProgressTrack.inset,
      hoverHighlight = null,
      surface = const Color(0xFFEDEFF4),
      border = null,
      blur = null,
      shadowLight = const Color(0xFFFFFFFF),
      shadowDark = const Color(0xFFC5C8D0),
      shadowDepth = 5,
      pillPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// Theme matching [style], with an optional glyph override.
  factory PlayerControlsTheme.of(PlayerControlsStyle style, {PlayerControlIcons? icons}) {
    final base = switch (style) {
      PlayerControlsStyle.material => const PlayerControlsTheme.material(),
      PlayerControlsStyle.cupertino => const PlayerControlsTheme.cupertino(),
      PlayerControlsStyle.fluent => const PlayerControlsTheme.fluent(),
      PlayerControlsStyle.macos => const PlayerControlsTheme.macos(),
      PlayerControlsStyle.yaru => const PlayerControlsTheme.yaru(),
      PlayerControlsStyle.neumorphic => const PlayerControlsTheme.neumorphic(),
    };

    return icons == null ? base : base.copyWith(icons: icons);
  }

  /// Primary text and glyph color.
  final Color foreground;

  /// Secondary text and inactive glyph color.
  final Color foregroundMuted;

  /// Backdrop behind the bars of a full-width layout.
  final Color scrim;

  /// Color painted behind a floating panel, when the language uses one.
  ///
  /// Independent of [scrim]: a pill sits on the picture, not across it.
  final Color? surface;

  /// Hairline around a panel or a flat button.
  final Color? border;

  /// Backdrop blur sigma for a panel; null for languages without blur.
  final double? blur;

  /// Light shadow of a soft (neumorphic) control.
  final Color? shadowLight;

  /// Dark shadow of a soft (neumorphic) control.
  final Color? shadowDark;

  /// Offset and blur scale of a soft shadow.
  final double shadowDepth;

  /// Padding inside a floating pill.
  final EdgeInsets pillPadding;

  /// Progress and active-state color.
  final Color accent;

  /// Unplayed part of the progress track.
  final Color progressTrack;

  /// Buffered part of the progress track.
  final Color progressBuffered;

  /// Played part of the progress track.
  final Color progressPlayed;

  /// Progress thumb.
  final Color progressThumb;

  /// Size of a regular control glyph.
  final double iconSize;

  /// Size of the primary (play/pause) glyph.
  final double primaryIconSize;

  /// Size of a glyph in a dense row.
  final double compactIconSize;

  /// Height of the progress track at rest.
  final double trackHeight;

  /// Height of the progress track while a drag is in progress.
  final double trackHeightWhileDragging;

  /// Radius of the progress thumb.
  final double thumbRadius;

  /// Padding inside the bars.
  final EdgeInsets contentPadding;

  /// Vertical gap between bar rows.
  final double barGap;

  /// Corner radius of a control button's highlight.
  final double controlButtonRadius;

  /// Text style of the title.
  final TextStyle titleTextStyle;

  /// Text style of the time labels.
  final TextStyle timeTextStyle;

  /// How long the controls stay on screen after the last interaction.
  final Duration hideDelay;

  /// Glyphs the style draws.
  final PlayerControlIcons icons;

  /// How a control button answers the pointer.
  final PlayerControlButtonSkin buttonSkin;

  /// Shape of the progress thumb.
  final PlayerProgressThumb progressThumbShape;

  /// How the progress track is drawn.
  final PlayerProgressTrack progressTrackShape;

  /// Highlight painted under a hovered control; null disables it.
  final Color? hoverHighlight;

  /// Whether the theme paints a hover highlight.
  bool get hasHoverHighlight => hoverHighlight != null;

  /// Whether the theme uses blur or translucent panels.
  bool get isTranslucent => blur != null || surface != null;

  /// Whether the theme extrudes controls out of the surface.
  bool get isSoft => shadowLight != null && shadowDark != null;

  /// The theme's hide delay, unless the host asked for another one.
  Duration hideDelayOr(Duration? override) => override ?? hideDelay;

  /// Creates a modified theme.
  PlayerControlsTheme copyWith({
    Color? foreground,
    Color? foregroundMuted,
    Color? scrim,
    Color? surface,
    Color? border,
    double? blur,
    Color? shadowLight,
    Color? shadowDark,
    double? shadowDepth,
    EdgeInsets? pillPadding,
    Color? accent,
    Color? progressTrack,
    Color? progressBuffered,
    Color? progressPlayed,
    Color? progressThumb,
    double? iconSize,
    double? primaryIconSize,
    double? compactIconSize,
    double? trackHeight,
    double? trackHeightWhileDragging,
    double? thumbRadius,
    EdgeInsets? contentPadding,
    double? barGap,
    double? controlButtonRadius,
    TextStyle? titleTextStyle,
    TextStyle? timeTextStyle,
    Duration? hideDelay,
    PlayerControlIcons? icons,
    PlayerControlButtonSkin? buttonSkin,
    PlayerProgressThumb? progressThumbShape,
    PlayerProgressTrack? progressTrackShape,
    Color? hoverHighlight,
  }) {
    return PlayerControlsTheme(
      foreground: foreground ?? this.foreground,
      foregroundMuted: foregroundMuted ?? this.foregroundMuted,
      scrim: scrim ?? this.scrim,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      blur: blur ?? this.blur,
      shadowLight: shadowLight ?? this.shadowLight,
      shadowDark: shadowDark ?? this.shadowDark,
      shadowDepth: shadowDepth ?? this.shadowDepth,
      pillPadding: pillPadding ?? this.pillPadding,
      accent: accent ?? this.accent,
      progressTrack: progressTrack ?? this.progressTrack,
      progressBuffered: progressBuffered ?? this.progressBuffered,
      progressPlayed: progressPlayed ?? this.progressPlayed,
      progressThumb: progressThumb ?? this.progressThumb,
      iconSize: iconSize ?? this.iconSize,
      primaryIconSize: primaryIconSize ?? this.primaryIconSize,
      compactIconSize: compactIconSize ?? this.compactIconSize,
      trackHeight: trackHeight ?? this.trackHeight,
      trackHeightWhileDragging: trackHeightWhileDragging ?? this.trackHeightWhileDragging,
      thumbRadius: thumbRadius ?? this.thumbRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      barGap: barGap ?? this.barGap,
      controlButtonRadius: controlButtonRadius ?? this.controlButtonRadius,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      timeTextStyle: timeTextStyle ?? this.timeTextStyle,
      hideDelay: hideDelay ?? this.hideDelay,
      icons: icons ?? this.icons,
      buttonSkin: buttonSkin ?? this.buttonSkin,
      progressThumbShape: progressThumbShape ?? this.progressThumbShape,
      progressTrackShape: progressTrackShape ?? this.progressTrackShape,
      hoverHighlight: hoverHighlight ?? this.hoverHighlight,
    );
  }
}
