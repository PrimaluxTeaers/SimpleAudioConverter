import "dart:async";
import "dart:io";

import "package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit_config.dart";
import "package:flutter/material.dart";
import "package:path/path.dart" as p;

@immutable
class Path {
  final String _uri;
  final bool _sharedInto;
  final String filename;

  new({
    required String uri,
    required bool sharedInto,
  }) : _uri = uri,
       _sharedInto = sharedInto,
       filename = sharedInto
           ? p.basename(uri)
           : p.basename(Uri.decodeFull(p.basename(uri)));

  bool get _needsSafing => !_sharedInto;

  /// Desktop builds receive a real filesystem path from the picker. The SAF
  /// parameter translation is an Android concept and buys nothing here.
  bool get _isDesktop => Platform.isWindows || Platform.isLinux;

  Future<String?> getUrl() async {
    if (_isDesktop) {
      return _uri;
    }
    if (_needsSafing) {
      return await FFmpegKitConfig.getSafParameterForRead(_uri);
    }
    return _uri;
  }

  /// If the input file was shared into the app, a copy was made in the app's cache.
  /// That can now be deleted.
  ///
  /// On desktop the shared flag comes from the file picker, which hands back the
  /// user's own file instead of a cache copy. Deleting it would destroy the
  /// original, so desktop never deletes the input.
  void deleteIfNecessary() {
    if (_isDesktop) return;
    if (_sharedInto) {
      print("Deleting temporary file: $_uri");
      unawaited(File(_uri).delete());
    }
  }

  @override
  String toString() {
    return "Path{\n"
        "\turi: $_uri\n"
        "\tsharedInto: $_sharedInto\n"
        "\tneedsSafing: $_needsSafing\n"
        "\tfilename: $filename\n"
        "}";
  }
}
