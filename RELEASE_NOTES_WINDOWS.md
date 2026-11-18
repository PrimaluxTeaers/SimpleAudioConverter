# Timbre 1.6.0 — Windows x86-64

## 中文

安装包命名：`Timbre-WindowsX86-64`

Windows 1.6 由 GitHub Actions 的 `windows-latest` runner 构建，产物为 `Timbre-WindowsX86-64-1.6.0.zip`；解压后运行 `simple_audio_converter.exe`。这台 Linux 环境不能直接产出 exe，真实 Windows 上的文件选择器、转换和音频输出仍需本地复核。

已确认的 Windows 口径：

- 只支持 Windows 10 / 11 x64。
- 纯音频转换。没有 GPU 编码路径，NVENC / AMF / Quick Sync 不参与，界面也不提供硬件加速开关。
- 转换在可见的前台窗口里运行；关掉窗口就停止，不保证托盘或后台继续。
- 输出写到系统临时目录下的 `converted` 文件夹，不提供 Android 那种持久输出目录授权；结果通过结果卡打开或分享。
- 批量队列、格式、码率和视频音轨替换逻辑与 Android 版共用。
- 视频音轨替换时保留全部音轨；纯音频转换只处理第一条音轨。
- Windows 包由 CI 产出，音频编码和 FFmpeg 版本以包内为准。

## English

Installer name: `Timbre-WindowsX86-64`

The Windows 1.6 build is produced on GitHub Actions' `windows-latest` runner as `Timbre-WindowsX86-64-1.6.0.zip`; unzip it and run `simple_audio_converter.exe`. A Linux machine cannot produce the exe directly; the file picker, conversion and audio output on a real Windows machine still need a local pass.

Confirmed Windows behaviour:

- Windows 10 / 11 x64 only.
- Audio-only conversion. There is no GPU encode path; NVENC / AMF / Quick Sync are not involved, and the UI has no hardware-acceleration switch.
- Conversion runs in a visible foreground window; closing it stops the job. Tray or background continuation is not guaranteed.
- Output goes to the `converted` folder under the system temp directory. There is no Android-style persistent output-folder grant; results are opened or shared from the result card.
- Batch queue, format, bitrate and video-audio replacement rules are shared with Android.
- Video audio replacement keeps every track; pure audio conversion handles the first track only.
- The Windows package is produced by CI; the audio encoder and FFmpeg version are those bundled in the package.
