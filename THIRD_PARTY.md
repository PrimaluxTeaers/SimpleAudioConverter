# Third-party notices

Timbre is built on existing open-source projects.

| Component | License | Role |
| --- | --- | --- |
| [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) | MPL-2.0 | Base Android/Flutter app, file picking and sharing |
| [FFmpegKit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new_audio` | LGPL-3.0 | Conversion runtime |
| [FFmpeg](https://ffmpeg.org) | LGPL-2.1+ | Codecs and muxers |
| [m3_expressive](https://pub.dev/packages/m3_expressive) | MIT | Material 3 Expressive morphing indicator |
| material_shapes (Kostiantyn Sokolovskyi) | MIT | Shape definitions used by m3_expressive |
| [Flutter](https://flutter.dev) | BSD-3-Clause | UI framework |
| file_picker | MIT | Document picking |
| share_plus | BSD-3-Clause | Outgoing share sheet |
| share_handler | MIT | Incoming share target |
| shared_preferences | BSD-3-Clause | Persisting theme, language and app settings |
| path_provider | BSD-3-Clause | Temporary output before publishing |

Full license texts ship with each package or are available at the linked project. Upstream copyright for SimpleAudioConverter belongs to TechnicJelle and its contributors. Files added or modified in this repository are distributed under MPL-2.0.

## What this build changed

- SimpleAudioConverter: label renamed to Timbre, processor-first performance card, device detection rewritten with wider chip and ROM coverage, 18 output formats with category grouping and user-defined groups, presets moved to the bottom of the format sheet, custom accent colour, manual language switch, settings page, persisted system-folder output, responsive width limits for split-screen and freeform windows, launcher icon replaced, and resizable activity enabled.
- FFmpegKit (`ffmpeg_kit_flutter_new_audio`): used as shipped; no source changes. The app layer builds the conversion command, including the audio-only mapping, metadata handling, fixed AMR rates and the optional level/loudness stage.
- No changes were pushed to the upstream SimpleAudioConverter, FFmpegKit or FFmpeg repositories. These edits live in this fork and are documented here.

Parts of the 1.2–1.3.3 rewrites (UI layout, settings page, format table, tests, README) were drafted with Doubao, an AI assistant, then reviewed, compiled and tested by the maintainer. The conversion engine and FFmpeg command lines were checked against actual encoder output.
