import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:aligned_tooltip/src/positioned_tooltip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

Future<void> show(
  WidgetTester tester,
  AlignedTooltipController controller,
) async {
  controller.showTooltip();
  await tester.pump(Duration.zero);
  await tester.pump(kFadeIn);
}

void main() {
  group('disposing the tooltip', () {
    testWidgets('while visible removes it and calls onDismiss', (tester) async {
      var dismissed = 0;
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            controller: controller,
            onDismiss: () => dismissed++,
            content: content(),
            child: target(),
          ),
        ),
      );
      await show(tester, controller);
      expect(contentFinder, findsOneWidget);

      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump();
      expect(contentFinder, findsNothing);
      expect(dismissed, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('while a hide timer is pending', (tester) async {
      await tester.pumpWidget(
        app(AlignedTooltip(content: content(), child: target())),
      );
      await tester.longPress(find.byKey(targetKey));
      await tester.pump(kFadeIn);
      expect(contentFinder, findsOneWidget);

      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump(const Duration(seconds: 2));
      expect(contentFinder, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('while fading in', (tester) async {
      await tester.pumpWidget(
        app(AlignedTooltip(content: content(), child: target())),
      );
      await tester.longPress(find.byKey(targetKey));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump(const Duration(seconds: 2));
      expect(contentFinder, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('while fading out', (tester) async {
      await tester.pumpWidget(
        app(AlignedTooltip(content: content(), child: target())),
      );
      await tester.longPress(find.byKey(targetKey));
      await tester.pump(const Duration(milliseconds: 1550));
      await tester.pump(const Duration(milliseconds: 20));

      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump(const Duration(seconds: 2));
      expect(contentFinder, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('while a show timer is pending', (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            waitDuration: const Duration(seconds: 1),
            content: content(),
            child: target(),
          ),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(targetKey)));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump(const Duration(seconds: 2));
      expect(contentFinder, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('before an immediate show happens', (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            controller: controller,
            content: content(),
            child: target(),
          ),
        ),
      );

      controller.showTooltip(immediately: true);
      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump();
      expect(contentFinder, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('then using its controller does nothing', (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            controller: controller,
            content: content(),
            child: target(),
          ),
        ),
      );
      await tester.pumpWidget(app(const SizedBox()));

      controller.showTooltip();
      await tester.pump(Duration.zero);
      await tester.pump();
      controller.hideTooltip(immediately: true);
      await tester.pump();
      expect(contentFinder, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not dispose a controller it does not own',
        (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      Widget build(AlignedTooltipController? controller) {
        return app(
          AlignedTooltip(
            controller: controller,
            content: content(),
            child: target(),
          ),
        );
      }

      await tester.pumpWidget(build(controller));
      await tester.pumpWidget(build(null));
      await tester.pumpWidget(app(const SizedBox()));

      // Throws if the controller was disposed.
      controller.addListener(() {});
    });
  });

  group('rebuilding the tooltip', () {
    testWidgets('while visible updates the content', (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      Widget build(String text) {
        return app(
          AlignedTooltip(
            controller: controller,
            content: Text(text),
            child: target(),
          ),
        );
      }

      await tester.pumpWidget(build('first'));
      await show(tester, controller);
      expect(find.text('first'), findsOneWidget);

      await tester.pumpWidget(build('second'));
      await tester.pump();
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('while visible updates the background color', (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      Widget build(Color color) {
        return app(
          AlignedTooltip(
            controller: controller,
            backgroundColor: color,
            content: content(),
            child: target(),
          ),
        );
      }

      await tester.pumpWidget(build(Colors.red));
      await show(tester, controller);
      expect(
        tester.renderObject(find.byType(PositionedTooltip)),
        paints
          ..shadow()
          ..path(color: Colors.red),
      );

      await tester.pumpWidget(build(Colors.blue));
      await tester.pump();
      expect(
        tester.renderObject(find.byType(PositionedTooltip)),
        paints
          ..shadow()
          ..path(color: Colors.blue),
      );
    });

    testWidgets('with a new controller attaches the new controller',
        (tester) async {
      final first = AlignedTooltipController();
      addTearDown(first.dispose);
      final second = AlignedTooltipController();
      addTearDown(second.dispose);
      Widget build(AlignedTooltipController controller) {
        return app(
          AlignedTooltip(
            controller: controller,
            content: content(),
            child: target(),
          ),
        );
      }

      await tester.pumpWidget(build(first));
      await tester.pumpWidget(build(second));
      await show(tester, second);
      expect(contentFinder, findsOneWidget);
      expect(second.value, TooltipStatus.isShowing);

      second.hideTooltip(immediately: true);
      await tester.pump();
      expect(contentFinder, findsNothing);
      expect(second.value, TooltipStatus.isHidden);
    });

    testWidgets('switching between modal and non-modal', (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      Widget build({required bool isModal}) {
        return app(
          AlignedTooltip(
            controller: controller,
            isModal: isModal,
            content: content(),
            child: target(),
          ),
        );
      }

      await tester.pumpWidget(build(isModal: false));
      await tester.pumpWidget(build(isModal: true));
      await tester.pumpWidget(build(isModal: true));
      await tester.pumpWidget(build(isModal: false));
      expect(tester.takeException(), isNull);

      // Non-modal again: long press shows the tooltip and a tap elsewhere
      // hides it.
      await tester.longPress(find.byKey(targetKey));
      await tester.pump(kFadeIn);
      expect(contentFinder, findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(contentFinder, findsNothing);

      await tester.pumpWidget(build(isModal: true));
      await tester.pumpWidget(app(const SizedBox()));
      expect(tester.takeException(), isNull);
    });
  });

  group('multiple tooltips', () {
    Widget twoTooltips({
      AlignedTooltipController? first,
      AlignedTooltipController? second,
    }) {
      return MaterialApp(
        home: Stack(
          children: [
            Positioned(
              left: 100,
              top: 100,
              child: AlignedTooltip(
                controller: first,
                content: const Text('first'),
                child: const SizedBox(
                  key: Key('a'),
                  width: 40,
                  height: 40,
                  child: ColoredBox(color: Color(0x00000000)),
                ),
              ),
            ),
            Positioned(
              left: 500,
              top: 100,
              child: AlignedTooltip(
                controller: second,
                content: const Text('second'),
                child: const SizedBox(
                  key: Key('b'),
                  width: 40,
                  height: 40,
                  child: ColoredBox(color: Color(0x00000000)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    testWidgets('long pressing another target hides the first tooltip',
        (tester) async {
      await tester.pumpWidget(twoTooltips());
      await tester.longPress(find.byKey(const Key('a')));
      await tester.pump(kFadeIn);
      expect(find.text('first'), findsOneWidget);

      await tester.longPress(find.byKey(const Key('b')));
      await tester.pump(kFadeIn);
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('moving the mouse from one target to another', (tester) async {
      await tester.pumpWidget(twoTooltips());
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byKey(const Key('a'))));
      await tester.pump(Duration.zero);
      await tester.pump(kFadeIn);
      expect(find.text('first'), findsOneWidget);

      await gesture.moveTo(tester.getCenter(find.byKey(const Key('b'))));
      await tester.pump(Duration.zero);
      await tester.pump(kFadeIn);
      expect(find.text('second'), findsOneWidget);
      // The first tooltip hides after the default hover delay.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(kFadeOut);
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('can be shown at the same time with controllers',
        (tester) async {
      final first = AlignedTooltipController();
      addTearDown(first.dispose);
      final second = AlignedTooltipController();
      addTearDown(second.dispose);
      await tester.pumpWidget(twoTooltips(first: first, second: second));

      await show(tester, first);
      await show(tester, second);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);

      first.hideTooltip(immediately: true);
      await tester.pump();
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(first.value, TooltipStatus.isHidden);
      expect(second.value, TooltipStatus.isShowing);
    });
  });

  group('semantics', () {
    testWidgets('the content is in the semantics tree while visible',
        (tester) async {
      final handle = tester.ensureSemantics();
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            controller: controller,
            content: const Text('Tooltip content'),
            child: const Text('Target'),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Target'), findsOneWidget);
      expect(find.bySemanticsLabel('Tooltip content'), findsNothing);

      await show(tester, controller);
      expect(find.bySemanticsLabel('Tooltip content'), findsOneWidget);

      controller.hideTooltip(immediately: true);
      await tester.pump();
      expect(find.bySemanticsLabel('Tooltip content'), findsNothing);
      handle.dispose();
    });

    testWidgets('does not add semantics actions to the target', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            content: const Text('Tooltip content'),
            child: const Text('Target'),
          ),
        ),
      );
      final data = tester.getSemantics(find.text('Target')).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.hasAction(SemanticsAction.longPress), isFalse);
      handle.dispose();
    });
  });
}
