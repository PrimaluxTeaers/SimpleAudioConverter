import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";

/// One switch for every tap/impact in the app. Default is on; turning it off
/// must stop all haptic calls, including the ones already in flight.
class Haptics {
  static bool enabled = true;

  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool("hapticsEnabled") ?? true;
    } catch (_) {}
  }

  static Future<void> setEnabled(bool value) async {
    if (enabled == value) return;
    enabled = value;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("hapticsEnabled", value);
    } catch (_) {}
  }

  static Future<void> selectionClick() async {
    if (enabled) await HapticFeedback.selectionClick();
  }

  static Future<void> lightImpact() async {
    if (enabled) await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    if (enabled) await HapticFeedback.mediumImpact();
  }
}
