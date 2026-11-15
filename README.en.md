# Timbre

An Android audio converter. Pick a file, pick a format, convert. Nothing else.

This is a modified build of [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter). The base app, Android project, file picking and sharing entry points come from upstream. MPL-2.0 applies to this repository as well.

[中文说明](README.md)

## Download

Installers, source snapshots, version numbers, checksums and per-release changes live in [Releases](https://github.com/Teacers/SimpleAudioConverter/releases). This manual covers the app itself and does not repeat release notes.

Only `arm64-v8a` is shipped. The package name stays `com.technicjelle.simple_audio_converter.zh`, so installing over an older build keeps settings. The signing certificate is unchanged.

## What it does

18 output formats, grouped as everyday, lossless, voice, legacy and other. Everyday: MP3, M4A, AAC, OGG, Opus. Lossless: FLAC, WAV, AIFF, ALAC, CAF, AU, WavPack. Voice: AMR-NB, AMR-WB. Legacy: WMA, MP2, AC-3, E-AC-3. Groups can be created and deleted.

MP3 exposes MPEG-1, MPEG-2 and MPEG-2.5. Switching variants clamps the bitrate to that variant's real ceiling, so a 12 kHz stream cannot be pushed to 320 kbps. AMR uses fixed legal steps and snaps the slider.

Below the bitrate block there is an overall level control, -12 to +12 dB. 0 dB leaves the file untouched; positive gain is limited automatically to avoid clipping. A separate “Match loudness across files” switch is meant for queues that mix quiet recordings with normal tracks. While it is on, the gain slider is bypassed.

Batch conversion, stop confirmation, a one-tap software fallback when hardware decode fails, and a second suggestion to change format or version when software also fails are all present. Split-screen, freeform windows and tablets are supported; the UI does not lock orientation.

## Settings

The settings page in the top bar controls three things: interface language, accent colour and the output folder.

Language offers System, 中文 and English. A change applies immediately and survives a restart, instead of following the system language on every launch.

The output folder is granted through the system folder picker. Android 15, 16 and 17 use the same mechanism. The grant is persisted, so the app can keep writing after a restart. Once a folder is set, finished files are written there directly and the result row says Done; the share button is not shown. Without a folder, files stay in the app's own directory and sharing remains available.

Changing or resetting the folder never touches files already saved. If the system revokes write access, the next conversion falls back to the app directory instead of dropping the result.

## Compatibility

The tested list is defined by processor family, never by phone marketing name:

- Dimensity 9300 and newer: 9300, 9400, 9500, 9600, including Plus, Pro, S and M variants.
- Dimensity 8400, 8450 and 8500 family. The 8400, 8450 and 8400 Ultra are essentially the same part; 8400 Max is close to the 8500; 8500 and 8550 are clocked-up members of that family.
- Snapdragon 8 Gen 3 and newer, including 8s Gen 4, 8 Elite, 8 Gen 5, 8 Elite Gen 5/6 and rebadged parts.
- Snapdragon 7 standard: 7 Gen 3 and 7 Gen 4. Snapdragon 7+: 7+ Gen 2 and 7+ Gen 3. Snapdragon 7s is deliberately excluded and falls back to software decoding.

Keep the Dimensity 8500 and 9400 separate. Their hardware encoding uses the same MediaTek path, with comparable H.264/HEVC and 4K60 support, so audio conversion is handled as the same tier. The CPU is not the same: the 8500 has eight Cortex-A725 cores, the 9400 uses X925 + X4 + A720; the 8500 has Mali-G720 MC8, the 9400 has G925 MC12. The encoder path is comparable; the chips are not the same part.

SM8450 (Snapdragon 8 Gen 1), SM8475 (8+ Gen 1) and SM8550 (8 Gen 2) are recognised. They are outside the validated hardware list: software decoding works, hardware decoding is not guaranteed. Older flagships outside the list follow the same rule.

Other chips still run. Pure audio conversion is CPU software decode, so it works, just slower. Hardware decode and encode are different: MediaCodec implementations vary, and a non-listed chip may fail outright or produce silence. The app marks such devices as outside the tested list.

The app is built against native Android first, with checks for Xiaomi HyperOS / MIUI, OPPO / OnePlus ColorOS, realme UI and vivo / iQOO OriginOS. Nothing OS and other near-AOSP builds follow AOSP. OEM ROMs tend to change the file picker, background limits, notifications and permission prompts; failures usually come from those areas, not the conversion engine.

Android 15 or newer is recommended. targetSdk is 36. Android 15 edge-to-edge, 16 KB page alignment and predictive back are implemented; Android 16 and 17 inherit the same behaviour. The app installs on older versions but those are untested.

Split-screen and freeform windows are handled. Starting with Android 16, apps targeting SDK 36 lose the ability to restrict orientation, aspect ratio and resizability on displays with smallest width ≥600dp. The UI therefore does not lock orientation; content is capped at 760dp and the bottom bar at 640dp.

## Forking

The repository is MPL-2.0. You can build on it, provided modified files keep the same license and upstream attribution stays intact. If you publish a modified build, use your own package name and signing key; reusing `com.technicjelle.simple_audio_converter.zh` makes it impossible for users to tell your build from the official one. Notes on trade-offs and known gaps are in [DEVLOG.md](DEVLOG.md) (Chinese); some material is omitted.

## Open source used

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) — MPL-2.0 — base app, Android project, file picking and sharing. Original author: TechnicJelle.
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new_audio` — LGPL-3.0 — conversion runtime. Used as shipped; no source changes.
- [FFmpeg](https://ffmpeg.org) — LGPL-2.1+ — codecs and muxers.
- [m3_expressive](https://pub.dev/packages/m3_expressive) — MIT — morphing indicator; material_shapes by Kostiantyn Sokolovskyi.
- Flutter, file_picker, share_plus, share_handler, shared_preferences, path_provider.

Upstream copyright belongs to TechnicJelle and contributors. New and modified files in this repository stay under MPL-2.0. See [THIRD_PARTY.md](THIRD_PARTY.md).

## AI disclosure

Since 1.2, parts of the UI rewrite, format tables, tests and these README files were drafted with Doubao, an AI assistant. The drafts were reviewed, compiled and tested by the maintainer. The conversion engine was not generated by AI; FFmpeg command lines were checked against actual encoder output.

`flutter analyze` reports no errors. `flutter test` covers format switching, the settings page, narrow split-window layout, long-press presets, slider fine adjustment, the MP3 version selector, format-reference expansion, the gain/loudness panel, and processor detection mappings. There is no Android emulator in the build environment, so on-device conversion and writes into system folders have not been verified.

## Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14, JDK 17, Android SDK 36, build-tools 36.0.0, NDK 28.2.13676358. Signing material is not stored in the repository.

## License

MPL-2.0. See [LICENSE](LICENSE) and [THIRD_PARTY.md](THIRD_PARTY.md).
