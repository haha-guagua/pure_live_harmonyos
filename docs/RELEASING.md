# 鸿蒙自动发布约定

## 当前状态

仓库公开源码。维护者已明确授权专用本机 Runner 构建并发布设备绑定的调试签名 HAP 与未签名 HAP。只允许仓库所有者触发版本标签/手动构建，不执行公开 PR 或 fork 工作流。私钥、口令和独立签名 profile 不作为发布附件；签名 HAP 本身包含验证所需的证书/profile及设备绑定信息。

## 触发与版本

普通提交不会发布。推送形如 `v3.1.19-ohos.1` 的标签后，`HarmonyOS preview release` 工作流自动构建并发布 GitHub 预览版。`3.1.19` 必须与 `pubspec.yaml` 的应用版本一致，末尾数字是该应用版本的鸿蒙迭代号。版本标签不可复用或强制移动。

每个标签必须有 `docs/releases/<标签>.md`，包含新增/修复、验证范围、已知限制、安装与升级说明。对应初版说明已提供；后续版本复制结构后填写真实变更，不能沿用旧版的真机验收结论。`.github/release.yml` 也提供 GitHub 自动生成说明的分类规则。

```bash
git tag -a v3.1.19-ohos.1 -m "HarmonyOS preview 1"
git push origin v3.1.19-ohos.1
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

4. 确认 Runner 能访问 GitHub、GitCode、pub.dev 与 OHPM，且可以运行 Git、PowerShell、Java 和编译工具。工作流通过固定提交的 `setup-python` 准备 Python 3.12。SDK 缓存与工具链补丁沿用本项目构建入口；重型任务仍使用共享资源锁。
5. 使用交互进程启动 Runner 进行首次验证；需要开机自动运行时再配置 Windows 服务。证书/profile 过期或增加设备时需在本机更新签名配置。

工作流只响应本仓库所有者的标签和手动事件，不执行 PR 或 fork 代码。公开源码不代表设备签名包可在所有设备安装。

## 发布附件与验收

构建后验证签名、ZIP完整性、应用包名/版本、Debug模式、arm64播放器与录制库、原生资产映射清单。同一构建产出的两种 HAP 还须通过逐项内容一致性检查；unsigned 必须不能通过包签名验证。成功后发布签名和未签名 HAP、`SHA256SUMS.txt`、`build-metadata.json` 和 `INSTALLATION.md`；完整说明写入 Release 正文。

先建立 Draft 并上传全部附件，再转为预览版。失败不覆盖已有正式可见版本。失败后留下的 Draft 应先检查附件与日志，再处理该草稿，不得用强制移动标签掩盖失败。

构建日志、签名配置、证书、原始设备标识不作为附件上传。GitHub Actions 中间产物保留7天。发布包含设备调试签名信息，只允许 profile 登记的设备安装。详情见 [安装说明](INSTALLATION.md)。

## GitHub Packages（可选）

GitHub Packages 不提供通用 HAP 文件仓库。面向手机的下载入口是 Releases。

工作流另预留 GHCR 容器归档：将仓库 Actions variable `PUBLISH_GHCR` 设置为字符串 `true` 后，同一版本发布成功会把安装附件归档到 `ghcr.io/haha-guagua/pure_live_harmonyos:<版本标签>`。这是供自动化使用的文件容器，不能当作手机应用或服务启动。本机接入时已按维护者授权启用此步骤。

首次发布的 Package 应检查为 Private，并保持仓库权限继承。流程使用短期 `GITHUB_TOKEN` 的 `packages:write` 权限，不需要额外提交 PAT。不要把此含设备限定签名的归档改为 Public。

下载归档时先按 GitHub 文档完成 GHCR 身份认证，再提取文件：

```bash
docker pull ghcr.io/haha-guagua/pure_live_harmonyos:v3.1.19-ohos.1
docker create --name purelive-extract ghcr.io/haha-guagua/pure_live_harmonyos:v3.1.19-ohos.1 /unused
docker cp purelive-extract:/release/. ./pure-live-release
docker rm purelive-extract
```

普通手机测试用户直接下载 Releases 的 HAP，无需 Docker。
