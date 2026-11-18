# Timbre 1.6.0 — Windows x86-64

## 中文

安装包命名：`Timbre-WindowsX86-64`

Windows 1.6 由 GitHub Actions 的 `windows-latest` runner 构建，产物为 `Timbre-WindowsX86-64-1.6.0.zip`；解压后运行 `simple_audio_converter.exe`。Windows 和 Android 共用本仓库同一套 Flutter 源码；`windows/` runner 在 CI 生成，FFmpeg 在构建时取用，仓库里没有闭源桌面模块。这台 Linux 环境不能直接产出 exe，真实 Windows 上的文件选择器、转换和音频输出仍需本地复核。

已确认的 Windows 口径：

- 只支持 Windows 10 / 11 x64。
- 纯音频转换。没有 GPU 编码路径，NVENC / AMF / Quick Sync 不参与，界面也不提供硬件加速开关。
- 转换在可见的前台窗口里运行；关掉窗口就停止，不保证托盘或后台继续。
- 输出目录用 Windows 文件夹选择器选择并持久化，默认 `下载/Timbre`；不是临时目录。结果卡可以打开文件或定位文件夹，底部“分享全部”改成“打开文件夹”。
- 快捷键：`Ctrl+O` 添加文件、`Ctrl+Enter` 开始或停止、`Esc` 停止、`Ctrl+,` 打开设置。
- 批量队列、格式、码率和视频音轨替换逻辑与 Android 版共用。码率滑块只吸固定档，数字框提交或失焦时卡到当前格式上下限。
- 视频音轨替换时保留全部音轨；纯音频转换只处理第一条音轨。
- Windows 包由 CI 产出，音频编码和 FFmpeg 版本以包内为准。

## English

Installer name: `Timbre-WindowsX86-64`

The Windows 1.6 build is produced on GitHub Actions' `windows-latest` runner as `Timbre-WindowsX86-64-1.6.0.zip`; unzip it and run `simple_audio_converter.exe`. Windows and Android share the same Flutter source in this repository; the `windows/` runner is generated in CI and FFmpeg is fetched at build time, so there is no closed-source desktop module. A Linux machine cannot produce the exe directly; the file picker, conversion and audio output on a real Windows machine still need a local pass.

Confirmed Windows behaviour:

- Windows 10 / 11 x64 only.
- Audio-only conversion. There is no GPU encode path; NVENC / AMF / Quick Sync are not involved, and the UI has no hardware-acceleration switch.
- Conversion runs in a visible foreground window; closing it stops the job. Tray or background continuation is not guaranteed.
- Output uses a native Windows folder picker and persists the choice, defaulting to `Downloads/Timbre`; it is not a temp directory. The result card opens the file or reveals the folder, and the bottom "share all" action becomes "Open folder".
- Shortcuts: `Ctrl+O` adds files, `Ctrl+Enter` starts or stops, `Esc` stops, `Ctrl+,` opens settings.
- Batch queue, format, bitrate and video-audio replacement rules are shared with Android. The bitrate slider only snaps to fixed stops; the number field clamps to the current format range on submit or focus loss.
- Video audio replacement keeps every track; pure audio conversion handles the first track only.
- The Windows package is produced by CI; the audio encoder and FFmpeg version are those bundled in the package.
