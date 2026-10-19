<p align="center">
  <a href="./README.md">🇺🇸 English</a> |
  <a href="./README_ZH.md">🇨🇳 简体中文</a>
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/liuchuancong/flame_barrage/refs/heads/main/assets/logo/logo.png" alt="FlameBarrage Engine Logo" width="720">
</p>

<h1 align="center">🔥 FlameBarrage Engine</h1>

<p align="center">
  基于 Flame 图形框架构建的高性能 Flutter 弹幕渲染引擎
</p>

<p align="center">
  <img src="https://img.shields.io/pub/v/flame_barrage.svg" alt="pub version">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Flame-1.38+-orange.svg" alt="Flame">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

---

## 🎮 在线体验

👉 **在线 Demo：** https://liuchuancong.github.io/flame_barrage/

在线演示包含高性能弹幕渲染、实时配置热更新、Emoji 与雪碧图渲染、交互处理与实时性能压测。

---

## 🚀 项目简介

FlameBarrage Engine 是一个基于 Flame 图形框架打造的高性能、硬件加速弹幕渲染引擎，专为直播间、高并发互动场景、长视频评论流、电竞赛事以及实时消息展示等业务场景设计。

引擎不采用「一条弹幕一个 Widget」的方式，而是从平坦的条目列表出发，通过一条小型系统管线完成渲染：

| 系统 | Priority | 职责 |
| --- | --- | --- |
| `BarrageDataSystem` | 100 | 等待队列、发射节流、消息预排版、派发时轨道分配 |
| `BarrageMotionSystem` | 200 | 基于逻辑时钟的滚动积分、到期判定、同帧 swap-remove 即时回收 |
| `BarrageMetricsSystem` | 300 | 每轨道密度 / 均速 / 最右边界聚合（约 30Hz） |
| `BarrageRenderSystem` | 400 | 单遍平坦 blit 绘制 + 命中测试 |

全部共享状态集中在 `BarrageContext`（配置、逻辑时钟、轨道、池、缓存、在屏条目）。游戏循环只在有可见工作时运行——静默房间零开销；每个逻辑步都按真实流逝时间推进时钟，滚动速度与帧负载无关，始终匀速。

---

## 🔥 核心特性

### ⚡ 批量渲染管线

文本、Emoji 与图形资源被拆解为轻量级渲染 Fragment，直接提交到底层 Canvas——没有 Widget、没有逐条布局、没有 Rebuild 开销。

### 🖼️ 弹幕位图化渲染

每条弹幕只录制一次矢量显示列表，随后按设备像素比烘焙成常驻显存的位图（`BarrageConfig.rasterizeItems`，默认开启）。每个显示帧只需为每条可见弹幕画一个纹理四边形，而不再重放它的文字、描边、阴影与 Emoji 绘制指令——描边字形在每一次重放时都会被光栅线程重新细分（tessellation），这正是 TV 等低端硬件上满屏弹幕掉帧的根因。

**1080p 场景、同屏约 74 条弹幕实测**（Windows / Impeller，每帧光栅耗时）：**p50 1.99 ms → 0.82 ms，p90 2.19 ms → 1.04 ms，显存占用 8.3 MB**。另在 CPU 光栅基准中，100 条互不相同的 CJK 弹幕由每帧 4.63 ms 降至 2.41 ms。

- 位图引用计数管理：缓存淘汰永远不会释放仍在屏幕上的弹幕资源
- 内存受 `pictureCacheMaxSize`（条数）与 `rasterCacheMaxBytes`（显存）双重约束
- 重复内容（"666"、进场模板）全场共用同一张位图
- 超过 4096 设备像素的超长弹幕、以及不支持位图光栅化的平台自动回退到矢量绘制

### 🎨 双通路文本渲染

文字描边与填充采用独立 Paragraph 绘制，规避字体缓存干扰：无首帧颜色异常、无描边污染、无闪烁。

### ♻️ 零分配对象池

`BarragePool` 复用弹幕条目对象；条目离场的同一帧即归还池中——极低 GC 压力，长时间运行内存稳定。

### 📐 配置实时生效

`updateConfig` 无需清屏即可应用配置。当修改会影响在屏弹幕的画面或位置时，所有可见弹幕立即重新排版并重新烘焙：滚动弹幕保持当前位置继续滚动，固定弹幕按新轨道几何重新居中。

