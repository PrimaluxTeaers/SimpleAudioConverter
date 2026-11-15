import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Runtime localization. English and Chinese strings live together at each
/// call site; the settings page can override the system language and the
/// choice survives a restart.
class S {
  static const String systemMode = "system";
  static const String zhMode = "zh";
  static const String enMode = "en";

  static String _mode = systemMode;

  /// Bumped whenever the language changes so open pages can rebuild in place
  /// without losing their state.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static bool get _systemChinese {
    try {
      return PlatformDispatcher.instance.locale.languageCode == "zh";
    } catch (_) {
      return false;
    }
  }

  static String get mode => _mode;

  static bool get isChinese =>
      _mode == zhMode || (_mode == systemMode && _systemChinese);

  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString("languageMode");
      if (stored == zhMode || stored == enMode || stored == systemMode) {
        _mode = stored!;
      }
    } catch (_) {
      // Preferences are optional; the system language still works.
    }
  }

  static Future<void> setMode(String mode) async {
    if (mode != systemMode && mode != zhMode && mode != enMode) return;
    if (_mode == mode) return;
    _mode = mode;
    revision.value++;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("languageMode", mode);
    } catch (_) {}
  }

  static String t(String en, String zh) => isChinese ? zh : en;
}
