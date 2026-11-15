import "dart:io";

import "package:flutter/services.dart";

import "l10n.dart";

/// What the shell reports about the SoC. Vendor builds are inconsistent:
/// `Build.SOC_MODEL` is sometimes literally "0" (seen on Snapdragon 8 Gen 6
/// units), so every field here is a fallback chain rather than a single
/// trusted value. Nothing here is a hard identification: the raw value is
/// always shown somewhere so a wrong guess is visible instead of silent.
class DeviceProfile {
  final Map<String, String> raw;
  final int cores;
  final bool is64Bit;
  final int sdkInt;

  const DeviceProfile({
    required this.raw,
    required this.cores,
    required this.is64Bit,
    required this.sdkInt,
  });

  static const DeviceProfile unknown = DeviceProfile(
    raw: {},
    cores: 8,
    is64Bit: true,
    sdkInt: 0,
  );

  String get _socModel => (raw["socModel"] ?? "").trim();

  /// Every property that has ever carried a chip name on a shipping Android
  /// build. Ordered from most specific to least, because e.g. ro.hardware on
  /// a Xiaomi device is often just the device codename.
  List<String> get _candidates => [
    raw["socModel"] ?? "",
    raw["ro.soc.model"] ?? "",
    raw["ro.vendor.qti.soc_model"] ?? "",
    raw["ro.qti.soc_model"] ?? "",
    raw["ro.vendor.qti.soc_name"] ?? "",
    raw["ro.chipname"] ?? "",
    raw["ro.hardware.chipname"] ?? "",
    raw["ro.mediatek.platform"] ?? "",
    raw["ro.board.platform"] ?? "",
    raw["ro.hardware"] ?? "",
    raw["ro.boot.hardware"] ?? "",
    raw["ro.product.board"] ?? "",
    raw["board"] ?? "",
    raw["device"] ?? "",
    raw["proc.cpuinfo.hardware"] ?? "",
    raw["proc.deviceTree.model"] ?? "",
    raw["proc.soc0.machine"] ?? "",
    raw["proc.soc0.socId"] ?? "",
    raw["proc.soc0.family"] ?? "",
    raw["ro.soc.manufacturer"] ?? "",
  ].map((String e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();

  bool get vendorReportedZero =>
      _socModel == "0" || (raw["ro.soc.model"] ?? "").trim() == "0";

  String get vendor {
    for (final String c in _candidates) {
      if (RegExp(r"mt\d{4}").hasMatch(c)) return "MediaTek";
      if (RegExp(r"sm\d{4}").hasMatch(c)) return "Qualcomm";
      if (RegExp(r"s5e\d{4}").hasMatch(c)) return "Samsung";
    }
    final String m = (raw["socManufacturer"] ?? "").toLowerCase();
    if (m.contains("mediatek") || m.contains("mtk")) return "MediaTek";
    if (m.contains("qti") || m.contains("qualcomm")) return "Qualcomm";
    if (m.contains("samsung") || m.contains("exynos")) return "Samsung";
    if ((raw["manufacturer"] ?? "").toLowerCase().contains("qualcomm")) {
      return "Qualcomm";
    }
    return "";
  }

  /// ROM family as the OEM reports it. Purely for display; it also explains
  /// why one device has a clean SOC_MODEL and another only has a codename.
  String get romLabel {
    final String mi = (raw["ro.mi.os.version.name"] ?? "").trim();
    if (mi.isNotEmpty) return "HyperOS $mi";
    final String miui = (raw["ro.miui.ui.version.name"] ?? "").trim();
    if (miui.isNotEmpty) return "MIUI $miui";
    final String color = (raw["ro.oppo.version"] ?? "").trim();
    if (color.isNotEmpty) return "ColorOS $color";
    final String realme = (raw["ro.realme.ui.version"] ?? "").trim();
    if (realme.isNotEmpty) return "realme UI $realme";
    final String origin = (raw["ro.vivo.os.version"] ?? "").trim();
    if (origin.isNotEmpty) return "OriginOS $origin";
    final String display = (raw["ro.build.display.id"] ?? "").trim();
    for (final String name in const <String>[
      "Nothing OS",
      "realme UI",
      "ColorOS",
      "OriginOS",
      "HyperOS",
      "MIUI",
    ]) {
      if (display.toLowerCase().contains(name.toLowerCase())) {
        return display;
      }
    }
    final String release = (raw["ro.build.version.release"] ?? "").trim();
    if (release.isNotEmpty) return "Android $release";
    return "Android";
  }

  String get chipName {
    for (final String c in _candidates) {
      final RegExpMatch? mt = RegExp(r"mt(\d{4})").firstMatch(c);
      if (mt != null) {
        switch (mt.group(1)) {
          case "6991":
            return "Dimensity 9400+ / 9400";
          case "6993":
            return "Dimensity 9500 / 9500+ / 9500S / 9500M";
          case "6995":
            return "Dimensity 9600 / 9600 Pro / 9600M";
          case "6989":
            return "Dimensity 9300 / 9300+";
          case "6985":
            return "Dimensity 9200 / 9200+";
          case "6983":
            return "Dimensity 9000 / 9000+";
          case "6899":
            return "Dimensity 8400 / 8400 Ultra / 8500";
          case "6897":
            return "Dimensity 8300 / 8350";
          case "6896":
            return "Dimensity 8200";
          case "6895":
            return "Dimensity 8000";
          case "6893":
            return "Dimensity 8100 / 8100 Max";
          case "6855":
            return "Dimensity 7300";
          case "6853":
            return "Dimensity 7200";
          case "6835":
            return "Dimensity 7025 / 7020";
          case "6789":
            return "Helio G99";
        }
        return "MediaTek MT${mt.group(1)}";
      }
      final RegExpMatch? sm = RegExp(r"sm(\d{4})").firstMatch(c);
      if (sm != null) {
        switch (sm.group(1)) {
          case "8975":
            return "Snapdragon 8 Elite Gen 6 Super";
          case "8950":
            return "Snapdragon 8 Elite Gen 6";
          case "8850":
            return "Snapdragon 8 Elite Gen 5";
          case "8845":
            return "Snapdragon 8 Gen 5";
          case "8750":
            return "Snapdragon 8 Elite";
          case "8745":
            return "Snapdragon 8s Gen 4";
          case "8735":
            return "Snapdragon 8s Gen 4";
          case "8650":
            return "Snapdragon 8 Gen 3";
          case "8635":
            return "Snapdragon 8s Gen 3";
          case "7750":
            return "Snapdragon 7 Gen 4";
          case "7675":
            return "Snapdragon 7+ Gen 3";
          case "7550":
            return "Snapdragon 7 Gen 3";
          case "7475":
            return "Snapdragon 7+ Gen 2";
          case "8550":
            return "Snapdragon 8 Gen 2";
          case "8475":
            return "Snapdragon 8+ Gen 1";
          case "8450":
            return "Snapdragon 8 Gen 1";
          case "7635":
            return "Snapdragon 7s Gen 3";
          case "6375":
            return "Snapdragon 6 Gen 1";
          case "4450":
            return "Snapdragon 4 Gen 2";
        }
        return "Qualcomm SM${sm.group(1)}";
      }
      final RegExpMatch? exynos = RegExp(r"s5e(\d{4})").firstMatch(c);
      if (exynos != null) {
        switch (exynos.group(1)) {
          case "9945":
            return "Exynos 2400";
          case "9955":
            return "Exynos 2500";
          case "9925":
            return "Exynos 2200";
          case "8835":
            return "Exynos 1380";
        }
        return "Exynos S5E${exynos.group(1)}";
      }
      if (c == "sun") return "Snapdragon 8 Elite series (sun)";
      if (c == "pineapple") return "Snapdragon 8 Gen 3 (pineapple)";
      if (c == "kalama") return "Snapdragon 8 Gen 2 (kalama)";
      if (c == "taro") return "Snapdragon 8 Gen 1 (taro)";
      if (c == "parrot") return "Snapdragon 8s Gen 3 (parrot)";
    }
    final String fallback = _socModel.isNotEmpty && _socModel != "0"
        ? _socModel
        : ((raw["ro.board.platform"] ?? "").isNotEmpty
              ? raw["ro.board.platform"]!
              : (raw["board"] ?? ""));
    if (fallback.trim().isEmpty) return S.t("Unknown", "未识别");
    return fallback.trim();
  }

  String get rawChip => _socModel.isNotEmpty && _socModel != "0"
      ? _socModel
      : (raw["ro.board.platform"] ?? raw["ro.soc.model"] ?? "");

  String get archLabel => is64Bit ? "arm64-v8a" : "armeabi-v7a";

  /// Release string that never degrades to "Android 0" when a vendor ROM
  /// hides `ro.build.version.release`.
  String get releaseLabel {
    final String release = (raw["release"] ?? raw["ro.build.version.release"] ?? "")
        .trim();
    if (release.isNotEmpty) return release;
    return sdkInt > 0 ? "SDK $sdkInt" : "?";
  }

  /// Supported list: Dimensity 9300 and newer, 8400/8500, Snapdragon 8 Gen 3
  /// and newer (including 8s Gen 4), plus 7 Gen 3/4 and 7+ Gen 2/3.
  /// Snapdragon 7s is deliberately excluded.
  bool get isPrimaryTarget {
    final String name = chipName.toLowerCase();
    if (name.contains("dimensity 9300") ||
        name.contains("dimensity 9400") ||
        name.contains("dimensity 9500") ||
        name.contains("dimensity 9600") ||
        name.contains("dimensity 8400") ||
        name.contains("dimensity 8500")) {
      return true;
    }
    return RegExp(
      r"snapdragon (8 (gen 3|gen 5|elite)|8s gen 4|7 (gen 3|gen 4)|7\+ gen (2|3))",
    ).hasMatch(name);
  }

  String get targetNote {
    if (chipName == S.t("Unknown", "未识别")) {
      return S.t(
        "Could not read a chip name. Converting still works; this only affects the compatibility note.",
        "没读到芯片型号。转换照常可用，这只影响兼容提示。",
      );
    }
    final String name = chipName.toLowerCase();
    if (name.contains("7s gen")) {
      return S.t(
        "Snapdragon 7s is outside the tested list. Use software decoding; hardware decode is not validated on this part.",
        "骁龙 7s 不在适配名单内，走软件解码；这颗芯片的硬解没有验证，不保证可用。",
      );
    }
    if (isPrimaryTarget) {
      return S.t(
        "On the tested list: Dimensity 9300+, 8400/8500; Snapdragon 8 Gen 3+, 7 Gen 3/4 and 7+ Gen 2/3.",
        "在本次验证名单内：天玑 9300 及以上、8400/8500；骁龙 8 Gen 3 及以上、7 Gen 3/4、7+ Gen 2/3。",
      );
    }
    return S.t(
      "Runs, but this chip is outside the tested list. Software decoding still works; hardware decode is not guaranteed.",
      "能跑，但不在本次验证名单内。软件解码照常可用，硬解不保证。",
    );
  }

  int get suggestedThreads {
    final int value = cores ~/ 2;
    return value.clamp(2, 6);
  }

  String get report {
    if (vendorReportedZero) {
      return S.t(
        "The ROM reports the SoC as 0 (Build.SOC_MODEL). Fell back to raw board properties.",
        "系统把 SoC 型号上报成了 0，已用底层属性兜底识别。",
      );
    }
    if (chipName == S.t("Unknown", "未识别")) {
      return S.t(
        "No recognisable SoC value in any of the known properties.",
        "已知属性里都没有可识别的芯片型号。",
      );
    }
    return "";
  }

  static Future<DeviceProfile> load() async {
    try {
      const MethodChannel channel = MethodChannel("audio_converter/device");
      final Map<String, dynamic>? map = await channel.invokeMapMethod<String, dynamic>(
        "info",
      );
      if (map == null) return unknown;
      final Map<String, String> raw = map.map(
        (key, value) => MapEntry(key, value?.toString() ?? ""),
      );
      int sdk = int.tryParse(raw["sdkInt"] ?? "") ?? 0;
      if (sdk == 0) sdk = sdkFromPlatform();
      return DeviceProfile(
        raw: raw,
        cores: int.tryParse(raw["cores"] ?? "") ?? Platform.numberOfProcessors,
        is64Bit: raw["is64Bit"] != "false",
        sdkInt: sdk,
      );
    } catch (_) {
      return DeviceProfile(
        raw: const {},
        cores: Platform.numberOfProcessors,
        is64Bit: true,
        sdkInt: sdkFromPlatform(),
      );
    }
  }

  static int sdkFromPlatform() {
    final RegExpMatch? match = RegExp(r"(?:SDK|API)[^0-9]*(\d+)")
        .firstMatch(Platform.operatingSystemVersion);
    return match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
  }
}
