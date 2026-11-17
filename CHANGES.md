# 改动清单

## 1.6.0 — 2026-11-17

### 中文

1.6 是新基线。1.5 及更早的 Release、tag 和旧文档入口已清理，仓库只保留 1.6 叙事。

- 版本升到 1.6.0，arm64-v8a 安装包的 versionCode 由构建偏移决定，高于 1.5。
- 完成条改为显示后消失，结果卡延迟收成一行摘要；点结果卡立即收起或展开，不再常驻页面。
- 音频导入只走系统文件管理器，不调用相册，也不申请全盘存储权限。
- 视频导入继续只替换第一条音轨，视频流复制；视频选择走系统文件选择器。
- 保留 18 种输出格式、MP3 版本与码率联动、AMR 固定档位、整体音量、统一响度、批量队列和失败切软解。
- HDR10、HDR10+、杜比视界在视频导入时按“HDR 保留”处理：音轨替换不动视频流，画面和 HDR 信息原样保留。
- 音频多轨：视频导入会保留全部音轨并逐条重编码；纯音频转码只处理第一条音轨。
- 主题、语言、输出目录持久化保持原行为；界面过渡、窄屏和小窗排版沿用 1.5 收口后的实现。

### English

1.6 is the new baseline. Releases, tags and old documentation entry points from 1.5 and earlier were removed; the repository keeps the 1.6 narrative only.

- Version is 1.6.0; the arm64-v8a versionCode comes from the build offset and is higher than 1.5.
- The completion bar now disappears; the result card collapses to a one-line summary after a delay and expands or collapses immediately when tapped.
- Audio import uses the system file manager only, with no gallery picker and no broad storage permission.
- Video import still replaces the first audio track and copies the video stream; video selection uses the system file picker.
- Keeps 18 output formats, MP3 version and bitrate limits, fixed AMR rates, overall volume, loudness matching, batch queue and software fallback.
- HDR10, HDR10+, Dolby Vision are handled as "HDR preservation" during video import: the video stream is untouched, so the picture and HDR metadata survive.
- Multiple audio tracks: video import preserves and re-encodes every audio track; pure audio conversion handles the first track only.
- Theme, language and output-folder persistence are unchanged; transitions and narrow-window layout follow the 1.5 close-out implementation.
