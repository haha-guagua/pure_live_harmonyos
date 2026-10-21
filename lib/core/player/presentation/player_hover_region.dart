import 'package:flutter/widgets.dart';

/// Hover belongs to desktop controls. Mobile input bridges can emit mouse
/// events around a touch; those must not reveal controls before the tap toggles
/// them, or reveal them again after the tap hides them.
class PlayerHoverRegion extends StatelessWidget {
  const PlayerHoverRegion({
    super.key,
    required this.enabled,
    required this.onHover,
    required this.onExit,
    required this.child,
    this.cursor = MouseCursor.defer,
  });

  final bool enabled;
  final VoidCallback onHover;
  final VoidCallback onExit;
  final Widget child;
  final MouseCursor cursor;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: cursor,
    onHover: enabled ? (_) => onHover() : null,
    onExit: enabled ? (_) => onExit() : null,
    child: child,
  );
}
