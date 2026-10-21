# 鸿蒙自动发布约定

## 当前状态

仓库公开源码。维护者已明确授权专用本机 Runner 构建并发布设备绑定的调试签名 HAP 与未签名 HAP。只允许仓库所有者触发版本标签/手动构建，不执行公开 PR 或 fork 工作流。私钥、口令和独立签名 profile 不作为发布附件；签名 HAP 本身包含验证所需的证书/profile及设备绑定信息。

## 触发与版本

普通提交不会发布。推送形如 `v3.1.19-ohos.2` 的标签后，`HarmonyOS preview release` 工作流自动构建并发布 GitHub 预览版。`3.1.19` 必须与 `pubspec.yaml` 的应用版本一致，末尾数字是该应用版本的鸿蒙迭代号。版本标签不可复用或强制移动。

每个标签必须有 `docs/releases/<标签>.md`，包含新增/修复、验证范围、已知限制、安装与升级说明。对应初版说明已提供；后续版本复制结构后填写真实变更，不能沿用旧版的真机验收结论。`.github/release.yml` 也提供 GitHub 自动生成说明的分类规则。

例如准备好下一轮 `docs/releases/v3.1.19-ohos.4.md` 并提交后：

```bash
git tag -a v3.1.19-ohos.4 -m "HarmonyOS preview 4"
git push origin v3.1.19-ohos.4
```

标签应指向已合并到 `main` 并通过本轮所需检查的提交。也可以在 Actions 中选择已有版本标签手动运行。分支或不合法标签会被拒绝。

## 构建机器

当前工作流需要专用 Windows x64 self-hosted Runner，标签为 `pure-live-ohos`，电脑必须开机联网。它复用固定 Flutter OH 与 DevEco SDK，构建目录由 Runner 独立管理，不使用日常开发工作区作为 checkout 目录。

Runner 尚未注册时，工作流会等待机器，不会自动在 GitHub 云端安装 DevEco。配置步骤：

1. 仓库 Settings → Actions → Runners → New self-hosted runner，选择 Windows x64，按 GitHub 当场生成的命令注册到独立目录，例如 `E:\DevTools\PureLiveCI\runner`。添加 `pure-live-ohos` 标签。注册凭据只在本机使用，不写入仓库或聊天。
2. 在 Runner checkout 目录外保存本地签名配置，例如 `E:\DevTools\PureLiveCI\signing\build-profile.json5`。可从已验证的本机配置直接复制，保持证书路径有效；不要将私钥、profile、密码上传成发布附件。
3. 创建 `E:\DevTools\PureLiveCI\config.json`，只记录路径：

   ```json
   {
     "FlutterSdk": "E:\\DevTools\\FlutterOH-3.41.10",
     "DevEcoStudio": "E:\\DevTools\\DevEcoStudio",
     "PubCache": "E:\\DevTools\\PubCache-OH",
     "SigningProfile": "E:\\DevTools\\PureLiveCI\\signing\\build-profile.json5"
   }
   ```

