import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:simple_audio_converter/main.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("audio_converter/device"),
          (MethodCall call) async {
            if (call.method == "info") {
              return <String, String>{
                "manufacturer": "MediaTek",
                "model": "Test Device",
                "sdkInt": "36",
                "cores": "8",
                "is64Bit": "true",
                "socModel": "MT6991",
                "ro.board.platform": "mt6991",
                "ro.build.version.release": "16",
              };
            }
            return null;
          },
        );
  });

  testWidgets("home renders and formats filter", (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimbreApp());
    await tester.pumpAndSettle();

    expect(find.text("Timbre 64 位"), findsWidgets);

    // Everyday list contains MP3 and M4A.
    expect(find.text("M4A (AAC)"), findsOneWidget);

    await tester.tap(find.text("Lossless"));
    await tester.pumpAndSettle();
    expect(find.text("FLAC"), findsOneWidget);
    expect(find.text("WAV"), findsOneWidget);
    expect(find.text("MP3"), findsNothing);

    await tester.tap(find.text("FLAC"));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text("Lossless: bitrate does not apply"), findsOneWidget);

    // Back to Everyday, then exercise the CBR/VBR switch.
    await tester.tap(find.text("Everyday"));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text("MP3"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("VBR"));
    await tester.pumpAndSettle();
    expect(find.textContaining("Quality"), findsOneWidget);
    await tester.tap(find.text("CBR"));
    await tester.pumpAndSettle();
    expect(find.textContaining("kbps"), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets("settings opens and changes accent colour", (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimbreApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text("Accent colour"), findsOneWidget);
    expect(find.text("Language"), findsOneWidget);

    await tester.tap(find.text("Cobalt"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets("narrow split-window layout stays clean", (WidgetTester tester) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimbreApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets("format sheet scrolls to presets", (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimbreApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.longPress(find.text("MP3"));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text("High quality"),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text("Recommended presets"), findsOneWidget);
    await tester.ensureVisible(find.text("High quality"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("High quality"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets("fine slider long-press micro adjust", (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 800);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    double value = 128;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Center(
                child: FineSlider(
                  value: value,
                  min: 8,
                  max: 320,
                  divisions: 312,
                  valueLabel: "${value.round()} kbps",
                  onChanged: (double v) => setState(() => value = v),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(FineSlider)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();
    expect(value, greaterThan(128));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets("mp3 shows a version selector", (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimbreApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.tap(find.text("MP3"));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text("Version"), findsOneWidget);
    expect(find.text("MPEG-1"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("format reference expands into plain detail", (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimbreApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining("All 18 formats"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("MP3").last);
    await tester.pumpAndSettle();
    expect(find.textContaining("Old stereos, car units"), findsOneWidget);
    expect(find.textContaining("LHDC"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("sound panel exposes gain and loudness matching", (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimbreApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text("Overall level"), findsOneWidget);
    expect(find.text("Match loudness across files"), findsOneWidget);
    await tester.tap(find.text("Match loudness across files"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
