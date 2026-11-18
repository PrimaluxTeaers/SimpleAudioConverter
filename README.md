# Timbre / 音频转换

Android 音频转换器。选文件、选格式、点转换，没有别的活。导入视频时只改音轨，画面原样保留。1.6 是新基线，1.5 及更早的发布记录和旧文档入口已清理。

## 关于这个项目

Timbre / 音频转换 是免费开源的离线工具，任何人都可以免费使用、修改、分发和自行构建，只要遵守 MPL-2.0 并保留上游署名。也完全允许其他人基于它做同类软件或另起分支；比起复制一个成品，更希望这套代码能让人自己搭出能用的版本。底座来自 SimpleAudioConverter，另外拼上了本项目的界面、转换链路和打包流程；作者本人也是被“找不到能用的音频工具、专业软件又太贵”困住的人。测试设备有限，遇到 bug 请见谅，也欢迎提交问题。没有把 Reencode 和 Timbre 合并成一个大型项目的打算，两个都只是小工具；更新完全随缘，能走到 1.6 靠的是想把它们做完整一点的心。曾经认真尝试过 Windows 构建，受限于设备和实际条件，最终放弃；与其发一个自己无法验证的包，不如把边界说清楚。

这是 [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) 的二次开发版。底座、Android 工程、文件选择和分享入口来自上游，原项目用 MPL-2.0，这个仓库也照样。

Android 版只提供 arm64-v8a，应用名显示为 **Timbre**，安装包文件名保留 `ARM64-v8a` 标识，包名 `com.technicjelle.simple_audio_converter.zh`。官方只发布 Android 版，不再构建、不再发布 Windows 包。仓库保留不依赖 Android 界面的 Flutter / Dart 逻辑，熟悉 Windows 构建的人可以自行生成 runner、补平台层并适配；这条路由第三方自行维护，官方不提供成品，也不为适配结果背书。

## 能做什么

输出格式 18 种，分日常、无损、语音、老格式、其他五类。日常是 MP3、M4A、AAC、OGG、Opus；无损是 FLAC、WAV、AIFF、ALAC、CAF、AU、WavPack；语音是 AMR-NB、AMR-WB；老格式是 WMA、MP2、AC-3、E-AC-3。分组可以自己建，长按能删。

MP3 可以选 MPEG-1、MPEG-2 和 MPEG-2.5。切版本后码率上限跟着变，12 kHz 的版本不会让你拖到 320 kbps。码率滑块只吸附固定档位；右侧数字框可填当前格式范围内的任意整数，提交或失焦时自动卡到上下限。AMR 只有固定档位，数字框也会回到最近的合法档。

码率下面有整体音量，范围 -12 到 +12 dB，0 dB 保持原样。正增益会自动限幅，避免削波。另一个开关是“统一整批响度”，适合一批文件里既有轻声录音又有正常成品的情况。开了它，音量滑块不参与。

批量转换、停止确认、硬解失败一键切软解、软解失败提示换格式或版本，这些都在。小窗、分屏、平板都能用，界面没有锁方向。

## 视频导入

视频文件可以像音频一样拖进来。处理的是第一条音轨，视频流直接复制，不重新编码，画面、分辨率、帧率、HDR 信息都保持原样。

输出容器按编码组合选：视频是 H.264 / H.265 / AV1 / MPEG-4，音频选 M4A / AAC / MP3 / ALAC 时用 MP4；其余组合用 MKV。只导出音频时还是普通的音频文件，不会包一层视频空壳。

这条路径只换音轨，不做视频转码。源文件有多条音轨时全部保留，统一重编码为目标音频格式，原音轨编码不保留。要改画面请用 Reencode。反过来，Reencode 的合并页也能把一条外部音轨放回视频里。

## Android 体验

- 转换在 Android 前台服务里跑，通知栏显示当前文件和整体进度，退到后台不会静默中断。
- 完成条显示后会消失，结果卡片延迟收成一行摘要；点结果卡可以立刻收起 / 展开，不会一直占着页面；底部操作栏、按钮和页面切换都有过渡动画。
- 平板、折叠屏和小窗按可用宽度排版，内容最大宽度 760，底栏 640；界面没有锁方向。
- 设置页的语言、主题色、输出目录都立即生效。输出目录用系统文件夹选择器授权，重启后仍然有效。

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

## 下载