4. 普通权限 Runner 需要 Windows 开发者模式提供插件符号链接支持，否则 Flutter 会在依赖解析后停止。由设备所有者确认后，在 Windows 设置的“开发者选项”中开启；参见 [微软说明](https://learn.microsoft.com/en-us/windows/advanced-settings/developer-mode)。不要为此改用管理员 Runner。
5. 确认 Runner 能访问 GitHub、GitCode、pub.dev 与 OHPM，且可以运行 Git、PowerShell、Java 和编译工具。工作流通过固定提交的 `setup-python` 准备 Python 3.12。SDK 缓存与工具链补丁沿用本项目构建入口；重型任务仍使用共享资源锁。
6. 使用交互进程启动 Runner 进行首次验证；需要开机自动运行时再配置 Windows 服务。证书/profile 过期或增加设备时需在本机更新签名配置。

工作流只响应本仓库所有者的标签和手动事件，不执行 PR 或 fork 代码。公开源码不代表设备签名包可在所有设备安装。

### 当前本机配置

- 节点名称：`pure-live-ohos-windows`，仅供本仓库使用，标签 `pure-live-ohos`。
- Runner 程序：`E:\DevTools\PureLiveCI\runner`；工作目录：`E:\pl-ci`，用于避免 Windows 路径过长。Runner 进程单独启用 Git `core.longpaths`，不修改系统全局 Git 设置。
- `PureLive-HarmonyOS-Runner` 计划任务在当前用户登录时启动，使用非提升权限。用户退出登录、电脑关机或网络代理不可用时不能构建。
- 签名配置位于仓库外受限目录，构建临时复制到 checkout，结束时清除。GitHub 只接收安装包与说明，不接收独立私钥、口令或签名配置。
- `PUBLISH_GHCR=true` 已启用；当前 GHCR 归档可匿名读取，与公开 Release 的附件内容相同。包可见性与仓库可见性分别管理，不能仅凭仓库状态推断包状态。

### 已完成的首次发布

2026-10-20，[v3.1.19-ohos.2](https://github.com/haha-guagua/pure_live_harmonyos/releases/tag/v3.1.19-ohos.2) 的 [构建、Release 和 Packages 三个任务](https://github.com/haha-guagua/pure_live_harmonyos/actions/runs/39387605667) 全部成功。源码提交 `797acea9fedb64fc7d9f786b65c205336ea7d3c2`，两个 HAP 及三个说明/校验附件的线上大小与 SHA-256 均已和本机产物核对一致。新包未执行真机复测。

同版本 GHCR 清单摘要为 `sha256:f682598122ff65269dcb1c71268e04dfb78dea508d7eb98ab74792e27d6d6df1`；匿名读取清单返回 HTTP 200。当前本机 GitHub CLI 没有 `read:packages` scope，因此没有通过 Packages REST API 读取设置页中的可见性字段；不以此声称包保持私有。Runner 发布后在线且空闲。

### 全屏与音量修复预览版

2026-10-21，[v3.1.19-ohos.3](https://github.com/haha-guagua/pure_live_harmonyos/releases/tag/v3.1.19-ohos.3) 已发布签名/未签名 HAP 及三个说明/校验附件，全部线上大小与 SHA-256 与本机产物一致。应用提交 `d94b5bf38e994eaf7edfea64ddb217b2c599a4ac`；签名包已覆盖安装并完成本轮全屏点击和音量真机复测，详见 [适配记录](HARMONYOS_PORT.md#全屏操作栏与音量修复2026-10-21)。

[原构建任务](https://github.com/haha-guagua/pure_live_harmonyos/actions/runs/39562269147) 编译、签名及双包校验通过，上传中间产物因网络失败。随后 [恢复任务](https://github.com/haha-guagua/pure_live_harmonyos/actions/runs/39566465502) 沿用该构建完成上传、Release 与 Packages 三阶段，不重复构建或移动标签。GHCR 清单摘要为 `sha256:d6e25d95b063d7589ca6e16961469f2d289fe72d7752d9d5b5d5483d7e2e46b0`，匿名读取 HTTP 200。

## 发布附件与验收

构建后验证签名、ZIP完整性、应用包名/版本、Debug模式、arm64播放器与录制库、原生资产映射清单。同一构建产出的两种 HAP 还须通过逐项内容一致性检查；unsigned 必须不能通过包签名验证。成功后发布签名和未签名 HAP、`SHA256SUMS.txt`、`build-metadata.json` 和 `INSTALLATION.md`；完整说明写入 Release 正文。

先建立 Draft 并上传全部附件，再转为预览版。失败不覆盖已有正式可见版本。失败后留下的 Draft 应先检查附件与日志，再处理该草稿，不得用强制移动标签掩盖失败。

如果编译、签名和双包校验已通过，仅上传因网络失败，可手动运行 `HarmonyOS package recovery` 并输入原版本标签，勾选 `recover_release`。任务只允许仓库所有者触发：本机 Runner 校验保留在 `E:\pl-ci\pure_live_harmonyos\pure_live_harmonyos\local-artifacts\release` 的元数据、标签提交、文件名和哈希，上传压缩中间产物；云端续传同一 Draft，核对全部附件后发布并归档到 GHCR。失败的中间产物上传自动重试一次。恢复过程不重新编译或访问签名配置，不替换已完成且内容不同的附件，只清理同一草稿中未完成的上传占位项。

如果 Release 已发布，仅缺 Packages，保持 `recover_release=false`。此时任务直接从 Releases 下载并验证附件后归档，不使用本机 Runner。已存在的同版本容器标签会拒绝覆盖。

构建日志、签名配置、证书、原始设备标识不作为附件上传。GitHub Actions 中间产物保留7天。发布包含设备调试签名信息，只允许 profile 登记的设备安装。详情见 [安装说明](INSTALLATION.md)。

## GitHub Packages（可选）

GitHub Packages 不提供通用 HAP 文件仓库。面向手机的下载入口是 Releases。

工作流另预留 GHCR 容器归档：将仓库 Actions variable `PUBLISH_GHCR` 设置为字符串 `true` 后，同一版本发布成功会把安装附件归档到 `ghcr.io/haha-guagua/pure_live_harmonyos:<版本标签>`。这是供自动化使用的文件容器，不能当作手机应用或服务启动。本机接入时已按维护者授权启用此步骤。

归档内容与已授权公开发布的 Release 文件一致。包的实际访问范围应独立核查；当前版本已确认可匿名读取。GitHub 的容器仓库支持公开包匿名访问，访问权限继承和包可见性有所区别，参见 [官方权限说明](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)。流程使用短期 `GITHUB_TOKEN` 的 `packages:write` 权限，不需要额外提交 PAT。

下载归档后提取文件；若后续将包设为私有，需先完成 GHCR 身份认证：

```bash
docker pull ghcr.io/haha-guagua/pure_live_harmonyos:v3.1.19-ohos.2
docker create --name purelive-extract ghcr.io/haha-guagua/pure_live_harmonyos:v3.1.19-ohos.2 /unused
docker cp purelive-extract:/release/. ./pure-live-release
docker rm purelive-extract
```

普通手机测试用户直接下载 Releases 的 HAP，无需 Docker。
