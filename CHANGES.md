# 改动清单 / Changes

相对上游 1.0.5 / Against upstream 1.0.5

## 新增文件 / Added

- `lib/conversion.dart` — 11 种格式定义、连续码率与 VBR 参数、ffmpeg 命令构建（含 `-vn` 修复）。
- `lib/convert_engine.dart` — 批处理引擎，逐个文件会话、进度回调、取消、输出重名处理。
- `lib/device_info.dart` — SoC 识别与多级兜底、线程建议。
- `lib/theme.dart` — Material 3 Expressive 主题。
- `android/app/src/main/java/com/technicjelle/simple_audio_converter/MainActivity.java` — MethodChannel `audio_converter/device`，读取 `Build` 字段与 `SystemProperties`。

## 修改文件 / Modified

- `lib/main.dart` — 整个界面重写：文件队列、格式选择器、码率面板、性能面板、结果与分享、edge-to-edge。
- `pubspec.yaml` — 版本 1.1.0+7，新增 `file_picker` 依赖。
- `android/app/src/main/AndroidManifest.xml` — `enableOnBackInvokedCallback`，应用名"音频转换"。
- `android/app/build.gradle.kts` — 包名改为 `com.technicjelle.simple_audio_converter.zh`（签名配置未公开）。

## 未使用但保留 / Kept, unused

- `lib/target_file_type.dart`、`lib/tech_app.dart`（旧实现，被新模块取代，未删除以便对照上游）。

## 关键命令差异 / Command difference

上游 / upstream:

```
ffmpeg -i IN <codec args> -y OUT
```

本仓库 / this fork:

```
ffmpeg -hide_banner -y [-hwaccel mediacodec] -i IN [-filter:a arnndn] -map 0:a:0 -vn -map_metadata 0 [-ar N] [-ac N] [-threads N] <codec args> "OUT"
```

只映射第一条音轨并丢弃全部视频/封面流，是"转出来没声音"的根因修复。
Mapping only the first audio stream and dropping video/cover streams is the root-cause fix for silent output.
