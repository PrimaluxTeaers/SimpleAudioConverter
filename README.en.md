# Timbre

An Android audio converter. Pick a file, pick a format, convert. Nothing else.

This is a modified build of [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter). The base app, Android project and file entry points come from upstream. MPL-2.0 applies to this repository as well.

[中文说明](README.md)

## Downloads

- APK (arm64-v8a, 39.8 MB, versionCode 40122): https://aka.doubaocdn.com/s/Y6Z49JnE31
- Source snapshot: https://aka.doubaocdn.com/s/UdkJJY9bHv

APK SHA-256: `9f49baabeddac93fb33b8fa5b56b95acbd649b00d897f7635ed63519fba8d04a`. 16 KB alignment verified with `zipalign -c -P 16`; signing certificate SHA-256 is unchanged at `354871FE58DC66F7CB5780F1DEBA20565897C9A4DD0C22154A9549F4E405F3F7`.

## Release status

**1.3.2 is the current release.** 1.3.1 and 1.3.0 are superseded; 1.2.0 was the first official build. Everything before 1.2 (1.0.x, 1.1.x) was internal testing and is discontinued. Old builds are not repackaged; install 1.3.2 over them.

- 1.3.1: official, superseded by 1.3.2.
- 1.3.0: official, superseded by 1.3.2.
- 1.2.0: first official build, old.
- 1.1.1 / 1.1.0: internal testing, discontinued.
- 1.0.5 and earlier: internal testing, discontinued.

The package name remains `com.technicjelle.simple_audio_converter.zh`. Renaming it would break in-place upgrades and orphan the old settings and output folder. The signing certificate is unchanged.

Only `arm64-v8a` is shipped. There is no 32-bit build. Current flagship phones are 64-bit, Android 17 no longer fully supports 32-bit apps, and dropping the second ABI saves roughly 20 MB.

## System requirements

Android 15 or newer is recommended. targetSdk is 36. Android 15 edge-to-edge, 16 KB page alignment and predictive back are implemented; Android 16 and 17 inherit the same behaviour.

On Android 17 with HyperOS 4, some vendor properties are harder to read. 1.3.0 could show "Unknown / Android 0" because the device-info channel put a `String[]` on the wire, which is not a StandardMessageCodec type; the whole call failed. 1.3.1 sends a comma-separated string instead, falls back to `getprop`, then to `/proc/cpuinfo`, device-tree and `soc0`. 1.3.2 adds `ro.hardware.chipname`, `ro.build.display.id` and more vendor keys. Dimensity 9400+ class parts now resolve to a name.

The app installs on older versions but those are untested. Expect unknown issues around status bar insets, file picker paths, or background process limits. Updating the OS or trying another device is the practical fix.

## Processors

The tested list is defined by processor family, never by phone marketing name:

- Dimensity 9300 and newer: 9300, 9400, 9500, 9600, including Plus, Pro, S and M variants.
- Dimensity 8400 and 8500. 8500 is the same part as 8400 with the GPU unlocked and a mild clock bump; 8400 Ultra and 8400 Max derivatives are covered too.
- Snapdragon 8 Gen 3 and newer, including 8s Gen 4, 8 Elite, 8 Gen 5, 8 Elite Gen 5/6 and rebadged parts.
- Snapdragon 7 standard: 7 Gen 3 and 7 Gen 4. Snapdragon 7+: 7+ Gen 2 and 7+ Gen 3. Snapdragon 7s is deliberately excluded and falls back to software decoding.

Detection reads `Build.SOC_MODEL`, `ro.soc.model`, `ro.board.platform`, `ro.chipname`, `ro.hardware.chipname`, `getprop` and `/proc` fallbacks. A literal `0` in `SOC_MODEL` falls through to the next key.

Other chips still run. Pure audio conversion is CPU software decode, so it works, just slower. Hardware decode/encode is different: MediaCodec implementations vary, and a non-listed chip may fail outright or produce silence. The app marks such devices as outside the tested list.

## OEM ROMs

The app is built against native Android first, with specific checks for:

- Xiaomi HyperOS / MIUI
- OPPO / OnePlus ColorOS
- realme UI
- vivo / iQOO OriginOS
- Nothing OS and other near-AOSP builds follow AOSP

Other brands, including HTC and Sony, follow AOSP behaviour and have not been tested device by device. OEM ROMs tend to change the file picker, background limits, notifications and permission prompts; failures usually come from those areas, not the conversion engine.

Split-screen and freeform windows are handled. Starting with Android 16, apps targeting SDK 36 lose the ability to restrict orientation, aspect ratio and resizability on displays with smallest width ≥600dp. The UI therefore does not lock orientation; content is capped at 760dp and the bottom bar at 640dp so narrow split windows and wide tablets both stay usable.

## What changed in 1.3.2

