# Third-party notices

Timbre is a derivative build assembled from existing open-source projects.

## Base app

- **SimpleAudioConverter** — MPL-2.0 — https://github.com/TechnicJelle/SimpleAudioConverter
  Base Android/Flutter application, file picking and share entry points. Upstream copyright belongs to TechnicJelle and its contributors.

## Conversion runtime

- **FFmpegKit** — LGPL-3.0 — https://github.com/arthenica/ffmpeg-kit
- **ffmpeg_kit_flutter_new_audio** — community maintained FFmpegKit distribution used by this build.
- **FFmpeg** — LGPL-2.1+ — https://ffmpeg.org

## UI and Flutter packages

- **Flutter** — BSD-3-Clause — https://flutter.dev
- **m3_expressive** — MIT — https://pub.dev/packages/m3_expressive (fabric-apps)
- **material_shapes** — MIT — shape definitions used by m3_expressive (Kostiantyn Sokolovskyi)
- **file_picker** — MIT — document picking
- **share_plus** — BSD-3-Clause — outgoing share sheet
- **share_handler** — MIT — incoming share target
- **shared_preferences** — BSD-3-Clause — accent colour persistence
- **path_provider** — BSD-3-Clause — output directory
- **installed_apps** — Apache-2.0 — installed-app queries

Full license texts ship with each package or are available at the linked project.

Files added or modified in this repository are distributed under MPL-2.0. See LICENSE.

## What this build changed

- SimpleAudioConverter: app label renamed to Timbre, SoC detection rewritten (multi-key fallback plus MediaTek/Qualcomm alias tables), 18 output formats with category grouping and user-defined groups, presets moved to the bottom of the format sheet, custom accent colour, responsive width limits for split-screen/freeform windows, launcher icon replaced, `android:resizeableActivity="true"`.
- FFmpegKit (`ffmpeg_kit_flutter_new_audio`): build trimmed to `arm64-v8a`, only the audio package and the encoders needed by the 18 formats. Conversion command now starts with `-map 0:a:0 -vn`, ends with `-map_metadata 0 -map_chapters -1`, and forces mono 8/16 kHz for AMR.
- No changes were pushed to the upstream SimpleAudioConverter, FFmpegKit or FFmpeg repositories. These edits live in this fork and are documented here.

Parts of the 1.2 rewrite (UI layout, format table, tests, README) were drafted with Doubao, an AI assistant, then reviewed, compiled and tested by the maintainer. The conversion engine and FFmpeg command lines were checked against actual encoder output.
