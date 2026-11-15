# 改动清单 / Changes

## 1.3.1（当前版本，2026-11-15）

- 格式说明重写：18 种格式的展开说明改成一句用途加几句取舍，不再复述参数表。
- 详情页分成“适合拿来做什么”和“用起来的取舍”，全部格式面板另用一段更短的参考文案，不再直接复制详情页。
- 全部格式面板按日常、无损、语音、老格式、其他分组。
- 修 Android 17 / HyperOS 4 上的设备识别。`String[]` 不能直接走 MethodChannel，整次调用失败，界面显示“未识别 / Android 0”；改成逗号分隔字符串，并补 `getprop`、`/proc/cpuinfo`、device-tree、`soc0` 兜底。
- 天玑 9400+ / 9300+、骁龙 8 第三代及以后的型号映射补测试；换皮型号落到基础型号。
- 删掉格式展开里重复的传输层备注。
- 界面收敛：顶部卡片减阴影，四个区块加编号，格式按钮去掉回弹，宽屏内容居中。
- 移除未使用的 3 MB `AppBar_Icon.png`，APK 从 42.8 MB 降到 39.8 MB。
- 版本 1.3.1，versionCode 20112，targetSdk 36，仅 arm64-v8a，签名证书不变。
- 1.3.0 已被取代；1.2.0 是第一个正式版；1.0.x、1.1.x 标为内测、废弃。

## 1.3.0（2026-11）

- MP3 增加版本选择：MPEG-1、MPEG-2（24 kHz / 160 kbps 上限）、MPEG-2.5（12 kHz / 64 kbps 上限），切换后码率滑块按真实范围收口。
- 硬解失败弹窗：MediaCodec 失败时说明原因，一键切软件并重试；软件也失败再提示换格式或版本。
- 停止转换前增加确认，说明当前文件作废、已完成文件保留。
- 移除未使用的 `installed_apps` 依赖，重新启用 R8 与资源压缩，APK 从 45 MB 降到 41 MB。
- README 重写为中英双语，新增 [README.en.md](README.en.md)、[DEVLOG.md](DEVLOG.md)。
- 版本 1.3.0+10，versionCode 20102，targetSdk 36，仅 arm64-v8a，签名证书不变。

## 1.2.0（第一个正式版，2026-11）

- 输出格式从 11 种扩到 18 种，新增 AAC(ADTS)、CAF、AU、WavPack、AMR-NB、AMR-WB、E-AC-3。
- 格式按日常、无损、语音、老格式、其他分组；支持自建分组，长按删除。
- 每个格式详情滑到底给出推荐预设，点了才生效。
- 滑块改为长按 0.35 倍速微调、松手吸附；切换按钮补过渡动画。
- 修掉 AnimatedContainer 在有无阴影之间插值时的负 blur 断言。
- 修掉设置页下拉框在窄屏下的 RenderFlex 溢出。
- 界面最大宽度 760、底栏 640，去掉方向锁，适配小窗、分屏、平板；`resizeableActivity=true`。
- SoC 识别补天玑 9500S、9600M 等换皮别名，新增是否在验证名单内的提示。
- 应用图标换成青色圆环箭头加音符，各密度与 adaptive icon 重切。
- 命令追加 `-map_chapters -1`；AMR 强制 8/16 kHz 单声道、固定档位。
- 版本 1.2.0+9，versionCode 20092，targetSdk 36，仅 arm64-v8a。
- 1.0.x 与 1.1.x 标为内测、废弃。

## 1.1.1（内测，已废弃）

- 修掉转换后无声音：`-map 0:a:0 -vn -map_metadata 0`。
- 11 种格式、连续码率、CBR/VBR、批量、双语、改名 Timbre、自定义主题色、SoC 多级兜底。

相对上游 1.0.5 / Against upstream 1.0.5

## 新增文件 / Added

- `lib/conversion.dart` — 格式定义、码率与 VBR 参数、ffmpeg 命令构建。
- `lib/convert_engine.dart` — 批处理引擎，逐个文件会话、进度回调、取消、输出重名处理。
- `lib/device_info.dart` — SoC 识别与多级兜底、线程建议。
- `lib/theme.dart` — Material 3 Expressive 主题。
- `android/app/src/main/java/com/technicjelle/simple_audio_converter/MainActivity.java` — MethodChannel `audio_converter/device`，读取 `Build` 字段、`getprop`、cpuinfo 和 device-tree。

## 修改文件 / Modified

- `lib/main.dart` — 整个界面重写：文件队列、格式选择器、码率面板、性能面板、结果与分享、edge-to-edge。
- `pubspec.yaml` — 版本 1.3.1+11；移除未使用的 `assets/AppBar_Icon.png` 打包项。
- `android/app/src/main/AndroidManifest.xml` — `enableOnBackInvokedCallback`，`resizeableActivity`，应用名 Timbre。
- `android/app/build.gradle.kts` — 包名 `com.technicjelle.simple_audio_converter.zh`（签名配置未公开）。

## 未使用但保留 / Kept, unused

- `lib/target_file_type.dart`、`lib/tech_app.dart`（旧实现，被新模块取代，未删除以便对照上游）。

## 关键命令差异 / Command difference

上游 / upstream:

```
ffmpeg -i IN <codec args> -y OUT
```

本仓库 / this fork:

```
ffmpeg -hide_banner -y [-hwaccel mediacodec] -i IN [-filter:a arnndn] -map 0:a:0 -vn -map_metadata 0 -map_chapters -1 [-ar N] [-ac N] [-threads N] <codec args> "OUT"
```

只映射第一条音轨并丢弃全部视频/封面流，是“转出来没声音”的根因修复。
Mapping only the first audio stream and dropping video/cover streams is the root-cause fix for silent output.
