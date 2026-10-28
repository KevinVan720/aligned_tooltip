import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _ensureTooltipVisible(GlobalKey key) {
  // The state of the tooltip is public so it can be used to show the tooltip.
  (key.currentState! as AlignedTooltipState).ensureTooltipVisible();
}

const String tooltipText = 'TIP';

Finder _findTooltipContainer(String tooltipText) {
  return find.ancestor(
    of: find.text(tooltipText),
    matching: find.byType(Material),
  );
}

void main() {
  testWidgets('Does tooltip end up in the right place - center',
      (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 300.0,
                      top: 0.0,
                      child: AlignedTooltip(
                        key: key,
                        offset: 20.0,
                        tailLength: 0.0,
                        content: const Text(tooltipText),
                        preferredDirection: AxisDirection.up,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    _ensureTooltipVisible(key);

    // faded in, show timer started (and at 0.0)
    await tester.pump(const Duration(seconds: 2));

    /********************* 800x600 screen
     *      o            * y=0
     *      |            * }- 20.0 vertical offset, of which 10.0 is in the screen edge margin
     *   +----+          * \- (5.0 padding in height)
     *   |    |          * |- 20 height
     *   +----+          * /- (5.0 padding in height)
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    final Offset tipInGlobal =
        tip.localToGlobal(tip.size.topCenter(Offset.zero));
    // The exact position of the left side depends on the font the test framework
    // happens to pick, so we don't test that.
    expect(tipInGlobal.dx, 300.0);
    expect(tipInGlobal.dy, 20.0);
  });

  testWidgets(
      'Does tooltip end up in the right place - center with padding outside overlay',
      (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Overlay(
            initialEntries: <OverlayEntry>[
              entry = OverlayEntry(
                builder: (BuildContext context) {
                  return Stack(
                    children: <Widget>[
                      Positioned(
                        left: 300.0,
                        top: 0.0,
                        child: AlignedTooltip(
                          key: key,
                          content: const Text(tooltipText),
                          offset: 20.0,
                          tailLength: 0.0,
                          preferredDirection: AxisDirection.up,
                          child: const SizedBox(
                            width: 0.0,
                            height: 0.0,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    _ensureTooltipVisible(key);

    // faded in, show timer started (and at 0.0)
    await tester.pump(const Duration(seconds: 2));

    /************************ 800x600 screen
     *   ________________   * }- 20.0 padding outside overlay
     *  |    o           |  * y=0
     *  |    |           |  * }- 20.0 vertical offset, of which 10.0 is in the screen edge margin
     *  | +----+         |  * \- (5.0 padding in height)
     *  | |    |         |  * |- 20 height
     *  | +----+         |  * /- (5.0 padding in height)
     *  |________________|  *
     *                      * } - 20.0 padding outside overlay
     ************************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    final Offset tipInGlobal =
        tip.localToGlobal(tip.size.topCenter(Offset.zero));
    // The exact position of the left side depends on the font the test framework
    // happens to pick, so we don't test that.
    expect(tipInGlobal.dx, 320.0);
    expect(tipInGlobal.dy, 40.0);
  });

  testWidgets('Does tooltip end up in the right place - top left',
      (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0.0,
                      top: 0.0,
                      child: AlignedTooltip(
                        key: key,
                        content: const SizedBox(width: 50, height: 20),
                        offset: 20.0,
                        tailLength: 0.0,
                        margin: const EdgeInsets.all(5.0),
                        preferredDirection: AxisDirection.up,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    _ensureTooltipVisible(key);

    // faded in, show timer started (and at 0.0)
    await tester.pump(const Duration(seconds: 2));

    /********************* 800x600 screen
     *o                  * y=0
     *|                  * }- 20.0 vertical offset
     *+----+             * \
     *|    |             * |- 20 height
     *+----+             * /
     *                   *
     *********************/

    // There is no space above the target, so the tooltip goes below it and
    // keeps the margin from the left edge of the screen.
    expect(
      tester.getRect(find.byType(SizedBox).last),
      const Rect.fromLTWH(5.0, 20.0, 50.0, 20.0),
    );
  });
}
