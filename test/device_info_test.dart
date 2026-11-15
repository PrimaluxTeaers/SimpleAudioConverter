import "package:flutter_test/flutter_test.dart";
import "package:simple_audio_converter/device_info.dart";

DeviceProfile profile(Map<String, String> raw) => DeviceProfile(
  raw: raw,
  cores: 8,
  is64Bit: true,
  sdkInt: 37,
);

void main() {
  test("MediaTek flagship ids resolve to marketing names", () {
    expect(profile({"socModel": "MT6991"}).chipName, "Dimensity 9400+ / 9400");
    expect(profile({"socModel": "MT6989"}).chipName, "Dimensity 9300 / 9300+");
    expect(
      profile({"socModel": "MT6993"}).chipName,
      "Dimensity 9500 / 9500+ / 9500S / 9500M",
    );
    expect(
      profile({"socModel": "MT6995"}).chipName,
      "Dimensity 9600 / 9600 Pro / 9600M",
    );
  });

  test("a zero SOC_MODEL falls through to board properties", () {
    final DeviceProfile device = profile({
      "socModel": "0",
      "ro.mediatek.platform": "MT6989",
    });
    expect(device.vendorReportedZero, isTrue);
    expect(device.chipName, "Dimensity 9300 / 9300+");
    expect(device.isPrimaryTarget, isTrue);
  });

  test("Snapdragon 8 Gen 3 and newer are on the primary list", () {
    for (final String id in <String>[
      "SM8650",
      "SM8745",
      "SM8750",
      "SM8845",
      "SM8850",
      "SM8950",
      "SM8975",
    ]) {
      expect(profile({"socModel": id}).isPrimaryTarget, isTrue, reason: id);
    }
    expect(profile({"socModel": "SM8550"}).isPrimaryTarget, isFalse);
    expect(profile({"socModel": "SM8635"}).chipName, "Snapdragon 8s Gen 3");
    expect(profile({"socModel": "SM8635"}).isPrimaryTarget, isFalse);
    expect(profile({"socModel": "SM7750"}).chipName, "Snapdragon 7 Gen 4");
    expect(profile({"socModel": "SM7750"}).isPrimaryTarget, isTrue);
    expect(profile({"socModel": "SM7675"}).chipName, "Snapdragon 7+ Gen 3");
    expect(profile({"socModel": "SM7675"}).isPrimaryTarget, isTrue);
    expect(profile({"socModel": "SM7475"}).chipName, "Snapdragon 7+ Gen 2");
    expect(profile({"socModel": "SM7475"}).isPrimaryTarget, isTrue);
    expect(profile({"socModel": "SM7550"}).chipName, "Snapdragon 7 Gen 3");
    expect(profile({"socModel": "SM7550"}).isPrimaryTarget, isTrue);
    expect(profile({"socModel": "SM7635"}).chipName, "Snapdragon 7s Gen 3");
    expect(profile({"socModel": "SM7635"}).isPrimaryTarget, isFalse);
    expect(profile({"socModel": "SM8450"}).chipName, "Snapdragon 8 Gen 1");
    expect(profile({"socModel": "SM8450"}).isPrimaryTarget, isFalse);
    expect(profile({"socModel": "MT6899"}).targetNote, contains("8400 Max"));
  });

  test("2024–2026 mainstream parts resolve without a model name", () {
    expect(
      profile({"socModel": "MT6899"}).chipName,
      "Dimensity 8400 / 8450 / 8500 series",
    );
    expect(profile({"socModel": "MT6899"}).isPrimaryTarget, isTrue);
    expect(profile({"socModel": "MT6897"}).chipName, "Dimensity 8300 / 8350");
    expect(profile({"socModel": "SM7675"}).chipName, "Snapdragon 7+ Gen 3");
    expect(profile({"socModel": "SM7550"}).chipName, "Snapdragon 7 Gen 3");
    expect(profile({"socModel": "S5E9945"}).chipName, "Exynos 2400");
    expect(
      profile({"ro.hardware.chipname": "MT6991"}).chipName,
      "Dimensity 9400+ / 9400",
    );
    expect(
      profile({"ro.build.display.id": "realme UI 6.0"}).romLabel,
      "realme UI 6.0",
    );
  });

  test("Android 17 does not degrade to Android 0", () {
    final DeviceProfile device = profile({
      "release": "17",
      "socModel": "MT6991",
      "ro.product.marketname": "REDMI K80 Ultra",
    });
    expect(device.releaseLabel, "17");
    expect(device.chipName, "Dimensity 9400+ / 9400");
    expect(device.chipName.contains("REDMI"), isFalse);
  });

  test("release falls back to SDK when the ROM hides the release string", () {
    final DeviceProfile device = DeviceProfile(
      raw: const {},
      cores: 8,
      is64Bit: true,
      sdkInt: 37,
    );
    expect(device.releaseLabel, "SDK 37");
  });
}
