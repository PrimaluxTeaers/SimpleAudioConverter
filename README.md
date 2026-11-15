# Timbre

一个 Android 音频转换器。选文件、选格式、点转换，没有别的活。

这是 [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) 的二次开发版，底座、工程结构和文件入口都来自上游。原项目用 MPL-2.0，这个仓库也照样。

## 下载

- APK（arm64-v8a，45 MB，versionCode 20092）：https://aka.doubaocdn.com/s/VpL8TCuwel
- 源码快照：https://aka.doubaocdn.com/s/7KtIJDhLm5

APK SHA-256 `ab38d6e016361fbae6aafcae0c2cb3790c792e4da87750204ccbf1abe50fab46`。16 KB 页对齐用 `zipalign -c -P 16` 验过。

## 先说版本

**1.2.0 是第一个正式版。** 1.0.x 和 1.1.x 都算内测，已经废弃，别再从旧链接装。它们改过包名、改过转换命令，也留着一堆现在看起来没必要的东西。要装就装 1.2。

包名还是 `com.technicjelle.simple_audio_converter.zh`。没改成独立包名，是因为改了就不能覆盖升级，旧版本的设置和输出目录会断。签名证书也没换。

只有 `arm64-v8a`，没有 32 位包。现在的旗舰机都是 64 位，Android 17 也不完整支持 32 位应用，省掉一份 so 能少 20 多 MB。

## 系统

推荐 Android 15 及以上。targetSdk 36，Android 15 的 edge-to-edge、16 KB 页对齐、预测性返回都按新规做了，Android 16 和 17 继续沿用这套行为。

Android 15 以下能装，但没测。可能会出现一些说不上名字的小毛病，比如状态栏高度、文件选择器返回路径、后台被杀。真遇到就升级系统，或者换台机器试。

Android 15 之后系统层面没有推翻重来的改动，底层架构还是那套。所以 15、16、17 我按同一份行为做，没有为每个版本单独分叉。

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

## 1.2 改了什么

**格式从 11 种加到 18 种。** 新增 AAC(ADTS)、CAF、AU、WavPack、AMR-NB、AMR-WB、E-AC-3。加上原来的 MP3、M4A、OGG、Opus、FLAC、WAV、AIFF、ALAC、WMA、MP2、AC-3，现在一共 18 种。

格式按用途分组：日常、无损、语音、老格式、其他。日常就是 MP3、M4A、AAC、OGG、Opus；无损是 FLAC、WAV、AIFF、ALAC、CAF、AU、WavPack；语音是 AMR、AMR-WB；老格式是 WMA、MP2、AC-3、E-AC-3。分组可以自己建，长按能删。

**推荐预设藏在详情底部。** 点开格式详情先看到说明和取舍，滑到底才有“推荐预设”。刚点开就被塞一套参数不太舒服，所以放后面。预设点了才生效，不点不影响当前设置。

**滑块重做。** 长按进入 0.35 倍速微调，松手吸附到整数；普通拖动还是跟手。切换按钮加了过渡，不再硬跳。之前 AnimatedContainer 在阴影和无阴影之间插值会触发负 blur 断言，这次改成两边都给阴影列表，未选中用透明色。

**图标换成了青色圆环箭头加音符。** 背景 `#278489`，自适应图标的前景改成全幅，各密度都重新切了。AI 生成的那版没再用。

**SoC 识别补了别名和兼容提示。** 天玑 9500S、9600M 这类换皮型号会落到正确的基础型号。界面会直接写清楚在不在验证名单里。

其它零碎：`-map_chapters -1` 去掉章节轨；AMR 强制 8k/16k 单声道、只给固定档位；WavPack、CAF、AU 走无损路径；`android:resizeableActivity="true"`。

## 用到的项目

这个应用是拼出来的，主要部分都不是我写的：

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter)（MPL-2.0）— 底座、Android 工程、文件选择与分享入口。原作者 TechnicJelle。
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit)（LGPL-3.0），实际用的是社区分支 `ffmpeg_kit_flutter_new_audio` — 转码运行时。
- [FFmpeg](https://ffmpeg.org)（LGPL-2.1+）— 编解码和封装。
- [m3_expressive](https://pub.dev/packages/m3_expressive)（MIT，fabric-apps）— 形变加载器，形状库来自 material_shapes（MIT，Kostiantyn Sokolovskyi）。
- Flutter（BSD-3-Clause）、file_picker（MIT）、share_plus（BSD-3-Clause）、share_handler（MIT）、shared_preferences（BSD-3-Clause）、path_provider（BSD-3-Clause）、installed_apps（Apache-2.0）。

上游 1.0.5 的版权归 TechnicJelle 和贡献者。这个仓库新增和改过的文件同样按 MPL-2.0 走。改过 FFmpegKit 的构建配置和命令拼接，具体在 [THIRD_PARTY.md](THIRD_PARTY.md) 里写了。

## 关于 AI

1.2 这轮重构用了 AI 工具：豆包。格式表、界面重排、测试用例和这份 README 都是它先出草稿，我再逐项改、编译、跑测试。转换引擎没让 AI 碰，FFmpeg 命令是照着实际输出一条条验的。

代码里能跑的部分以 `flutter analyze` 和 `flutter test` 为准。测试里模拟了点击、切格式、开主题面板、窄屏分屏和长按开详情。没有 Android 模拟器，所以真机转码没跑过，这一条别当成已验证。

## 构建

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14，JDK 17，Android SDK 36，build-tools 36.0.0，NDK 28.2.13676358。签名配置不放在仓库里。

## 许可

MPL-2.0，见 [LICENSE](LICENSE)。署名和第三方许可见 [THIRD_PARTY.md](THIRD_PARTY.md)。