### 🎯 帧率无关的匀速运动

滚动位移基于亚毫秒精度的逻辑时钟、按每帧真实流逝时间积分——速度不依赖帧负载，也没有按时长截断带来的忽快忽慢。60/120/144Hz 面板下均保持匀速，带轨道冲突规避与安全间距控制。

### 🐎 座驾特效弹幕

`BarrageItem.effect` 传入一个 `BarrageMotionEffect`（内置骑马、飞机、火箭、UFO、流星、祥龙、幽灵、魔毯八种），引擎接管进场/巡游/出场编排、独占轨道与粒子渲染，座驾为纯 Canvas 手绘，零图片资源。

### ⏩ 倍速与全量实时派发

- `engine.playbackRate` 对整个逻辑时钟全局加速（0.05–8.0）：滚动速度与固定弹幕驻留时长同步变化。
- `BarrageConfig.realtimeMode` 关闭发射节流，每个逻辑帧整队清空等待队列（仍受同屏上限与轨道余量约束）——洪峰消息到达即上屏。

---

## 📦 安装

```yaml
dependencies:
  flame: ^1.38.2
  flame_barrage: ^0.0.8
```

---

## 🛠 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key});
  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  final BarrageController _controller = BarrageController();

  final BarrageConfig _config = const BarrageConfig(
    fontSize: 20,
    baseSpeed: 150,
    trackHeight: 44,
    showStroke: true,
    safeArea: true,
    opacity: 0.8,
  );

  @override
  void dispose() {
    _controller.clear();
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FlameBarrageWidget(
            controller: _controller,
            config: _config,
            emojiAtlas: EmojiAtlas.instance,
          ),
        ),
      ],
    );
  }
}
```

发送消息、实时更新配置、暂停恢复：

```dart
_controller.send(BarrageItem(content: 'Hello FlameBarrage!', type: BarrageType.scroll));

_controller.updateConfig(_config.copyWith(fontSize: 24)); // 在屏弹幕立即换新样式

