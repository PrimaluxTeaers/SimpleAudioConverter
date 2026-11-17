# Timbre 1.6.0 — Windows x86-64

## 中文

安装包命名：`Timbre-WindowsX86-64`

Windows 1.6 由 GitHub Actions 的 `windows-latest` runner 构建，产物为 `Timbre-WindowsX86-64-1.6.0.zip`；解压后运行 `simple_audio_converter.exe`。这台 Linux 环境不能直接产出 exe，真实 Windows 上的拖拽、文件选择器和音频输出仍需本地复核。

已确认的 Windows 口径：

- 只支持 Windows 10 / 11 x64。
- 转换必须在可见的前台窗口里运行；关掉窗口就停止，不保证托盘或后台继续。
- 音频编码没有 GPU 路径，NVENC / AMF / Quick Sync 不参与；界面不提供假的硬件加速开关。
- 输出目录用系统文件夹选择器；批量队列、格式和码率逻辑与 Android 版共用。
- 视频音轨替换时保留全部音轨；纯音频转换只处理第一条音轨。
- Windows 包由 CI 产出，音频编码和 FFmpeg 版本以包内为准。

## English

Installer name: `Timbre-WindowsX86-64`

The Windows 1.6 build is produced on GitHub Actions' `windows-latest` runner as `Timbre-WindowsX86-64-1.6.0.zip`; unzip it and run `simple_audio_converter.exe`. A Linux machine cannot produce the exe directly; drag-and-drop, the file picker and audio output on a real Windows machine still need a local pass.

Confirmed Windows behaviour:

- Windows 10 / 11 x64 only.
- Conversion must run in a visible foreground window; closing the window or minimizing to the tray does not guarantee progress. Windows is not a single-task background service.
- Processor detection counts physical cores and available logical threads, does not show clock speed, and does not count efficiency cores as extra performance cores.
- CPU / GPU encoders are detected per vendor: Intel shows Intel and its core count, AMD shows AMD and its core count, and NVIDIA / AMD GPUs are listed separately instead of one generic GPU name.
- A missing hardware encoder is marked red in place; an unreadable model is marked black as "Unknown", with one more warning before enabling.
- Encoding threads are selectable, including Intel Hyper-Threading; AMD SMT counts logical threads without promising extra "virtual threads".
- A separate shortcut panel allows rebinding; defaults follow common audio/video software for play, pause, queue and convert.
- Multiple audio tracks: video audio replacement preserves every track; pure audio conversion handles the first track only.
