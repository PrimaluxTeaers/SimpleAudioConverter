# Timbre 1.5.0 — Android arm64-v8a（重做版）

## 中文

1.5 仍在重做，版本号保持 1.5.0。之前的 1.5 Release 和标签已从仓库撤下，这一轮改完后重新构建、重新发布；1.3.3 等旧发布记录不动。

- 视频导入不再只抽音轨：处理第一条音轨，视频流原样复制，画面、分辨率、帧率、HDR 信息保持。
- 视频输出容器按编码组合选：H.264 / H.265 / AV1 / MPEG-4 加 M4A / AAC / MP3 / ALAC 用 MP4，其余组合用 MKV。只导出音频时仍是普通音频文件。
- Android 前台服务通知显示当前文件和整体进度；退到后台不再静默中断。
- 完成条显示约 5 秒后自动收起，结果卡片约 9 秒后收成一行摘要；点结果卡可以立刻收起 / 展开。底部栏、按钮和页面切换补过渡动画。
- 应用名 `Timbre 64 位`，Windows 版 `Timbre x86-64`，只支持 Windows 10 / 11 x64。
- 包名 `com.technicjelle.simple_audio_converter.zh` 不变，签名证书不变，旧版可以覆盖安装。
- README 改为中英上下对照，去掉独立的 `README.en.md` 跳转。

安装包在重新构建后附上；当前 Release 不挂旧 APK。

## English

1.5 is still being reworked and the version stays 1.5.0. The previous 1.5 releases and tags were removed from the repository; this round will be rebuilt and republished when it is finished. Releases such as 1.3.3 remain untouched.

- Video import no longer extracts audio only: it processes the first audio track and copies the video stream, keeping the picture, resolution, frame rate and HDR metadata.
- The video output container follows the codec pair: H.264 / H.265 / AV1 / MPEG-4 with M4A / AAC / MP3 / ALAC goes to MP4; other combinations go to MKV. Audio-only exports remain plain audio files.
- An Android foreground-service notification shows the current file and overall progress; leaving the app no longer silently kills the job.
- The completion bar hides itself after about five seconds and the results card collapses into a one-line summary after about nine seconds. Tapping the card collapses or expands it immediately. The bottom bar, buttons and page changes use transitions.
- App name `Timbre 64 位`; Windows build `Timbre x86-64`, supporting Windows 10 / 11 x64 only.
- Package name `com.technicjelle.simple_audio_converter.zh` is unchanged; the signing certificate is unchanged and the build installs over the old one.
- README is a Chinese/English pair in one file, with no separate `README.en.md` jump.

The APK will be attached after the rebuild; this release carries no old APK.