_controller.pause();
_controller.resume();
_controller.clear();
```

---

## 📖 API 参考

### FlameBarrageWidget

入口 Widget，生命周期内持有一个 `BarrageEngine` 实例。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `controller` | `BarrageController` | 必填 | 发送消息与驱动引擎的门面 |
| `config` | `BarrageConfig` | 必填 | 引擎配置，修改会热更新 |
| `emojiAtlas` | `EmojiAtlas` | 必填 | Emoji/雪碧图注册表，通常传 `EmojiAtlas.instance` |
| `enablePointerEvents` | `bool` | `false` | 开启后点击/长按会对弹幕做命中测试；不开启时表面忽略指针，不会抢占底层视频播放器的手势 |

### BarrageController

业务代码与引擎之间的类型安全门面。

| 成员 | 签名 | 说明 |
| --- | --- | --- |
| `send` | `void send(BarrageItem item)` | 入队一条消息（`running == false` 时不发送） |
| `updateConfig` | `void updateConfig(BarrageConfig config)` | 热更新配置 |
| `pause` / `resume` | `void pause()` / `void resume()` | 停止/恢复推进；暂停期间发送的消息进入缓冲而不丢弃 |
| `togglePause` | `void togglePause()` | 翻转 `running` |
| `clear` | `void clear()` | 释放全部条目、队列与缓存资源 |
| `attach` / `detach` | `void attach(BarrageEngineApi engine)` / `void detach([BarrageEngineApi? engine])` | 绑定/解绑引擎（`FlameBarrageWidget` 自动完成） |
| `triggerItemAt` | `bool triggerItemAt(double x, double y, {required bool longPress})` | 对指定点做命中测试并触发最上层弹幕回调；未命中返回 false |
| `running` | `bool` | 发送与引擎推进是否激活 |
| `totalEmitted` | `int` | `send` 接受的消息总数 |
| `activeItemCount` | `int` | 当前在屏弹幕数 |
| `pendingMessageCount` | `int` | 等待轨道的消息数（含暂停缓冲） |
| `pictureCacheCount` | `int` | 渲染缓存条目数 |
| `rasterCacheBytes` | `int` | 烘焙位图占用的显存字节数 |
| `poolObjectCount` | `int` | 对象池中暂存的条目数 |

### BarrageEngine / BarrageEngineApi

`BarrageEngine extends FlameGame implements BarrageEngineApi`。通常不需要直接构造——`FlameBarrageWidget` 会创建。用于倍速控制与指标观测：

```dart
engine.playbackRate = 2.0;          // 0.05–8.0，全局缩放逻辑时钟
engine.activeCount;                 // 在屏弹幕数
engine.pendingMessageCount;         // 排队消息数
engine.rasterCacheBytes;            // 位图显存占用
engine.activeCacheSize;             // 渲染缓存条目数
engine.activePoolSize;              // 池中条目对象数
engine.rasterizationActive;         // 是否正在以位图模式绘制
engine.lastStepCostUs;              // 上一逻辑帧步进耗时（微秒）
engine.peakStepCostUs;              // 自上次超载告警以来的峰值耗时
engine.parserCacheSize;             // 内容解析缓存条目数
engine.layoutCacheSize;             // 排版结果缓存条目数
engine.frameStepCount;              // 已执行的逻辑步总数
engine.context;                     // 进阶：共享 BarrageContext
```

单帧逻辑成本超过 20ms 会节流输出超载告警日志。

### BarrageItem

不可变的消息描述。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `content` | `String`（必填） | 原始文本，可内嵌 emoji 按键（由图集正则解析） |
| `type` | `BarrageType` | `scroll`（默认）/ `topFixed` / `bottomFixed` |
| `priority` | `int` | 轨道竞争时优先级高者胜 |
| `userId` / `userName` | `String?` | 发送者身份 |
| `textColor`、`fontSize`、`fontWeight`、`fontStyle`、`fontFamily`、`letterSpacing` | 覆写项 | 单条排版覆写（缺省回退 `BarrageConfig`） |
| `showStroke`、`strokeColor`、`strokeWidth` | 覆写项 | 单条描边 |
| `showShadow`、`shadowColor`、`shadowBlur`、`shadowOffset` | 覆写项 | 单条阴影 |
| `opacity` | `double?` | 单条透明度 |
| `fixedDuration` | `Duration?` | 固定弹幕的单条驻留时长 |
| `emojiSize` | `double?` | 单条行内 Emoji 尺寸 |
| `baseSpeed` | `double?` | 单条滚动速度 |
| `overlapSafeGap` | `double?` | 单条轨道安全间距 |
| `effect` | `BarrageMotionEffect?` | 交给座驾特效接管运动编排（进场/巡游/出场、手绘座驾、粒子），整场表演独占一条轨道 |
| `cachedFragments`、`cachedLayout`、`cachedPicture` | 进阶 | 预计算产物，跳过解析/排版/烘焙阶段 |
| `onTapDown` / `onTapUp` / `onLongTapDown` / `onTapCancel` | `void Function()?` | 交互回调（需要 `enablePointerEvents: true` 或 `triggerItemAt`） |

### BarrageConfig

引擎全部调优参数。所有字段均可通过 `copyWith` 热更新；样式与轨道几何类修改会立即刷新在屏画面。

<details>
<summary><b>全部字段</b></summary>

| 分组 | 字段 | 类型 / 默认值 | 说明 |
| --- | --- | --- | --- |
| 排版 | `fontSize` | `double` / 18 | 基准字号 |
| | `fontWeight` | `FontWeight` / w500 | 基准字重 |
| | `fontStyle` | `FontStyle` / normal | 斜体或常规 |
| | `fontFamily` | `String?` | 自定义字体 |
| | `letterSpacing` | `double` / 0 | 字符间距 |
| 颜色与效果 | `textColor` | `Color` / white | 填充色 |
| | `showStroke` | `bool` / true | 描边渲染 |
| | `strokeColor` / `strokeWidth` | black / 1.0 | 描边样式 |
| | `showShadow` / `shadowColor` / `shadowBlur` / `shadowOffset` | false / black / 0 / (1,1) | Paragraph 阴影（逐帧无 saveLayer） |
| | `opacity` | `double` / 1.0 | 全局透明度 |
| 布局 | `area` | `double` / 1.0 | 可用于轨道的视口高度比例 |
| | `trackHeight` | `double` / 36 | 轨道高度（自动下限 fontSize+10） |
| | `topAreaDistance` / `bottomAreaDistance` | 0 / 0 | 安全区之外的额外留白 |
| | `safeArea` | `bool` / true | 适配 `MediaQuery` 安全区 |
| 时间与速度 | `fps` | `int` / 60 | 逻辑步进上限；实际受屏幕刷新率约束 |
| | `fixedDuration` | `Duration` / 4s | 固定弹幕驻留时长 |
| | `baseSpeed` | `double` / 120 | 滚动速度（px/s） |
| 派发 | `emitInterval` | `double` / 0.1 | 节流派发间隔（秒） |
| | `realtimeMode` | `bool` / false | 关闭节流，每逻辑帧整队上屏 |
| | `maxVisibleCount` | `int` / 80 | 同屏弹幕上限 |
| | `maxPendingCount` | `int` / 120 | 等待队列上限（超出丢弃最旧） |
| | `maxPendingAge` | `Duration` / 5s | 上屏前超龄消息直接丢弃 |
| | `overlapSafeGap` | `double` / 40 | 轨道内最小安全间距 |
| 资源 | `noEmojiMode` | `bool` / false | 纯文本模式，跳过全部 Emoji |
| | `barragePoolMaxSize` | `int` / 150 | 条目对象池上限 |
| | `pictureCacheMaxSize` | `int` / 200 | 渲染缓存条目上限 |
| | `rasterCacheMaxBytes` | `int` / 24 MB | 位图显存预算 |
| | `rasterizeItems` | `bool` / true | 烘焙位图 |
| | `textCacheMaxSize` | `int` / 1000 | Paragraph/排版缓存上限 |
| | `effectInterceptors` | `List<BarrageEffectInterceptor>` / [] | 自定义文字特效管线 |

</details>

### BarrageType

| 取值 | 行为 |
| --- | --- |
| `scroll` | 从右缘进入，向左滚动直至离屏 |
| `topFixed` | 顶部轨道固定展示 `fixedDuration` |
| `bottomFixed` | 底部轨道固定展示 `fixedDuration` |

### Emoji 与雪碧图系统

```dart
final atlas = EmojiAtlas.instance;

