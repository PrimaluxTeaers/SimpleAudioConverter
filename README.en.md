# Timbre / Audio Converter

An Android audio converter. Pick a file, pick a format, press convert. When you import a video, only the audio track changes; the picture stays untouched. 1.6 is the new baseline; releases and documentation from 1.5 and earlier were removed.

## About

Timbre / Audio Converter is a free, open-source offline tool. Anyone may use, modify, redistribute and build it, provided the MPL-2.0 license and upstream attribution are respected. Other people are free to make similar apps or fork this one; the point is not to ship one perfect binary, but to let people build their own working version. The foundation comes from SimpleAudioConverter, with this project's interface, conversion chain and packaging added on top. The author is one of the people who could not find a usable audio tool and could not afford professional software. Testing has been limited to a small set of devices, so bugs are possible; reports are welcome. There is no plan to merge Reencode and Timbre into one large project. Both are small tools, updated irregularly; reaching 1.6 is simply the wish to make them a little more complete. A Windows build was attempted in earnest, but without the devices and verification conditions to stand behind it, it was abandoned; saying so is better than shipping an untested package.

This is a fork of [TechnicJelle/SimpleAudioConverter](https://github.com/TechnicJelle/SimpleAudioConverter). The foundation, Android project, file picker and share entry come from upstream, which uses MPL-2.0; this repository keeps that license.

## Download

Installers, source snapshots, version numbers, checksums and per-release changes live in [Releases](https://github.com/PrimaluxTeaers/SimpleAudioConverter/releases).

The Android 1.6 build ships `arm64-v8a` only and shows **Timbre** as its name; the installer filename keeps the `ARM64-v8a` tag. The package name stays `com.technicjelle.simple_audio_converter.zh`, so an update over an older install keeps its settings. The signing key has not changed. Android is the only official target. The Windows build has been dropped: no Windows package is built or published. The shared Flutter / Dart logic stays in the repository for anyone with Windows build experience to adapt; the project does not maintain, publish or endorse third-party builds.

## What it does

Eighteen output formats, grouped into daily, lossless, voice, legacy and other. Daily: MP3, M4A, AAC, OGG, Opus. Lossless: FLAC, WAV, AIFF, ALAC, CAF, AU, WavPack. Voice: AMR-NB, AMR-WB. Legacy: WMA, MP2, AC-3, E-AC-3. Groups can be created and removed with a long press.

MP3 offers MPEG-1, MPEG-2 and MPEG-2.5. Switching the version changes the bitrate ceiling, so the 12 kHz variant cannot be pushed to 320 kbps. AMR has fixed steps and the slider snaps to legal rates.

Below bitrate is an overall gain control from -12 to +12 dB, with 0 dB leaving the source alone. Positive gain adds a limiter to avoid clipping. The other switch is “match loudness across the batch”, useful when a queue mixes quiet recordings and finished masters. While it is on, the gain slider is not used.

Batch conversion, stop confirmation, one-tap fallback from hardware to software decoding and format/version suggestions after a software failure are all here. Small windows, split screen and tablets work; the UI is not locked to portrait.

## Video import

Video files can be added like audio. Timbre copies the video stream without re-encoding, so the picture, resolution, frame rate and HDR metadata stay as they were. Every audio track is preserved and re-encoded to the target format; the original per-track codecs are not kept.

The output container follows the codec pair: H.264 / H.265 / AV1 / MPEG-4 video with M4A / AAC / MP3 / ALAC audio goes to MP4; other combinations go to MKV. Audio-only exports stay plain audio files and do not get a video wrapper.

This path only replaces the audio. Use Reencode when the picture itself needs work. Reencode's merge page can also put an external audio track back into a video.

## Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Flutter 3.50 / Dart 3.14, JDK 17, Android SDK 36, build-tools 36.0.0, NDK 28.2.13676358. Signing configuration is not committed.

`flutter analyze` reports no errors. `flutter test` covers format switching, settings, narrow split screen, long-press details, fine slider adjustment, MP3 version selection, format reference expansion, gain and loudness panels, processor mapping and the video audio-track replacement command. The build environment has no Android emulator, so real-device transcoding and system folder writes remain untested.

`lib/main.dart` owns the UI, queue and settings entry; `lib/conversion.dart` holds the format table, bitrate ranges and FFmpeg command; `lib/output_store.dart` owns output folders and Android SAF; `lib/settings.dart` holds preferences and permission copy; `lib/runtime_settings.dart` holds background-residency and haptics. These `lib/` files are not tied to the Android UI and remain available to anyone adapting the app to Windows or another desktop target; the project does not generate, commit or maintain a Windows runner. There is no closed-source desktop module.

## License

MPL-2.0, see [LICENSE](LICENSE). Attribution and third-party licenses are in [THIRD_PARTY.md](THIRD_PARTY.md).
