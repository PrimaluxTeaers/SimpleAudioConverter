import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";

import "font_manager.dart";
import "haptics.dart";
import "l10n.dart";

class FontManagerPage extends StatefulWidget {
  const FontManagerPage({super.key});

  @override
  State<FontManagerPage> createState() => _FontManagerPageState();
}

class _FontManagerPageState extends State<FontManagerPage> {
  String _folder = "";
  List<FontEntry> _entries = const <FontEntry>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String folder = await FontManager.folderPath();
    final List<FontEntry> entries = await FontManager.entries();
    if (!mounted) return;
    setState(() {
      _folder = folder;
      _entries = entries;
    });
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final List<PlatformFile> picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>["ttf", "otf", "ttc"],
      );
      if (picked.isEmpty) return;
      final String? path = picked.first.path;
      if (path == null) return;
      final String? error = await FontManager.importFile(path);
      if (!mounted) return;
      if (error != null) {
        _toast(error);
      } else {
        _toast(S.t("Font imported and applied.", "字体已导入并应用。"));
      }
      await _load();
    } catch (error) {
      if (mounted) _toast(S.t("Import failed: $error", "导入失败：$error"));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select(String path) async {
    final String? error = await FontManager.select(path);
    if (!mounted) return;
    if (error != null) {
      _toast(error);
      return;
    }
    Haptics.selectionClick();
    setState(() {});
  }

  Future<void> _clear() async {
    await FontManager.clear();
    Haptics.selectionClick();
    if (mounted) setState(() {});
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

  String _size(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).round()} KB";
    return "${(bytes / 1024 / 1024).toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool custom = FontManager.isCustom;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(S.t("Fonts", "字体")),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            tooltip: S.t("Refresh", "刷新"),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.t("App font folder", "应用字体文件夹"),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _folder.isEmpty ? "…" : _folder,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  S.t(
                    "Put TTF/OTF/TTC files here, or import one below. Android does not allow a normal app to replace system fonts, so the choice applies inside this app only.",
                    "把 TTF/OTF/TTC 放这里，或者点下面导入。安卓不允许普通应用替换系统字体，所以这里只改本应用的字体。",
                  ),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.file_open_rounded),
                  label: Text(S.t("Import a font", "导入字体")),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: !custom,
            onChanged: (bool? value) {
              if (value == true) _clear();
            },
            title: Text(S.t("System default", "系统默认")),
            subtitle: Text(
              S.t(
                "Unchecked when a custom font is active. Tap to return to the system font.",
                "启用了自定义字体时会取消勾选。点它可回到系统字体。",
              ),
            ),
          ),
          if (_entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Text(
                S.t(
                  "No font files found yet.",
                  "还没有找到字体文件。",
                ),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ..._entries.map((FontEntry entry) {
              final bool selected = FontManager.selectedPath == entry.path;
              return CheckboxListTile(
                value: selected,
                onChanged: (bool? value) {
                  if (value == true) {
                    _select(entry.path);
                  } else {
                    _clear();
                  }
                },
                title: Text(entry.name),
                subtitle: Text(_size(entry.bytes)),
                secondary: const Icon(Icons.font_download_outlined),
              );
            }),
          const SizedBox(height: 10),
          Text(
            S.t(
              "Only files in this folder are listed. Selecting a font applies it immediately; the setting survives a restart. Some variable or TTC collections may not load.",
              "只列出这个文件夹里的文件。选中后立即应用，重启仍保留。部分可变字体或 TTC 合集可能加载失败。",
            ),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
