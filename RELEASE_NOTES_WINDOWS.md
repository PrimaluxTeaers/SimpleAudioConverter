# Timbre 1.5.0 — Windows x86-64

## 中文

Timbre 的 Windows 版由同一项目的 Windows 实现接手，版本线与 Android 共用 1.5.0。只支持 Windows 10 / 11 x64，应用名为 `Timbre x86-64`。

这一版需要对齐 Android 1.5 重做后的能力：

- 18 种输出格式：MP3、M4A、AAC、OGG、Opus；FLAC、WAV、AIFF、ALAC、CAF、AU、WavPack；AMR-NB、AMR-WB；WMA、MP2、AC-3、E-AC-3。
- MP3 支持 MPEG-1 / MPEG-2 / MPEG-2.5，码率上限跟随版本。
- 码率、整体音量 -12 到 +12 dB、统一整批响度。
- 视频导入只处理音轨，视频流复制，容器按编码组合选 MP4 或 MKV。
- 批量转换、停止确认、硬件失败回退、处理器识别、输出目录授权。
- 完成提示、按钮和页面切换保留过渡动画；Windows 不做 Android 通知，也不把通知写成平台限制。
- 构建和视频音轨替换说明见仓库中的 `WINDOWS-IMPLEMENTATION-NOTES.md`。

Windows 安装包由 Windows 侧构建后附上，仓库不会把 Android APK 当作 Windows 包。

## English

The Windows build is handled by the project's Windows implementation and shares the 1.5.0 line with Android. It supports Windows 10 / 11 x64 only and ships as `Timbre x86-64`.

This build needs to match the reworked Android 1.5:

- 18 output formats: MP3, M4A, AAC, OGG, Opus; FLAC, WAV, AIFF, ALAC, CAF, AU, WavPack; AMR-NB, AMR-WB; WMA, MP2, AC-3, E-AC-3.
- MP3 supports MPEG-1 / MPEG-2 / MPEG-2.5, with the bitrate ceiling following the selected version.
- Bitrate, overall gain from -12 to +12 dB, and batch loudness matching.
- Video import processes only the audio track; the video stream is copied and the container is MP4 or MKV based on the codec pair.
- Batch conversion, stop confirmation, hardware-failure fallback, processor detection and output-folder grants.
- Completion banners, buttons and page changes keep their transitions. Windows has no Android notification, and the docs do not present that as a platform limitation.
- Build and video audio-track replacement notes live in `WINDOWS-IMPLEMENTATION-NOTES.md`.

The Windows installer is attached by the Windows side after it is built; the repository never treats the Android APK as a Windows package.
