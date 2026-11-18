import "dart:io";
import "dart:typed_data";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";

class FontEntry {
  final String path;
  final String name;
  final int bytes;

  const FontEntry({required this.path, required this.name, required this.bytes});
}

/// App-local font replacement. Android does not let a normal APK write system
/// fonts, so the app copies a chosen TTF/OTF/TTC into its own folder and
/// registers it with Flutter at runtime. Clearing the selection returns to
/// the system default.
class FontManager {
  static const String _appName = "Timbre";
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static String? _family;
  static String? _path;

  static String? get family => _family;
  static String? get selectedPath => _path;
  static bool get isCustom => _family != null;

  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String stored = prefs.getString("fontPath") ?? "";
      if (stored.isEmpty) return;
      final File file = File(stored);
      if (!await file.exists()) return;
      final String? error = await _register(file);
      if (error == null) _path = stored;
    } catch (_) {}
  }

  static Future<Directory> ensureFolder() async {
    final Directory dir = await _folder();
    if (!await dir.exists()) await dir.create(recursive: true);
    final File readme = File(p.join(dir.path, "README.txt"));
    if (!await readme.exists()) {
      await readme.writeAsString(
        "Place .ttf, .otf or .ttc font files in this folder.\n"
        "在这个文件夹放入 .ttf、.otf 或 .ttc 字体文件。\n"
        "Then open the app's font manager and select one.\n"
        "然后在应用的字体管理页里选中它。\n",
      );
    }
    return dir;
  }

  static Future<String> folderPath() async => (await _folder()).path;

  static Future<Directory> _folder() async {
    if (Platform.isAndroid) {
      final Directory? external = await getExternalStorageDirectory();
      if (external != null) {
        return Directory(p.join(external.path, "fonts"));
      }
    }
    final Directory documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, _appName, "fonts"));
  }

  static Future<List<FontEntry>> entries() async {
    final Directory dir = await ensureFolder();
    final List<FontEntry> result = <FontEntry>[];
    try {
      await for (final FileSystemEntity entity in dir.list()) {
        if (entity is! File) continue;
        final String ext = p.extension(entity.path).toLowerCase();
        if (ext != ".ttf" && ext != ".otf" && ext != ".ttc") continue;
        result.add(
          FontEntry(
            path: entity.path,
            name: p.basename(entity.path),
            bytes: await entity.length(),
          ),
        );
      }
    } catch (_) {}
    result.sort((FontEntry a, FontEntry b) => a.name.compareTo(b.name));
    return result;
  }

  static Future<String?> importFile(String source) async {
    try {
      final Directory dir = await ensureFolder();
      final String ext = p.extension(source).toLowerCase();
      if (ext != ".ttf" && ext != ".otf" && ext != ".ttc") {
        return "只支持 .ttf / .otf / .ttc 字体文件。";
      }
      final String base = p.basenameWithoutExtension(source);
      String target = p.join(dir.path, p.basename(source));
      int suffix = 1;
      while (await File(target).exists()) {
        target = p.join(dir.path, "$base-$suffix$ext");
        suffix++;
      }
      await File(source).copy(target);
      return select(target);
    } catch (error) {
      return "字体导入失败：$error";
    }
  }

  static Future<String?> select(String path) async {
    final String? error = await _register(File(path));
    if (error != null) return error;
    _path = path;
    revision.value++;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("fontPath", path);
    } catch (_) {}
    return null;
  }

  static Future<void> clear() async {
    _family = null;
    _path = null;
    revision.value++;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove("fontPath");
    } catch (_) {}
  }

  static Future<String?> _register(File file) async {
    if (!await file.exists()) return "找不到字体文件。";
    try {
      final Uint8List bytes = await file.readAsBytes();
      final String family = _familyName(file.path);
      final FontLoader loader = FontLoader(family);
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      await loader.load();
      _family = family;
      return null;
    } catch (error) {
      return "这个字体加载失败，可能不是有效的 TTF/OTF：$error";
    }
  }

  static String _familyName(String path) {
    final String base = p
        .basenameWithoutExtension(path)
        .replaceAll(RegExp(r"[^A-Za-z0-9_]+"), "_");
    return "userFont_${base}_${p.basename(path).length}";
  }
}
