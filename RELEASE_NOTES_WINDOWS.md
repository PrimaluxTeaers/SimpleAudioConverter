# Timbre 1.6.0 — Windows x86-64

## 中文

安装包命名：`Timbre-WindowsX86-64`

Windows 1.6 还没有构建。这一轮只发布 Android arm64-v8a；Windows 版按 1.6 口径先写好说明，正式构建另开工。

已确认的 Windows 口径：

- 只支持 Windows 10 / 11 x64。
- 转换必须在可见的前台窗口里运行；关掉窗口或最小化到托盘后不保证继续，Windows 不是单任务后台服务模型。
- 处理器识别只统计物理核和可用逻辑线程，不显示频率，不把能效核算成额外性能核。
- CPU / GPU 编码器按厂商检测：Intel 显示 Intel 与核心数，AMD 显示 AMD 与核心数，NVIDIA / AMD 显卡单独列出，不混成一张通用显卡名。
- 检测不到硬件编码器时标红并留在原位置，识别不到型号时标黑并写“未知”；启用前再提示一次。
- 编码线程可选择，支持 Intel 超线程；AMD SMT 按逻辑线程计入，不额外承诺“虚拟线程”。
- 快捷键面板独立入口，可改键；默认参考常见音视频软件的播放、暂停、队列和转换键位。
- 音频多轨：视频音轨替换时保留全部音轨；纯音频转换只处理第一条音轨。

## English

Installer name: `Timbre-WindowsX86-64`

The Windows 1.6 build does not exist yet. This round ships Android arm64-v8a only; the Windows documentation is written for 1.6, and the actual build starts separately.

Confirmed Windows behaviour:

- Windows 10 / 11 x64 only.
- Conversion must run in a visible foreground window; closing the window or minimizing to the tray does not guarantee progress. Windows is not a single-task background service.
- Processor detection counts physical cores and available logical threads, does not show clock speed, and does not count efficiency cores as extra performance cores.
- CPU / GPU encoders are detected per vendor: Intel shows Intel and its core count, AMD shows AMD and its core count, and NVIDIA / AMD GPUs are listed separately instead of one generic GPU name.
- A missing hardware encoder is marked red in place; an unreadable model is marked black as "Unknown", with one more warning before enabling.
- Encoding threads are selectable, including Intel Hyper-Threading; AMD SMT counts logical threads without promising extra "virtual threads".
- A separate shortcut panel allows rebinding; defaults follow common audio/video software for play, pause, queue and convert.
- Multiple audio tracks: video audio replacement preserves every track; pure audio conversion handles the first track only.
