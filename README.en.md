# Timbre

An Android audio converter. Pick a file, pick a format, convert. Nothing else.

This is a modified build of [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter). The base app, Android project and file entry points come from upstream. MPL-2.0 applies to this repository as well.

[中文说明](README.md)

## Downloads

- APK (arm64-v8a, 41 MB, versionCode 20102): https://aka.doubaocdn.com/s/g9THD5ybU9
- Source snapshot: https://aka.doubaocdn.com/s/4MVRRJG5Yj

APK SHA-256: `b2149aa9d004b49db061935b392c532c302667cf7548616182a0f1bd33af7b71`. 16 KB alignment verified with `zipalign -c -P 16`; signing certificate SHA-256 is unchanged at `354871FE58DC66F7CB5780F1DEBA20565897C9A4DD0C22154A9549F4E405F3F7`.

## Release status

**1.3.0 is the current release.** 1.2.0 was the first official build. Everything before 1.2 (1.0.x, 1.1.x) was internal testing and is discontinued; old links are kept only for reference.

The package name remains `com.technicjelle.simple_audio_converter.zh`. Renaming it would break in-place upgrades and orphan the old settings and output folder. The signing certificate is unchanged.

Only `arm64-v8a` is shipped. There is no 32-bit build. Current flagship phones are 64-bit, Android 17 no longer fully supports 32-bit apps, and dropping the second ABI saves roughly 20 MB.

## System requirements

Android 15 or newer is recommended and tested. targetSdk is 36. Android 15 edge-to-edge, 16 KB page alignment and predictive back are implemented; Android 16 and 17 inherit the same behaviour.

The app installs on older versions but those are untested. Expect unknown issues around status bar insets, file picker paths, or background process limits. Updating the OS or trying another device is the practical fix.

There is no separate branch per Android version. After Android 15 the platform did not change the underlying app model, so 15, 16 and 17 share one implementation.

## Devices

Primary targets:

- Dimensity 9300 and newer: 9300, 9400, 9500, 9600, including Plus, Pro and S variants. 9500S is a rebadged 9400; 9600M is a rebadged 9500+. Detection resolves them to the base part instead of reporting a new chip.
- Snapdragon 8 Gen 3 and newer, including 8s Gen 4 and rebadged parts. Detection reads `Build.SOC_MODEL`, `ro.soc.model`, `ro.board.platform` and several vendor keys; a literal `0` in `SOC_MODEL` falls through to the next key.

Other chips still run. Pure audio conversion is CPU software decode, so it works, just slower. Hardware decode/encode is different: MediaCodec implementations vary, and a non-listed chip may fail outright or produce silence. The app marks such devices as outside the tested list.

## OEM ROMs

The app is built against native Android first, with specific checks for:

- Xiaomi HyperOS / MIUI
- OPPO / OnePlus ColorOS
- vivo / iQOO OriginOS

Other brands, including HTC, Sony and Nothing, follow AOSP behaviour and have not been tested device by device. OEM ROMs tend to change the file picker, background limits, notifications and permission prompts; failures usually come from those areas, not the conversion engine.

Split-screen and freeform windows are handled. Starting with Android 16, apps targeting SDK 36 lose the ability to restrict orientation, aspect ratio and resizability on displays with smallest width ≥600dp. The UI therefore does not lock orientation; content is capped at 760dp and the bottom bar at 640dp so narrow split windows and wide tablets both stay usable.

## What changed in 1.3

**Selectable format versions.** MP3 now exposes MPEG-1, MPEG-2 (24 kHz, 160 kbps ceiling) and MPEG-2.5 (12 kHz, 64 kbps ceiling). The version control appears above the bitrate panel and clamps the slider to the variant's real range. Formats without multiple real bitstreams do not get a fake version list.

**Hardware decode failures are actionable.** If MediaCodec fails while hardware decode is selected, the app explains what happened and offers a one-tap switch to software with a retry. If software also fails, a second dialog suggests another format or version.

**Stop confirmation.** Interrupting a batch now asks first and explains that the in-flight file is discarded while finished files remain.

**LHDC and NearLink are documented, not faked.** LHDC 3.0–5.0 and NearLink L2HC are wireless transport codecs, not file formats. FFmpeg has no encoder for either, so Timbre does not list them as output formats. The format reference sheet states this in both languages.

**Smaller build.** The unused `installed_apps` dependency was removed, and R8 plus resource shrinking are enabled again.

The rest of the 1.3 baseline is inherited from 1.2: 18 output formats, category grouping with user-defined groups, presets at the bottom of the detail sheet, long-press fine adjustment on sliders, the teal ring-and-note icon, SoC aliases, and responsive width limits.

## Forking

The repository is MPL-2.0. You can build on 1.3, provided modified files keep the same license and upstream attribution stays intact. If you publish a modified build, use your own package name and signing key; reusing `com.technicjelle.simple_audio_converter.zh` makes it impossible for users to tell your build from the official one. Notes on trade-offs and known gaps are in [DEVLOG.md](DEVLOG.md) (Chinese); some internal details are omitted.

## Formats

Daily: MP3, M4A (AAC), AAC (ADTS), OGG Vorbis, Opus.

Lossless: FLAC, WAV, AIFF, ALAC, CAF, AU, WavPack.

Voice: AMR-NB, AMR-WB.

Legacy: WMA, MP2, AC-3, E-AC-3.

## Open source used

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) — MPL-2.0 — base app, Android project, file picking and sharing. Original author: TechnicJelle.
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new_audio` — LGPL-3.0 — conversion runtime. Used as shipped; no source changes.
- [FFmpeg](https://ffmpeg.org) — LGPL-2.1+ — codecs and muxers.
- [m3_expressive](https://pub.dev/packages/m3_expressive) — MIT — morphing indicator; material_shapes by Kostiantyn Sokolovskyi.
- Flutter, file_picker, share_plus, share_handler, shared_preferences, path_provider.

Upstream copyright belongs to TechnicJelle and contributors. New and modified files in this repository stay under MPL-2.0. See [THIRD_PARTY.md](THIRD_PARTY.md).

## AI disclosure

Parts of the 1.2/1.3 rewrite were drafted with Doubao, an AI assistant: UI layout, format tables, tests and these README files. The drafts were reviewed, compiled and tested by the maintainer. The conversion engine was not generated by AI; FFmpeg command lines were checked against actual encoder output.

`flutter analyze` reports no errors and `flutter test` covers format switching, CBR/VBR, theme changes, narrow split-window layout, long-press presets, slider fine adjustment, the MP3 version selector and the LHDC/NearLink note. There is no Android emulator in the build environment, so on-device conversion has not been verified.

## Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14, JDK 17, Android SDK 36, build-tools 36.0.0, NDK 28.2.13676358. Signing material is not stored in the repository; release builds read `TIMBRE_KEYSTORE`, `TIMBRE_STORE_PASSWORD`, `TIMBRE_KEY_ALIAS` and `TIMBRE_KEY_PASSWORD` from the environment.

## License

MPL-2.0. See [LICENSE](LICENSE) and [THIRD_PARTY.md](THIRD_PARTY.md).