**The performance card no longer shows a phone name.** It used to prefer `ro.product.marketname`, which put the retail name above everything else. The title is now the chip name; the subtitle keeps vendor, core count, architecture and Android release. If no chip is readable, it says "Unknown" instead of substituting a model name.

**Wider chip and ROM detection.** Added Snapdragon 7 Gen 3/4, 7+ Gen 2/3, Dimensity 8400/8500, 9500M and 9600 Pro, plus Exynos 2400/2500. When `SOC_MODEL` is `0`, `ro.board.platform` is missing or HyperOS hides properties, detection continues through `ro.hardware.chipname`, `getprop`, `/proc/cpuinfo`, device-tree and `soc0`. ROM labels now cover realme UI and Nothing OS; `ro.build.display.id` is the generic last resort.

**Overall level controls.** The sound card now has a -12 to +12 dB gain slider. 0 dB leaves the file untouched; positive gain adds `alimiter` so peaks do not clip. A separate "Match loudness across files" switch runs single-pass EBU R128 at -16 LUFS, useful when a queue mixes quiet recordings with loud tracks.

**The support list is explicit.** Dimensity 9300+, 8400/8500, Snapdragon 8 Gen 3+, 7 Gen 3/4 and 7+ Gen 2/3 are in. Snapdragon 7s is out, software only. The compatibility note in the app says exactly that instead of a vague "may not work".

**Quieter layout.** The top card keeps a lighter shadow; the level controls sit behind a divider under the bitrate block instead of becoming another card. Slider, switch and helper text are tighter.

## What changed in 1.3.1

The format notes were rewritten: the expanded copy for all 18 formats is one line of use plus a few trade-offs. The detail sheet separates "WHAT IT'S FOR" from "TRADE-OFFS", and the full reference sheet uses a separate, shorter note per format. The full reference is grouped by use. The `String[]` device-channel bug was fixed. A 3 MB unused `AppBar_Icon.png` was dropped from the bundle, taking the APK from 42.8 MB to 39.8 MB. The hero card lost its heavy shadow, the four sections carry numbers, format chips no longer spring back, and content is centred on wide screens.

## What changed in 1.3.0

MP3 now exposes MPEG-1, MPEG-2 (24 kHz, 160 kbps ceiling) and MPEG-2.5 (12 kHz, 64 kbps ceiling); the version control clamps the slider to the variant's real range. Hardware decode failures offer a one-tap switch to software with a retry; if software also fails, a second dialog suggests another format or version. Interrupting a batch asks first. The unused `installed_apps` dependency was removed, R8 and resource shrinking were re-enabled, and the APK went from 45 MB to 41 MB.

## What changed in 1.2.0

The format list went from 11 to 18, adding AAC (ADTS), CAF, AU, WavPack, AMR-NB, AMR-WB and E-AC-3. Formats are grouped by use, with user-defined groups. Presets moved to the bottom of the detail sheet and apply only on tap. Sliders gained a 0.35× long-press fine adjustment with snap on release. The launcher icon became the teal ring and note. SoC detection gained rebadged-part aliases and a compatibility note.

## Forking

The repository is MPL-2.0. You can build on 1.3.2, provided modified files keep the same license and upstream attribution stays intact. If you publish a modified build, use your own package name and signing key; reusing `com.technicjelle.simple_audio_converter.zh` makes it impossible for users to tell your build from the official one. Notes on trade-offs and known gaps are in [DEVLOG.md](DEVLOG.md) (Chinese); some internal details are omitted.

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

Parts of the 1.2–1.3.2 rewrite were drafted with Doubao, an AI assistant: UI layout, format tables, tests and these README files. The drafts were reviewed, compiled and tested by the maintainer. The conversion engine was not generated by AI; FFmpeg command lines were checked against actual encoder output.

`flutter analyze` reports no errors. `flutter test` covers format switching, theme changes, narrow split-window layout, long-press presets, slider fine adjustment, the MP3 version selector, format-reference expansion, the gain/loudness panel, plus Dimensity 8400/8500, Snapdragon 7 Gen 3/4, 7+ Gen 2/3, 7s exclusion, Snapdragon 8 Gen 3 and newer, and Android 17 detection mappings. There is no Android emulator in the build environment, so on-device conversion has not been verified.

## Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14, JDK 17, Android SDK 36, build-tools 36.0.0, NDK 28.2.13676358. 1.3.2 uses versionCode 40122. Signing material is not stored in the repository; release builds read `TIMBRE_KEYSTORE`, `TIMBRE_STORE_PASSWORD`, `TIMBRE_KEY_ALIAS` and `TIMBRE_KEY_PASSWORD` from the environment.

## License

MPL-2.0. See [LICENSE](LICENSE) and [THIRD_PARTY.md](THIRD_PARTY.md).
