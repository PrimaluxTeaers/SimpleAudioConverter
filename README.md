# Timbre

一个 Android 音频转换器。选文件、选格式、点转换，没有别的活。

这是 [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) 的二次开发版。底座、Android 工程、文件选择和分享入口都来自上游，原项目用 MPL-2.0，这个仓库也照样。

[English](README.en.md)

## 下载

- APK（arm64-v8a，39.8 MB，versionCode 40122）：https://aka.doubaocdn.com/s/Y6Z49JnE31
- 源码快照：[source-1.3.2.zip](source-1.3.2.zip)

APK SHA-256 `9f49baabeddac93fb33b8fa5b56b95acbd649b00d897f7635ed63519fba8d04a`。16 KB 页对齐验过，签名证书 SHA-256 是 `354871FE58DC66F7CB5780F1DEBA20565897C9A4DD0C22154A9549F4E405F3F7`，和 1.3.1 一致。

## 版本

1.3.2 是当前版本。1.3.1 和 1.3.0 已经被它取代，1.2.0 是第一个正式版。1.1.x 和 1.0.x 都算内测，已经废弃，别再从旧链接装。旧版本不再重新打包，直接用 1.3.2 覆盖安装。

包名还是 `com.technicjelle.simple_audio_converter.zh`。没改成独立包名，是因为改了就不能覆盖升级，旧版本的设置和输出目录会断。签名证书也没换。

只有 `arm64-v8a`，没有 32 位包。现在的旗舰机都是 64 位，Android 17 也不完整支持 32 位应用，省掉一份 so 能少 20 多 MB。

## 能做什么

输出格式 18 种，分日常、无损、语音、老格式、其他五类。日常是 MP3、M4A、AAC、OGG、Opus；无损是 FLAC、WAV、AIFF、ALAC、CAF、AU、WavPack；语音是 AMR-NB、AMR-WB；老格式是 WMA、MP2、AC-3、E-AC-3。分组可以自己建，长按能删。

MP3 可以选 MPEG-1、MPEG-2 和 MPEG-2.5。切版本后码率上限跟着变，12 kHz 的版本不会让你拖到 320 kbps。AMR 只有固定档位，滑块会吸附到合法码率。

码率下面有整体音量，范围 -12 到 +12 dB，0 dB 保持原样。正增益会自动限幅，避免削波。另一个开关是“统一整批响度”，适合一批文件里既有轻声录音又有正常成品的情况。开了它，音量滑块不参与。

批量转换、停止确认、硬解失败一键切软解、软解失败提示换格式或版本，这些都在。主题色可以换，小窗、分屏、平板都能用，界面没有锁方向。

## 兼容

适配按处理器走，不看手机商品名。验证名单：

- 天玑 9300 及以上，含 9300/9400/9500/9600 以及它们的 Plus、Pro、S、M 版本。
- 天玑 8400 和 8500。8500 是 8400 的换皮，GPU 解锁加一点频率，按同一档处理；8400 Ultra、8400 Max 这类衍生也在。
- 骁龙 8 Gen 3 及以上，含 8s Gen 4、8 Elite、8 Gen 5、8 Elite Gen 5/6 和换皮型号。
- 骁龙 7 只认标准款 7 Gen 3、7 Gen 4，以及 7+ Gen 2、7+ Gen 3。7s 全系不进名单，只能走通用软件解码；个别机器碰巧能硬解也不保证。

不在名单里的处理器也能跑。纯音频转码本来就是 CPU 软解，慢一点但能出结果。硬解硬编是另一回事，这些芯片的 MediaCodec 实现参差不齐，可能直接失败，也可能转出来没声音。应用里会标出“不在验证名单内”，看到这行就别指望硬解，切回软件。

主要按原生 Android 做，另外对小米 HyperOS / MIUI、OPPO / 一加 ColorOS、realme UI、vivo / iQOO OriginOS 做了适配。Nothing OS 这类接近原生的系统按 AOSP 走。国产 ROM 改过文件选择器、后台限制、通知和权限弹窗，出问题大概率出在这些地方，不在转码引擎。

推荐 Android 15 及以上。targetSdk 36，Android 15 的 edge-to-edge、16 KB 页对齐、预测性返回都按新规做了，Android 16 和 17 继续沿用这套行为。Android 15 以下能装，但没测。

