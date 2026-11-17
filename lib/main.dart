import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:math" as math;
import "dart:ui" show ImageFilter;

import "package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart";
import "package:ffmpeg_kit_flutter_new_audio/media_information.dart";
import "package:ffmpeg_kit_flutter_new_audio/media_information_session.dart";
import "package:ffmpeg_kit_flutter_new_audio/stream_information.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:m3_expressive/m3_expressive.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:share_handler/share_handler.dart";
import "package:share_plus/share_plus.dart";
import "package:shared_preferences/shared_preferences.dart";

import "conversion.dart";
import "convert_engine.dart";
import "dialogs.dart";
import "device_info.dart";
import "l10n.dart";
import "media_information_view.dart";
import "output_store.dart";
import "page_route.dart";
import "path.dart";
import "picked_file_info.dart";
import "settings.dart";
import "theme.dart";
import "utils.dart";

const Color kDefaultSeed = Color(0xFF20695C);

final ValueNotifier<Color> appSeed = ValueNotifier<Color>(kDefaultSeed);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await S.load();
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int stored = prefs.getInt("themeSeed") ?? kDefaultSeed.toARGB32();
    appSeed.value = Color(stored);
  } catch (_) {}
  runApp(const TimbreApp());
}

class TimbreApp extends StatelessWidget {
  const TimbreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appSeed,
      builder: (BuildContext context, Color seed, _) {
        return MaterialApp(
          title: "Timbre 64 位",
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light, seed),
          darkTheme: buildAppTheme(Brightness.dark, seed),
          themeMode: ThemeMode.system,
          home: const HomePage(),
        );
      },
    );
  }
}

class InputEntry {
  final PickedFileInfo info;

  const InputEntry(this.info);

  String get name => info.filename;

  double get seconds => double.tryParse(info.mediaInformation.getDuration() ?? "") ?? 0;

  String get durationText {
    if (seconds <= 0) return "";
    final int total = seconds.round();
    final int h = total ~/ 3600;
    final int m = (total % 3600) ~/ 60;
    final int s = total % 60;
    if (h > 0) {
      return "$h:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}";
    }
    return "$m:${s.toString().padLeft(2, "0")}";
  }

  String get sizeText =>
      intToSize(int.tryParse(info.mediaInformation.getSize() ?? "")) ?? "";
}

/// A user-created bucket of formats. Stored as JSON in shared_preferences.
class CustomGroup {
  final String id;
  final String name;
  final Set<String> formatIds;