// 1. 注册 Emoji 元数据（一张图可对应多个触发按键）
atlas.registerAll([
  EmojiInfo(
    id: '29',
    asset: 'assets/emoji/29.png',
    keys: ['[大笑]', '[开心]'],
    sourceType: EmojiSourceType.asset,   // asset | atlas | network | animated
    width: 24,
    height: 24,
  ),
]);

// 2. 预加载图片（异步；内部完成 Sprite/动画解析）
await atlas.preloadAll();

// 3. 图集切片 Emoji：加载大图前先注册源矩形
atlas.updateAtlasRects({
  '[切片A]': const Rect.fromLTWH(0, 0, 96, 96),
  '[切片B]': const Rect.fromLTWH(96, 0, 96, 96),
});
```

| 类 | 关键成员 | 用途 |
| --- | --- | --- |
| `EmojiAtlas` | `register`、`registerAll`、`updateAtlasRects`、`preloadEmoji`、`preloadAll`、`find`、`image`、`getStaticSprite`、`getAnimation`、`resolveLoadedImage`、`regex`、`clear` | 触发按键到图片/Sprite/动画的注册表；按键会合成一个匹配用 `RegExp` |
| `EmojiInfo` | `id`、`asset`、`keys`、`sourceType`、`width`、`height` | 单个 Emoji 的元数据 |
| `EmojiSourceType` | `asset` / `atlas` / `network` / `animated` | 资源解释方式（animated 会从横向序列帧构建 `SpriteAnimation`） |
| `AtlasLoader` | `loadFromAsset(path, {targetWidth, targetHeight})` | 把 Flutter 资源解码为 `ui.Image` |
| `SpriteSheet` | `getSpriteRect(i)`、`generateAllRects()`、`srcWidth`、`srcHeight` | 大图网格切分计算 |

解析器按图集正则切分消息内容：普通文本是 `TextFragment`，注册按键按来源成为 `SpriteFragment`（atlas）或 `EmojiFragment`（其余），文本与图形可在一条弹幕内自由混排。

### 交互

```dart
FlameBarrageWidget(
  controller: controller,
  config: config,
  emojiAtlas: EmojiAtlas.instance,
  enablePointerEvents: true, // 直接命中测试必须开启
);

