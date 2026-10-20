# HarmonyOS 适配与验证记录

本仓库基于 [liuchuancong/pure_live](https://github.com/liuchuancong/pure_live) 的
`997713d21498350a92f260951fb0400f51e8ef42` 改造，应用基线为 `3.1.19+4108`。
当前兼容源码作为新仓库的初始快照提交；完整上游历史可通过原项目查看。

## 当前结论

2026-10-19，签名 arm64 Debug HAP 已在 HUAWEI Mate 90 Pro 安装并完成部分验证：

| 项目 | 实际证据 |
| --- | --- |
| 设备 | CMS-AL20，HarmonyOS 7.0.0.109，设备工具返回 API 26、arm64-v8a |
| 应用 | `com.mystyle.purelive.ohos`，`3.1.19+4108` |
| 安装和启动 | 包管理器安装成功，Ability 启动成功，窗口及进程已核对 |
| 页面 | 首屏正常，热门页加载哔哩哔哩列表，直播间导航成功 |
| 视频 | HTTP-FLV，H.264 1280×720/30fps，实际画面可见 |
| 解码和渲染 | `ohcodec` 硬件解码、`gpu-next` 输出，日志确认首帧显示 |
| 音频 | AAC 双声道 48kHz、`ohaudio` 输出；日志为 audio=playing/video=playing |
| 弹幕 | 连接成功，页面显示弹幕 |
| 生命周期 | 一次前后台切换后恢复焦点，视频画面继续显示 |

听感、长时间音画同步、HLS、其他站点、IPTV、旋转、系统音频中断、设置与收藏跨重启持久化均未完整验收。
FFmpeg 录制/转封装不支持；系统媒体会话未接入。录制入口尚未在全部页面隐藏。
IJK/Exo、Firebase、扫码/WebView、系统画中画、投屏与分享不属于已支持能力。
版本更新接口曾返回 HTML 导致 JSON 解析失败；SDK 图片解码也有 orientation:401 日志，但页面图片可显示。

## 全屏适配修复（2026-10-20）

全屏驱动的默认平台识别尚未覆盖 `ohos`，应用的方向切换分支也只包含 Android/iOS，
导致点击按钮后无法完成移动端全屏。鸿蒙现显式使用驱动的 mobile 模式，并通过
Flutter OH 的 `SystemChrome` 执行沉浸显示、全屏方向策略与退出恢复。
固定版 Flutter OH 的 `PlatformChannel.ets` 在处理
`SystemChrome.setEnabledSystemUIMode` 时还漏掉了 `result.success(null)`：
系统栏已经隐藏，但 Dart Future 不结束，后续方向切换和退出流程因此等待。
`tool/apply_harmonyos_fullscreen_patch.ps1` 为 arm64 Debug 引擎补齐此回调，
对原始与补丁后源码进行 SHA-256 校验，并备份 SDK 原 HAR；构建入口自动调用。
该补丁仅覆盖当前 arm64 Debug 构建，不代表其他 SDK/Release 已验证。
鸿蒙播放器额外通过 `BackButtonListener` 在 Router 分发层拦截全屏返回：
当前 Get 路由代理直接移除页面，会绕过 `PopScope`；Android 原有原生拦截不适用于鸿蒙。
弹窗仍先处理返回，普通直播间仍沿用原路由返回行为。
亮度、音量及电池插件的原平台限制保持不变。

原引擎归档保存在 SDK 同级的
`FlutterOH-compat-backups/fullscreen-callback-3.41.10-ohos-1.0.1/`。
撤销补丁时恢复对应的 `flutter.har`、`flutter_embedding_debug.har`，并重新解析
项目的引擎依赖；重新使用本仓库构建入口会再次应用补丁。


## 2026-10-20 主要功能实机回归

在同一 Mate 90 Pro 上覆盖安装最终签名 Debug HAP，保留应用数据。
HAP SHA-256：`3434a9d06946ba4980ca03b0fad5bc9cd35c42de566e5c12fb2aaf80609cfc89`。

| 检查项 | 结果与边界 |
| --- | --- |
| 全屏按钮 | 实际点击后窗口和播放器均为 `2832×1280`，连续进入两次通过 |
| 退出全屏 | 系统返回键和播放器退出按钮均恢复竖屏直播间，未关闭房间 |
| 直播播放 | 斗鱼 H.264 1920×1080、AAC / ohcodec / ohaudio，实际画面可见 |
| 清晰度 | 蓝光4M切换高清，日志确认 960×540 新流首帧，实际画面恢复 |
| 线路 | 线路1切换线路2后实际出画面；不是全线路验收 |
| 弹幕 | 直播间弹幕列表有持续内容 |
| 前后台 | 一次 Home 后返回应用，原直播间保留并继续显示画面 |
| 首页关注 | 已开播/未开播分类可切换，未开播房间在全部及平台筛选下可见 |
| 数据保留 | 应用冷启动后原4个关注仍在，本轮为3个已开播、1个未开播 |
| 热门 | 哔哩哔哩热门房间列表正常加载 |
| 搜索 | 斗鱼公开关键词搜索提交后返回房间列表；未验收所有平台搜索与排序准确性 |
| 分区 | 哔哩哔哩主分类正常加载；英雄联盟房间列表提示需要登录，未代用户登录，不计为通过 |
| 设置 | 设置分类和主题设置正常打开；未修改用户配置，未验收所有设置的保存行为 |
| 自动化 | 12项平台/主题/颜色组件兼容测试通过；受影响3个Dart文件定向分析通过 |

流切换期间观察到引擎 NativeImage 缓冲获取/释放警告，后续日志有新首帧且实际画面恢复；
这不是长期稳定性、全部站点、音频听感或完整测试套件的验收。
全仓架构检查另有既存的 recorder 跨域引用违规，本次未改动该文件。

## 工具链与源码

- Flutter OH `3.41.10-ohos-1.0.1`，提交 `adaf911c35c9136a7d18fc424d714c9ec7724e60`。
- Dart `3.11.5`，DevEco Studio `26.0.0.851`，SDK `26.0.0.105` / API 26。
- 宿主声明最低 API 18，仅 API 26 获得本次实机证据。
- `media_core` 固定 `a13f5c15f90f0180a93a2ab539ea82ef55a7f7fd`。
- `media_kit` / `media_kit_video` 基线固定 `803c4a27912091db6f839d48d1b984a0d9f588c7`。
- 兼容依赖来源与许可见 [HARMONYOS_PATCHES.md](../third_party/HARMONYOS_PATCHES.md)。

根 SDK 与依赖约束针对鸿蒙兼容工具链调整，并对 32 处私有命名字段参数进行语法回写，保持参数名、类型、默认值和 required 标记。
颜色组件、列表缓存、拖拽与托盘相关 API 也做了对应兼容处理；这些不构成 Windows/Android 新版本验收。

## 真实故障与修复

1. **包名冲突**：设备 BMS 扩展已有 `com.mystyle.purelive`，普通原生包查询不能证明包名空闲，更新安装也遭拒。鸿蒙版改为独立的 `com.mystyle.purelive.ohos`，保留原应用及数据。
2. **网络插件缺失**：`MissingPluginException` 栈定位到默认清晰度选择中的 `MethodChannelConnectivity.checkConnectivity`。补入 `connectivity_plus_harmonyos` 0.0.1 与 GET_NETWORK_INFO 权限后，清晰度、线路和弹幕恢复。
3. **播放器初始化失败**：真机报 `mpv_client_api_version` 无法解析、`No available native assets`。构建目录有正确的 `ohos_arm64` 映射，但签名 HAP 漏掉 `NativeAssetsManifest.json`。按固定 SDK Android/Linux 目标的 copyAssets 实现补齐打包；重新安装后 MPV 后端注册、首帧与实际硬件解码播放均恢复。

SDK 补丁只改 OHOS 资产打包目标，校验源文件 SHA256，备份原文件与工具快照后应用。
详见 [补丁与回滚说明](../tool/patches/README.md)。
原生资产包括 `libmpv.so`、`libmedia_kit_event_loop.so`、`libsqlite3.so`，另带 SDK 的 `libc++_shared.so`；均按鸿蒙 arm64 准备，未使用 Linux glibc 库冒充。

## 已运行的检查

- 实际 OH Dart：7 个 OS 场景、35 项能力断言通过。
- 直接导入生产文件的隔离 Flutter 测试：12 项通过；包括平台分类、调色板、明暗主题和颜色选择器输入确认。
- 28 个受影响 Dart 文件聚焦分析通过；未执行完整应用回归。
- 最终签名 HAP ZIP CRC 通过，包名、原生库 ABI 与资产映射已核对。
- 本次源码上传后只增加文档、忽略规则和工作流归档变更，复用上述应用行为证据。

已验证本机签名 Debug HAP 的 SHA256：
`863ec83b4c48e897b02d81d5664a12688c7efb6f40898a04b007b7a39d946553`，278669232 字节。
该哈希用于追溯此次测试包，不承诺其他开发者重签名后得到相同字节。
调试证书/profile 绑定设备，未随源码上传，也未发布通用安装包。

## 构建与下一步

使用根 [README](../README.md#开发与构建) 的 Windows 构建入口。
配置你自己的开发者签名后执行 `-Codesign`。首次构建应解析依赖；只有解析完成后可用 `-SkipPubGet`。

后续验收按站点与能力分别记录：HLS/HTTP-FLV、画质/线路切换、持久化、横竖屏、系统返回、前后台及音频中断。
在相应能力完成前，不把上游已有功能直接标为鸿蒙已支持。
