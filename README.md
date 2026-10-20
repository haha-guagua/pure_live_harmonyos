<div align="center">

<img src="assets/icons/icon.png" width="120" alt="Pure Live 图标" />

# Pure Live HarmonyOS · 纯粹直播鸿蒙适配版

基于 Flutter 的直播聚合播放器 · HarmonyOS 原生实验适配

</div>

**本项目基于 [liuchuancong/pure_live](https://github.com/liuchuancong/pure_live) 进行鸿蒙原生适配改造。**
上游基线为 [`997713d21498350a92f260951fb0400f51e8ef42`](https://github.com/liuchuancong/pure_live/commit/997713d21498350a92f260951fb0400f51e8ef42)，应用版本 `3.1.19+4108`。感谢原作者和上游贡献者；本仓库继承原项目源码及 AGPL-3.0 许可证，新增工作集中在鸿蒙工程、插件、原生播放器和构建兼容性，不代表上游官方鸿蒙版本。

当前是**已通过部分真机验证的实验版本**，尚未完成全部站点和功能验收。源码沿用上游的多平台结构，但本仓库的验证范围以以下鸿蒙记录为准。

## 真机验证

2026-10-19，在 HUAWEI Mate 90 Pro（CMS-AL20、HarmonyOS 7.0.0.109 / API 26、arm64-v8a）上通过签名 HAP 安装与无线调试验证：

| 项目 | 结果 |
| --- | --- |
| 安装、冷启动、首屏 | 通过 |
| 哔哩哔哩热门直播列表、直播间导航 | 通过 |
| HTTP-FLV 直播 | 已确认 H.264 1280×720 / 30fps 视频出画面 |
| 硬件解码 | MPV 日志确认使用鸿蒙 `ohcodec` |
| 音频输出 | AAC 双声道 48kHz，`ohaudio` 日志报告播放；听感与长时间音画同步未独立验收 |
| 弹幕 | 连接成功，页面可显示弹幕 |
| 前后台切换 | 一次返回前台后视频画面继续显示 |

2026-10-20 补充回归：全屏左右滑动已实测可改变窗口亮度和应用音量（实体音量键仍控制系统音量）。已修复全屏按钮与返回处理，真机连续全屏进入、按钮退出及系统返回退出均通过；斗鱼播放、清晰度/线路切换、弹幕、关键词搜索、关注筛选及关注跨应用重启保留均获得部分验证。设置和主题设置页面可打开。哔哩哔哩分区主分类能加载，但部分房间列表需登录，当前未通过该项。

2026-10-20 录制与手势回归：斗鱼短录制完成，停止后生成约 50 秒、13.70 MB 的 MP4，已实际播放并确认进度推进；左右上/下滑均能调节窗口亮度或应用音量，退出房间后亮度恢复跟随系统。测试录像保留在录制中心。

HLS、其他未记录站点、IPTV、自由旋转与其他方向策略、来电中断、长期播放、所有设置的持久化等仍待单独验证。流切换期间有底层纹理缓冲警告，实际画面可恢复，详见 [回归记录](docs/HARMONYOS_PORT.md#2026-10-20-主要功能实机回归)。上游注册的站点数量不等于鸿蒙版已全部支持。

## 已知限制

- 录制目前仅验证斗鱼 HTTP-FLV 的短录制、停止及 MP4 回放；其他站点、HLS、长时间录制、断流重连和后台持续录制仍待验收。
- 系统媒体会话暂未接入，不承诺锁屏控制和系统音频中断处理。
- IJK / Exo、系统画中画、Firebase、扫码 / WebView、投屏与分享等未在鸿蒙验收。
- 曾观察到版本检查接口返回 HTML、导致 `releases.json` 解析失败；不影响已验证的直播播放，该问题仍待处理。
- 当前是 Debug 构建，尚无面向所有设备的正式发行版或自动化鸿蒙 CI。

## 本次改造内容

- 增加 `ohos/` 原生宿主，鸿蒙包名为 **`com.mystyle.purelive.ohos`**。独立包名用于与可能已存在的上游版本并存。
- 使用 Flutter OH `3.41.10-ohos-1.0.1` / Dart `3.11.5`，调整依赖和部分语法/API以适配该 SDK，兼容代码保存在 `compat/`、`third_party/`。
- 为路径、偏好存储、应用信息、链接、常亮和网络类型检测接入鸿蒙实现；补齐 `GET_NETWORK_INFO` 权限。
- 使用鸿蒙 arm64 MPV 原生库，并通过 OpenHarmony clang 编译事件循环与 SQLite；随包准备 SDK 的 C++ 运行库。
- 修复 Flutter OH 工具链漏打包 `NativeAssetsManifest.json` 的问题：缺少该清单会导致 MPV 初始化失败，并在界面上表现为“解码失败”。补丁按固定 SDK 源码哈希校验，备份后应用，详见 [SDK 补丁说明](tool/patches/README.md)。
- 补齐鸿蒙移动端全屏分支，并修复固定版 Flutter OH 系统界面方法漏回调的问题；构建自动校验和备份引擎补丁，详见 [全屏修复记录](docs/HARMONYOS_PORT.md#全屏适配修复2026-10-20)。
- 接入鸿蒙窗口亮度、应用音量及原生 FFmpeg 录制桥接；固定 AKI 1.2.25，避免桥接库自动升级导致会话创建崩溃。
- 保留第三方依赖许可证，并在 [兼容依赖清单](third_party/HARMONYOS_PATCHES.md)中记录来源和修改范围。

完整的通过项、限制与构建产物校验见 [鸿蒙适配记录](docs/HARMONYOS_PORT.md)。

## 开发与构建

已验证环境为 Windows 11 x64、DevEco Studio `26.0.0.851`、内置 HarmonyOS SDK/API 26。工程声明最低 API 20，但本次只在 API 26 真机验证。

1. 从 [Flutter OH 官方仓库](https://gitcode.com/CPF-Flutter/flutter_flutter)准备固定 SDK：

   ```powershell
   git clone --depth 1 --branch 3.41.10-ohos-1.0.1 https://gitcode.com/CPF-Flutter/flutter_flutter.git E:\DevTools\FlutterOH-3.41.10
   & 'E:\DevTools\FlutterOH-3.41.10\bin\flutter.bat' --version
   ```

   `.fvmrc` 记录的是鸿蒙分支标签，不能直接替换为普通 Flutter 稳定版。首次运行 SDK 和构建需要下载依赖与原生资源。

2. 安装 DevEco Studio，并确认已安装所需 SDK。将本仓库克隆到 Windows 本地目录，例如 `E:\DevWork\pure_live_harmonyos`。下列示例使用自定义工具路径，可按实际位置修改参数。

   ```powershell
   git clone https://github.com/haha-guagua/pure_live_harmonyos.git E:\DevWork\pure_live_harmonyos
   cd E:\DevWork\pure_live_harmonyos
   ```

3. 在仓库根目录执行未签名构建：

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tool\build_harmonyos.ps1 `
     -FlutterSdk 'E:\DevTools\FlutterOH-3.41.10' `
     -DevEcoStudio 'E:\DevTools\DevEcoStudio' `
     -PubCache 'E:\DevTools\PubCache-OH'
   ```

   构建入口负责生成本地 `ohos/build-profile.json5`、校验 SDK 版本、应用固定版本的资产打包补丁、准备 C++ 运行库、按锁文件解析依赖并串行构建。原生依赖由构建过程准备，不把生成的 `.so`、SDK 或缓存提交到 Git。

   产物：`build\ohos\hap\entry-default-unsigned.hap`。

4. 真机安装需要你自己的华为开发者调试签名：用 DevEco Studio 打开 `ohos/`，登录开发者账号，在项目签名配置中为已连接设备生成自动签名。确认 `default` 产品的 `signingConfig` 指向对应签名配置，再执行：

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tool\build_harmonyos.ps1 -SkipPubGet -Codesign
   ```

   使用自定义工具路径时同时传入上一步的路径参数。首次构建不要使用 `-SkipPubGet`。

   产物：`build\ohos\hap\entry-default-signed.hap`。调试 profile 通常只允许其中登记的设备安装，不是通用安装包。

`ohos/build-profile.template.json5` 是无凭据模板；实际 `build-profile.json5`、证书、私钥、口令、HAP 和本地调试记录均不应提交。原上游的 Android/桌面发布工作流保存在 `.github/workflows-disabled/`，本仓库不会自动触发它们；鸿蒙构建目前通过上述本机入口执行。

## 验证记录

- 实际鸿蒙 Dart SDK：7 个 OS 场景、35 项能力断言通过。
- 隔离 Flutter 测试宿主：12 项测试通过，覆盖平台分类、主题与颜色选择器；不等于全应用回归。
- 28 个受影响 Dart 文件：聚焦 `flutter analyze --no-pub` 通过。
- 签名 HAP：ZIP CRC、arm64 原生库、资产映射清单及上述真机播放验证通过。

这些记录对应已验证的鸿蒙兼容源码；上传所做的说明文档、忽略规则和工作流归档修改没有触发重复的应用构建。

## 来源、许可与致谢

- 原始项目：[liuchuancong/pure_live](https://github.com/liuchuancong/pure_live)。上游功能和其他平台发行说明请以原项目为准。
- Flutter OH：[CPF-Flutter/flutter_flutter](https://gitcode.com/CPF-Flutter/flutter_flutter)。
- 播放器：[Predidit/media-kit](https://github.com/Predidit/media-kit)，以及 [media-kit 鸿蒙适配工作](https://github.com/media-kit/media-kit/pull/1326)。
- 本仓库保留 [GNU AGPL v3](LICENSE)。各第三方依赖仍适用其各自的许可证，具体见依赖目录中的 LICENSE 和来源记录。

本项目是第三方客户端，与直播平台无隶属关系。请遵守相关平台规则并尊重内容版权。
