import "dart:ui" show PlatformDispatcher;

/// Minimal runtime localization: picks Chinese when the device language
/// starts with "zh", otherwise falls back to English.
class S {
  static final bool _zh = _detect();

  static bool _detect() {
    try {
      final String lang = PlatformDispatcher.instance.locale.languageCode;
      return lang == "zh";
    } catch (_) {
      return false;
    }
  }

  static bool get isChinese => _zh;

  static String t(String en, String zh) => _zh ? zh : en;
}
