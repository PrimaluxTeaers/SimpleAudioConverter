# Third-party notices

Timbre is a derivative build assembled from existing open-source projects.

| Component | License | Role |
| --- | --- | --- |
| [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) | MPL-2.0 | Base Android/Flutter app, file picking and sharing entry points |
| [FFmpegKit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new_audio` | LGPL-3.0 | Conversion runtime |
| [FFmpeg](https://ffmpeg.org) | LGPL-2.1+ | Codecs and muxers |
| [m3_expressive](https://pub.dev/packages/m3_expressive) | MIT | Material 3 Expressive morphing indicator |
| material_shapes (Kostiantyn Sokolovskyi) | MIT | Shape definitions used by m3_expressive |
| [Flutter](https://flutter.dev) | BSD-3-Clause | UI framework |
| file_picker | MIT | Document picking |
| share_plus | BSD-3-Clause | Outgoing share sheet |
| share_handler | MIT | Incoming share target |
| shared_preferences | BSD-3-Clause | Persisting the accent colour |
| path_provider | BSD-3-Clause | Output directory |

Full license texts ship with each package or are available at the linked project.
Upstream copyright for SimpleAudioConverter belongs to TechnicJelle and its contributors.
Files added or modified in this repository are distributed under MPL-2.0.

## What this build changed

- SimpleAudioConverter: package label renamed to Timbre, processor-first performance card, SoC detection rewritten (multi-key fallback, `getprop`/cpuinfo/device-tree fallbacks, plus MediaTek/Qualcomm/Samsung alias tables), 18 output formats with category grouping and user-defined groups, presets moved to the bottom of the format sheet, custom accent colour, responsive width limits for split-screen/freeform windows, launcher icon replaced, `android:resizeableActivity="true"`.
- FFmpegKit (`ffmpeg_kit_flutter_new_audio`): the audio-only package is used as shipped; no source changes. The app layer builds the conversion command, which starts with `-map 0:a:0 -vn`, ends with `-map_metadata 0 -map_chapters -1`, forces mono 8/16 kHz for AMR, and adds a single `-filter:a` chain for RNNoise, overall gain with `alimiter`, or one-pass `loudnorm`.
- No changes were pushed to the upstream SimpleAudioConverter, FFmpegKit or FFmpeg repositories. These edits live in this fork and are documented here.

Parts of the 1.2–1.3.2 rewrites (UI layout, format table, tests, README) were drafted with Doubao, an AI assistant, then reviewed, compiled and tested by the maintainer. The conversion engine and FFmpeg command lines were checked against actual encoder output.
