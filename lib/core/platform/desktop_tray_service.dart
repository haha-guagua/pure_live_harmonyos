// HarmonyOS compatibility workspace: retain the Dart-3.11 tray_manager API.
// The regular workspace keeps its newer desktop tray implementation.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

class DesktopTrayService {
  static _TrayCallbacks? _listener;
  static String _windowLabel = '';
  static String _exitLabel = '';

  static void initialize({
    required Future<void> Function() onClick,
    required Future<void> Function() onRightClick,
    required Future<void> Function() onWindowAction,
    required Future<void> Function() onExit,
  }) {
    if (_listener != null) return;
    final listener = _TrayCallbacks(onClick, onRightClick, onWindowAction, onExit);
    _listener = listener;
    trayManager.addListener(listener);
    unawaited(
      _initialize().catchError((Object error) {
        debugPrint('Desktop tray initialization failed: $error');
      }),
    );
  }

  static Future<void> _initialize() async {
    await trayManager.setIcon('assets/icons/icon.png');
    await trayManager.setToolTip('PureLive');
    await _setMenu();
  }

  static Future<void> _setMenu() => trayManager.setContextMenu(
    Menu(
      items: [
        MenuItem(key: 'window', label: _windowLabel),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: _exitLabel),
      ],
    ),
  );

  static void update({required String tooltip, required String windowLabel, required String exitLabel}) {
    _windowLabel = windowLabel;
    _exitLabel = exitLabel;
    if (_listener == null) return;
    unawaited(trayManager.setToolTip(tooltip));
    unawaited(_setMenu());
  }

  static void openContextMenu() => unawaited(trayManager.popUpContextMenu());

  static void dispose() {
    final listener = _listener;
    if (listener == null) return;
    trayManager.removeListener(listener);
    _listener = null;
    unawaited(trayManager.destroy());
  }
}

class _TrayCallbacks with TrayListener {
  _TrayCallbacks(this.click, this.rightClick, this.window, this.exit);
  final Future<void> Function() click, rightClick, window, exit;
  @override
  void onTrayIconMouseDown() => unawaited(click());
  @override
  void onTrayIconRightMouseDown() => unawaited(rightClick());
  @override
  void onTrayMenuItemClick(MenuItem item) {
    if (item.key == 'window') unawaited(window());
    if (item.key == 'exit') unawaited(exit());
  }
}
