# Timbre

An Android audio converter. Pick a file, pick a format, convert. Nothing else.

This is a modified build of [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter). The base app, Android project, file picking and sharing entry points come from upstream. MPL-2.0 applies to this repository as well.

[中文说明](README.md)

## Downloads

- APK (arm64-v8a, 39.8 MB, versionCode 40122): https://aka.doubaocdn.com/s/Y6Z49JnE31
- Source snapshot: [source-1.3.2.zip](source-1.3.2.zip)

APK SHA-256: `9f49baabeddac93fb33b8fa5b56b95acbd649b00d897f7635ed63519fba8d04a`. 16 KB alignment verified. The signing certificate SHA-256 is `354871FE58DC66F7CB5780F1DEBA20565897C9A4DD0C22154A9549F4E405F3F7`, same as 1.3.1.

## Releases

1.3.2 is the current release. 1.3.1 and 1.3.0 are superseded; 1.2.0 was the first official build. Everything before 1.2 (1.0.x, 1.1.x) was internal testing and is discontinued. Old builds are not repackaged; install 1.3.2 over them.

The package name remains `com.technicjelle.simple_audio_converter.zh`. Renaming it would break in-place upgrades and orphan the old settings and output folder. The signing certificate is unchanged.

Only `arm64-v8a` is shipped. There is no 32-bit build. Current flagship phones are 64-bit, Android 17 no longer fully supports 32-bit apps, and dropping the second ABI saves roughly 20 MB.

## What it does

18 output formats, grouped as everyday, lossless, voice, legacy and other. Everyday: MP3, M4A, AAC, OGG, Opus. Lossless: FLAC, WAV, AIFF, ALAC, CAF, AU, WavPack. Voice: AMR-NB, AMR-WB. Legacy: WMA, MP2, AC-3, E-AC-3. Groups can be created and deleted.

MP3 exposes MPEG-1, MPEG-2 and MPEG-2.5. Switching variants clamps the bitrate to that variant's real ceiling, so a 12 kHz stream cannot be pushed to 320 kbps. AMR uses fixed legal steps and snaps the slider.

Below the bitrate block there is an overall level control, -12 to +12 dB. 0 dB leaves the file untouched; positive gain is limited automatically to avoid clipping. A separate "Match loudness across files" switch is meant for queues that mix quiet recordings with normal tracks. While it is on, the gain slider is bypassed.

Batch conversion, stop confirmation, a one-tap software fallback when hardware decode fails, and a second suggestion to change format or version when software also fails are all present. The accent colour is changeable; split-screen, freeform windows and tablets are supported, and the UI does not lock orientation.

## Compatibility

The tested list is defined by processor family, never by phone marketing name:

- Dimensity 9300 and newer: 9300, 9400, 9500, 9600, including Plus, Pro, S and M variants.
- Dimensity 8400 and 8500. 8500 is the same part as 8400 with the GPU unlocked and a mild clock bump; 8400 Ultra and 8400 Max derivatives are covered too.
- Snapdragon 8 Gen 3 and newer, including 8s Gen 4, 8 Elite, 8 Gen 5, 8 Elite Gen 5/6 and rebadged parts.
- Snapdragon 7 standard: 7 Gen 3 and 7 Gen 4. Snapdragon 7+: 7+ Gen 2 and 7+ Gen 3. Snapdragon 7s is deliberately excluded and falls back to software decoding.

Other chips still run. Pure audio conversion is CPU software decode, so it works, just slower. Hardware decode and encode are different: MediaCodec implementations vary, and a non-listed chip may fail outright or produce silence. The app marks such devices as outside the tested list.

The app is built against native Android first, with checks for Xiaomi HyperOS / MIUI, OPPO / OnePlus ColorOS, realme UI and vivo / iQOO OriginOS. Nothing OS and other near-AOSP builds follow AOSP. OEM ROMs tend to change the file picker, background limits, notifications and permission prompts; failures usually come from those areas, not the conversion engine.

