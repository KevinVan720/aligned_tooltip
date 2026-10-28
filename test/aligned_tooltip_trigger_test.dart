import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// Lets the zero-duration show timer fire and builds the overlay entries.
Future<void> pumpShowTimer(WidgetTester tester) async {
  await tester.pump(Duration.zero);
  await tester.pump();
}

/// Pumps until a hide that was scheduled with [delay] has fully faded out.
Future<void> pumpHide(WidgetTester tester, Duration delay) async {
  await tester.pump(delay);
  await tester.pump(kFadeOut);
  await tester.pump();
}

Future<TestGesture> hover(WidgetTester tester, Offset location) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(location);
  await tester.pump();
  return gesture;
}

void main() {
  group('long press (default trigger mode)', () {
    testWidgets('shows the tooltip and hides it after showDuration',
        (tester) async {
      final feedback = recordFeedback(tester);
      var shown = 0;
      var dismissed = 0;
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            content: content(),
            onShow: () => shown++,
            onDismiss: () => dismissed++,
            child: target(),
          ),
        ),
      );
      expect(contentFinder, findsNothing);

      await tester.longPress(find.byKey(targetKey));
      await tester.pump();
      expect(contentFinder, findsOneWidget);
      // Feedback is given as soon as the tooltip is triggered.
      expect(feedback.map((call) => call.method), ['HapticFeedback.vibrate']);
      expect(shown, 0);

      await tester.pump(kFadeIn);
      expect(contentOpacity(tester), 1.0);
      expect(shown, 1);
      expect(feedback, hasLength(1));

      // The default showDuration is 1.5 seconds after the pointer is released.
      await pumpFor(tester, const Duration(milliseconds: 1300));
      expect(contentFinder, findsOneWidget);
      expect(dismissed, 0);

      await pumpHide(tester, const Duration(milliseconds: 50));
      expect(contentFinder, findsNothing);
      expect(dismissed, 1);
      expect(shown, 1);
    });

    testWidgets('does not provide feedback when enableFeedback is false',
        (tester) async {
      final feedback = recordFeedback(tester);
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            enableFeedback: false,
            content: content(),
            child: target(),
          ),
        ),
      );

      await tester.longPress(find.byKey(targetKey));
      await tester.pump(kFadeIn);
      expect(contentFinder, findsOneWidget);
      expect(feedback, isEmpty);
      await pumpHide(tester, const Duration(seconds: 2));
    });

    testWidgets('a tap does not show the tooltip', (tester) async {
      await tester.pumpWidget(
        app(AlignedTooltip(content: content(), child: target())),
      );

      await tester.tap(find.byKey(targetKey));
      await pumpShowTimer(tester);
      expect(contentFinder, findsNothing);
    });

    testWidgets('uses showDuration', (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            showDuration: const Duration(seconds: 3),
            content: content(),
            child: target(),
          ),
        ),
      );

      await tester.longPress(find.byKey(targetKey));
      await pumpFor(tester, const Duration(milliseconds: 2900));
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 100));
      expect(contentFinder, findsNothing);
    });

    testWidgets('a pointer down elsewhere hides the tooltip immediately',
        (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            content: content(),
            onDismiss: () => dismissed++,
            child: target(),
          ),
        ),
      );

      await tester.longPress(find.byKey(targetKey));
      await tester.pump(kFadeIn);
      expect(contentFinder, findsOneWidget);

      final gesture = await tester.startGesture(const Offset(10, 10));
      await tester.pump();
      expect(contentFinder, findsNothing);
      expect(dismissed, 1);
      await gesture.up();
      await tester.pump(const Duration(seconds: 2));
      expect(dismissed, 1);
    });

    testWidgets('fades in again when re-shown after an immediate dismissal',
        (tester) async {
      await tester.pumpWidget(
        app(AlignedTooltip(content: content(), child: target())),
      );

      await tester.longPress(find.byKey(targetKey));
      await tester.pump(kFadeIn);
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(contentFinder, findsNothing);

      await tester.longPress(find.byKey(targetKey));
      await tester.pump();
      expect(contentOpacity(tester), 0.0);
      await tester.pump(kFadeIn);
      expect(contentOpacity(tester), 1.0);
      await pumpHide(tester, const Duration(seconds: 2));
    });
  });

  group('tap trigger mode', () {
    testWidgets('shows on tap and hides after showDuration', (tester) async {
      final feedback = recordFeedback(tester);
      var shown = 0;
      var dismissed = 0;
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            triggerMode: TooltipTriggerMode.tap,
            onShow: () => shown++,
            onDismiss: () => dismissed++,
            content: content(),
            child: target(),
          ),
        ),
      );

      await tester.tap(find.byKey(targetKey));
      await tester.pump();
      expect(contentFinder, findsOneWidget);
      expect(feedback.map((call) => call.method), ['SystemSound.play']);
      await tester.pump(kFadeIn);
      expect(shown, 1);
      expect(feedback, hasLength(1));

      await pumpFor(tester, const Duration(milliseconds: 1300));
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 100));
      expect(contentFinder, findsNothing);
      expect(dismissed, 1);
    });

    testWidgets('trigger mode and durations come from the TooltipTheme',
        (tester) async {
      await tester.pumpWidget(
        app(
          theme: ThemeData(
            tooltipTheme: const TooltipThemeData(
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 3),
            ),
          ),
          AlignedTooltip(content: content(), child: target()),
        ),
      );

      await tester.tap(find.byKey(targetKey));
      await pumpFor(tester, const Duration(milliseconds: 2900));
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 100));
      expect(contentFinder, findsNothing);
    });
  });

  group('manual trigger mode', () {
    testWidgets('only the controller shows the tooltip', (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            triggerMode: TooltipTriggerMode.manual,
            controller: controller,
            content: content(),
            child: target(),
          ),
        ),
      );

      await tester.tap(find.byKey(targetKey));
      await tester.longPress(find.byKey(targetKey));
      await pumpShowTimer(tester);
      expect(contentFinder, findsNothing);

      controller.showTooltip();
      await pumpShowTimer(tester);
      expect(contentFinder, findsOneWidget);
    });
  });

  group('modal', () {
    testWidgets('shows on tap and stays until the barrier is tapped',
        (tester) async {
      var shown = 0;
      var dismissed = 0;
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            isModal: true,
            controller: controller,
            onShow: () => shown++,
            onDismiss: () => dismissed++,
            content: content(),
            child: target(),
          ),
        ),
      );

      await tester.tap(find.byKey(targetKey));
      await pumpShowTimer(tester);
      expect(contentFinder, findsOneWidget);
      await tester.pump(kFadeIn);
      expect(shown, 1);
      expect(controller.value, TooltipStatus.isShowing);

      await pumpFor(tester, const Duration(seconds: 10));
      expect(contentFinder, findsOneWidget);

      // Taps on the barrier hide the tooltip after a short delay.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 100));
      expect(contentFinder, findsNothing);
      expect(dismissed, 1);
      expect(controller.value, TooltipStatus.isHidden);
    });

    testWidgets('the barrier blocks pointer events to widgets behind it',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
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
                child: AlignedTooltip(
                  isModal: true,
                  content: content(),
                  child: target(),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tapAt(const Offset(10, 10));
      expect(taps, 1);

      await tester.tap(find.byKey(targetKey));
      await pumpShowTimer(tester);
      await tester.pump(kFadeIn);

      await tester.tapAt(const Offset(10, 10));
      expect(taps, 1);
      await pumpHide(tester, const Duration(milliseconds: 100));
      expect(contentFinder, findsNothing);

      await tester.tapAt(const Offset(10, 10));
      expect(taps, 2);
    });

    testWidgets('paints the barrierColor', (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            isModal: true,
            barrierColor: const Color(0x80FF0000),
            content: content(),
            child: target(),
          ),
        ),
      );

      Finder barrier() => find.byWidgetPredicate(
            (widget) =>
                widget is ColoredBox && widget.color == const Color(0x80FF0000),
          );
      expect(barrier(), findsNothing);
      await tester.tap(find.byKey(targetKey));
      await pumpShowTimer(tester);
      expect(barrier(), findsOneWidget);
      expect(tester.getSize(barrier()), const Size(800, 600));
    });

    testWidgets('barrierBuilder can dismiss the tooltip', (tester) async {
      Animation<double>? barrierAnimation;
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            isModal: true,
            barrierBuilder: (context, animation, dismiss) {
              barrierAnimation = animation;
              return Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: dismiss,
                  child: const Text('close'),
                ),
              );
            },
            content: content(),
            child: target(),
          ),
        ),
      );

      await tester.tap(find.byKey(targetKey));
      await pumpShowTimer(tester);
      await tester.pump(kFadeIn);
      expect(barrierAnimation?.value, 1.0);

      await tester.tap(find.text('close'));
      await pumpHide(tester, const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(contentFinder, findsNothing);
      expect(find.text('close'), findsNothing);
    });

    for (final barrierDismissible in [true, false]) {
      testWidgets(
          'tapping the barrier hides the tooltip '
          '(barrierDismissible: $barrierDismissible)', (tester) async {
        var tapsBehind = 0;
        var dismissed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapsBehind++,
                    child: const SizedBox(width: 50, height: 50),
                  ),
                ),
                Positioned(
                  left: 380,
                  top: 280,
                  child: AlignedTooltip(
                    isModal: true,
                    barrierDismissible: barrierDismissible,
                    onDismiss: () => dismissed++,
                    content: content(),
                    child: target(),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.byKey(targetKey));
        await pumpShowTimer(tester);
        await tester.pump(kFadeIn);

        // The flag only changes the hit test behavior of the barrier.
        final barrier = tester.widget<GestureDetector>(
          find.byWidgetPredicate(
            (widget) =>
                widget is GestureDetector &&
                widget.child is Container &&
                (widget.child! as Container).color == Colors.transparent,
          ),
        );
        expect(
          barrier.behavior,
          barrierDismissible
              ? HitTestBehavior.translucent
              : HitTestBehavior.deferToChild,
        );

        await tester.tapAt(const Offset(10, 10));
        await pumpHide(tester, const Duration(milliseconds: 100));
        expect(contentFinder, findsNothing);
        expect(dismissed, 1);
        // Either way, the opaque barrier absorbs the tap: the widgets behind
        // it do not receive it.
        expect(tapsBehind, 0);
      });
    }
  });

  group('hover', () {
    testWidgets('shows on mouse enter and hides after mouse exit',
        (tester) async {
      var shown = 0;
      var dismissed = 0;
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            onShow: () => shown++,
            onDismiss: () => dismissed++,
            content: content(),
            child: target(),
          ),
        ),
      );

      final gesture =
          await hover(tester, tester.getCenter(find.byKey(targetKey)));
      await pumpShowTimer(tester);
      expect(contentFinder, findsOneWidget);
      await tester.pump(kFadeIn);
      expect(contentOpacity(tester), 1.0);
      expect(shown, 1);

      // Still shown while hovered.
      await pumpFor(tester, const Duration(seconds: 5));
      expect(contentFinder, findsOneWidget);

      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 90));
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 10));
      expect(contentFinder, findsNothing);
      expect(dismissed, 1);
    });

    testWidgets('waits waitDuration before showing', (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            waitDuration: const Duration(milliseconds: 500),
            content: content(),
            child: target(),
          ),
        ),
      );

      await hover(tester, tester.getCenter(find.byKey(targetKey)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(contentFinder, findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(contentFinder, findsOneWidget);
    });

    testWidgets('leaving before waitDuration does not show the tooltip',
        (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            waitDuration: const Duration(milliseconds: 500),
            content: content(),
            child: target(),
          ),
        ),
      );

      final gesture =
          await hover(tester, tester.getCenter(find.byKey(targetKey)));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(contentFinder, findsNothing);
    });

    testWidgets('showDuration also delays hiding after mouse exit',
        (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            showDuration: const Duration(seconds: 1),
            content: content(),
            child: target(),
          ),
        ),
      );

      final gesture =
          await hover(tester, tester.getCenter(find.byKey(targetKey)));
      await pumpShowTimer(tester);
      await tester.pump(kFadeIn);
      await gesture.moveTo(const Offset(10, 10));
      await pumpFor(tester, const Duration(milliseconds: 900));
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 100));
      expect(contentFinder, findsNothing);
    });

    testWidgets('hoverShowDuration delays hiding after mouse exit',
        (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            hoverShowDuration: const Duration(milliseconds: 600),
            content: content(),
            child: target(),
          ),
        ),
      );

      final gesture =
          await hover(tester, tester.getCenter(find.byKey(targetKey)));
      await pumpShowTimer(tester);
      await tester.pump(kFadeIn);
      await gesture.moveTo(const Offset(10, 10));
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 100));
      expect(contentFinder, findsNothing);
    });

    testWidgets('re-entering before the hide delay keeps the tooltip',
        (tester) async {
      await tester.pumpWidget(
        app(AlignedTooltip(content: content(), child: target())),
      );

      final center = tester.getCenter(find.byKey(targetKey));
      final gesture = await hover(tester, center);
      await pumpShowTimer(tester);
      await tester.pump(kFadeIn);

      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(center);
      await pumpShowTimer(tester);
      await pumpFor(tester, const Duration(seconds: 1));
      expect(contentFinder, findsOneWidget);
      expect(contentOpacity(tester), 1.0);
    });

    testWidgets('modal tooltips are not shown on hover', (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(isModal: true, content: content(), child: target()),
        ),
      );

      await hover(tester, tester.getCenter(find.byKey(targetKey)));
      await pumpShowTimer(tester);
      expect(contentFinder, findsNothing);
    });

    testWidgets('connecting a mouse keeps the state of the child',
        (tester) async {
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            content: content(),
            child: const _StatefulTarget(),
          ),
        ),
      );
      final state = tester.state(find.byType(_StatefulTarget));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      expect(tester.state(find.byType(_StatefulTarget)), same(state));

      await gesture.removePointer();
      await tester.pump();
      expect(tester.state(find.byType(_StatefulTarget)), same(state));
    });
  });

  group('controller', () {
    testWidgets('shows and hides the tooltip', (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      final statuses = <TooltipStatus>[];
      controller.addListener(() => statuses.add(controller.value));
      await tester.pumpWidget(
        app(
          AlignedTooltip(
            controller: controller,
            content: content(),
            child: target(),
          ),
        ),
      );
      expect(controller.value, TooltipStatus.isHidden);

      var showCompleted = false;
      controller.showTooltip().then((_) => showCompleted = true);
      await pumpShowTimer(tester);
      expect(contentFinder, findsOneWidget);
      expect(showCompleted, isFalse);
      await tester.pump(kFadeIn);
      await tester.pump();
      expect(showCompleted, isTrue);
      expect(controller.value, TooltipStatus.isShowing);

      // A tooltip shown by the controller stays visible.
      await pumpFor(tester, const Duration(seconds: 5));
      expect(contentFinder, findsOneWidget);

      controller.hideTooltip();
      await tester.pump(const Duration(milliseconds: 50));
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 50));
      expect(contentFinder, findsNothing);
      expect(controller.value, TooltipStatus.isHidden);
      expect(statuses, [TooltipStatus.isShowing, TooltipStatus.isHidden]);
    });

    testWidgets('showTooltip(immediately: true) shows on the next frame',
        (tester) async {
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

      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);

      controller.showTooltip(immediately: true);
      // The tooltip is shown after the next frame, which must be scheduled.
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump();
      await tester.pump();
      expect(contentFinder, findsOneWidget);
      await tester.pump(kFadeIn);
      expect(controller.value, TooltipStatus.isShowing);

      controller.hideTooltip(immediately: true);
      await tester.pump();
      expect(contentFinder, findsNothing);
      expect(controller.value, TooltipStatus.isHidden);
    });

    testWidgets('showTooltip(autoClose: true) hides after a delay',
        (tester) async {
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

      controller.showTooltip(autoClose: true);
      await pumpShowTimer(tester);
      await tester.pump(kFadeIn);
      expect(contentFinder, findsOneWidget);
      await pumpHide(tester, const Duration(milliseconds: 100));
      expect(contentFinder, findsNothing);
    });

    testWidgets('a pointer up elsewhere hides a non-modal tooltip',
        (tester) async {
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

      controller.showTooltip();
      await pumpShowTimer(tester);
      await tester.pump(kFadeIn);

      // A pointer down elsewhere hides the tooltip immediately.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(contentFinder, findsNothing);
      expect(controller.value, TooltipStatus.isHidden);
    });

    testWidgets('an unattached controller throws', (tester) async {
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      expect(controller.showTooltip, throwsStateError);
      expect(controller.hideTooltip, throwsStateError);
    });
  });
}

class _StatefulTarget extends StatefulWidget {
  const _StatefulTarget();

  @override
  State<_StatefulTarget> createState() => _StatefulTargetState();
}

class _StatefulTargetState extends State<_StatefulTarget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(key: targetKey, size: kTargetSize);
  }
}
