# Timbre

一个 Android 音频转换器。选文件、选格式、点转换，没有别的活。

这是 [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) 的二次开发版。底座、Android 工程、文件选择和分享入口都来自上游，原项目用 MPL-2.0，这个仓库也照样。

[English](README.en.md)

## 下载

安装包、源码快照、版本号、校验值和每个版本的改动都在 [Releases](https://github.com/Teacers/SimpleAudioConverter/releases)。这份说明只写软件本身，不再重复发行内容。

只提供 `arm64-v8a`。包名保持 `com.technicjelle.simple_audio_converter.zh`，从旧版覆盖安装不会丢设置。签名证书没有换。

## 能做什么

输出格式 18 种，分日常、无损、语音、老格式、其他五类。日常是 MP3、M4A、AAC、OGG、Opus；无损是 FLAC、WAV、AIFF、ALAC、CAF、AU、WavPack；语音是 AMR-NB、AMR-WB；老格式是 WMA、MP2、AC-3、E-AC-3。分组可以自己建，长按能删。

MP3 可以选 MPEG-1、MPEG-2 和 MPEG-2.5。切版本后码率上限跟着变，12 kHz 的版本不会让你拖到 320 kbps。AMR 只有固定档位，滑块会吸附到合法码率。

码率下面有整体音量，范围 -12 到 +12 dB，0 dB 保持原样。正增益会自动限幅，避免削波。另一个开关是“统一整批响度”，适合一批文件里既有轻声录音又有正常成品的情况。开了它，音量滑块不参与。

批量转换、停止确认、硬解失败一键切软解、软解失败提示换格式或版本，这些都在。小窗、分屏、平板都能用，界面没有锁方向。

## 设置

右上角的设置页管三件事：界面语言、主题色、输出目录。

语言有“跟随系统”“中文”“English”三档。切换立即生效，重启后仍然保留，不跟着系统语言反复跳。

输出目录用系统文件夹选择器授权，Android 15、16、17 走同一套机制。授权会持久化，重启后还能写。设好之后，转换完成的文件直接存进那个文件夹，结果栏显示“已完成”，不再出现分享按钮。没设目录时，文件留在应用自己的目录，仍然可以分享。

换目录、改回默认都不影响已经存好的文件。系统如果收回了写权限，下一次转换会退回应用目录，不会把文件丢掉。

## 兼容

适配按处理器走，不看手机商品名。验证名单：

- 天玑 9300 及以上，含 9300/9400/9500/9600 以及它们的 Plus、Pro、S、M 版本。
- 天玑 8400、8450、8500 系列。8400、8450、8400 Ultra 基本是同一颗；8400 Max 约等于 8500；8500 和 8550 是这一系的提频版。
- 骁龙 8 Gen 3 及以上，含 8s Gen 4、8 Elite、8 Gen 5、8 Elite Gen 5/6 和换皮型号。
- 骁龙 7 只认标准款 7 Gen 3、7 Gen 4，以及 7+ Gen 2、7+ Gen 3。7s 全系不进名单，只能走通用软件解码；个别机器碰巧能硬解也不保证。

天玑 8500 和 9400 要分开看。硬件编码走的是同一套 MediaTek 路径，H.264/HEVC、4K60 这档能力接近，音频转码按同档处理。CPU 不是同一套：8500 是 8 个 Cortex-A725，9400 是 X925 + X4 + A720；GPU 8500 是 Mali-G720 MC8，9400 是 G925 MC12。硬编能按同档看，芯片本身不是同一颗。

SM8450（骁龙 8 Gen 1）、SM8475（8+ Gen 1）、SM8550（8 Gen 2）都能识别。它们不在硬件验证名单内，软件解码可用，硬解不保证。名单外的老旗舰同样按这个规则处理。

不在名单里的处理器也能跑。纯音频转码本来就是 CPU 软解，慢一点但能出结果。硬解硬编是另一回事，这些芯片的 MediaCodec 实现参差不齐，可能直接失败，也可能转出来没声音。应用里会标出“不在验证名单内”，看到这行就别指望硬解，切回软件。

主要按原生 Android 做，另外对小米 HyperOS / MIUI、OPPO / 一加 ColorOS、realme UI、vivo / iQOO OriginOS 做了适配。Nothing OS 这类接近原生的系统按 AOSP 走。国产 ROM 改过文件选择器、后台限制、通知和权限弹窗，出问题大概率出在这些地方，不在转码引擎。

推荐 Android 15 及以上。targetSdk 36，Android 15 的 edge-to-edge、16 KB 页对齐、预测性返回都按新规做了，Android 16 和 17 继续沿用这套行为。Android 15 以下能装，但没测。

小窗和分屏是特意处理的。Android 16 起，targetSdk 36 的应用在最小宽度 ≥600dp 的屏幕上会被系统忽略方向、宽高比和可调整性限制，硬锁竖屏会直接铺满窗口。所以界面没有再锁方向，内容最大宽度 760，底栏 640。

## 接着改

仓库按 MPL-2.0 开放，欢迎接着做。改过的文件保留同一许可证、保留上游署名就行。要公开发修改版，建议换自己的包名和签名，别用 `com.technicjelle.simple_audio_converter.zh`，否则用户分不清是官方包还是你的包。开发过程中的取舍和踩坑记在 [DEVLOG.md](DEVLOG.md)，部分内容没有放出。

## 用到的项目

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter)（MPL-2.0）— 底座、Android 工程、文件选择与分享入口。原作者 TechnicJelle。
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit)（LGPL-3.0），实际用的是社区分支 `ffmpeg_kit_flutter_new_audio` — 转码运行时。
- [FFmpeg](https://ffmpeg.org)（LGPL-2.1+）— 编解码和封装。
- [m3_expressive](https://pub.dev/packages/m3_expressive)（MIT，fabric-apps）— 形变加载器，形状库来自 material_shapes（MIT，Kostiantyn Sokolovskyi）。
- Flutter（BSD-3-Clause）、file_picker（MIT）、share_plus（BSD-3-Clause）、share_handler（MIT）、shared_preferences（BSD-3-Clause）、path_provider（BSD-3-Clause）。

上游 1.0.5 的版权归 TechnicJelle 和贡献者。这个仓库新增和改过的文件同样按 MPL-2.0 走。FFmpegKit 用的是现成的 audio 包，没改它源码；转码命令是在应用层重写的，具体在 [THIRD_PARTY.md](THIRD_PARTY.md) 里写了。

## 关于 AI

1.2 起的界面重排、格式表、测试和这份说明里，有一部分是豆包先出草稿，我再逐项改、编译、跑测试。转换引擎没让 AI 碰，FFmpeg 命令是照着实际输出一条条验的。

`flutter analyze` 没有 error。`flutter test` 19 项全过，覆盖切格式、设置页、窄屏分屏、长按详情、滑块微调、MP3 版本选择、格式说明展开、音量与响度面板，以及处理器识别映射。构建环境没有 Android 模拟器，真机转码和系统文件夹写入仍然没跑过。

## 构建

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14，JDK 17，Android SDK 36，build-tools 36.0.0，NDK 28.2.13676358。签名配置不放在仓库里。

## 许可

MPL-2.0，见 [LICENSE](LICENSE)。署名和第三方许可见 [THIRD_PARTY.md](THIRD_PARTY.md)。
