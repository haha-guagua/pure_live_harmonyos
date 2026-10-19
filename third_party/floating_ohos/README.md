# floating

> **fork 说明** —— 这里是 [`wrbl606/floating`](https://github.com/wrbl606/floating)
> 6.0.0 的上游快照 fork，为 [media_core](https://github.com/liuchuancong/media_core)
> 的 `media_core_pip` 提供 Android 系统画中画后端。改动清单见
> [PATCHES.md](PATCHES.md)：AGP 9 内置 Kotlin 的构建修复，以及
> `FloatingSystemPip` 状态轮询的行为修复。上游的 license 与署名保持不变
> （MIT，Copyright © 2021 Marcin Wróblewski）。
>
> 本仓库**不**发布到 pub.dev：`floating` 这个名字已被上游占用，所以它以
> git 依赖的形式被消费，而 pub.dev 不接受 git 依赖。需要它的包
> （`media_core_pip`）因此也暂不发到 pub.dev。

Picture in Picture management for Flutter. **Android only**

<image src="https://wrbl.xyz/floating-example.gif" alt="Picture in picture demo" width="40%">

## App configuration

Add `android:supportsPictureInPicture="true"` line to the `<activity>` tag in `android/src/main/AndroidManifest.xml`:

```xml
<manifest>
   <application>
        <activity
            android:name=".MainActivity"
            android:supportsPictureInPicture="true"
            ...
```

## Widget

This package provides a helper `PiPSwitcher` widget for switching the displayed widgets according to current PiP status. Use it like so:

```dart
PiPSwitcher(
    childWhenDisabled: Scaffold(...),
    childWhenEnabled: JustVideo(), 
)
```

## API

PiP mode in desired mode is available only in Android
so iOS and web support is not planned until
the platforms adds native support for such feature.

### Create a Floating instance

```dart
final floating = Floating();
```

### Check if PiP is available

```dart
final canUsePiP = await floating.isPipAvailable;
```

> PiP may be unavailable because of system settings managed
> by admin or device manufacturer. Also, the device may
> have Android version that was released without this feature.

### Check if app is in PiP mode

```dart
final currentStatus = await floating.pipStatus;
```

Possible statuses:

| Status | Description | Will `enable()` have an effect? |
| ------ | ----------- | ------------------------------ |
| disabled | PiP is available to use but currently disabled. | Yes |
| enabled | PiP is enabled. The app can display content but will not receive user inputs until the user decides to bring the app to it's full size. | No |
| automatic | PiP will be enabled automatically by the OS. | Yes |
| unavailable | PiP is disabled on given device. | No |

### Enable PiP mode

Enable PiP right away:

```dart
final statusAfterEnabling = await floating.enable(ImmediatePiP());
```

Enable PiP when the app gets minimized via system gesture:

```dart
final statusAfterEnabling = await floating.enable(OnLeavePiP());
```

To later cancel, use `.cancelOnLeavePiP()`.

When enabled, PiP mode can be toggled off by the user via system UI.

#### Arguments

##### `aspectRatio:`

The default 16/9 aspect ratio can be overridden with custom `Rational`.
Eg. to make PiP square use: `.enable(aspectRatio: Rational(1, 1))` or `.enable(aspectRatio: Rational.square())`.

##### `sourceRectHint:`

By default, system will simply use fade animation to tween between full app and PiP.
Switching animation can be smoother by using source rect hint ([example animation](https://developer.android.com/static/images/pip.mp4)).

Check [the example project](https://github.com/wrbl606/floating/blob/main/example/lib/main.dart) to see an example of usage.
