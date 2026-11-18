import "package:shared_preferences/shared_preferences.dart";

/// Small runtime switches shared by the home page, engine and settings.
class RuntimeSettings {
  static bool backgroundMode = false;

  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      backgroundMode = prefs.getBool("backgroundMode") ?? false;
    } catch (_) {}
  }

  static Future<void> setBackgroundMode(bool value) async {
    if (backgroundMode == value) return;
    backgroundMode = value;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("backgroundMode", value);
    } catch (_) {}
  }
}
