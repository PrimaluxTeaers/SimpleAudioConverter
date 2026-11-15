# Timbre

一个 Android 音频转换器。选文件、选格式、点转换，没有别的活。

这是 [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) 的二次开发版，底座、工程结构和文件入口都来自上游。原项目用 MPL-2.0，这个仓库也照样。

[English](README.en.md)

## 下载

- APK（arm64-v8a，39.8 MB，versionCode 20112）：https://aka.doubaocdn.com/s/d9034kq7SI
- 源码快照：https://aka.doubaocdn.com/s/Za2BVzaBf7

APK SHA-256 `6bf4eb3837c6f1a746de20cd9ff1715550d7eeaad5ef7f2b9f80b77d52d9a082`。16 KB 页对齐用 `zipalign -c -P 16` 验过，签名证书 SHA-256 仍是 `354871FE58DC66F7CB5780F1DEBA20565897C9A4DD0C22154A9549F4E405F3F7`。

## 先说版本

**1.3.1 是当前版本。** 1.3.0 已经被它取代，1.2.0 是第一个正式版。1.1.x 和 1.0.x 都算内测，已经废弃，别再从旧链接装。旧版本不再重新打包，直接用 1.3.1 覆盖安装。

- 1.3.0：正式版，已被 1.3.1 取代。
- 1.2.0：第一个正式版，旧。
- 1.1.1 / 1.1.0：内测，废弃。
- 1.0.5 及更早：内测，废弃。

包名还是 `com.technicjelle.simple_audio_converter.zh`。没改成独立包名，是因为改了就不能覆盖升级，旧版本的设置和输出目录会断。签名证书也没换。

只有 `arm64-v8a`，没有 32 位包。现在的旗舰机都是 64 位，Android 17 也不完整支持 32 位应用，省掉一份 so 能少 20 多 MB。

## 系统

推荐 Android 15 及以上。targetSdk 36，Android 15 的 edge-to-edge、16 KB 页对齐、预测性返回都按新规做了，Android 16 和 17 继续沿用这套行为。

Android 17 + HyperOS 4 上，系统属性读取比之前收得更紧。1.3.0 在部分机器上会显示“未识别 / Android 0”，原因是设备信息通道里塞了 `String[]`，序列化失败，整次调用都断了。1.3.1 改成逗号分隔的字符串；`SystemProperties` 反射失败时走 `getprop`，再不行读 `/proc/cpuinfo`、device-tree 和 `soc0`。天玑 9400+ 这类现在能落到名字。

Android 15 以下能装，但没测。可能会出现一些说不上名字的小毛病，比如状态栏高度、文件选择器返回路径、后台被杀。真遇到就升级系统，或者换台机器试。

## 机器

主要适配这两条线：

- 天玑 9300 及以上，含 9300/9400/9500/9600 以及它们的 Plus、Pro、S 版本。9500S 是 9400 换皮，9600M 是 9500+ 换皮，识别时按底子型号算，不会当成新芯片瞎报。
- 骁龙 8 第三代及以上，含 8s Gen 4 和一些换皮型号。识别走 `Build.SOC_MODEL`、`ro.soc.model`、`ro.board.platform` 等多个入口，遇到厂商把字段填成 `0` 的情况会继续往下找。

不在这两条线上的机器也能跑。纯音频转码本来就是 CPU 软解，慢一点但能出结果。硬解硬编是另一回事，这些芯片的 MediaCodec 实现参差不齐，可能直接失败，也可能转出来没声音。应用里会标出“不在验证名单内”，看到这行就别指望硬解，切回软件。

## 国产 ROM

主要按原生 Android 做，另外对这几家做了适配：

- 小米 HyperOS / MIUI
- OPPO / 一加 ColorOS
- vivo / iQOO OriginOS

其它品牌，包括 HTC、Sony、Nothing 这类接近原生的系统，基本沿用 AOSP 行为，没逐个真机验证。国产 ROM 改过文件选择器、后台限制、通知和权限弹窗，出问题大概率出在这些地方，不在转码引擎。

小窗和分屏是特意处理的。Android 16 起，targetSdk 36 的应用在最小宽度 ≥600dp 的屏幕上会被系统忽略方向、宽高比和可调整性限制，硬锁竖屏会直接铺满窗口。所以界面没有再锁方向，内容最大宽度 760，底栏 640，窄到分屏、宽到平板都不会把控件拉成一条。

## 1.3.1 改了什么

**格式说明重写了一遍。** 18 种格式的展开说明不再报参数表，改成一句用途加几句取舍。详情页分开“适合拿来做什么”和“用起来的取舍”，不是把同一段话换个标题再贴一遍。全部格式面板里的展开说明是另一段更短的参考文案，跟详情页不重复。推荐预设仍在底部，点了才生效。

**全部格式按用途分组。** 格式说明面板按日常、无损、语音、老格式、其他分开，不再是一条十八行的长列表。每行只放简短说明，工程参数留在详情页顶部。