  CustomGroup({required this.id, required this.name, required this.formatIds});

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "formats": formatIds.toList(),
  };

  static CustomGroup? fromJson(Map<String, dynamic> json) {
    final Object? id = json["id"];
    final Object? name = json["name"];
    final Object? formats = json["formats"];
    if (id is! String || name is! String || formats is! List) return null;
    return CustomGroup(
      id: id,
      name: name,
      formatIds: formats.whereType<String>().toSet(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<InputEntry> _files = [];
  final ConversionSettings _settings = ConversionSettings();
  final ConvertEngine _engine = ConvertEngine();
  final TextEditingController _bitrateController = TextEditingController();

  Directory? _outputDir;
  OutputTarget? _outputTarget;
  bool _probing = false;
  bool _converting = false;
  bool _publishing = false;
  bool _finished = false;
  bool _showFinishedBar = false;
  bool _resultsExpanded = true;
  Timer? _finishBarTimer;
  Timer? _resultsTimer;
  int _activeIndex = 0;
  double _activeProgress = 0;
  List<ConvertOutcome> _results = const [];
  bool _advancedOpen = false;
  DeviceProfile? _device;
  int _decodeMode = 0;
  FormatCategory? _category = FormatCategory.daily;
  String? _activeGroupId;
  List<CustomGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    _bitrateController.text = _settings.bitrate.toString();
    S.revision.addListener(_onLanguageChanged);
    _prepareDir();
    _loadOutputTarget();
    _loadGroups();
    _initShareReceiver();
    DeviceProfile.load().then((DeviceProfile profile) {
      if (!mounted) return;
      setState(() {
        _device = profile;
        _settings.threads = 0;
      });
    });
  }

  @override
  void dispose() {
    _finishBarTimer?.cancel();
    _resultsTimer?.cancel();
    S.revision.removeListener(_onLanguageChanged);
    _bitrateController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadOutputTarget() async {
    final OutputTarget? target = await OutputStore.current();
    if (mounted) setState(() => _outputTarget = target);
  }

  Future<void> _prepareDir() async {
    try {
      final Directory base =
          (await getExternalStorageDirectory()) ?? await getTemporaryDirectory();
      final Directory dir = Directory(p.join(base.path, "converted"));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      _outputDir = dir;
    } catch (_) {
      // Desktop/tests have no path_provider plugin. A temp dir keeps the UI
      // usable instead of crashing before the first build.
      final Directory fallback = Directory(p.join(Directory.systemTemp.path, "timbre"));
      if (!fallback.existsSync()) fallback.createSync(recursive: true);
      _outputDir = fallback;
    }
  }

  Future<void> _initShareReceiver() async {
    try {
      final handler = ShareHandlerPlatform.instance;
      final SharedMedia? media = await handler.getInitialSharedMedia();
      if (media != null) _openShared(media);
      handler.sharedMediaStream.listen(_openShared);
    } catch (_) {
      // Sharing into the app is a bonus, not a requirement.
    }
  }

  void _openShared(SharedMedia media) {
    try {
      final String? path = media.attachments?.first?.path;
      if (path == null) return;
      unawaited(_addPath(path, sharedInto: true));
    } catch (_) {}
  }

  Future<void> _pickFiles() async {
    try {
      final List<PlatformFile> picked = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (picked.isEmpty) return;
      final List<String> paths = picked
          .map((PlatformFile f) => f.path)
          .whereType<String>()
          .toList();
      if (paths.isEmpty) return;
      for (final String path in paths) {
        await _addPath(path, sharedInto: true);
      }
      setState(() {
        _finished = false;
        _showFinishedBar = false;
        _results = const [];
      });
    } catch (e) {
      _toast(S.t("Could not open the file picker: $e", "打开文件选择器失败：$e"));
    }
  }

  Future<void> _addPath(String path, {required bool sharedInto}) async {
    setState(() => _probing = true);
    try {
      final PickedFileInfo? info = await _probe(path, sharedInto: sharedInto);
      if (info == null) {
        _toast(S.t("No audio found in this file. Try another one.", "这个文件里读不到音频，换一个试试"));
        return;
      }
      final bool duplicate = _files.any(
        (e) =>
            e.info.path.filename == info.filename &&
            e.seconds ==
                (double.tryParse(info.mediaInformation.getDuration() ?? "") ?? 0),
      );
      if (duplicate) {
        _toast(S.t("This file is already in the queue.", "这个文件已经在队列里了"));
        return;
      }
      setState(() {
        _files.add(InputEntry(info));
        _finished = false;
        _results = const [];
      });
    } finally {
      if (mounted) setState(() => _probing = false);
    }
  }

  Future<PickedFileInfo?> _probe(String uri, {required bool sharedInto}) async {
    final Path path = Path(uri: uri, sharedInto: sharedInto);
    final String? url = await path.getUrl();
    if (url == null) return null;

    final MediaInformationSession session =
        await FFprobeKit.getMediaInformationFromCommandArguments(<String>[
          "-hide_banner",
          "-v",
          "error",
          "-print_format",
          "json",
          "-show_format",
          "-show_streams",
          "-i",
          url,
        ]);
    final MediaInformation? information = session.getMediaInformation();
    if (information == null) return null;

    final bool hasAudio = information.getStreams().any(
      (StreamInformation s) => s.getType() == "audio",
    );
    if (!hasAudio) return null;
    return PickedFileInfo(path: path, mediaInformation: information);
  }

  void _removeFile(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _files.removeAt(index);
      _finished = false;
      _results = const [];
    });
  }

  void _resetAll() {
    setState(() {
      _files.clear();
      _results = const [];
      _finished = false;
    });
  }

  Future<void> _start() async {
    if (_files.isEmpty || _converting) return;
    if (_outputDir == null) await _prepareDir();
    HapticFeedback.mediumImpact();
    _finishBarTimer?.cancel();
    _resultsTimer?.cancel();
    setState(() {
      _converting = true;
      _finished = false;
      _showFinishedBar = false;
      _resultsExpanded = true;
      _results = const [];
      _activeIndex = 0;
      _activeProgress = 0;
    });

    final List<ConvertOutcome> outcomes = await _engine.run(
      files: _files.map((e) => e.info).toList(),
      settings: _settings,
      outputDir: _outputDir!,
      onProgress: (int i, double progress) {
        if (!mounted) return;
        setState(() {
          _activeIndex = i;
          _activeProgress = progress;
        });
      },
    );

    final OutputTarget? target = _outputTarget;
    List<ConvertOutcome> results = outcomes;
    if (target != null && outcomes.any((ConvertOutcome r) => r.ok)) {
      if (mounted) {
        setState(() {
          _converting = false;
          _publishing = true;
          _activeProgress = 1;
        });
      }
      results = await _publishResults(outcomes, target);
      if (!mounted) return;
      final int failedCopies = results
          .where((ConvertOutcome r) => r.ok && !r.published)
          .length;
      if (failedCopies > 0) {
        _toast(
          S.t(
            "$failedCopies file(s) could not be written to the picked folder. They are still in the app folder.",
            "有 $failedCopies 个文件写不进所选文件夹，已留在应用目录里。",
          ),
        );
      }
    }

    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _converting = false;
      _publishing = false;
      _finished = true;
      _showFinishedBar = true;
      _resultsExpanded = true;
      _results = results;
      _files.removeWhere(
        (entry) => results.any(
          (r) => r.ok && r.input.path.filename == entry.info.path.filename,
        ),
      );
    });
    _scheduleFinishedUi();
    final bool hardwareFailed =
        _settings.hardwareDecode &&
        results.any((ConvertOutcome r) => !r.ok && _looksLikeHardwareFailure(r));
    if (hardwareFailed) {
      await _showHardwareFallback();
    } else if (results.isNotEmpty && results.every((ConvertOutcome r) => !r.ok)) {
      await _showAllFailed();
    }
  }

  void _scheduleFinishedUi() {
    _finishBarTimer?.cancel();
    _resultsTimer?.cancel();
    _finishBarTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showFinishedBar = false);
    });
    _resultsTimer = Timer(const Duration(seconds: 9), () {
      if (!mounted) return;
      setState(() => _resultsExpanded = false);
    });
  }

  void _collapseResults() {
    _resultsTimer?.cancel();
    if (_resultsExpanded) setState(() => _resultsExpanded = false);
  }

  Future<List<ConvertOutcome>> _publishResults(
    List<ConvertOutcome> results,
    OutputTarget target,
  ) async {
    final List<ConvertOutcome> published = <ConvertOutcome>[];
    for (final ConvertOutcome outcome in results) {
      if (!outcome.ok) {
        published.add(outcome);
        continue;
      }
      final PublishedFile? file = await OutputStore.publish(outcome.outputPath!);
      if (file == null) {
        published.add(outcome);
        continue;
      }
      // The tree has its own copy now. Keeping a second one in the app
      // sandbox only wastes space, so drop the temporary file.
      try {
        File(outcome.outputPath!).deleteSync();
      } catch (_) {}
      published.add(outcome.withPublished(file.uri, file.name));
    }
    return published;
  }

  Future<void> _confirmStop() async {
    final bool stop =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => TimbreDialog(
            icon: Icons.stop_circle_outlined,
            title: S.t("Stop conversion?", "停止转换？"),
            message: S.t(
              "The file being converted right now will be abandoned. Finished files stay in the output folder.",
              "当前正在转的文件会作废。已经转好的文件还在输出目录里。",
            ),
            secondaryLabel: S.t("Keep going", "继续转"),
            secondaryResult: false,
            primaryLabel: S.t("Stop", "停止"),
            primaryResult: true,
            destructive: true,
          ),
        ) ??
        false;
    if (stop) await _engine.cancel();
  }

  bool _looksLikeHardwareFailure(ConvertOutcome r) {
    final String e = (r.error ?? "").toLowerCase();
    return e.contains("mediacodec") ||
        e.contains("hwaccel") ||
        e.contains("hardware decoder") ||
        e.contains("硬解");
  }

  Future<void> _showHardwareFallback() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => TimbreDialog(
        icon: Icons.memory_rounded,
        title: S.t("Hardware decode didn't open it", "这个文件硬解没打开"),
        message: S.t(
          "Hardware decoding failed. Software decoding usually gets through; tap below to retry. If that also fails, switch to another format or version.",
          "已经试过硬解，没成功。换软件解码通常能过，点下面直接重试；要是还不行，再换输出格式或版本。",
        ),
        secondaryLabel: S.t("Pick another format", "换个格式"),
        onSecondary: _showAllFormatsSheet,
        primaryLabel: S.t("Switch to software and retry", "改用软件再试一次"),
        onPrimary: () {
          HapticFeedback.lightImpact();
          setState(() {
            _settings.hardwareDecode = false;
            _decodeMode = 1;
          });
          _start();
        },
      ),
    );
  }

  Future<void> _showAllFailed() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => TimbreDialog(
        icon: Icons.report_gmailerrorred_rounded,
        title: S.t("Still didn't convert", "还是没转成"),
        message: S.t(
          "Software decode did not help either. Try another format or version; the source may use a codec this build cannot read.",
          "软件解码也没成功。换一个输出格式或版本试试，也可能是源文件用了本构建读不了的编码。",
        ),
        secondaryLabel: S.t("Close", "关闭"),
        primaryLabel: S.t("Choose format", "选择格式"),
        onPrimary: _showAllFormatsSheet,
      ),
    );
  }

  void _removeResultAt(int index) {
    if (index < 0 || index >= _results.length) return;
    HapticFeedback.selectionClick();
    setState(() => _results = <ConvertOutcome>[..._results]..removeAt(index));
  }

  Future<void> _shareOutcome(ConvertOutcome outcome) async {
    if (!outcome.ok || outcome.published) return;
    final File file = File(outcome.outputPath!);
    if (!file.existsSync()) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: p.basename(file.path)),
    );
  }

  Future<void> _shareAll() async {
    final List<XFile> files = _results
        .where((r) => r.ok && !r.published)
        .map((r) => File(r.outputPath!))
        .where((f) => f.existsSync())
        .map((f) => XFile(f.path))
        .toList();
    if (files.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: S.t("${files.length} converted files", "转换完成 ${files.length} 个文件"),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Brightness brightness = Theme.of(context).brightness;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.10),
                  scheme.surface,
                ),
                scheme.surface,
                Color.alphaBlend(
                  scheme.tertiary.withValues(alpha: 0.06),
                  scheme.surface,
                ),
              ],
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _scrollContent(),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom:
                    16 +
                    math.max(
                      MediaQuery.viewPaddingOf(context).bottom,
                      MediaQuery.viewInsetsOf(context).bottom,
                    ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _bottomBar(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scrollContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          expandedHeight: 128,
          title: const Text("Timbre 64 位"),
          actions: [
            if (_files.isNotEmpty && !_converting)
              IconButton(
                tooltip: S.t("Clear all", "清空"),
                onPressed: _resetAll,
                icon: const Icon(Icons.clear_all_rounded),
              ),
            IconButton(
              tooltip: S.t("Settings", "设置"),
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
            IconButton(
              tooltip: S.t("About", "关于"),
              onPressed: _showAbout,
              icon: const Icon(Icons.info_outline_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            _contentSidePadding(context),
            0,
            _contentSidePadding(context),
            150,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _heroCard(),
              const SizedBox(height: 20),
              if (_results.isNotEmpty)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _resultsExpanded ? _resultsCard() : _resultsSummaryCard(),
                ),
              _sectionTitle(
                index: "01",
                S.t("Files", "文件"),
                trailing: _files.isEmpty
                    ? null
                    : S.t("${_files.length} items", "${_files.length} 个"),
              ),
              const SizedBox(height: 10),
              ..._fileTiles(),
              const SizedBox(height: 12),
              _addFilesButton(),
              const SizedBox(height: 26),
              _sectionTitle(S.t("Output format", "输出格式"), index: "02"),
              const SizedBox(height: 10),
              _formatPicker(),
              const SizedBox(height: 12),
              _formatDetails(),
              const SizedBox(height: 26),
              _sectionTitle(S.t("Sound", "声音参数"), index: "03"),
              const SizedBox(height: 10),
              _bitratePanel(),
              const SizedBox(height: 26),
              _sectionTitle(S.t("Decode & performance", "解码与性能"), index: "04"),
              const SizedBox(height: 10),
              _performanceCard(),
              const SizedBox(height: 18),
              _advancedPanel(),
            ]),
          ),
        ),
      ],
    );
  }

  double _contentSidePadding(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return width <= 792 ? 16 : (width - 760) / 2;
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      appPageRoute<void>(
        builder: (BuildContext ctx) => SettingsPage(
          seed: appSeed.value,
          onSeedChanged: (Color color) {
            appSeed.value = color;
            unawaited(_saveSeed(color));
          },
        ),
      ),
    );
    if (mounted) await _loadOutputTarget();
  }

  Future<void> _saveSeed(Color color) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt("themeSeed", color.toARGB32());
    } catch (_) {}
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => TimbreDialog(
        icon: Icons.info_outline_rounded,
        title: "Timbre $kAppVersion",
        message: S.t(
          "An unofficial, independently signed build based on SimpleAudioConverter by TechnicJelle. Not an official upstream release.\n\n"
              "Source stays under MPL-2.0; this package is distributed under the same license.\n\n"
              "64-bit only · arm64-v8a. Built for Android 15, 16 and 17; Android 15+ is recommended, older versions are untested. Native Android, HyperOS/MIUI, ColorOS and OriginOS are the main targets.\n\n"
              "Primary targets: Dimensity 9300 and newer (9300/9400/9500/9600, including Plus/Pro/S rebadges), the Dimensity 8400/8450/8500 family; Snapdragon 8 Gen 3 and newer (including 8s Gen 4). Other chips still convert on the CPU; hardware decode may not hold up.",
          "基于 TechnicJelle 的 SimpleAudioConverter 二次开发，非官方独立签名构建，与上游作者无关。\n\n"
              "源码遵循 MPL-2.0，本安装包以同一许可证分发。\n\n"
              "仅 64 位 · arm64-v8a。针对 Android 15、16、17 构建；建议 Android 15 及以上，更低版本未验证。主要照顾原生 Android、澎湃/MIUI、ColorOS 和 OriginOS。\n\n"
              "主要适配：天玑 9300 及以上（9300/9400/9500/9600，含 Plus/Pro/S 换皮），以及天玑 8400/8450/8500 系列；骁龙 8 第三代及以上（含 8s Gen 4）。其他芯片也能转，靠 CPU 软解，慢一点；硬解不一定稳。",
        ),
        primaryLabel: S.t("Close", "关闭"),
      ),
    );
  }

  Widget _heroCard() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.withValues(alpha: 0.88),
            scheme.tertiaryContainer.withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.graphic_eq_rounded,
              color: scheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.t("Convert on device", "本机转码，文件不出手机"),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.t(
                    "${kFormats.length} outputs · grouped by use · batch ready",
                    "${kFormats.length} 种输出 · 按用途分组 · 可批量",
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, {String? trailing, String? index}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (index != null) ...[
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  List<Widget> _fileTiles() {
    if (_files.isEmpty) return [_emptyFiles()];

    return _files.asMap().entries.map((entry) {
      final int index = entry.key;
      final InputEntry file = entry.value;
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                backgroundColor: scheme.surfaceContainerLow,
                builder: (_) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: MediaInformationView(info: file.info),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.audio_file_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (file.durationText.isNotEmpty) file.durationText,
                            if (file.sizeText.isNotEmpty) file.sizeText,
                          ].join("  ·  "),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _converting ? null : () => _removeFile(index),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: S.t("Remove", "移除"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _emptyFiles() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.library_music_rounded, size: 40, color: scheme.primary),
          const SizedBox(height: 10),
          Text(
            S.t("No files yet", "还没有文件"),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            S.t(
              "Audio and video files both work. Video keeps its picture; only the audio track is replaced.",
              "音频和视频文件都行。视频会保留画面，只替换音轨。",
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addFilesButton() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: _converting ? null : _pickFiles,
            icon: _probing
                ? const M3LoadingIndicator(
                    size: 18,
                    morphDuration: Duration(milliseconds: 1200),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(
              _probing ? S.t("Reading…", "正在读取…") : S.t("Add files", "添加文件"),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadGroups() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString("customGroups");
      if (raw == null || raw.isEmpty) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final List<CustomGroup> groups = decoded
          .whereType<Map<String, dynamic>>()
          .map(CustomGroup.fromJson)
          .whereType<CustomGroup>()
          .toList();
      if (mounted) setState(() => _groups = groups);
    } catch (_) {}
  }

  Future<void> _saveGroups() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        "customGroups",
        jsonEncode(_groups.map((g) => g.toJson()).toList()),
      );
    } catch (_) {}
  }

  List<AudioFormat> get _visibleFormats {
    if (_activeGroupId != null) {
      CustomGroup? group;
      for (final CustomGroup g in _groups) {
        if (g.id == _activeGroupId) {
          group = g;
          break;
        }
      }
      if (group == null) return kFormats;
      return kFormats.where((f) => group!.formatIds.contains(f.id)).toList();
    }
    if (_category == null) return kFormats;
    return kFormats.where((f) => f.category == _category).toList();
  }

  String _categoryLabel(FormatCategory category) {
    return switch (category) {
      FormatCategory.daily => S.t("Everyday", "日常"),
      FormatCategory.lossless => S.t("Lossless", "无损"),
      FormatCategory.voice => S.t("Voice", "语音"),
      FormatCategory.legacy => S.t("Legacy", "老格式"),
      FormatCategory.other => S.t("Others", "其他"),
    };
  }

  void _showGroupEditor() {
    final TextEditingController nameController = TextEditingController();
    final Set<String> picked = <String>{};
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setLocal) => AlertDialog(
          title: Text(S.t("New group", "新建分组")),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: S.t("Group name", "分组名称"),
                      hintText: S.t("Podcast, Phone calls…", "播客、通话…"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.t("Cancel", "取消")),
            ),
            FilledButton(
              onPressed: () {
                final String name = nameController.text.trim();
                if (name.isEmpty || picked.length < 2) return;
                final CustomGroup group = CustomGroup(
                  id: "g${DateTime.now().millisecondsSinceEpoch}",
                  name: name,
                  formatIds: picked,
                );
                setState(() {
                  _groups = [..._groups, group];
                  _activeGroupId = group.id;
                  _category = null;
                });
                _saveGroups();
                Navigator.of(ctx).pop();
              },
              child: Text(S.t("Create", "创建")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.5)
                : scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _formatPicker() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<AudioFormat> visible = _visibleFormats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                S.t("All", "全部"),
                _category == null && _activeGroupId == null,
                () => setState(() {
                  _category = null;
                  _activeGroupId = null;
                }),
              ),
              const SizedBox(width: 8),
              ...FormatCategory.values.map((FormatCategory c) {
                final bool on = _category == c && _activeGroupId == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _filterChip(_categoryLabel(c), on, () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _category = c;
                      _activeGroupId = null;
                    });
                  }),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._groups.map((CustomGroup g) {
                final bool on = _activeGroupId == g.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onLongPress: () {
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext ctx) => AlertDialog(
                          title: Text(g.name),
                          content: Text(S.t("Delete this group?", "删除这个分组？")),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(S.t("Cancel", "取消")),
                            ),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  _groups = _groups.where((x) => x.id != g.id).toList();
                                  if (_activeGroupId == g.id) {
                                    _activeGroupId = null;
                                    _category = FormatCategory.daily;
                                  }
                                });
                                _saveGroups();
                                Navigator.of(ctx).pop();
                              },
                              child: Text(S.t("Delete", "删除")),
                            ),
                          ],
                        ),
                      );
                    },
                    child: _filterChip(g.name, on, () {
                      setState(() {
                        _activeGroupId = g.id;
                        _category = null;
                      });
                    }),
                  ),
                );
              }),
              _filterChip(S.t("+ Group", "＋分组"), false, _showGroupEditor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              S.t("No formats in this group yet.", "这个分组里还没有格式。"),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visible.map((AudioFormat f) {
            final bool selected = _settings.formatId == f.id;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _settings.selectFormat(f.id);
                  _bitrateController.text = _settings.bitrate.toString();
                });
              },
              onLongPress: () => _showFormatSheet(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.18)
                          : Colors.transparent,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  f.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// One-line "what it is for" under the chips, with a way into the full
  /// per-format reference. Every format carries its own summary + long text;
  /// nothing is hard-coded here.
  Widget _formatDetails() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AudioFormat f = _settings.format;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${f.label} · ${S.t(f.summaryEn, f.summaryZh)}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: _showAllFormatsSheet,
                  child: Text(
                    S.t(
                      "All ${kFormats.length} formats and what they are for",
                      "查看全部 ${kFormats.length} 种格式的用途与详情",
                    ),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: S.t("Details", "详情"),
            onPressed: () => _showFormatSheet(f),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _specsFor(AudioFormat f) {
    if (f.lossless) {
      return S.t("Lossless · bitrate does not apply", "无损 · 码率不适用");
    }
    if (f.hasFixedSteps) {
      return S.t(
        "${f.fixedKbps.length} fixed steps · ${f.fixedKbps.first}–${f.fixedKbps.last} kbps",
        "${f.fixedKbps.length} 个固定档 · ${f.fixedKbps.first}–${f.fixedKbps.last} kbps",
      );
    }
    final String range = S.t(
      "${f.minKbps}–${f.maxKbps} kbps",
      "${f.minKbps}–${f.maxKbps} kbps",
    );
    final String modes = f.hasVbr
        ? S.t("CBR + VBR", "CBR + VBR")
        : S.t("CBR only", "仅 CBR");
    return "$range · $modes";
  }

  void _applyFormat(AudioFormat f, {FormatPreset? preset}) {
    setState(() {
      _settings.selectFormat(f.id);
      if (preset != null) _settings.applyPreset(preset);
      _bitrateController.text = _settings.bitrate.toString();
      if (preset != null && preset.vbr) {
        _settings.vbrQuality = preset.vbrQuality;
      }
    });
  }

  void _showFormatSheet(AudioFormat f) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainerLow,
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          builder: (BuildContext ctx, ScrollController controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(f.label, style: Theme.of(ctx).textTheme.headlineSmall),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _categoryLabel(f.category),
                        style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _specsFor(f),
                  style: Theme.of(ctx).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Text(
                  S.t("WHAT IT'S FOR", "适合拿来做什么"),
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  S.t(f.summaryEn, f.summaryZh),
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  S.t("TRADE-OFFS", "用起来的取舍"),
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  S.t(f.detailEn, f.detailZh),
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _applyFormat(f);
                  },
                  child: Text(
                    S.t("Use ${f.label}, keep my settings", "使用 ${f.label}，保留当前设置"),
                  ),
                ),
                const SizedBox(height: 26),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  S.t("Recommended presets", "推荐配置"),
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  S.t(
                    "Only applied when you tap. Opening a format never rewrites your settings.",
                    "只有点了才会生效。光看详情不会改你的设置。",
                  ),
                  style: Theme.of(ctx).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                ...presetsFor(f).map((FormatPreset preset) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _applyFormat(f, preset: preset);
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      S.t(preset.labelEn, preset.labelZh),
                                      style: Theme.of(ctx).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      S.t(preset.noteEn, preset.noteZh),
                                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                S.t("Apply", "应用"),
                                style: Theme.of(ctx).textTheme.labelLarge
                                    ?.copyWith(color: scheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _showAllFormatsSheet() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainerLow,
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.94,
          builder: (BuildContext ctx, ScrollController controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Text(
                  S.t("Format reference", "格式说明"),
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  S.t(
                    "Grouped by use. Tap a row for the short version.",
                    "按用途分组。点开一行看简短说明。",
                  ),
                  style: Theme.of(ctx).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                ...FormatCategory.values.expand((FormatCategory category) {
                  final List<AudioFormat> formats = kFormats
                      .where((AudioFormat f) => f.category == category)
                      .toList();
                  if (formats.isEmpty) return const <Widget>[];
                  return <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                      child: Row(
                        children: [
                          Text(
                            _categoryLabel(category),
                            style: Theme.of(ctx).textTheme.titleSmall,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${formats.length}",
                            style: Theme.of(ctx).textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    ...formats.map(
                      (AudioFormat f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: Theme(
                            data: Theme.of(ctx)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Text(
                                f.label,
                                style: Theme.of(ctx).textTheme.titleSmall,
                              ),
                              subtitle: Text(
                                S.t(f.summaryEn, f.summaryZh),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              expandedCrossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.t(
                                    kFormatReferenceEn[f.id] ?? f.detailEn,
                                    kFormatReferenceZh[f.id] ?? f.detailZh,
                                  ),
                                  style: Theme.of(ctx).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ];
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _bitratePanel() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AudioFormat format = _settings.format;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (format.variants.length > 1) ...[
            _dropdownRow<String>(
              S.t("Version", "版本"),
              _settings.variantId,
              format.variants
                  .map((FormatVariant v) => (v.id, S.t(v.labelEn, v.labelZh)))
                  .toList(),
              (String id) {
                HapticFeedback.selectionClick();
                setState(() {
                  _settings.selectVariant(id);
                  _bitrateController.text = _settings.bitrate.toString();
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          if (format.lossless) ...[
            Text(
              S.t("Lossless: bitrate does not apply", "无损格式不需要码率"),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              S.t("Size depends on sample rate and bit depth only.", "文件大小只取决于采样率和位深。"),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (format.id == "flac" || format.id == "wv") _flacLevel(),
            if (format.isPcm) _pcmDepth(format.id),
            if (format.id == "alac")
              Text(
                S.t("ALAC is fixed lossless. Nothing to tune.", "ALAC 固定无损，没有可调项。"),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ] else ...[
            if (format.hasVbr) ...[
              _modeSwitcher(),
              const SizedBox(height: 18),
            ],
            if (!_settings.vbr || !format.hasVbr)
              _cbrControls(format)
            else
              _vbrControls(format),
          ],
          const SizedBox(height: 14),
          const Divider(height: 18),
          _soundControls(),
        ],
      ),
    );
  }

  Widget _soundControls() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool normalize = _settings.normalizeLoudness;
    final double gain = _settings.gainDb;
    final String gainLabel = normalize
        ? S.t("Loudness matched", "响度已统一")
        : "${gain >= 0 ? "+" : ""}${gain.toStringAsFixed(1)} dB";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.graphic_eq_rounded, size: 18, color: scheme.secondary),
            const SizedBox(width: 8),
            Text(
              S.t("Overall level", "整体音量"),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              gainLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: normalize ? scheme.primary : scheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (!normalize && gain.abs() >= 0.05)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: S.t("Reset to original", "恢复原样"),
                onPressed: () => setState(() => _settings.gainDb = 0),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
        Slider(
          value: gain,
          min: -12,
          max: 12,
          divisions: 24,
          label: gainLabel,
          onChanged: normalize
              ? null
              : (double v) => setState(() {
                  _settings.gainDb = (v * 2).round() / 2;
                }),
        ),
        Text(
          normalize
              ? S.t(
                  "EBU R128 single-pass, target -16 LUFS. The gain slider is bypassed while this is on.",
                  "单遍 EBU R128，目标 -16 LUFS。开启时音量滑块不参与。",
                )
              : S.t(
                  "0 dB keeps the source. Positive values raise the whole file; a limiter catches peaks. Negative values lower it.",
                  "0 dB 保持原样。正数整体提高，自动限幅防削波；负数整体降低。",
                ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.t("Match loudness across files", "统一整批响度"),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.t(
                        "Useful when the queue mixes quiet recordings with loud tracks.",
                        "一批文件里有录音也有成品时，这个比手动拖音量稳。",
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: normalize,
                onChanged: (bool v) => setState(() => _settings.normalizeLoudness = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeSwitcher() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool vbr = _settings.vbr;
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: vbr ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _modeHalf(
                  S.t("CBR", "固定码率"),
                  !vbr,
                  () => _setVbr(false),
                ),
              ),
              Expanded(
                child: _modeHalf(
                  S.t("VBR", "可变码率"),
                  vbr,
                  () => _setVbr(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeHalf(String label, bool selected, VoidCallback onTap) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 240),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  /// Sets an explicit mode. The old version passed `!vbr` into the tap
  /// handler, so tapping the already-selected chip flipped it to the other
  /// mode.
  void _setVbr(bool value) {
    HapticFeedback.selectionClick();
    setState(() {
      _settings.vbr = value;
      if (_settings.format.hasCbr) {
        _settings.bitrate = _settings.bitrate.clamp(
          _settings.format.minKbps,
          _settings.format.maxKbps,
        );
        _bitrateController.text = _settings.bitrate.toString();
      }
    });
  }

  Widget _cbrControls(AudioFormat format) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool fixed = format.hasFixedSteps;
    final int value = _settings.bitrate;
    final double sliderValue = fixed
        ? _settings.fixedIndex.toDouble()
        : value.toDouble();
    final double sliderMin = fixed ? 0 : format.minKbps.toDouble();
    final double sliderMax = fixed
        ? (format.fixedKbps.length - 1).toDouble()
        : format.maxKbps.toDouble();

    void setBitrate(double raw) {
      setState(() {
        if (fixed) {
          final int index = raw.round().clamp(0, format.fixedKbps.length - 1);
          _settings.bitrate = format.fixedKbps[index].round();
        } else {
          _settings.bitrate = raw.round();
        }
        _bitrateController.text = _settings.bitrate.toString();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value.toDouble()),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double animated, _) {
                return Text(
                  fixed ? _settings.bitrate.toString() : animated.round().toString(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: scheme.primary,
                    height: 1,
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "kbps",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _bitrateController,
                keyboardType: TextInputType.numberWithOptions(decimal: fixed),
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  suffixText: "k",
                ),
                onSubmitted: (String raw) {
                  final double? parsed = double.tryParse(raw);
                  if (parsed == null) return;
                  setBitrate(parsed);
                },
              ),
            ),
          ],
        ),
        FineSlider(
          value: sliderValue,
          min: sliderMin,
          max: sliderMax,
          divisions: fixed ? format.fixedKbps.length - 1 : null,
          onChanged: setBitrate,
          valueLabel: fixed ? "${_settings.bitrate} kbps" : "${_settings.bitrate} kbps",
        ),
        Text(
          fixed
              ? S.t(
                  "This codec only accepts ${format.fixedKbps.length} legal bitrates. Hold the slider to fine-tune, release to snap.",
                  "这个编码只认 ${format.fixedKbps.length} 个合法码率。长按滑块可微调，松手自动吸附。",
                )
              : S.t(
                  "Any value between ${format.minKbps} and ${format.maxKbps} kbps. Long-press the slider for fine adjustment.",
                  "可填 ${format.minKbps}–${format.maxKbps} 之间任意值。长按滑块可微调。",
                ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _vbrControls(AudioFormat format) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (format.id == "opus") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.t("Variable bitrate", "可变码率"),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.t(
                        "Bitrate is allocated by content; the value below is the target ceiling.",
                        "打开后按内容自动分配码率，下面的值作为目标参考。",
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _settings.vbr,
                onChanged: (bool v) => setState(() => _settings.vbr = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _cbrControls(format),
        ],
      );
    }

    final int q = _settings.vbrQuality;
    final int maxQ = format.vbrMax ?? 9;
    final String qualityNote = q == 0
        ? S.t("best quality, largest file", "最好，文件最大")
        : (q >= maxQ ? S.t("smallest file", "最小，文件最小") : S.t("balanced", "中等"));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              S.t("Quality $q", "质量 $q"),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            Text(
              qualityNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(
          value: q.toDouble(),
          min: 0,
          max: maxQ.toDouble(),
          divisions: maxQ,
          onChanged: (double v) => setState(() => _settings.vbrQuality = v.round()),
        ),
        Text(
          format.id == "mp3"
              ? S.t(
                  "0 is best quality, 9 is smallest. The encoder picks the bitrate.",
                  "0 音质最好，9 文件最小，码率由编码器分配。",
                )
              : S.t(
                  "0 is best quality, 10 is smallest. The encoder picks the bitrate.",
                  "0 音质最好，10 文件最小，码率由编码器分配。",
                ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _flacLevel() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.t("Compression level ${_settings.flacLevel}", "压缩等级 ${_settings.flacLevel}"),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _settings.flacLevel.toDouble(),
          min: 0,
          max: 12,
          divisions: 12,
          onChanged: (double v) => setState(() => _settings.flacLevel = v.round()),
        ),
        Text(
          S.t(
            "0 is fastest, 12 compresses hardest. Audio is untouched.",
            "0 最快、12 压得最小，音质完全不变。",
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _pcmDepth(String id) {
    final List<int> depths = switch (id) {
      "wav" => [16, 24, 32],
      "au" => [16],
      _ => [16, 24],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.t("Bit depth", "位深"), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: depths.map((int d) {
            final bool selected = _settings.pcmDepth == d;
            final ColorScheme scheme = Theme.of(context).colorScheme;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _settings.pcmDepth = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d == 32 ? S.t("32-bit float", "32 位浮点") : S.t("$d-bit", "$d 位"),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _performanceCard() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DeviceProfile? device = _device;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.memory_rounded, color: scheme.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device == null
                          ? S.t("Detecting device…", "正在识别设备…")
                          : device.chipName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device == null
                          ? S.t("Reading SoC model", "读取 SoC 型号")
                          : "${device.vendor.isNotEmpty ? '${device.vendor} · ' : ''}${device.cores} cores · ${device.archLabel} · Android ${device.releaseLabel}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (device != null && device.report.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              device.report,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.error,
              ),
            ),
          ],
          if (device != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  device.isPrimaryTarget
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  size: 15,
                  color: device.isPrimaryTarget
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    device.targetNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 22),
          _dropdownRow<int>(
            S.t("Decoder", "解码方式"),
            _decodeMode,
            [
              (0, S.t("Auto", "自动")),
              (1, S.t("Software (CPU)", "软件（CPU）")),
              (2, S.t("Hardware (MediaCodec)", "硬件（MediaCodec）")),
            ],
            (int v) => setState(() {
              _decodeMode = v;
              _settings.hardwareDecode = v == 2;
            }),
          ),
          const SizedBox(height: 6),
          Text(
            S.t(
              "Hardware decoding only applies when the source carries a video track. Pure audio always runs on the CPU, so enabling it there changes nothing. On chips outside the tested list, hardware decode can fail; switch back to software if it does.",
              "硬解只作用于带视频轨的源文件。纯音频转码靠 CPU，开了也不会更快。不在适配名单里的芯片，硬解可能失败，失败就切回软件。",
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _dropdownRow<int>(
            S.t("Encoder threads", "编码线程"),
            _settings.threads,
            [
              (
                0,
                S.t(
                  "Auto (${device?.suggestedThreads ?? 4} recommended)",
                  "自动（推荐 ${device?.suggestedThreads ?? 4}）",
                ),
              ),
              (1, S.t("1 thread", "1 线程")),
              (2, S.t("2 threads", "2 线程")),
              (4, S.t("4 threads", "4 线程")),
              (6, S.t("6 threads", "6 线程")),
              (8, S.t("8 threads", "8 线程")),
            ],
            (int v) => setState(() => _settings.threads = v),
          ),
        ],
      ),
    );
  }

  Widget _advancedPanel() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _advancedOpen,
          onExpansionChanged: (bool v) => _advancedOpen = v,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          title: Text(
            S.t("More options", "更多选项"),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          children: [
            _dropdownRow<int>(
              S.t("Sample rate", "采样率"),
              _settings.sampleRate,
              [
                (0, S.t("Keep source", "保持原样")),
                (22050, "22.05 kHz"),
                (32000, "32 kHz"),
                (44100, "44.1 kHz"),
                (48000, "48 kHz"),
              ],
              (int v) => setState(() => _settings.sampleRate = v),
            ),
            const SizedBox(height: 12),
            _dropdownRow<int>(
              S.t("Channels", "声道"),
              _settings.channels,
              [
                (0, S.t("Keep source", "保持原样")),
                (1, S.t("Mono", "单声道")),
                (2, S.t("Stereo", "立体声")),
              ],
              (int v) => setState(() => _settings.channels = v),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _settings.voiceOptimization,
              onChanged: (bool v) => setState(() => _settings.voiceOptimization = v),
              title: Text(S.t("Reduce background noise, favour voice", "降低背景噪声，优化人声")),
              subtitle: Text(
                S.t(
                  "Bundled RNNoise model. Good for podcasts and recordings.",
                  "内置 RNNoise 模型，适合播客和录音。",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownRow<T>(
    String label,
    T value,
    List<(T, String)> items,
    ValueChanged<T> onChanged,
  ) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              alignment: Alignment.centerRight,
              borderRadius: BorderRadius.circular(20),
              selectedItemBuilder: (BuildContext context) => items
                  .map(
                    (item) => Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item.$1,
                      child: Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (T? v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String barKey = _publishing
        ? "publishing"
        : _converting
        ? "converting"
        : _finished && _showFinishedBar && _results.isNotEmpty
        ? "done"
        : "idle";
    final bool allSaved =
        _finished &&
        _showFinishedBar &&
        _results.isNotEmpty &&
        _results.any((ConvertOutcome r) => r.ok) &&
        _outputTarget != null &&
        _results
            .where((ConvertOutcome r) => r.ok)
            .every((ConvertOutcome r) => r.published);
    final String summary = _publishing
        ? S.t("Saving to the folder…", "正在存到文件夹…")
        : _converting
        ? S.t(
            "Converting ${_activeIndex + 1} of ${_files.length}",
            "正在转换 ${_activeIndex + 1}/${_files.length}",
          )
        : _files.isEmpty
        ? S.t("Add a file to start", "先加文件")
        : "${_files.length} × ${_settings.format.label}${_settings.format.lossless ? "" : (_settings.vbr && _settings.format.hasVbr ? " · VBR" : " · ${_settings.bitrate} kbps")}";

    return ClipRRect(
      key: ValueKey<String>(barKey),
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _publishing
                          ? S.t("Saving to the folder…", "正在存到文件夹…")
                          : _finished && _showFinishedBar && _results.isNotEmpty
                          ? (allSaved ? S.t("Done", "已完成") : S.t("Done", "转换完成"))
                          : summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_converting) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _activeProgress,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (_publishing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              else if (_converting)
                IconButton.filledTonal(
                  onPressed: _confirmStop,
                  icon: const Icon(Icons.stop_rounded),
                  tooltip: S.t("Stop", "停止"),
                )
              else if (_finished && _showFinishedBar && _results.isNotEmpty)
                allSaved
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              S.t("Done", "已完成"),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: scheme.primary),
                            ),
                          ],
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: _shareAll,
                        icon: const Icon(Icons.ios_share_rounded),
                        label: Text(S.t("Share all", "分享全部")),
                      )
              else
                FilledButton.icon(
                  onPressed: _files.isEmpty ? null : _start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(S.t("Start", "开始")),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultsSummaryCard() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey<String>("results-collapsed"),
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _resultsTimer?.cancel();
            setState(() => _resultsExpanded = true);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: scheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    S.t(
                      "${_results.length} result(s) · saved",
                      "${_results.length} 个结果 · 已保存",
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultsCard() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey<String>("results-expanded"),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _collapseResults,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.t("Results", "转换结果"),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._results.asMap().entries.map((entry) {
            final int index = entry.key;
            final ConvertOutcome r = entry.value;
            final String name = r.ok
                ? (r.publishedName ?? p.basename(r.outputPath!))
                : r.input.filename;
            final int? size =
                r.bytes ??
                (r.ok && File(r.outputPath!).existsSync()
                    ? File(r.outputPath!).lengthSync()
                    : null);
            final String sizeText = intToSize(size) ?? "";
            return ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: r.published ? () => _removeResultAt(index) : null,
              leading: Icon(
                r.published
                    ? Icons.check_circle_rounded
                    : (r.ok ? Icons.audio_file_rounded : Icons.error_outline_rounded),
                color: r.ok ? scheme.primary : scheme.error,
              ),
              title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                r.ok
                    ? (r.published ? "$sizeText · ${S.t("Saved", "已保存")}" : sizeText)
                    : (r.error ?? S.t("Failed", "失败")),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: r.ok
                  ? (r.published
                        ? TextButton(
                            onPressed: () => _removeResultAt(index),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(
                              S.t("Done", "已完成"),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: scheme.primary),
                            ),
                          )
                        : IconButton(
                            onPressed: () => _shareOutcome(r),
                            icon: const Icon(Icons.ios_share_rounded),
                            tooltip: S.t("Share", "分享"),
                          ))
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

/// A slider that behaves normally on a quick drag and switches to a slower
/// "fine" response when the user presses and holds first, then moves. Same
/// idea as the press-and-drag sliders in iOS: hold, then slide, and the value
/// moves at 35% speed so one pixel is not one kbps.
class FineSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String valueLabel;

  const FineSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.valueLabel,
    this.divisions,
  });

  @override
  State<FineSlider> createState() => _FineSliderState();
}

class _FineSliderState extends State<FineSlider> {
  bool _fine = false;
  double _startValue = 0;
  double _originX = 0;
  double _width = 1;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (LongPressStartDetails details) {
            _width = width;
            _originX = details.localPosition.dx;
            _startValue = widget.value;
            HapticFeedback.mediumImpact();
            setState(() => _fine = true);
          },
          onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
            final double range = widget.max - widget.min;
            final double delta =
                (details.localPosition.dx - _originX) / _width * range * 0.35;
            final double next = (_startValue + delta).clamp(widget.min, widget.max);
            widget.onChanged(next);
          },
          onLongPressEnd: (_) => setState(() => _fine = false),
          onLongPressCancel: () => setState(() => _fine = false),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Slider(
                value: widget.value.clamp(widget.min, widget.max),
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                onChanged: widget.onChanged,
              ),
              if (_fine)
                Positioned(
                  top: -2,
                  right: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.valueLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