小窗和分屏是特意处理的。Android 16 起，targetSdk 36 的应用在最小宽度 ≥600dp 的屏幕上会被系统忽略方向、宽高比和可调整性限制，硬锁竖屏会直接铺满窗口。所以界面没有再锁方向，内容最大宽度 760，底栏 640。

## 1.3.2 改了什么

性能区不再显示手机商品名，标题固定是处理器，副行只留厂商、核心数、架构和 Android 版本；没读到芯片就写“未识别”。

芯片和系统识别补了一轮。天玑 8400/8500、9500M、9600 Pro，骁龙 7 Gen 3/4、7+ Gen 2/3，以及 Exynos 2400/2500 都能落到名字。属性被系统藏起来时有别的读取路径，不会把商品名当芯片名。

声音参数多了一组：整体音量和统一响度。命令里把降噪、增益、限幅或响度统一串在一起，不再只处理降噪。

兼容提示写清楚了：谁在名单里，谁不在，7s 为什么排除。不再只给一句模糊的“可能不支持”。

界面又收了一点。顶部卡片阴影更轻，声音控制接在码率面板里，不再单独加卡。

## 之前的版本

1.3.1 把 18 种格式的展开说明重写了，详情页分开“适合拿来做什么”和“用起来的取舍”，全部格式按用途分组。设备识别在 Android 17 上显示“未识别 / Android 0”的问题也在这版修掉。没用的 3 MB 图标从打包里摘掉，APK 从 42.8 MB 降到 39.8 MB。

1.3.0 加了 MP3 版本选择、硬解失败一键切软解、停止确认；去掉没用的依赖，重开 R8 和资源压缩，APK 从 45 MB 降到 41 MB。

1.2.0 把格式从 11 种扩到 18 种，加了分组、自建组、详情底部预设、滑块长按微调、青色图标和 SoC 兜底。

## 接着改

仓库按 MPL-2.0 开放，欢迎基于 1.3.2 继续做。改过的文件保留同一许可证、保留上游署名就行。要公开发修改版，建议换自己的包名和签名，别用 `com.technicjelle.simple_audio_converter.zh`，否则用户分不清是官方包还是你的包。开发过程中的取舍和踩坑记在 [DEVLOG.md](DEVLOG.md)，部分内容没有放出。

## 用到的项目

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter)（MPL-2.0）— 底座、Android 工程、文件选择与分享入口。原作者 TechnicJelle。
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit)（LGPL-3.0），实际用的是社区分支 `ffmpeg_kit_flutter_new_audio` — 转码运行时。
- [FFmpeg](https://ffmpeg.org)（LGPL-2.1+）— 编解码和封装。
- [m3_expressive](https://pub.dev/packages/m3_expressive)（MIT，fabric-apps）— 形变加载器，形状库来自 material_shapes（MIT，Kostiantyn Sokolovskyi）。
- Flutter（BSD-3-Clause）、file_picker（MIT）、share_plus（BSD-3-Clause）、share_handler（MIT）、shared_preferences（BSD-3-Clause）、path_provider（BSD-3-Clause）。

上游 1.0.5 的版权归 TechnicJelle 和贡献者。这个仓库新增和改过的文件同样按 MPL-2.0 走。FFmpegKit 用的是现成的 audio 包，没改它源码；转码命令是在应用层重写的，具体在 [THIRD_PARTY.md](THIRD_PARTY.md) 里写了。

## 关于 AI

1.2 到 1.3.2 的重构用了 AI 工具：豆包。格式表、界面重排、测试用例和这份 README 都是它先出草稿，我再逐项改、编译、跑测试。转换引擎没让 AI 碰，FFmpeg 命令是照着实际输出一条条验的。

`flutter analyze` 没有 error。`flutter test` 19 项全过，覆盖切格式、主题面板、窄屏分屏、长按详情、滑块微调、MP3 版本选择、格式说明展开、音量与响度面板，以及处理器识别映射。构建环境没有 Android 模拟器，真机转码仍然没跑过。

## 构建

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14，JDK 17，Android SDK 36，build-tools 36.0.0，NDK 28.2.13676358。1.3.2 的 versionCode 是 40122。签名配置不放在仓库里。

## 许可

MPL-2.0，见 [LICENSE](LICENSE)。署名和第三方许可见 [THIRD_PARTY.md](THIRD_PARTY.md)。
