import "dart:io";

import "package:flutter/services.dart";

/// A folder the user picked through the system document picker. The URI is a
/// persisted SAF tree, so the grant survives restarts and the app can keep
/// writing without asking again.
class OutputTarget {
  final String uri;
  final String name;

  const OutputTarget({required this.uri, required this.name});
}

class PublishedFile {
  final String uri;
  final String name;

  const PublishedFile({required this.uri, required this.name});
}

/// Bridge to the Android document provider. Everything is a no-op on desktop
/// and in tests, where the channel is not registered.
class OutputStore {
  static const MethodChannel _channel = MethodChannel("timbre/output");

  static bool get _supported => Platform.isAndroid;

  static Future<OutputTarget?> current() async {
    if (!_supported) return null;
    try {
      final Map<Object?, Object?>? value = await _channel
          .invokeMethod<Map<Object?, Object?>>("current");
      return _toTarget(value);
    } catch (_) {
      return null;
    }
  }

  static Future<OutputTarget?> choose() async {
    if (!_supported) return null;
    try {
      final Map<Object?, Object?>? value = await _channel
          .invokeMethod<Map<Object?, Object?>>("choose");
      return _toTarget(value);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> clear() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>("clear") ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Copies a converted file into the chosen tree. The local file is left in
  /// place so a failed copy can still fall back to sharing.
  static Future<PublishedFile?> publish(String path) async {
    if (!_supported) return null;
    try {
      final Map<Object?, Object?>? value = await _channel
          .invokeMethod<Map<Object?, Object?>>("publish", <String, String>{
            "path": path,
          });
      if (value == null) return null;
      final Object? uri = value["uri"];
      final Object? name = value["name"];
      if (uri is! String || uri.isEmpty) return null;
      return PublishedFile(
        uri: uri,
        name: name is String && name.isNotEmpty ? name : "audio",
      );
    } catch (_) {
      return null;
    }
  }

  static OutputTarget? _toTarget(Map<Object?, Object?>? value) {
    if (value == null) return null;
    final Object? uri = value["uri"];
    final Object? name = value["name"];
    if (uri is! String || uri.isEmpty) return null;
    return OutputTarget(
      uri: uri,
      name: name is String && name.isNotEmpty ? name : "Output folder",
    );
  }
}