Android 15 or newer is recommended. targetSdk is 36. Android 15 edge-to-edge, 16 KB page alignment and predictive back are implemented; Android 16 and 17 inherit the same behaviour. The app installs on older versions but those are untested.

Split-screen and freeform windows are handled. Starting with Android 16, apps targeting SDK 36 lose the ability to restrict orientation, aspect ratio and resizability on displays with smallest width ≥600dp. The UI therefore does not lock orientation; content is capped at 760dp and the bottom bar at 640dp.

## What changed in 1.3.2

The performance card no longer shows a phone name. The title is the processor; the subtitle keeps vendor, core count, architecture and Android release. If no chip is readable, it says "Unknown".

Chip and ROM detection was widened: Dimensity 8400/8500, 9500M and 9600 Pro; Snapdragon 7 Gen 3/4 and 7+ Gen 2/3; Exynos 2400/2500. When a vendor ROM hides the usual properties, detection has other paths to read and does not fall back to a retail model name.

The sound card gained overall gain and loudness matching. The conversion command now chains denoise, gain, limiting or loudness matching instead of handling denoise alone.

The compatibility note is explicit about who is in the tested list, who is not, and why Snapdragon 7s is excluded.

The layout is a little quieter: the top card has a lighter shadow, and the level controls sit inside the bitrate card instead of becoming another card.

## Earlier releases

1.3.1 rewrote the format notes, split the detail sheet into "WHAT IT'S FOR" and "TRADE-OFFS", and grouped the full reference by use. It also fixed the Android 17 "Unknown / Android 0" device readout. A 3 MB unused icon was dropped from the bundle, taking the APK from 42.8 MB to 39.8 MB.

1.3.0 added MP3 variant selection, a one-tap software fallback after hardware decode failure, and stop confirmation. It removed an unused dependency, re-enabled R8 and resource shrinking, and took the APK from 45 MB to 41 MB.

1.2.0 expanded the format list from 11 to 18, added grouping and user-defined groups, presets at the bottom of the detail sheet, long-press slider fine adjustment, the teal icon and SoC aliases.

## Forking

The repository is MPL-2.0. You can build on 1.3.2, provided modified files keep the same license and upstream attribution stays intact. If you publish a modified build, use your own package name and signing key; reusing `com.technicjelle.simple_audio_converter.zh` makes it impossible for users to tell your build from the official one. Notes on trade-offs and known gaps are in [DEVLOG.md](DEVLOG.md) (Chinese); some material is omitted.

## Open source used

- [SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter) — MPL-2.0 — base app, Android project, file picking and sharing. Original author: TechnicJelle.
- [FFmpegKit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new_audio` — LGPL-3.0 — conversion runtime. Used as shipped; no source changes.
- [FFmpeg](https://ffmpeg.org) — LGPL-2.1+ — codecs and muxers.
- [m3_expressive](https://pub.dev/packages/m3_expressive) — MIT — morphing indicator; material_shapes by Kostiantyn Sokolovskyi.
- Flutter, file_picker, share_plus, share_handler, shared_preferences, path_provider.

Upstream copyright belongs to TechnicJelle and contributors. New and modified files in this repository stay under MPL-2.0. See [THIRD_PARTY.md](THIRD_PARTY.md).

## AI disclosure

Parts of the 1.2–1.3.2 rewrite were drafted with Doubao, an AI assistant: UI layout, format tables, tests and these README files. The drafts were reviewed, compiled and tested by the maintainer. The conversion engine was not generated by AI; FFmpeg command lines were checked against actual encoder output.

`flutter analyze` reports no errors. `flutter test` covers format switching, theme changes, narrow split-window layout, long-press presets, slider fine adjustment, the MP3 version selector, format-reference expansion, the gain/loudness panel, and processor detection mappings. There is no Android emulator in the build environment, so on-device conversion has not been verified.

## Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14, JDK 17, Android SDK 36, build-tools 36.0.0, NDK 28.2.13676358. 1.3.2 uses versionCode 40122. Signing material is not stored in the repository.

## License

MPL-2.0. See [LICENSE](LICENSE) and [THIRD_PARTY.md](THIRD_PARTY.md).
