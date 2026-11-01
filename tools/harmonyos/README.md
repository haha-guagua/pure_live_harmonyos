# HarmonyOS 构建与检查

此入口仅构建原生HAP，基于wzgrx/PureLive 5.5.0，不生成Android或桌面发布包。使用独立Flutter OH 3.47.8-ohos-1.0.0（Dart实测3.13.3）、DevEco 26与API26（新引擎最低API24），固定版本及框架修复校验在toolchain.json。SDK安装来源为 https://atomgit.com/oh-flutter/flutter_flutter ，标签提交9d2002f78070ca6eb1fea073eb1baac07e287089；官方语义树修复来源和原始补丁保留在 ../flutter_sdk/。

Windows原生工作副本默认 E:\DevWork\PureLiveNextOH；WSL主源码 /home/gdx/code/PureLive_harmonyos。先同步源码，再从工程根执行：

```powershell
powershell -ExecutionPolicy Bypass -File tools\harmonyos\prepare_sdk.ps1
powershell -ExecutionPolicy Bypass -File tools\harmonyos\gate.ps1 -All
powershell -ExecutionPolicy Bypass -File tools\harmonyos\build.ps1 -SkipPubGet
```

各入口串行获取同一资源守卫；不要在外层重复套锁。Windows和WSL的Python均要求3.11以上，分别可传入-Python及-PosixPython；Bash门禁回归由WSL中的主源码执行，-SourceCheckout指定其UNC路径。Flutter、DevEco、PubCache路径均可参数覆盖。质量门禁保留14个工作区成员的格式、fatal-infos分析和测试，以及仓库分层、隐私、界面、文档、归属、门禁脚本与官方语义树回归。宿主测试需要可用C++编译器。不要把依赖版本降低或移除门禁来代替移植。

产物：apps/pure_live/build/ohos/hap/entry-default-unsigned.hap。未签名包不能直接安装。新包名com.mystyle.purelive.next.ohos，与旧鸿蒙版并存；周一设备调试时使用匹配该包名的外部证书/profile。需要签名时传-Codesign -SigningProfile <仓库外build-profile.json5>，所有签名文件保持仓库外。

构建记录、日志与包校验数据保存在忽略目录local-artifacts。构建检查ZIP CRC、包名/版本/API、arm64 ELF、必需原生库及OHOS资产映射，不能替代实际解码、系统音量与录制回放验收。

原生修复来源：旧适配仓库 haha-guagua/pure_live_harmonyos 的d94b5bf用于历史回归；Flutter OH新版自身已包含NativeAssetsManifest打包修复。FFmpeg采用OHPM @ohos/ffmpeg-kit 1.0.0，AKI固定1.2.25。第三方来源和许可证见各兼容包OHOS_COMPAT.md。

系统音量使用公开 `AVVolumePanel` 组件，由Flutter中明确的手势、滑块或静音操作触发；不依赖已废弃的 `AudioManager.setVolume` 或系统级权限。组件初始值从当前MEDIA档位读取，实体键事件同步回Flutter，写入以事件/超时回读确认。系统音量面板保留默认显示位置。参考：https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-audio-kit/ohos-multimedia-avvolumepanel.md 。实际系统版本上的行为仍以周一真机验收为准。

宿主测试与HAP使用不同平台内核：`flutter-host-test.patch` 仅为 `TargetPlatform.tester` 选择与cf636b1引擎同源的官方host_common内核、前端快照和Dart 3.13.7 AOT运行时，HAP保留OHOS内核；两处窗口平台判断使用等价的operatingSystem检查以兼容宿主Dart核心库。准备脚本校验下载归档、内核及修改后源码的SHA-256，旧快照保留备份。框架语义树回归按原文件及相对依赖逐字复制到本机忽略目录，在已解析的应用工作区执行，避免把完整Flutter开发仓库当作已安装SDK。

Windows聊天布局基线使用 `chat_list_sizing_baseline_windows_cf636b1.json`，绑定上述宿主引擎。原基线保留；108组合、三套主题和0.01像素比较精度均保留。新旧基线仅8个坐标相差约0.0375像素，测量所用聊天组件源码与固定上游提交一致。
