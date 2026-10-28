import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:aligned_tooltip/src/positioned_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// Shows a tooltip whose target is placed at [targetTopLeft] in an 800x600
/// screen and returns the global rect of its content.
Future<Rect> showTooltipAt(
  WidgetTester tester, {
  Offset targetTopLeft = const Offset(380, 280),
  Size targetSize = kTargetSize,
  Size contentSize = kContentSize,
  AxisDirection preferredDirection = AxisDirection.down,
  EdgeInsetsGeometry margin = const EdgeInsets.all(8.0),
  double offset = 0.0,
  double tailLength = 16.0,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final controller = AlignedTooltipController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    app(
      topLeft: targetTopLeft,
      AlignedTooltip(
        controller: controller,
        preferredDirection: preferredDirection,
        margin: margin,
        offset: offset,
        tailLength: tailLength,
        textDirection: textDirection,
        content: content(contentSize),
        child: target(targetSize),
      ),
    ),
  );
  controller.showTooltip();
  await tester.pump(Duration.zero);
  await tester.pump(kFadeIn);
  return tester.getRect(contentFinder);
}

void main() {
  group('places the tooltip next to the target', () {
    // The target is 40x40 and centered at (400, 300). The content is 100x40.
    testWidgets('below', (tester) async {
      final rect = await showTooltipAt(tester);
      expect(rect, const Rect.fromLTWH(350, 336, 100, 40));
      // The tail fills the space between the target and the content.
      expect(rect.top - tester.getRect(find.byKey(targetKey)).bottom, 16);
    });

    testWidgets('above', (tester) async {
      final rect = await showTooltipAt(
        tester,
        preferredDirection: AxisDirection.up,
      );
      expect(rect, const Rect.fromLTWH(350, 224, 100, 40));
    });

    testWidgets('left', (tester) async {
      final rect = await showTooltipAt(
        tester,
        preferredDirection: AxisDirection.left,
      );
      expect(rect, const Rect.fromLTWH(264, 280, 100, 40));
    });

    testWidgets('right', (tester) async {
      final rect = await showTooltipAt(
        tester,
        preferredDirection: AxisDirection.right,
      );
      expect(rect, const Rect.fromLTWH(436, 280, 100, 40));
    });
  });

  group('offset and tailLength', () {
    for (final (direction, expected) in [
      (AxisDirection.down, const Rect.fromLTWH(350, 346, 100, 40)),
      (AxisDirection.up, const Rect.fromLTWH(350, 214, 100, 40)),
      (AxisDirection.left, const Rect.fromLTWH(254, 280, 100, 40)),
      (AxisDirection.right, const Rect.fromLTWH(446, 280, 100, 40)),
    ]) {
      testWidgets('offset is added to the tail length ($direction)',
          (tester) async {
        final rect = await showTooltipAt(
          tester,
          preferredDirection: direction,
          offset: 10,
        );
        expect(rect, expected);
      });
    }

    testWidgets('no tail and no offset', (tester) async {
      final rect = await showTooltipAt(tester, tailLength: 0);
      expect(rect, const Rect.fromLTWH(350, 320, 100, 40));
    });
  });

  group('falls back to the opposite side', () {
    testWidgets('up -> down at the top edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(380, 0),
        preferredDirection: AxisDirection.up,
      );
      expect(rect, const Rect.fromLTWH(350, 56, 100, 40));
    });

    testWidgets('down -> up at the bottom edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(380, 560),
      );
      expect(rect, const Rect.fromLTWH(350, 504, 100, 40));
    });

    testWidgets('left -> right at the left edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(0, 280),
        preferredDirection: AxisDirection.left,
      );
      expect(rect, const Rect.fromLTWH(56, 280, 100, 40));
    });

    testWidgets('right -> left at the right edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(760, 280),
        preferredDirection: AxisDirection.right,
      );
      expect(rect, const Rect.fromLTWH(644, 280, 100, 40));
    });

    testWidgets(
        'keeps the preferred side and shrinks the content when neither fits',
        (tester) async {
      final below = await showTooltipAt(
        tester,
        contentSize: const Size(100, 400),
      );
      // 600 - 300 (target center) - 20 (half target) - 16 (tail) - 8 (margin)
      expect(below, const Rect.fromLTWH(350, 336, 100, 256));

      final above = await showTooltipAt(
        tester,
        contentSize: const Size(100, 400),
        preferredDirection: AxisDirection.up,
      );
      expect(above, const Rect.fromLTWH(350, 8, 100, 256));
    });
  });

  group('stays within the margin near screen edges', () {
    testWidgets('below, at the left edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(0, 280),
      );
      expect(rect, const Rect.fromLTWH(8, 336, 100, 40));
    });

    testWidgets('below, at the right edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(760, 280),
      );
      expect(rect, const Rect.fromLTWH(692, 336, 100, 40));
    });

    testWidgets('right, at the top edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(380, 0),
        preferredDirection: AxisDirection.right,
      );
      expect(rect, const Rect.fromLTWH(436, 8, 100, 40));
    });

    testWidgets('right, close to the top edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(380, 5),
        preferredDirection: AxisDirection.right,
      );
      expect(rect, const Rect.fromLTWH(436, 8, 100, 40));
    });

    testWidgets('left, close to the bottom edge', (tester) async {
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(380, 554),
        preferredDirection: AxisDirection.left,
      );
      expect(rect, const Rect.fromLTWH(264, 552, 100, 40));
    });

    testWidgets('content wider than the screen is constrained', (tester) async {
      final rect = await showTooltipAt(
        tester,
        contentSize: const Size(900, 40),
      );
      expect(rect, const Rect.fromLTWH(8, 336, 784, 40));
    });

    testWidgets('asymmetric margins', (tester) async {
      const margin = EdgeInsets.fromLTRB(30, 8, 4, 8);
      final right = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(760, 280),
        margin: margin,
      );
      expect(right, const Rect.fromLTWH(696, 336, 100, 40));

      final left = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(0, 280),
        margin: margin,
      );
      expect(left, const Rect.fromLTWH(30, 336, 100, 40));
    });

    testWidgets('directional margins are resolved with textDirection',
        (tester) async {
      const margin = EdgeInsetsDirectional.fromSTEB(30, 8, 4, 8);
      final rect = await showTooltipAt(
        tester,
        targetTopLeft: const Offset(0, 280),
        margin: margin,
        textDirection: TextDirection.rtl,
      );
      expect(rect, const Rect.fromLTWH(4, 336, 100, 40));
    });
  });

  testWidgets('paints the bubble and the tail', (tester) async {
    await showTooltipAt(tester);
    final renderObject = tester.renderObject(find.byType(PositionedTooltip));
    expect(
      renderObject,
      paints
        ..shadow()
        ..path(
          includes: const [
            // Inside the bubble.
            Offset(355, 340),
            // Inside the tail, between the target and the bubble.
            Offset(400, 330),
          ],
          excludes: const [
            // Next to the tail.
            Offset(380, 330),
            Offset(420, 330),
            // Above the tip of the tail.
            Offset(400, 318),
          ],
        ),
    );
  });

  testWidgets('follows the target when it moves', (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final controller = AlignedTooltipController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          controller: scrollController,
          children: [
            const SizedBox(height: 280),
            Center(
              child: AlignedTooltip(
                controller: controller,
                content: content(),
                child: target(),
              ),
            ),
            const SizedBox(height: 1000),
          ],
        ),
      ),
    );
    controller.showTooltip();
    await tester.pump(Duration.zero);
    await tester.pump(kFadeIn);
    expect(
      tester.getRect(contentFinder),
      const Rect.fromLTWH(350, 336, 100, 40),
    );

    scrollController.jumpTo(100);
    await tester.pump();
    expect(
      tester.getRect(contentFinder),
      const Rect.fromLTWH(350, 236, 100, 40),
    );
  });

  group('with a scrollController', () {
    Future<Rect> showInList(
      WidgetTester tester, {
      required bool passScrollController,
    }) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final controller = AlignedTooltipController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: 500),
              Center(
                child: AlignedTooltip(
                  controller: controller,
                  scrollController:
                      passScrollController ? scrollController : null,
                  content: content(const Size(100, 550)),
                  child: target(),
                ),
              ),
              const SizedBox(height: 1000),
            ],
          ),
        ),
      );
      controller.showTooltip();
      await tester.pump(Duration.zero);
      await tester.pump(kFadeIn);
      return tester.getRect(contentFinder);
    }

    testWidgets('without it the content is constrained to the screen',
        (tester) async {
      final rect = await showInList(tester, passScrollController: false);
      // 600 - 520 (target center) - 20 (half target) - 16 (tail) - 8 (margin)
      expect(rect, const Rect.fromLTWH(350, 556, 100, 36));
    });

    testWidgets('with it the content may use the scrollable space',
        (tester) async {
      final rect = await showInList(tester, passScrollController: true);
      expect(rect, const Rect.fromLTWH(350, 556, 100, 550));
    });
  });

  testWidgets('positions the tooltip relative to the screen', (tester) async {
    final controller = AlignedTooltipController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: Stack(
            children: [
              Positioned(
                left: 380,
                top: 224,
                child: AlignedTooltip(
                  controller: controller,
                  content: content(),
                  child: target(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getRect(find.byKey(targetKey)),
      const Rect.fromLTWH(380, 280, 40, 40),
    );

    controller.showTooltip();
    await tester.pump(Duration.zero);
    await tester.pump(kFadeIn);
    expect(
      tester.getRect(contentFinder),
      const Rect.fromLTWH(350, 336, 100, 40),
    );
  });

  testWidgets('list tile targets', (tester) async {
    final controller = AlignedTooltipController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: [
              AlignedTooltip(
                controller: controller,
                content: content(),
                child: const ListTile(title: Text('tile')),
              ),
            ],
          ),
        ),
      ),
    );
    controller.showTooltip();
    await tester.pump(Duration.zero);
    await tester.pump(kFadeIn);
    expect(tester.takeException(), isNull);
    final tile = tester.getRect(find.byType(ListTile));
    final rect = tester.getRect(contentFinder);
    expect(rect.top, tile.bottom + 16);
    expect(rect.center.dx, tile.center.dx);
  });
}
