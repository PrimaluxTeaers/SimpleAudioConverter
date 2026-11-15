# 音频转换 / Audio Converter 1.1.0

> **仅支持 64 位架构 / 64-BIT ONLY**
> 只提供 `arm64-v8a` 安装包，没有 32 位版本。Android 17 起系统本身也不再完整支持 32 位应用，天玑 9300/9400/9500/9600、骁龙 8 全系均为 64 位。
> Only an `arm64-v8a` APK is published. There is no 32-bit build. Android 17 no longer fully supports 32-bit apps either; Dimensity 9300/9400/9500/9600 and all Snapdragon 8 chips are 64-bit.

> **主要针对 Android 17 适配 / Tuned for Android 17**
> targetSdk 36，edge-to-edge 全屏手势、predictive back、Material 3 Expressive 视觉均已适配。
> targetSdk 36 with edge-to-edge insets, predictive back and a Material 3 Expressive UI.

这是 [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) 1.0.5 的改造版，保留 **MPL-2.0** 许可，改动的文件同样以 MPL-2.0 分发。
This is a derivative of [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) 1.0.5, still under **MPL-2.0**; modified files stay MPL-2.0.

## 下载 / Download

- APK（arm64-v8a，44.1 MB）: https://aka.doubaocdn.com/s/BdNnhaFbWX
- 完整源码快照（zip，含全部改动）: https://aka.doubaocdn.com/s/dYqXCrbxmU

APK SHA-256: `9c09f56feb23b09a106bb88f43347f52bb932ee56d6c4927cd0e8f40d47fbf55`

包名 `com.technicjelle.simple_audio_converter.zh`，可与上游原版共存。签名 SHA-256 `354871FE58DC66F7CB5780F1DEBA20565897C9A4DD0C22154A9549F4E405F3F7`。
Package id `com.technicjelle.simple_audio_converter.zh`, coexists with the upstream app.

## 改了什么 / What changed

上游 1.0.5 只支持 Opus/MP3/FLAC/WAV 四种输出，码率完全不可调，且转换命令会保留视频流——封面图被写成视频轨后，部分播放器只认视频轨，表现为"转换完没有声音"。
Upstream 1.0.5 supports only Opus/MP3/FLAC/WAV output with no bitrate control, and its ffmpeg command keeps video streams. Cover art ends up as a video track and some players latch onto it, which is the "converted file has no sound" bug.

1. **11 outputs**: MP3, M4A (AAC), OGG (Vorbis), Opus, FLAC, WAV, AIFF, ALAC, WMA, MP2, AC-3.
2. **Continuous bitrate**: any kbps inside the format range, e.g. MP3 8–320, AAC 8–512, Opus 6–510. A slider plus a numeric field; `191` is accepted (LAME snaps to 192k internally — encoder limitation, not ours).
3. **VBR where the codec has quality levels**: MP3 `-q:a 0-9`, Vorbis `0-10`, Opus VBR on/off. AAC/WMA/MP2/AC-3 have no quality scale, so only CBR is exposed instead of faking one.
4. **Lossless formats**: FLAC compression level 0–12, WAV 16/24/32-bit depth, AIFF 16/24, ALAC fixed.
5. **Batch**: multi-select, sequential queue, per-file progress, cancellable.
6. **Silence fix**: command is now `-map 0:a:0 -vn -map_metadata 0` — first audio track only, video and cover art dropped.
7. **SoC detection** with fallbacks: `Build.SOC_MODEL` → `ro.soc.model` → `ro.board.platform` → `ro.chipname` → `ro.hardware` → codename (`sun`/`pineapple`/`kalama`/`taro`). Vendor builds that report `0` (early Snapdragon 8 Gen 6 units) fall through instead of showing a wrong name.
8. **Decode mode and encoder threads** are user-selectable (auto / CPU / MediaCodec, threads 1–8 or auto).

On the hardware decode switch: the bundled ffmpeg does ship MediaCodec decoders (`h264_mediacodec`, `hevc_mediacodec`, `aac_mediacodec` are present in `libavcodec.so`), but this tool only keeps the audio track and never decodes video, so pure audio conversion gains nothing from it. It is exposed for video sources and defaults to software.

## 界面 / UI

Material 3 Expressive: large continuous-corner shapes, tonal layered surfaces, a floating blurred bottom bar, shape-morphing selection states, spring curves, edge-to-edge with status/navigation/keyboard insets, predictive back enabled.

## 构建 / Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

需要的环境：Flutter 3.50 / Dart 3.14，JDK 17，Android SDK platform 36 + build-tools 36 + NDK 28.2.13676358。签名配置不随仓库提供，请在 `android/app/build.gradle.kts` 里换成你自己的 keystore。

Requires Flutter 3.50 / Dart 3.14, JDK 17, Android SDK 36, NDK 28.2.13676358. The signing config is not published — supply your own keystore in `android/app/build.gradle.kts`.

## 许可 / License

MPL-2.0，见 [LICENSE](LICENSE)。上游版权归 TechnicJelle 及其贡献者；本仓库的改动文件同样以 MPL-2.0 提供，完整改动见 [CHANGES.md](CHANGES.md)。

MPL-2.0, see [LICENSE](LICENSE). Upstream copyright belongs to TechnicJelle and contributors; modified files in this fork are likewise MPL-2.0. See [CHANGES.md](CHANGES.md).
