# Timbre 1.1.1

**仅 64 位 / 64-BIT ONLY.** 只有 `arm64-v8a`。没有 32 位包。天玑 9300/9400/9500/9600 与骁龙 8 全系都是 64 位，Android 17 也不再完整支持 32 位应用。

**Android 16/17.** targetSdk 36，edge-to-edge 全屏手势、预测性返回、16 KB 页对齐（`zipalign -c -P 16` 与 ELF `LOAD` 对齐均已验证）都做了。Android 17 上直接沿用这套行为。

这是 [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) 的二次开发版，保留 **MPL-2.0**。不是上游官方发行版，APK 由独立证书签名。

## 下载 / Download

- APK（arm64-v8a，45 MB）: https://aka.doubaocdn.com/s/DSfkMAOXs0
- 源码快照（zip）: https://aka.doubaocdn.com/s/CJ4SmY0GJl

APK SHA-256: `cadaec162f4f11caf536652f42e32cebfa40d9d48647ad6837a3e78e47c750e9`

包名 `com.technicjelle.simple_audio_converter.zh`，可与上游原版共存，也能直接覆盖本项目的旧版本。签名证书 SHA-256 `354871FE58DC66F7CB5780F1DEBA20565897C9A4DD0C22154A9549F4E405F3F7`。

## 用到的开源项目 / Open source used

这个应用是把现成项目拼起来再改，不是从零重写：

- **[SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter)**（MPL-2.0）— 应用底座、Android 工程、文件选择与分享入口。
- **[FFmpegKit](https://github.com/arthenica/ffmpeg-kit)**（LGPL-3.0）及其社区维护分支 `ffmpeg_kit_flutter_new_audio` — 转码运行时，内置 FFmpeg 与音频编码器。
- **[FFmpeg](https://ffmpeg.org)**（LGPL-2.1+）— 编解码与封装。
- **[m3_expressive](https://pub.dev/packages/m3_expressive)**（MIT，fabric-apps）— M3 Expressive 形变加载器；形状库来自 **material_shapes**（MIT，Kostiantyn Sokolovskyi）。
- **Flutter**（BSD-3-Clause）— UI 框架。
- **file_picker**（MIT）、**share_plus**（BSD-3-Clause）、**share_handler**（MIT）、**shared_preferences**（BSD-3-Clause）、**path_provider**（BSD-3-Clause）、**installed_apps**（Apache-2.0）— 文件选择、分享、接收分享、设置持久化、路径与已安装应用查询。

上游 1.0.5 的原始版权归 TechnicJelle 及贡献者所有。本仓库新增与修改的文件同样以 MPL-2.0 提供。

## 相对上游改了什么 / What changed

1. **11 种输出**：MP3、M4A (AAC)、OGG (Vorbis)、Opus、FLAC、WAV、AIFF、ALAC、WMA、MP2、AC-3。
2. **码率连续可调**：格式范围内任意 kbps（MP3 8–320、AAC 8–512、Opus 6–510）；只有编解码器本身有固定档位的格式才保留档位。`191` 也能填，LAME 内部会落到 192k，这是编码器行为。
3. **CBR/VBR 都在**：MP3 `-q:a 0–9`、Vorbis `0–10`、Opus VBR 开关；AAC/WMA/MP2/AC-3 没有质量档，就不假装有，只给 CBR。
4. **格式可展开**：每个格式都有一句用途说明和一段取舍详情，可在应用内展开查看全部 11 种。
5. **沉默 bug 修复**：命令改为 `-map 0:a:0 -vn -map_metadata 0`，只留第一条音轨，丢掉视频与封面图轨。
6. **界面**：Material 3 Expressive，大连续圆角、分层色调、悬浮模糊底栏、形变动效、弹簧曲线；支持自定义主题色并持久化，深浅色跟随系统。
7. **中英双语**：按系统语言自动切换，格式名统一英文。
8. **SoC 识别**：`Build.SOC_MODEL` → `ro.soc.model` → `ro.vendor.qti.soc_model` / `ro.vendor.qti.soc_name` / `ro.qti.soc_model` → `ro.chipname` → `ro.mediatek.platform` → `ro.board.platform` → `ro.hardware` / `ro.boot.hardware` / `ro.product.board`，再用 `sun`/`pineapple`/`kalama`/`taro`/`parrot` 代号兜底。某些骁龙 8 第六代机器把 `SOC_MODEL` 填成 `0`，会继续往下找而不是显示错误型号，并在界面上标出这一情况。ROM 标识读取 HyperOS、MIUI、ColorOS、OriginOS 与通用 `ro.build.version.release`。
9. **解码与线程**：自动 / 软件 CPU / MediaCodec；编码线程 1–8 或自动。纯音频转码不会走视频硬解，界面上已注明。

## 构建 / Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

环境：Flutter 3.50 / Dart 3.14，JDK 17，Android SDK 36 + build-tools 36.0.0 + NDK 28.2.13676358。签名配置不随仓库提供。

## 许可 / License

MPL-2.0，见 [LICENSE](LICENSE)。署名与第三方许可见 [THIRD_PARTY.md](THIRD_PARTY.md)。
