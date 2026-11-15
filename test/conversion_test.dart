import "package:flutter_test/flutter_test.dart";
import "package:simple_audio_converter/conversion.dart";

ConversionSettings settings() => ConversionSettings()
  ..formatId = "mp3"
  ..bitrate = 192;

void main() {
  test("default command keeps the source level", () {
    final String command = buildConvertCommand(
      inputUrl: "/tmp/in.mp3",
      outputPath: "/tmp/out.mp3",
      settings: settings(),
    );
    expect(command.contains("-filter:a"), isFalse);
    expect(command.contains("-map 0:a:0 -vn"), isTrue);
  });

  test("positive gain adds a limiter", () {
    final ConversionSettings s = settings()..gainDb = 6;
    final String command = buildConvertCommand(
      inputUrl: "/tmp/in.mp3",
      outputPath: "/tmp/out.mp3",
      settings: s,
    );
    expect(command.contains('volume=6.0dB,alimiter=limit=0.95'), isTrue);
  });

  test("negative gain does not add a limiter", () {
    final ConversionSettings s = settings()..gainDb = -4.5;
    final String command = buildConvertCommand(
      inputUrl: "/tmp/in.mp3",
      outputPath: "/tmp/out.mp3",
      settings: s,
    );
    expect(command.contains('volume=-4.5dB'), isTrue);
    expect(command.contains("alimiter"), isFalse);
  });

  test("normalisation replaces the gain slider", () {
    final ConversionSettings s = settings()
      ..gainDb = 8
      ..normalizeLoudness = true;
    final String command = buildConvertCommand(
      inputUrl: "/tmp/in.mp3",
      outputPath: "/tmp/out.mp3",
      settings: s,
    );
    expect(command.contains("loudnorm=I=-16:TP=-1.5:LRA=11"), isTrue);
    expect(command.contains("volume="), isFalse);
  });

  test("MP3 2.5 clamps bitrate to 64 kbps", () {
    final ConversionSettings s = settings()..bitrate = 320;
    s.selectVariant("mpeg25");
    expect(s.bitrate, 64);
  });
}