安装包、源码快照、版本号、校验值和每个版本的改动都在 [Releases](https://github.com/PrimaluxTeaers/SimpleAudioConverter/releases)。这份说明只写软件本身，不再重复发行内容。

Android 版只提供 `arm64-v8a`，应用名显示为 `Timbre`，安装包文件名保留 `ARM64-v8a` 标识。包名保持 `com.technicjelle.simple_audio_converter.zh`，从旧版覆盖安装不会丢设置。签名证书没有换。官方不再提供 Windows 构建；仓库保留共享逻辑，供有 Windows 环境的人自行适配，官方不维护、不发布，也不为第三方构建背书。

## 接着改

仓库按 MPL-2.0 开放，欢迎接着做。改过的文件保留同一许可证、保留上游署名就行。要公开发修改版，建议换自己的包名和签名，别用 `com.technicjelle.simple_audio_converter.zh`，否则用户分不清是官方包还是你的包。开发过程中的取舍和踩坑记在 [DEVLOG.md](DEVLOG.md)。

## 用到的项目

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter)（MPL-2.0）— 底座、Android 工程、文件选择与分享入口。原作者 TechnicJelle。
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit)（LGPL-3.0），实际用的是社区分支 `ffmpeg_kit_flutter_new_audio` — 转码运行时。
- [FFmpeg](https://ffmpeg.org)（LGPL-2.1+）— 编解码和封装。
- [m3_expressive](https://pub.dev/packages/m3_expressive)（MIT，fabric-apps）— 形变加载器，形状库来自 material_shapes（MIT，Kostiantyn Sokolovskyi）。
- Flutter（BSD-3-Clause）、file_picker（MIT）、share_plus（BSD-3-Clause）、share_handler（MIT）、shared_preferences（BSD-3-Clause）、path_provider（BSD-3-Clause）。

上游 1.0.5 的版权归 TechnicJelle 和贡献者。这个仓库新增和改过的文件同样按 MPL-2.0 走。FFmpegKit 用的是现成的 audio 包，没改它源码；转码命令是在应用层重写的，具体在 [THIRD_PARTY.md](THIRD_PARTY.md) 里写了。

## 构建

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14，JDK 17，Android SDK 36，build-tools 36.0.0，NDK 28.2.13676358。签名配置不放在仓库里。

`flutter analyze` 没有 error。`flutter test` 覆盖切格式、设置页、窄屏分屏、长按详情、滑块微调、MP3 版本选择、格式说明展开、音量与响度面板、处理器识别映射，以及视频音轨替换命令。构建环境没有 Android 模拟器，真机转码和系统文件夹写入仍然没跑过。

`lib/main.dart` 是界面、队列和设置入口；`lib/conversion.dart` 放格式表、码率范围与 FFmpeg 命令；`lib/output_store.dart` 管输出目录和 Android SAF；`lib/settings.dart` 管偏好与权限说明；`lib/runtime_settings.dart` 管后台驻留和震动。这些 `lib/` 文件不绑定 Android 界面，保留给愿意自行做 Windows 或其他桌面适配的人；官方不生成、不提交也不维护 Windows runner，仓库里也没有闭源桌面模块。

## 许可

MPL-2.0，见 [LICENSE](LICENSE)。署名和第三方许可见 [THIRD_PARTY.md](THIRD_PARTY.md)。

---

# Timbre / Audio Converter

An Android audio converter. Pick a file, pick a format, press convert. When you import a video, only the audio track changes; the picture stays untouched. 1.6 is the new baseline; releases and documentation from 1.5 and earlier were removed.

## About

Timbre / Audio Converter is a free, open-source offline tool. Anyone may use, modify, redistribute and build it, provided the MPL-2.0 license and upstream attribution are respected. Other people are free to make similar apps or fork this one; the point is not to ship one perfect binary, but to let people build their own working version. The foundation comes from SimpleAudioConverter, with this project's interface, conversion chain and packaging added on top. The author is one of the people who could not find a usable audio tool and could not afford professional software. Testing has been limited to a small set of devices, so bugs are possible; reports are welcome. There is no plan to merge Reencode and Timbre into one large project. Both are small tools, updated irregularly; reaching 1.6 is simply the wish to make them a little more complete. A Windows build was attempted in earnest, but without the devices and verification conditions to stand behind it, it was abandoned; saying so is better than shipping an untested package.

This is a fork of [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter). The foundation, Android project, file picker and share entry come from upstream, which uses MPL-2.0; this repository keeps that license.

The Android build ships arm64-v8a only and shows **Timbre** as its name; the installer filename keeps the `ARM64-v8a` tag. Android is the only official target. The Windows build has been dropped: no Windows package is built or published. The repository keeps the Flutter / Dart logic that does not depend on the Android UI, so anyone with Windows build experience can generate a runner, fill in the platform layer and adapt it; that path is maintained by whoever builds it, not by this project, and the project does not endorse third-party builds.

## What it does

Eighteen output formats, grouped into daily, lossless, voice, legacy and other. Daily: MP3, M4A, AAC, OGG, Opus. Lossless: FLAC, WAV, AIFF, ALAC, CAF, AU, WavPack. Voice: AMR-NB, AMR-WB. Legacy: WMA, MP2, AC-3, E-AC-3. Groups can be created and removed with a long press.

MP3 offers MPEG-1, MPEG-2 and MPEG-2.5. Switching the version changes the bitrate ceiling, so the 12 kHz variant cannot be pushed to 320 kbps. The bitrate slider only snaps to fixed stops; the number field accepts any whole value inside the current format range, then clamps on submit or focus loss. AMR has fixed steps, and the field snaps back to the nearest legal rate.

Below bitrate is an overall gain control from -12 to +12 dB, with 0 dB leaving the source alone. Positive gain adds a limiter to avoid clipping. The other switch is “match loudness across the batch”, useful when a queue mixes quiet recordings and finished masters. While it is on, the gain slider is not used.

Batch conversion, stop confirmation, one-tap fallback from hardware to software decoding and format/version suggestions after a software failure are all here. Small windows, split screen and tablets work; the UI is not locked to portrait.

## Video import

Video files can be added like audio. Timbre copies the video stream without re-encoding, so the picture, resolution, frame rate and HDR metadata stay as they were. Every audio track is preserved and re-encoded to the target format; the original per-track codecs are not kept.

The output container follows the codec pair: H.264 / H.265 / AV1 / MPEG-4 video with M4A / AAC / MP3 / ALAC audio goes to MP4; other combinations go to MKV. Audio-only exports stay plain audio files and do not get a video wrapper.

This path only replaces the audio. Use Reencode when the picture itself needs work. Reencode's merge page can also put an external audio track back into a video.

## Android behaviour

- Conversion runs in an Android foreground service. The notification shows the current file and overall progress, and leaving the app does not silently kill the job.
- The completion bar hides itself after about five seconds, and the results card collapses into a one-line summary after about nine seconds. Tapping the card collapses or expands it immediately, so neither block occupies the page forever. The bottom bar, buttons and page changes use transitions.
- Tablets, foldables and small windows lay out by available width. Content is capped at 760 logical pixels and the bottom bar at 640; the UI is not locked to portrait.
- Language, accent colour and output folder in Settings apply immediately. The output folder grant uses the system folder picker and survives a restart.

## Settings

The settings page handles three things: UI language, accent colour and output folder.

Language has “follow system”, “中文” and “English”. Switching applies immediately and survives a restart; it does not follow the system language on every launch.

The output folder uses the system folder picker, with the same mechanism on Android 15, 16 and 17. The grant is persisted and survives a restart. Once set, finished files go straight into that folder and the result row shows “Done” instead of a share button. Without a folder, files stay in the app directory and can still be shared.

Changing the folder or reverting to the default does not affect files already written. If the system revokes write access, the next conversion falls back to the app directory instead of losing the output.

## Compatibility

Compatibility is matched by processor, not by phone marketing name. The verified list:

- Dimensity 9300 and newer, including 9300/9400/9500/9600 and their Plus, Pro, S and M variants.
- Dimensity 8400, 8450 and 8500 series. 8400, 8450 and 8400 Ultra are basically the same part; 8400 Max is close to 8500; 8500 and 8550 are clocked versions of that family.
- Snapdragon 8 Gen 3 and newer, including 8s Gen 4, 8 Elite, 8 Gen 5, 8 Elite Gen 5/6 and rebadged variants.
- Snapdragon 7: only standard 7 Gen 3, 7 Gen 4, 7+ Gen 2 and 7+ Gen 3. The whole 7s line stays off the list and uses generic software decoding; a few devices may happen to work, but that is not guaranteed.

Dimensity 8500 and 9400 are different chips. Hardware encoding follows the same MediaTek path, and H.264/HEVC and 4K60 capability is close, so audio transcoding is treated as the same tier. The CPU is not the same: 8500 uses eight Cortex-A725 cores; 9400 uses X925 + X4 + A720. The GPU is Mali-G720 MC8 on 8500 and G925 MC12 on 9400. Hardware encoding can share a tier; the chips themselves do not.

SM8450 (Snapdragon 8 Gen 1), SM8475 (8+ Gen 1) and SM8550 (8 Gen 2) are recognized. They are outside the hardware verification list: software decoding works, hardware decoding is not guaranteed. Older flagships outside the list follow the same rule.

Phones outside the list still run. Pure audio conversion is CPU software work; it is slower but it finishes. Hardware decode and encode are a different story: MediaCodec implementations vary, and a job may fail outright or produce silence. The app marks “outside the verified list”; when that appears, do not count on hardware decoding.

The primary target is native Android, with adaptations for Xiaomi HyperOS / MIUI, OPPO / OnePlus ColorOS, realme UI and vivo / iQOO OriginOS. Systems close to AOSP, such as Nothing OS, follow the AOSP path. Chinese ROMs change file pickers, background limits, notifications and permission prompts; problems usually come from those layers, not the conversion engine.

Android 15 and newer is recommended. targetSdk is 36; Android 15 edge-to-edge, 16 KB page alignment and predictive back follow the new rules, and Android 16 and 17 keep the same behaviour. Older versions install but are not tested.

Small windows and split screen are handled deliberately. Starting with Android 16, apps targeting SDK 36 on screens with a minimum width of 600dp or more have their orientation, aspect ratio and resizability limits ignored; forcing portrait would fill the window. The UI therefore does not lock orientation, with content capped at 760 and the bottom bar at 640.

## Download

Installers, source snapshots, version numbers, checksums and per-release changes live in [Releases](https://github.com/PrimaluxTeaers/SimpleAudioConverter/releases). This file covers the software itself and does not repeat release contents.

The Android build ships `arm64-v8a` only, shows `Timbre` as its name and keeps the `ARM64-v8a` tag in the installer filename. The package name stays `com.technicjelle.simple_audio_converter.zh`, so an update over an older install keeps its settings. The signing key has not changed. No Windows build is provided; the shared logic stays in the repository for anyone with a Windows environment to adapt, and the project does not maintain, publish or endorse third-party builds.

## Contributing

The repository is open under MPL-2.0. Modified files keep the same license and upstream attribution. If you publish a modified build, use your own package name and signing key instead of `com.technicjelle.simple_audio_converter.zh`; otherwise users cannot tell your build from the official one. Development trade-offs and pitfalls are recorded in [DEVLOG.md](DEVLOG.md), with some parts left out.

## Credits

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) (MPL-2.0) — foundation, Android project, file picker and share entry. Original author TechnicJelle.
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit) (LGPL-3.0), using the community fork `ffmpeg_kit_flutter_new_audio` — conversion runtime.
- [FFmpeg](https://ffmpeg.org) (LGPL-2.1+) — codecs and muxing.
- [m3_expressive](https://pub.dev/packages/m3_expressive) (MIT, fabric-apps) — morphing loader; shape library from material_shapes (MIT, Kostiantyn Sokolovskyi).
- Flutter (BSD-3-Clause), file_picker (MIT), share_plus (BSD-3-Clause), share_handler (MIT), shared_preferences (BSD-3-Clause), path_provider (BSD-3-Clause).

Upstream 1.0.5 copyright belongs to TechnicJelle and contributors. New and modified files in this repository are also under MPL-2.0. The FFmpegKit audio package is used as-is; the conversion command is rewritten at the app layer and documented in [THIRD_PARTY.md](THIRD_PARTY.md).

## Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14, JDK 17, Android SDK 36, build-tools 36.0.0, NDK 28.2.13676358. Signing configuration is not committed.

`flutter analyze` reports no errors. `flutter test` covers format switching, settings, narrow split screen, long-press details, fine slider adjustment, MP3 version selection, format reference expansion, gain and loudness panels, processor mapping and the video audio-track replacement command. The build environment has no Android emulator, so real-device transcoding and system folder writes remain untested.

## License

MPL-2.0, see [LICENSE](LICENSE). Attribution and third-party licenses are in [THIRD_PARTY.md](THIRD_PARTY.md).
