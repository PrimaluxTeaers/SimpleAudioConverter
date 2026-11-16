# Timbre 1.5.0 — Android arm64-v8a

## 中文

Timbre 从 1.3.3 跳到 1.5.0。Android 与 Windows 共用 1.5 版本线，这一版先发 Android arm64-v8a。

- 18 种输出格式：MP3、M4A、AAC、OGG、Opus；FLAC、WAV、AIFF、ALAC、CAF、AU、WavPack；AMR-NB、AMR-WB；WMA、MP2、AC-3、E-AC-3。
- MP3 可选 MPEG-1 / MPEG-2 / MPEG-2.5，码率上限跟随版本。
- 码率、整体音量 -12 到 +12 dB、统一整批响度。
- 批量转换、停止确认、硬件失败一键软解、软解失败提示换格式。
- 设置页语言、主题色、SAF 输出目录。
- 包名 `com.technicjelle.simple_audio_converter.zh` 不变，签名证书不变，旧版可以覆盖安装。

安装包：`Timbre-1.5.0-arm64-v8a.apk`  
versionName `1.5.0`，versionCode `80152`  
SHA-256：`2c458102f69332db4c32a674a752f58516967e180acec1921636b16f740264fd`

MPL-2.0，基于 TechnicJelle/SimpleAudioConverter 二次开发。Windows 1.5 由另一侧构建。

## English

Timbre moves from 1.3.3 to 1.5.0. Android and Windows share the 1.5 line; this release ships Android arm64-v8a first.

- 18 output formats: MP3, M4A, AAC, OGG, Opus; FLAC, WAV, AIFF, ALAC, CAF, AU, WavPack; AMR-NB, AMR-WB; WMA, MP2, AC-3, E-AC-3.
- MP3 exposes MPEG-1 / MPEG-2 / MPEG-2.5, with the bitrate ceiling following the selected version.
- Bitrate, overall gain -12 to +12 dB, and batch loudness matching.
- Batch conversion, stop confirmation, one-tap hardware-to-software fallback and a second format suggestion when software also fails.
- Settings: language, accent colour and SAF output folder.
- Package name `com.technicjelle.simple_audio_converter.zh` is unchanged; the signing certificate is unchanged and the build installs over the old one.

APK: `Timbre-1.5.0-arm64-v8a.apk`  
versionName `1.5.0`, versionCode `80152`  
SHA-256: `2c458102f69332db4c32a674a752f58516967e180acec1921636b16f740264fd`

MPL-2.0, a modified build of TechnicJelle/SimpleAudioConverter. Windows 1.5 is built separately.
