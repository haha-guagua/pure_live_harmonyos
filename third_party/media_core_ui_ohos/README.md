# media_core_ui

`media_core` 的播放器控制层：一套控制逻辑，六种设计语言。所有控件都只渲染同一个控制器的状态、调用同一批动作，换皮肤不换行为。

## 定位

包体分两半：

- `src/common` —— 每种风格都要用的东西：镜像 [PlayerHandle](../media_core) 播放状态、掌控控件可见性的 `PlayerControlsController`，主题令牌 `PlayerControlsTheme`，时间轴（进度条 + 时间标签）、控制按钮、键盘映射，以及把上下两条栏叠在画面上的 `PlayerControlsStage`。
- `src/material`、`src/cupertino`、`src/fluent`、`src/macos`、`src/yaru`、`src/neumorphic` —— 一种设计语言一个控件集。控件集是**无状态**的：只渲染控制器的状态、调用它的动作。

`PlayerControlsStyle` 是设计语言而非设备：宿主可以主动选（在 Android 上 `style: PlayerControlsStyle.neumorphic` 是正当选择），也可以用 `forPlatform` 拿平台默认。六种都用 Flutter 原生控件手写，不引 `fluent_ui` / `macos_ui` / `yaru` 那四个 kit——一个轻依赖包在任何宿主树里都能渲染，胜过四个各自要求 theme 包装的组件库。字形来自 `PlayerControlIcons`，已依赖某个 kit 的宿主可替换成自己的图标。

一个"能力"如何暴露由**回调是否存在**决定，而不是能力标志位：`PlayerControlActions` 里为 null 的回调，控制栏就不画那个按钮——库从不提供一个按下去不工作的按钮。`KernelPlayerControlActions` 把这套回调节洲到 `PlayerKernel` 的演示驱动上。

## 用法

```dart
// 常规：一个 widget 装好画面、控件、手势与键盘，风格按平台挑。
MediaCorePlayerView(
  handle: handle,
  actions: KernelPlayerControlActions(kernel: kernel, playerId: handle.id),
)

// 强制某种设计语言，并自带主题覆盖。
MediaCorePlayerView(
  handle: handle,
  style: PlayerControlsStyle.fluent,
  theme: PlayerControlsTheme.of(PlayerControlsStyle.fluent),
  pinchToZoom: false,
  doubleTapAction: PlayerDoubleTapAction.fullscreen,
  actions: const PlayerControlActions(
    enterFullscreen: _enterFullscreen,
    enterPip: _enterPip,
    onScreenshot: _saveFrame,
  ),
)

// 只要控制栏、自己排版：控制器 + 主题即可。
final controller = PlayerControlsController(handle: handle, actions: actions);
CupertinoPlayerControls(controller: controller, theme: PlayerControlsTheme.of(PlayerControlsStyle.cupertino));
```

`MediaCorePlayerView` 的所有槽都可覆盖：`style` 强制、`theme` 换、`controller` 外部注入、`controls` 整条替换成宿主自己的栏；`showControls: false` 只留画面与手势（给缩略图、网格单元）。跳转按钮默认关（Android 惯用手势），`showSkipButtons` + `skipStep` 打开；`showTopBar` 目前只有 Material 尊重，其余风格始终画自己的顶栏。

## 平台支持

纯 Dart/Flutter widget 包，不含任何平台代码：只要 Flutter 能跑，本包就能渲染，也不新增原生依赖。风格的自动选择：

| 平台 | 默认 `PlayerControlsStyle` |
| --- | --- |
| Android / Fuchsia | `material` |
| iOS | `cupertino` |
| macOS | `macos` |
| Windows | `fluent` |
| Linux | `yaru`（Ubuntu 发 Yaru；其他发行版请显式传 `material`/`fluent`） |
| Web | `fluent`（浏览器由指针 + 键盘驱动，即使底层是手机） |

`neumorphic` 永不自动选中——它是风格声明，不是平台约定。

## 相关文档

- 主包与播放器 API：[../media_core](../media_core)
- 演示能力（全屏 / PiP / 悬浮）：[../media_core_presentation](../media_core_presentation)
- 仓库总览：[../../README.md](../../README.md)