**设备识别修了。** 上面提到的 `String[]` 问题就是这版修的。另外补了 `getprop`、`/proc/cpuinfo`、`/proc/device-tree/model`、`/sys/devices/soc0/*` 这几条兜底，HyperOS 把属性藏起来时还有东西可读。天玑 9400+、9300+ 和骁龙 8 第三代以后的名字都对照过。

**又瘦了 3 MB。** 打包清单里有一张 3 MB 的 `AppBar_Icon.png`，代码里没人用它，之前一直被塞进 APK。1.3.1 把它从 assets 里摘掉，安装包从 42.8 MB 降到 39.8 MB。降噪模型 `std.rnnn` 留着，那个是真在用的。

**界面收了一点。** 顶部卡片去掉厚重阴影，四个区块加了编号，格式按钮去掉回弹，宽屏内容居中。小窗和分屏的行为没变，还是按 Android 16 的自适应规则走。

## 1.3.0 改了什么

**MP3 可以选版本了。** 详情页的码率面板上方多了版本下拉：MPEG-1、MPEG-2（24 kHz，最高 160 kbps）、MPEG-2.5（12 kHz，最高 64 kbps）。选完码率滑块按该版本的真实上限收口，不会让你在 12 kHz 版本里拖 320 kbps。

**硬解失败会直接给退路。** 选了硬件解码、MediaCodec 又打不开文件时，弹窗说明原因，下方一个按钮切到软件并重试。软件也失败，再弹一次，建议换格式或版本。不会只丢一行红字让你自己猜。

**停止转换前先确认。** 批量转到一半点停止，会提示当前文件作废、已完成的文件保留。

**体积做了一点减法。** 去掉没用的 `installed_apps` 依赖，重新打开 R8 和资源压缩，APK 从 45 MB 降到 41 MB。再往下压就得自己裁 FFmpeg 的编码器重编 so，这次没做。

## 1.2 改了什么

格式从 11 种加到 18 种。新增 AAC(ADTS)、CAF、AU、WavPack、AMR-NB、AMR-WB、E-AC-3。按日常、无损、语音、老格式、其他分组，可以自己建组，长按能删。推荐预设挪到详情底部，点了才生效。滑块长按 0.35 倍速微调，松手吸附整数。图标换成青色圆环箭头加音符。SoC 识别补了换皮别名和兼容提示。

## 想接着改

仓库按 MPL-2.0 开放，欢迎基于 1.3.1 继续做。改过的文件保留同一许可证、保留上游署名就行。要公开发修改版，建议换自己的包名和签名，别用 `com.technicjelle.simple_audio_converter.zh`，否则用户分不清是官方包还是你的包。开发过程中的取舍和踩坑记在 [DEVLOG.md](DEVLOG.md)，部分敏感内容没有放出。

## 用到的项目

这个应用是拼出来的，主要部分都不是我写的：

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter)（MPL-2.0）— 底座、Android 工程、文件选择与分享入口。原作者 TechnicJelle。
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit)（LGPL-3.0），实际用的是社区分支 `ffmpeg_kit_flutter_new_audio` — 转码运行时。
- [FFmpeg](https://ffmpeg.org)（LGPL-2.1+）— 编解码和封装。
- [m3_expressive](https://pub.dev/packages/m3_expressive)（MIT，fabric-apps）— 形变加载器，形状库来自 material_shapes（MIT，Kostiantyn Sokolovskyi）。
- Flutter（BSD-3-Clause）、file_picker（MIT）、share_plus（BSD-3-Clause）、share_handler（MIT）、shared_preferences（BSD-3-Clause）、path_provider（BSD-3-Clause）。

上游 1.0.5 的版权归 TechnicJelle 和贡献者。这个仓库新增和改过的文件同样按 MPL-2.0 走。FFmpegKit 用的是现成的 audio 包，没改它源码；转码命令是在应用层重写的，具体在 [THIRD_PARTY.md](THIRD_PARTY.md) 里写了。

## 关于 AI

1.2 到 1.3.1 的重构用了 AI 工具：豆包。格式表、界面重排、测试用例和这份 README 都是它先出草稿，我再逐项改、编译、跑测试。转换引擎没让 AI 碰，FFmpeg 命令是照着实际输出一条条验的。

代码里能跑的部分以 `flutter analyze` 和 `flutter test` 为准。1.3.1 的测试覆盖了切格式、主题面板、窄屏分屏、长按详情、滑块微调、MP3 版本选择、格式说明展开，以及天玑 9400+ / 9300+、骁龙 8 第三代以后和 Android 17 的识别映射。构建环境没有 Android 模拟器，真机转码仍然没跑过，这一条别当成已验证。

## 构建

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14，JDK 17，Android SDK 36，build-tools 36.0.0，NDK 28.2.13676358。1.3.1 的 versionCode 是 20112。签名配置不放在仓库里。

## 许可

MPL-2.0，见 [LICENSE](LICENSE)。署名和第三方许可见 [THIRD_PARTY.md](THIRD_PARTY.md)。
