import "dart:io";

import "package:flutter/services.dart";

/// Android-only foreground-service notification. Desktop builds no-op.
class BackgroundProgress {
  static const MethodChannel _channel = MethodChannel("timbre/progress");

  static bool get _supported => Platform.isAndroid;

  static Future<void> start(String title, String text) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>("start", <String, Object?>{
        "title": title,
        "text": text,
      });
    } catch (_) {}
  }

  static Future<void> update(
    String title,
    String text,
    double progress,
  ) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>("update", <String, Object?>{
        "title": title,
        "text": text,
        "progress": (progress.clamp(0.0, 1.0) * 100).round(),
      });
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>("stop");
    } catch (_) {}
  }
}
