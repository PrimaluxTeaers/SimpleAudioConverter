import "dart:async";
import "dart:io";

import "package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart";
import "package:ffmpeg_kit_flutter_new_audio/media_information.dart";
import "package:ffmpeg_kit_flutter_new_audio/return_code.dart";
import "package:ffmpeg_kit_flutter_new_audio/statistics.dart";
import "package:ffmpeg_kit_flutter_new_audio/stream_information.dart";
import "package:path/path.dart" as p;

import "background_progress.dart";
import "conversion.dart";
import "picked_file_info.dart";
import "utils.dart";

class ConvertOutcome {
  final PickedFileInfo input;
  final String? outputPath;
  final String? error;
  final int? bytes;
  final String? publishedUri;
  final String? publishedName;

  const ConvertOutcome({
    required this.input,
    this.outputPath,
    this.error,
    this.bytes,
    this.publishedUri,
    this.publishedName,
  });

  bool get ok => outputPath != null;
  bool get published => publishedUri != null;

  ConvertOutcome withPublished(String uri, String name) => ConvertOutcome(
    input: input,
    outputPath: outputPath,
    error: error,
    bytes: bytes,
    publishedUri: uri,
    publishedName: name,
  );
}

/// Runs the batch conversion. One ffmpeg session at a time, which keeps memory
/// pressure predictable on phones.
class ConvertEngine {
  FFmpegSession? _session;
  bool _cancelled = false;

  bool get running => _session != null;

  Future<void> cancel() async {
    _cancelled = true;
    await _session?.cancel();
  }

  Future<List<ConvertOutcome>> run({
    required List<PickedFileInfo> files,
    required ConversionSettings settings,
    required Directory outputDir,
    required void Function(int index, double progress) onProgress,
    bool allowBackground = true,
  }) async {
    _cancelled = false;
    final List<ConvertOutcome> results = [];

    File? model;
    if (settings.voiceOptimization) {
      model = await getFileFromAssets("arnndn-models/std.rnnn");
    }

    if (allowBackground) {
      await BackgroundProgress.start("Timbre", "${files.length} file(s) queued");
    }
    try {
      for (int i = 0; i < files.length; i++) {
        if (_cancelled) break;
        final PickedFileInfo info = files[i];
        onProgress(i, 0);

        String? readUrl;
        try {
          readUrl = await info.path.getUrl();
        } catch (_) {
          readUrl = null;
        }
        if (readUrl == null) {
          results.add(
            ConvertOutcome(input: info, error: "无法读取源文件路径"),
          );
          continue;
        }

        final String baseName = _safeBaseName(
          p.withoutExtension(info.filename),
          "",
        );
        final bool hasVideo = _hasRealVideo(info.mediaInformation);
        final String videoCodec = _videoCodec(info.mediaInformation);
        final String ext = videoOutputExtension(
          hasVideo: hasVideo,
          format: settings.format,
          videoCodec: videoCodec,
        );
        final String outPath = _uniquePath(outputDir, baseName, ext);
        final String command = buildConvertCommand(
          inputUrl: readUrl,
          outputPath: outPath,
          settings: settings,
          rnnModel: model,
          hasVideo: hasVideo,
        );

        final double duration =
            double.tryParse(info.mediaInformation.getDuration() ?? "") ?? 0;
        final Completer<ConvertOutcome> completer = Completer<ConvertOutcome>();

        final FFmpegSession session = await FFmpegKit.executeAsync(
          command,
          (FFmpegSession s) async {
            final ReturnCode? rc = await s.getReturnCode();
            if (rc?.isValueSuccess() ?? false) {
              info.path.deleteIfNecessary();
              int? bytes;
              try {
                bytes = File(outPath).lengthSync();
              } catch (_) {}
              completer.complete(
                ConvertOutcome(input: info, outputPath: outPath, bytes: bytes),
              );
            } else if (rc?.isValueCancel() ?? false) {
              completer.complete(
                ConvertOutcome(input: info, error: "已取消"),
              );
            } else {
              final String? output = await s.getOutput();
              completer.complete(
                ConvertOutcome(
                  input: info,
                  error: _tail(output) ?? "转换失败",
                ),
              );
            }
          },
          null,
          (Statistics stats) {
            if (duration > 0) {
              final double progress = (stats.getTime() / (duration * 1000)).clamp(
                0.0,
                1.0,
              );
              onProgress(i, progress);
              if (allowBackground) {
                BackgroundProgress.update(
                  "Timbre",
                  info.filename,
                  (i + progress) / files.length,
                );
              }
            }
          },
        );

        _session = session;
        final ConvertOutcome outcome = await completer.future;
        _session = null;
        results.add(outcome);
        if (_cancelled) break;
      }
    } finally {
      if (allowBackground) await BackgroundProgress.stop();
    }
    return results;
  }

  static bool _hasRealVideo(MediaInformation info) {
    return info.getStreams().any((StreamInformation stream) {
      if (stream.getType() != "video") return false;
      final String? fps = stream.getAverageFrameRate();
      if (fps == null || fps == "0/0") return false;
      return (stream.getWidth() ?? 0) > 0 && (stream.getHeight() ?? 0) > 0;
    });
  }

  static String _videoCodec(MediaInformation info) {
    for (final StreamInformation stream in info.getStreams()) {
      if (stream.getType() == "video") return stream.getCodec() ?? "";
    }
    return "";
  }

  static String _safeBaseName(String raw, String ext) {
    String name = raw.trim();
    if (name.isEmpty || name.contains(":")) {
      name = "audio";
    }
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), "_");
    if (name.length > 80) name = name.substring(0, 80);
    return name;
  }

  static String _uniquePath(Directory dir, String base, String ext) {
    String candidate = p.join(dir.path, "$base.$ext");
    int n = 2;
    while (File(candidate).existsSync()) {
      candidate = p.join(dir.path, "$base ($n).$ext");
      n++;
    }
    return candidate;
  }

  static String? _tail(String? log) {
    if (log == null) return null;
    final List<String> lines = log
        .replaceAll(String.fromCharCode(13), "\n")
        .split("\n")
        .where((String l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;
    return lines.sublist(lines.length > 8 ? lines.length - 8 : 0).join("\n");
  }
}
