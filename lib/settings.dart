import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "dialogs.dart";
import "l10n.dart";
import "output_store.dart";
import "theme.dart";

const String kAppVersion = "1.3.3";

/// Settings that do not belong in the conversion sheet: interface language,
/// the folder results are written to, and the accent colour.
class SettingsPage extends StatefulWidget {
  final Color seed;
  final ValueChanged<Color> onSeedChanged;

  const SettingsPage({
    super.key,
    required this.seed,
    required this.onSeedChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  OutputTarget? _target;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    S.revision.addListener(_onLanguageChanged);
    _loadTarget();
  }

  @override
  void dispose() {
    S.revision.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTarget() async {
    final OutputTarget? target = await OutputStore.current();
    if (mounted) setState(() => _target = target);
  }

  Future<void> _pickTarget() async {
    if (_busy) return;
    setState(() => _busy = true);
    final OutputTarget? target = await OutputStore.choose();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (target != null) _target = target;
    });
    if (target != null) {
      HapticFeedback.selectionClick();
      _toast(S.t("Results will go here from now on.", "之后的转换结果会直接存到这里。"));
    }
  }

  Future<void> _clearTarget() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => TimbreDialog(
        icon: Icons.folder_off_outlined,
        title: S.t("Use the default folder again?", "改回默认目录？"),
        message: S.t(
          "New conversions will stay in the app's own folder. Files already saved to the picked folder are untouched.",
          "之后的转换会回到应用自己的目录。已经存进所选文件夹的文件不会动。",
        ),
        secondaryLabel: S.t("Keep it", "保留"),
        secondaryResult: false,
        primaryLabel: S.t("Use default", "改回默认"),
        primaryResult: true,
      ),
    );
    if (confirmed != true) return;
    await OutputStore.clear();
    if (!mounted) return;
    setState(() => _target = null);
    _toast(S.t("Default folder restored.", "已改回默认目录。"));
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text(S.t("Settings", "设置")),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _languagePanel(scheme),
                const SizedBox(height: 16),
                _folderPanel(scheme),
                const SizedBox(height: 16),
                _accentPanel(scheme),
                const SizedBox(height: 16),
                _aboutPanel(scheme),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languagePanel(ColorScheme scheme) {
    return _panel(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                S.t("Language", "界面语言"),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            S.t(
              "Changes apply immediately. “System” follows the phone language.",
              "切换后立即生效。“跟随系统”会跟着手机语言走。",
            ),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: S.systemMode,
                  label: Text(S.t("System", "系统")),
                ),
                ButtonSegment<String>(
                  value: S.zhMode,
                  label: Text(S.t("中文", "中文")),
                ),
                ButtonSegment<String>(
                  value: S.enMode,
                  label: Text(S.t("English", "English")),
                ),
              ],
              selected: <String>{S.mode},
              onSelectionChanged: (Set<String> value) {
                HapticFeedback.selectionClick();
                S.setMode(value.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _folderPanel(ColorScheme scheme) {
    final String folder =
        _target?.name ?? S.t("App's own folder (default)", "应用专属目录（默认）");
    return _panel(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  S.t("Save results to", "转换结果存到"),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            folder,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            S.t(
              "Pick a folder through the system picker. The permission stays after a restart, and finished files are written there directly. When a folder is set, the result row shows Done instead of sharing.",
              "通过系统文件夹选择器授权。重启后仍保留权限，转换完成后直接写进去。设置目录后，结果栏显示“已完成”，不再给分享按钮。",
            ),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _pickTarget,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(
                    _target == null
                        ? S.t("Choose folder", "选择文件夹")
                        : S.t("Change folder", "换一个文件夹"),
                  ),
                ),
              ),
              if (_target != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _busy ? null : _clearTarget,
                  tooltip: S.t("Use default", "改回默认"),
                  icon: const Icon(Icons.folder_off_outlined),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            S.t(
              "Android 15, 16 and 17 use the same system picker. On older versions the picker is also available, but those ROMs have not been tested.",
              "Android 15、16、17 都用同一套系统选择器；更低版本也能选，只是没测过。",
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accentPanel(ColorScheme scheme) {
    return _panel(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                S.t("Accent colour", "主题色"),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: kAccentPalette.map((item) {
              final bool selected = widget.seed.toARGB32() == item.$1.toARGB32();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSeedChanged(item.$1);
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.$1,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? scheme.onSurface : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      S.t(item.$2, item.$3),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _aboutPanel(ColorScheme scheme) {
    return _panel(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                S.t("Timbre $kAppVersion", "Timbre $kAppVersion"),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            S.t(
              "Built on SimpleAudioConverter by TechnicJelle. MPL-2.0. Not an official upstream release.",
              "基于 TechnicJelle 的 SimpleAudioConverter，MPL-2.0，非上游官方版本。",
            ),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _panel(ColorScheme scheme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
      ),
      child: child,
    );
  }
}
