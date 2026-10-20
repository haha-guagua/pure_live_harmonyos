# 鸿蒙安装包说明

本项目基于 [liuchuancong/pure_live](https://github.com/liuchuancong/pure_live) 改造，属于实验性鸿蒙原生适配。请先阅读对应版本发布说明中的验证范围。

## 下载哪个文件

| 文件 | 用途 |
| --- | --- |
| `PureLive-vX.Y.Z-ohos.N-harmonyos-arm64-debug-device-signed.hap` | arm64 鸿蒙手机调试安装包，仅允许签名 profile 登记的设备安装 |
| `SHA256SUMS.txt` | 安装包 SHA-256 校验值 |
| `build-metadata.json` | 版本、提交、架构、构建模式和校验值，不包含证书或设备标识 |
| `INSTALLATION.md` | 本安装说明 |
| GitHub 自动生成的 Source code | 源码，不能直接安装 |

当前最低 API 20，仅 Mate 90 Pro / HarmonyOS 7.0.0.109 SP11 / API 26 获得实机验证。HAP 不是 Android APK；Debug 签名包也不是面向所有手机的正式发行包。

## 校验与安装

Windows PowerShell 中检查安装包：

```powershell
Get-FileHash .\PureLive-vX.Y.Z-ohos.N-harmonyos-arm64-debug-device-signed.hap -Algorithm SHA256
```

确认结果与 `SHA256SUMS.txt` 一致。使用 DevEco Studio 配套 HDC，手机开启开发者模式与 USB/无线调试并完成授权：

```powershell
hdc list targets
hdc -t '<设备标识或无线调试地址>' install -r '.\PureLive-vX.Y.Z-ohos.N-harmonyos-arm64-debug-device-signed.hap'
```

应用包名为 `com.mystyle.purelive.ohos`。同包名、兼容签名的覆盖安装通常保留数据；安装失败时先查看 HDC 的实际错误，不要直接卸载。卸载会影响关注、设置与沙箱录像，应先备份。

## 设备不在调试签名范围时

不能直接安装此调试包。用自己的华为开发者账号和 DevEco Studio，为自己的设备生成调试签名，再按根 README 从源码构建。不要索取或分享他人的私钥、口令、签名 profile 或原始设备标识。

正式通用分发需要另外完成发布签名、分发渠道配置与验收。本仓库的 GitHub Release 不等于已上架华为应用市场，也不承诺任意鸿蒙设备可侧载。

## 已知功能边界

播放、全屏、录制等结果以该版本说明为准。已验证的斗鱼短录制不能替代其他平台、HLS、长期或后台录制验证。全屏滑动调节本应用音量；实体音量键仍控制系统媒体音量。
