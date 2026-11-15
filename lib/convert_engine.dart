import "dart:async";
import "dart:io";

import "package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart";
import "package:ffmpeg_kit_flutter_new_audio/return_code.dart";
import "package:ffmpeg_kit_flutter_new_audio/statistics.dart";
import "package:path/path.dart" as p;

import "conversion.dart";
import "picked_file_info.dart";
import "utils.dart";

class ConvertOutcome {
  final PickedFileInfo input;
  final String? outputPath;
  final String? error;

  const ConvertOutcome({required this.input, this.outputPath, this.error});

  bool get ok => outputPath != null;
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
  }) async {
    _cancelled = false;
    final List<ConvertOutcome> results = [];

    File? model;
    if (settings.voiceOptimization) {
      model = await getFileFromAssets("arnndn-models/std.rnnn");
    }

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
        settings.format.ext,
      );
      final String outPath = _uniquePath(outputDir, baseName, settings.format.ext);
      final bool hasVideo = info.mediaInformation
          .getStreams()
          .any((s) => s.getType() == "video");
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
            completer.complete(
              ConvertOutcome(input: info, outputPath: outPath),
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
            onProgress(i, (stats.getTime() / (duration * 1000)).clamp(0.0, 1.0));
          }
        },
      );

      _session = session;
      final ConvertOutcome outcome = await completer.future;
      _session = null;
      results.add(outcome);
      if (_cancelled) break;
    }
    return results;
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