controller.send(BarrageItem(
  content: '点我！',
  onTapDown: () => debugPrint('down'),
  onTapUp: () => debugPrint('up'),
  onLongTapDown: () => debugPrint('long-press'),
  onTapCancel: () => debugPrint('cancel'),
));

// 自定义手势层（例如视频播放器保留滑动手势）：
final handled = controller.triggerItemAt(x, y, longPress: false);
```

命中测试按从后往前的顺序遍历在屏条目；未挂回调的消息不会抢占手势。

#### 点击暂停（操作面板流程）

常见产品流程：点击弹幕冻结该条，弹出屏蔽/举报/点赞面板，操作完成后释放继续滚动。引擎会在暂停期间保持该条不动——既不滚动也不到期：

```dart
final item = controller.pauseItemAt(x, y);   // 未命中返回 null
if (item != null) {
  final action = await showActionSheet(item.userId, item.content);
  // ... 屏蔽该用户 / 提交举报 / 点赞 ...
}
controller.resumeAllPaused();                // 被冻结的弹幕从原地继续滚动
```

| 成员 | 说明 |
| --- | --- |
| `controller.pauseItemAt(x, y)` | 冻结命中点最上层的弹幕并返回它（未命中返回 null）；被冻结的弹幕保持位置与轨道 |
| `controller.resumeAllPaused()` | 释放全部被冻结的弹幕 |
| `controller.pausedCount` | 当前被冻结的弹幕数量 |

### 扩展渲染

**`BarrageEffectInterceptor`**——拦截匹配的消息并替换为自定义 `LayoutSpan`：

```dart
class VipRainbowInterceptor extends BarrageEffectInterceptor {
  const VipRainbowInterceptor();

  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) =>
      item.content.contains('[VIP]');

  @override
  LayoutSpan createCustomSpan({
    required BarrageItem item,
    required String text,
    required ui.Paragraph paragraph,
    required double x, required double y,
    required double width, required double height,
    required BarrageConfig config,
  }) {
    return VipRainbowTextLayoutSpan(
      x: x, y: y, width: width, height: height,
      text: text, paragraph: paragraph, config: config,
    );
  }
}

class VipRainbowTextLayoutSpan extends TextLayoutSpan {
  const VipRainbowTextLayoutSpan({
    required super.x, required super.y, required super.width,
    required super.height, required super.text, required super.paragraph,
    required this.config,
  });

  final BarrageConfig config;

  // TextLayoutSpan 的子类建议实现 copyWithY(double)，
  // 以便垂直居中时能重新定位。
  VipRainbowTextLayoutSpan copyWithY(double newY) => VipRainbowTextLayoutSpan(
    x: x, y: newY, width: width, height: height,
    text: text, paragraph: paragraph, config: config,
  );

  @override
  void paint(ui.Canvas canvas) {
    // 渐变填充、描边、徽标——Canvas 能画的都可以
  }
}

