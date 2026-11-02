# X06.2 鸿蒙平台官方网页登录

接X06.1，复用上游K01.3的平台官方登录配置、账号核验、保存及退出流程。鸿蒙端新增应用内部的WebLoginAbility，以独立原生ArkWeb窗口显示官方网页；Cookie通过私有能力结果和Flutter通道返回，随后交给原有加密存储。B站可切回二维码，其他平台保留手动Cookie导入。

登录前按平台域清理浏览器Cookie，失败则显示重试；不清空其他平台。官方网页只允许HTTPS导航，拒绝证书错误、HTTP降级、文件访问和混合内容，启用媒体手势限制；页面不注册JS原生接口。WebLoginAbility不向其他应用导出，HAP检查器验证其声明与私有属性。日志只记录不含URL、账号或Cookie的页面生命周期。

通用Flutter内嵌网页仍沿用原来的系统浏览器降级，不用网页登录窗口冒充通用WebView支持。签名材料与设备日志仅保留在本机。

接口依据：[OpenHarmony ArkWeb Cookie API](https://github.com/openharmony/docs/blob/master/en/application-dev/reference/apis-arkweb/arkts-apis-webview-WebCookieManager.md)。具体结果见[记录](record.md)与[真机步骤](verify.md)。实际账号、短信及验证码由用户完成；页面显示不等于完整登录已通过。

2026-11-02开发候选已签名安装，14个工作区完整回归8769项通过、1项原有跳过。斗鱼官方页面、空输入框键盘、短信登录切换和取消返回已做真机检查，虎牙首页可显示；真实登录、自动回传与重启保持等待用户验证。签名与未签名包分别保留，未签名包须自行签名。
