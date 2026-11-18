# Timbre 1.6.0 — Android arm64-v8a

## 中文

安装包：`Timbre-AndroidARM64-v8a.apk`  
应用名：`Timbre`  
最低系统：Android 7.0（API 24）  
包名：`com.technicjelle.simple_audio_converter.zh`  
版本：1.6.0，versionCode 1021622  
SHA-256：`45e85a94e33bb1e36d6a5d1d8e477d24b7539d0729ed7763e69712152e88af4c`，文件大小 43,758,525 字节

1.6 是新基线。1.5 及更早的 Release、tag 和旧文档入口已清理。

- 完成条显示后会消失，结果卡延迟收成一行摘要；点结果卡立即收起或展开。
- 音频导入只走系统文件管理器，不调用相册，也不申请全盘存储权限。
- 视频导入只替换音轨，视频流复制；音轨替换时保留全部音轨并逐条重编码。
- 视频流、HDR10、HDR10+、杜比视界按“HDR 保留”处理，画面信息不重新编码。
- 输出格式、MP3 版本与码率联动、AMR 固定档位、音量与响度、批量队列和软解回退保持原行为。码率滑块只吸固定档，数字框在提交或失焦时卡到当前格式上下限。
- 主题、语言、输出目录持久化立即生效；窄屏、小窗、平板排版和过渡动画保持原行为。

已知边界：纯音频转码只处理第一条音轨；视频导入的多音轨会统一为目标音频编码，原音轨编码不保留。真机转码和系统文件夹写入仍未在本轮验证。

## English

Installer: `Timbre-AndroidARM64-v8a.apk`  
App name: `Timbre`  
Minimum Android 7.0 (API 24)  
Package: `com.technicjelle.simple_audio_converter.zh`  
Version: 1.6.0, versionCode 1021622  
SHA-256: `45e85a94e33bb1e36d6a5d1d8e477d24b7539d0729ed7763e69712152e88af4c`; 43,758,525 bytes.

1.6 is the new baseline. Releases, tags and old documentation entry points from 1.5 and earlier were removed.

- The completion bar disappears after showing; the result card collapses to a one-line summary after a delay and expands or collapses immediately when tapped.
- Audio import uses the system file manager only, with no gallery picker and no broad storage permission.
- Video import replaces the audio only and copies the video stream; every audio track is preserved and re-encoded.
- The video stream, HDR10, HDR10+ and Dolby Vision are handled as "HDR preservation"; the picture is not re-encoded.
- Output formats, MP3 version and bitrate limits, fixed AMR rates, volume and loudness, batch queue and software fallback are unchanged. The bitrate slider only snaps to fixed stops, and the number field clamps to the current format range on submit or focus loss.
- Theme, language and output-folder persistence apply immediately; narrow-window, small-window and tablet layout and transitions are unchanged.

Known limits: pure audio conversion handles the first audio track only; multiple tracks from a video are all re-encoded to the target codec, so the original per-track codecs are not kept. Physical-device conversion and system folder writes have not been verified in this round.

## 平台支持

官方只发布 Android arm64-v8a。Windows 构建已经放弃：曾经认真尝试过，受限于设备和验证条件，最终没有继续。仓库保留共享的 Flutter / Dart 逻辑，熟悉 Windows 构建的人可以自行生成 runner 并适配；官方不提供成品、不维护，也不为第三方构建背书。

## Platform support

Android arm64-v8a is the only official build. The Windows build was attempted in earnest and then dropped because the devices and verification conditions were not there. The shared Flutter / Dart logic stays in the repository so someone with Windows build experience can generate a runner and adapt it; the project does not ship, maintain or endorse third-party builds.
