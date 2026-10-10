# Google Translate Menu

原生 Apple Silicon macOS 菜单栏翻译工具。独立开发，非 Google 官方产品。

## 下载

**[直接下载 Mac 安装包（v0.1.1 · Apple Silicon）](https://github.com/ming1024yue/google-translate-menu/releases/download/v0.1.1/GoogleTranslateMenu-0.1.1-arm64.dmg)**

[产品网站](https://yueming.xyz/products.html) · [版本说明与校验文件](https://github.com/ming1024yue/google-translate-menu/releases/tag/v0.1.1)

支持 macOS 13+ 和 M 系列 Mac。下载 DMG，将应用拖入 Applications 后启动。
应用与 DMG 已完成 Developer ID 签名、Apple 公证和 Gatekeeper 验证。
0.1.1 为预发布版本，完整交互和另一台 Mac 安装验收尚待完成。

## 使用

- 单击菜单栏气泡图标打开/隐藏窗口；双击显示包含退出操作的原生菜单。
- Command + Shift + G 快捷键显示/隐藏窗口。
- 支持中、英、日、韩目标语言，主动粘贴翻译，固定窗口和浏览器打开。
- 需要能访问 translate.google.com 的网络。语言切换会重新加载网页；暂不支持自动更新。

## 隐私

没有后台剪贴板监控、自建服务器、分析统计或广告 SDK。翻译内容交由 Google 网页处理。详见 [隐私说明](release/PRIVACY.md)。

## 开发

用 Xcode 打开 `Google Translate Menu.xcodeproj`，选择 My Mac 运行，或执行 `./build.sh`。
本地构建使用自签名；正式包使用 `./scripts/release.sh --publish`，需设置 SIGNING_IDENTITY 与 NOTARY_PROFILE。私钥及公证凭据保留在本机钥匙串，不提交到仓库。

## 反馈

[GitHub Issues](https://github.com/ming1024yue/google-translate-menu/issues)

## 许可证

源码采用 [MIT License](LICENSE)。Google 翻译服务及商标不包含在本项目许可证中。