// 接入：
final config = BarrageConfig(effectInterceptors: [const VipRainbowInterceptor()]);
```

**`Fragment`**——解析产出的内容单元（`TextFragment`、`SpriteFragment`、`EmojiFragment`）。可继承后接入自己的解析路径。

**`LayoutSpan`**——`LayoutResult` 内的绘制单元。内置：`TextLayoutSpan`（填充 + 可选描边 Paragraph）、`EmojiLayoutSpan`（图片）、`SpriteLayoutSpan`（图集 Sprite，可带 `SpriteAnimationPlayer`）。

**`BarrageMotionEffect`**——座驾特效编排。实现 `duration`、`onSpawn`、`advance`，可选 `paint`（画在文字位图之下）。引擎负责派发、逐帧推进、轨道独占与粒子渲染（`BarrageFxParticleSystem`）；每帧只需把姿态字段（`x/y/alpha/rotation/scale`）写进 `BarrageFxState`。内置的 `HorseRidingEffect`、`RocketLaunchEffect` 等可直接作为参考实现。

### 数据协议

```dart
final message = const MessageProtocol().fromWebSocketJson(json);   // BarrageItem?，来自 {content, type, vip}
final emojis = const EmojiProtocol().parseRegistryJson(rawList);    // List<EmojiInfo>，来自 {id, keys, asset, width, height}
```

### 工具类

| 类 | 成员 | 用途 |
| --- | --- | --- |
| `FpsMonitor` | `start(callback)`、`stop()` | 基于滑动窗口的真实显示帧率采样 |
| `Measure` | `Measure.profile(label, action)` | 计时闭包执行，超过 1ms 输出告警 |
| `ColorUtil` | `fromHex`、`fromInt`、`toARGB32` | 颜色转换 |
| `BarrageLogger` | `d/w/e` | 引擎统一使用的带标签日志 |

### 进阶内部组件

以下类型已导出，供自定义宿主或实验使用：

| 领域 | 类 |
| --- | --- |
| 系统 | `BarrageDataSystem`、`BarrageMotionSystem`、`BarrageMetricsSystem`、`BarrageRenderSystem` |
| 共享状态 | `BarrageContext`（配置、时钟、视口、轨道、缓存、在屏条目） |
| 调度 | `TrackManager`（轨道生命周期）、`TrackAllocator`（轨道分配）、`SpeedStrategy`（防追尾速度） |
| 缓存 | `RenderCache`/`CachedRender`（引用计数位图）、`TextCache`（Paragraph）、`PictureCache`（兼容保留）、`AtlasCache`、`SpriteCache`、`PicturePool` |
| 对象池 | `BarragePool`（条目）、`ObjectPool<T>`（泛型 `Poolable` 池） |
| 渲染 | `BaseRenderer`、`MixedRenderer`（Picture 录制）、`EmojiRenderer` |
| 模型 | `BarrageEntry`（池化运行时状态）、`BarrageTrack`、`BarrageMessage` |
| 时钟 | `EngineClock`（`now()` 毫秒、`nowPrecise()` 亚毫秒、`scale` 倍速） |
| 特效 | `GlowEffect`、`GradientEffect`、`ShadowEffect`、`StrokeEffect`（画笔工厂）、`ComboAnimation`、`SpriteAnimationPlayer` |

---

## 📺 TV / 低端设备调优建议

| 参数 | 建议 | 原因 |
| --- | --- | --- |
| `fps` | 设为屏幕实际刷新率（60 / 120） | 引擎每帧最多推进一次，不可能超过屏幕刷新率。60Hz 电视上设 `fps: 144` 不会有任何提升——如果仍然掉帧，问题在单帧成本而不在目标帧率。 |
| `rasterizeItems` | `true`（默认） | 消除逐帧的文字/描边/阴影光栅化。 |
| `maxVisibleCount` | 弱 GPU 上 40–80 | 这个值就是每帧位图 blit 的次数。 |
| `showStroke` | 亮色视频上建议保留；若烘焙本身带来启动尖峰可关闭 | 描边每条弹幕只光栅化一次，不再是逐帧成本。 |
| `trackHeight` / `area` | 轨道越多，同屏弹幕越多，量力而行 | 减少同屏数量是最直接的降载手段。 |
| `pictureCacheMaxSize` / `rasterCacheMaxBytes` | 按设备显存设定 | 限制位图缓存占用的显存（`rasterCacheBytes` 可观察实时占用）。 |
| `emitInterval` | 平稳直播用 `0.1`，高峰用 `0.02`–`0.05` | 控制每秒新增弹幕的排版与烘焙节奏。更在意时效时可改用 `realtimeMode: true`。 |

调用 `controller.clear()`（或 `FlameBarrageWidget` 被 dispose）会彻底停止游戏循环，静默房间零开销。

---

## 🔬 性能设计理念

1. **减少对象分配**——池化条目、复用画笔、稳态零分配循环
2. **降低框架开销**——无逐条 Widget，单遍平坦绘制
3. **充分利用 GPU**——烘焙位图，每条弹幕一个纹理四边形
4. **每条弹幕只光栅化一次，而不是每帧一次**
5. **位移按真实流逝时间积分**——速度绝不依赖帧负载

---

## 📋 开源协议

FlameBarrage Engine 基于 MIT License 开源发布。
