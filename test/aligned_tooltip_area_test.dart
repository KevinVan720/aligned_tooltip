import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// An [AlignedTooltipArea] that fills the screen and places [children] in a
/// [Stack] below the scrim and the tooltip.
Widget area(List<Widget> children) {
  return MaterialApp(
    home: AlignedTooltipArea(
      builder: (context, tooltip, scrim) {
        return Stack(
          fit: StackFit.passthrough,
          children: [
            Stack(children: children),
            scrim,
            tooltip,
          ],
        );
      },
    ),
  );
}

Future<void> pumpShowTimer(WidgetTester tester) async {
  await tester.pump(Duration.zero);
  await tester.pump();
}

void main() {
  testWidgets('a modal entry shows its content in the tooltip slot',
      (tester) async {
    var shown = 0;
    var dismissed = 0;
    await tester.pumpWidget(
      area([
        Positioned(
          left: 380,
          top: 280,
          child: AlignedTooltipEntry(
            isModal: true,
            onShow: () => shown++,
            onDismiss: () => dismissed++,
            content: content(),
            child: target(),
          ),
        ),
      ]),
    );
    expect(contentFinder, findsNothing);

    await tester.tap(find.byKey(targetKey));
    await pumpShowTimer(tester);
    expect(contentFinder, findsOneWidget);
    await tester.pump(kFadeIn);
    expect(contentOpacity(tester), 1.0);
    expect(shown, 1);
    expect(
      tester.getRect(contentFinder),
      const Rect.fromLTWH(350, 336, 100, 40),
    );

    // Stays open until the scrim is tapped.
    await pumpFor(tester, const Duration(seconds: 5));
    expect(contentFinder, findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(kFadeOut);
    await tester.pump();
    expect(contentFinder, findsNothing);
    expect(dismissed, 1);
  });

  testWidgets(
      'tapping the scrim hides a modal entry '
      'even with barrierDismissible: false', (tester) async {
    await tester.pumpWidget(
      area([
        Positioned(
          left: 380,
          top: 280,
          child: AlignedTooltipEntry(
            isModal: true,
            barrierDismissible: false,
            content: content(),
            child: target(),
          ),
        ),
      ]),
    );

    await tester.tap(find.byKey(targetKey));
    await pumpShowTimer(tester);
    await tester.pump(kFadeIn);
    expect(contentFinder, findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(kFadeOut);
    await tester.pump();
    expect(contentFinder, findsNothing);
  });

  testWidgets('a non-modal entry is shown on long press', (tester) async {
    await tester.pumpWidget(
      area([
        Positioned(
          left: 380,
          top: 280,
          child: AlignedTooltipEntry(content: content(), child: target()),
        ),
      ]),
    );

    await tester.longPress(find.byKey(targetKey));
    await tester.pump(kFadeIn);
    expect(contentFinder, findsOneWidget);
    expect(
      tester.getRect(contentFinder),
      const Rect.fromLTWH(350, 336, 100, 40),
    );

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(kFadeOut);
    await tester.pump();
    expect(contentFinder, findsNothing);
  });

  testWidgets('can be shown and hidden with a controller', (tester) async {
    final controller = AlignedTooltipController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      area([
        Positioned(
          left: 380,
          top: 280,
          child: AlignedTooltipEntry(
            controller: controller,
            content: content(),
            child: target(),
          ),
        ),
      ]),
    );

    controller.showTooltip();
    await pumpShowTimer(tester);
    await tester.pump(kFadeIn);
    expect(contentFinder, findsOneWidget);
    expect(controller.value, TooltipStatus.isShowing);

    controller.hideTooltip(immediately: true);
    await tester.pump();
    expect(contentFinder, findsNothing);
    expect(controller.value, TooltipStatus.isHidden);
  });

  testWidgets('rebuilding an entry that is not shown does not show it',
      (tester) async {
    var taps = 0;
    late StateSetter setState;
    await tester.pumpWidget(
      area([
        StatefulBuilder(
          builder: (context, stateSetter) {
            setState = stateSetter;
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                    child: const SizedBox(width: 50, height: 50),
                  ),
                ),
                Positioned(
                  left: 380,
                  top: 280,
                  child: AlignedTooltipEntry(
                    isModal: true,
                    content: content(),
                    child: target(),
                  ),
                ),
              ],
            );
          },
        ),
      ]),
    );

    setState(() {});
    await tester.pump();
    await tester.pump();
    expect(contentFinder, findsNothing);

    // Nothing blocks the widgets below the area.
    await tester.tapAt(const Offset(10, 10));
    expect(taps, 1);
  });

  testWidgets('rebuilding a visible entry updates its content', (tester) async {
    final controller = AlignedTooltipController();
    addTearDown(controller.dispose);
    Widget build(String text) {
      return area([
        Positioned(
          left: 380,
          top: 280,
          child: AlignedTooltipEntry(
            controller: controller,
            content: Text(text),
            child: target(),
          ),
        ),
      ]);
    }

    await tester.pumpWidget(build('first'));
    controller.showTooltip();
    await pumpShowTimer(tester);
    await tester.pump(kFadeIn);
    expect(find.text('first'), findsOneWidget);

    await tester.pumpWidget(build('second'));
    await tester.pump();
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('disposing another entry keeps the visible tooltip',
      (tester) async {
    final controller = AlignedTooltipController();
    addTearDown(controller.dispose);
    var otherDismissed = 0;
    Widget build({required bool showOther}) {
      return area([
        Positioned(
          left: 380,
          top: 280,
          child: AlignedTooltipEntry(
            controller: controller,
            content: content(),
            child: target(),
          ),
        ),
        if (showOther)
          Positioned(
            left: 0,
            top: 0,
            child: AlignedTooltipEntry(
              onDismiss: () => otherDismissed++,
              content: const Text('other'),
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
      ]);
    }

    await tester.pumpWidget(build(showOther: true));
    controller.showTooltip();
    await pumpShowTimer(tester);
    await tester.pump(kFadeIn);
    expect(contentFinder, findsOneWidget);

    await tester.pumpWidget(build(showOther: false));
    await tester.pump();
    expect(contentFinder, findsOneWidget);
    expect(controller.value, TooltipStatus.isShowing);
    expect(otherDismissed, 0);
  });

  testWidgets('disposing the visible entry removes the tooltip',
      (tester) async {
    var dismissed = 0;
    final controller = AlignedTooltipController();
    addTearDown(controller.dispose);
    Widget build({required bool showEntry}) {
      return area([
        if (showEntry)
          Positioned(
            left: 380,
            top: 280,
            child: AlignedTooltipEntry(
              isModal: true,
              controller: controller,
              onDismiss: () => dismissed++,
              content: content(),
              child: target(),
            ),
          ),
      ]);
    }

    await tester.pumpWidget(build(showEntry: true));
    controller.showTooltip();
    await pumpShowTimer(tester);
    await tester.pump(kFadeIn);
    expect(contentFinder, findsOneWidget);

    await tester.pumpWidget(build(showEntry: false));
    await tester.pump();
    expect(contentFinder, findsNothing);
    expect(dismissed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing the area while a tooltip is visible', (tester) async {
    final controller = AlignedTooltipController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      area([
        Positioned(
          left: 380,
          top: 280,
          child: AlignedTooltipEntry(
            controller: controller,
            content: content(),
            child: target(),
          ),
        ),
      ]),
    );
    controller.showTooltip();
    await pumpShowTimer(tester);
    await tester.pump(kFadeIn);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(contentFinder, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AlignedTooltipArea.of and maybeOf', (tester) async {
    BuildContext? inside;
    BuildContext? outside;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Builder(
              builder: (context) {
                outside = context;
                return const SizedBox();
              },
            ),
            Expanded(
              child: AlignedTooltipArea(
                builder: (context, tooltip, scrim) {
                  inside = context;
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(AlignedTooltipArea.maybeOf(outside!), isNull);
    expect(AlignedTooltipArea.maybeOf(inside!), isNotNull);
    expect(AlignedTooltipArea.of(inside!), AlignedTooltipArea.maybeOf(inside!));
    expect(() => AlignedTooltipArea.of(outside!), throwsFlutterError);
  });
}
