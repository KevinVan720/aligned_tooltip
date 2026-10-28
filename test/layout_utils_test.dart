import 'package:aligned_tooltip/src/utils/get_axis_direction.dart';
import 'package:aligned_tooltip/src/utils/get_position_dependent_offset.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const size = Size(800, 600);
  const targetSize = Size(40, 40);
  const childSize = Size(100, 40);
  const margin = EdgeInsets.all(8);

  group('getAxisDirection', () {
    AxisDirection direction(
      Offset target,
      AxisDirection preferredDirection, {
      Size childSize = childSize,
    }) {
      return getAxisDirection(
        size: size,
        targetSize: targetSize,
        childSize: childSize,
        target: target,
        preferredDirection: preferredDirection,
        offsetAndTail: 16,
        margin: margin,
        scrollPosition: null,
      );
    }

    test('keeps the preferred direction when there is enough space', () {
      for (final preferred in AxisDirection.values) {
        expect(direction(const Offset(400, 300), preferred), preferred);
      }
    });

    test('uses the opposite direction when there is not enough space', () {
      expect(
        direction(const Offset(400, 20), AxisDirection.up),
        AxisDirection.down,
      );
      expect(
        direction(const Offset(400, 580), AxisDirection.down),
        AxisDirection.up,
      );
      expect(
        direction(const Offset(20, 300), AxisDirection.left),
        AxisDirection.right,
      );
      expect(
        direction(const Offset(780, 300), AxisDirection.right),
        AxisDirection.left,
      );
    });

    test('keeps the preferred direction when no side has enough space', () {
      const tall = Size(100, 500);
      expect(
        direction(const Offset(400, 300), AxisDirection.up, childSize: tall),
        AxisDirection.up,
      );
      expect(
        direction(const Offset(400, 300), AxisDirection.down, childSize: tall),
        AxisDirection.down,
      );
    });
  });

  group('getPositionDependentOffset', () {
    Offset offset(
      Offset target,
      AxisDirection axisDirection, {
      EdgeInsets margin = margin,
      Size childSize = childSize,
    }) {
      return getPositionDependentOffset(
        size: size,
        targetSize: targetSize,
        childSize: childSize,
        target: target,
        axisDirection: axisDirection,
        offsetAndTail: 16,
        margin: margin,
        scrollPosition: null,
      );
    }

    test('centers the child on the target', () {
      expect(
        offset(const Offset(400, 300), AxisDirection.down),
        const Offset(350, 336),
      );
      expect(
        offset(const Offset(400, 300), AxisDirection.up),
        const Offset(350, 224),
      );
      expect(
        offset(const Offset(400, 300), AxisDirection.left),
        const Offset(264, 280),
      );
      expect(
        offset(const Offset(400, 300), AxisDirection.right),
        const Offset(436, 280),
      );
    });

    test('keeps the child within the margins', () {
      const margin = EdgeInsets.fromLTRB(10, 20, 30, 40);
      // Horizontally, for vertical directions.
      expect(
        offset(const Offset(0, 300), AxisDirection.down, margin: margin).dx,
        10,
      );
      expect(
        offset(const Offset(800, 300), AxisDirection.down, margin: margin).dx,
        800 - 30 - 100,
      );
      // Vertically, for horizontal directions.
      expect(
        offset(const Offset(400, 0), AxisDirection.right, margin: margin).dy,
        20,
      );
      expect(
        offset(const Offset(400, 600), AxisDirection.right, margin: margin).dy,
        600 - 40 - 40,
      );
      // Below a target at the bottom of the screen.
      expect(
        offset(const Offset(400, 600), AxisDirection.down, margin: margin).dy,
        600 - 40,
      );
    });
  });
}
