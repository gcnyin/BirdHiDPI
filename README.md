# Bird HiDPI

[简体中文](README.md) | [English](README.en.md)

<img src="Resources/AppIcon.png" alt="Bird HiDPI 应用图标" width="128" height="128">

Bird HiDPI 是一个轻量的原生 macOS 菜单栏工具，用于在真实外接显示器上选择 WindowServer 已经提供、但系统设置可能没有展示的 HiDPI 模式。

> [!WARNING]
> 本项目依赖 macOS 私有 SkyLight API。系统更新可能导致功能失效或需要适配，应用也不适合提交 Mac App Store。切换前请保存正在进行的工作。

## 特性

- 在同一个物理显示器 ID 上直接切换，不创建虚拟显示器或镜像桌面。
- 分开展示标准与 HiDPI 模式，并列出对应的逻辑分辨率和 framebuffer 尺寸。
- 只展示与面板原生宽高比匹配、可作为桌面模式使用的分辨率。
- 尽量保持当前刷新率和像素编码。
- 切换后验证 framebuffer、在线显示器集合和屏幕排列，验证失败时立即恢复。
- 点击“恢复”、退出应用或正常结束会话时恢复启动前的显示模式。
- 不安装显示器 override，不修改 EDID，不需要管理员权限或屏幕录制权限。
- 支持简体中文、English 以及自动跟随系统语言。

例如，在原生分辨率为 2560 x 1440 的显示器上选择 1920 x 1080 HiDPI 时，WindowServer 可以使用 3840 x 2160 framebuffer 渲染，再缩采样至物理面板。前提是当前 macOS、显卡和显示器连接已经提供这个 mode；本应用不会凭空创建新的显示模式。

## 系统要求

- macOS 13 Ventura 或更高版本
- 至少一台真实外接显示器
- Xcode Command Line Tools（仅从源码构建时需要）

可用模式由 macOS、显卡、线材/接口和显示器共同决定。不同机器上的分辨率与刷新率列表可能不同。

## 安装

### 从 GitHub Releases 安装

1. 从 [Releases](../../releases) 下载最新的 `Bird-HiDPI-<version>-macos.zip`。
2. 解压后将 `Bird HiDPI.app` 移入“应用程序”目录。
3. 首次启动若 macOS 提示无法验证开发者，请在 Finder 中按住 Control 点击应用，选择“打开”。

当前公开构建使用 ad-hoc 签名，尚未使用 Apple Developer ID 签名或公证。无需关闭 Gatekeeper，也不要运行来源不明的解除隔离脚本。

下载校验文件后，可在同一目录验证压缩包：

```sh
shasum -a 256 -c Bird-HiDPI-1.0.0-macos.zip.sha256
```

### 从源码构建

```sh
git clone https://github.com/gcnyin/BirdHiDPI.git
cd BirdHiDPI
make test
make app
open "dist/Bird HiDPI.app"
```

## 使用

1. 点击菜单栏中的显示器图标。
2. 打开或关闭 HiDPI 开关。
3. 在完整列表中选择目标逻辑分辨率。
4. 点击“应用”。启用后可继续直接切换模式。
5. 点击“恢复”返回应用启动前的显示模式。

应用只对当前登录会话应用显示模式。正常退出时会恢复原模式，因此如果希望持续使用所选模式，需要保持应用运行。

## 安全与故障恢复

模式切换通常会造成短暂黑屏。应用会在切换后检查物理显示器是否仍在线、显示器集合和排列是否变化，以及实际 framebuffer 是否符合预期；任何一项失败都会尝试恢复切换前的 mode number。

由于底层接口是私有 API，无法保证所有 macOS 版本、显卡和显示器组合都不会触发 WindowServer 异常。如果画面没有自动恢复，请重新登录当前用户会话或重新连接显示器；`.forSession` 配置不会作为永久系统配置写入。报告问题时请附上 macOS 版本、Mac 型号、显示器型号、连接方式、目标分辨率和刷新率。

安全问题请参阅 [SECURITY.md](SECURITY.md)。一般故障请使用 GitHub Issue 模板。

## 工作原理

应用通过 SkyLight 的 `CGSGetNumberOfDisplayModes` 与 `CGSGetDisplayModeDescriptionOfLength` 读取完整 mode 表，再在 `CGBeginDisplayConfiguration` / `CGCompleteDisplayConfiguration` 事务中调用 `CGSConfigureDisplayMode`，按 mode number 切换原物理显示器。

切换使用 CoreGraphics 的 `.forSession` 范围。应用不创建第二个显示器、不建立 ScreenCaptureKit 采集流，也不写入 `/Library/Displays`。

## 隐私

应用没有网络功能，不收集遥测数据。它只在本地 `UserDefaults` 中保存每台显示器上次选择的输出模式和应用语言偏好。

## 开发

常用命令：

```sh
make build       # Debug 构建
make test        # 本地化校验与单元测试
make icon        # 重新生成 AppIcon.png 与 AppIcon.icns
make app         # 生成 dist/Bird HiDPI.app
make release     # 生成版本化 ZIP 与 SHA-256
```

显式集成测试会真实切换外接显示器模式，默认不会运行：

```sh
RUN_DISPLAY_INTEGRATION_TEST=1 \
swift test --filter DisplayIntegrationTests/testResolutionAndHiDPIToggleEndToEnd
```

只读 mode 表诊断同样需要显式启用。运行实机测试前请保存工作，并确保能通过重新登录恢复会话。

## 参与项目

提交问题或代码前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。版本变化记录在 [CHANGELOG.md](CHANGELOG.md)。

## 许可证

本项目采用 [MIT License](LICENSE)。
