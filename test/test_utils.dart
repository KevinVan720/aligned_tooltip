import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Key of the widget the tooltip is attached to.
const Key targetKey = Key('target');

/// Key of the tooltip content.
const Key contentKey = Key('content');

/// Default size of the target in tests.
const Size kTargetSize = Size(40, 40);

/// Default size of the tooltip content in tests.
const Size kContentSize = Size(100, 40);

/// Time after which the default fade in animation (150ms) has completed.
///
/// Animations complete on the first frame strictly after their duration.
const Duration kFadeIn = Duration(milliseconds: 151);

/// Time after which the default fade out animation (75ms) has completed.
const Duration kFadeOut = Duration(milliseconds: 76);

/// A target with a fixed size.
Widget target([Size size = kTargetSize]) {
  return SizedBox.fromSize(
    key: targetKey,
    size: size,
    child: const ColoredBox(color: Color(0x00000000)),
  );
}

/// Tooltip content with a fixed size.
Widget content([Size size = kContentSize]) {
  return SizedBox.fromSize(key: contentKey, size: size);
}

/// Wraps [child] in a [MaterialApp] and places it at [topLeft] in an 800x600
/// screen.
Widget app(
  Widget child, {
  Offset topLeft = const Offset(380, 280),
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    home: Stack(
      children: [
        Positioned(left: topLeft.dx, top: topLeft.dy, child: child),
      ],
    ),
  );
}

/// Pumps frames every [step] for [duration], so that animations started
/// during that time are run as well.
Future<void> pumpFor(
  WidgetTester tester,
  Duration duration, {
  Duration step = const Duration(milliseconds: 20),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    final remaining = duration - elapsed;
    final next = remaining < step ? remaining : step;
    await tester.pump(next);
    elapsed += next;
  }
}

/// Finds the tooltip content.
Finder get contentFinder => find.byKey(contentKey);

/// Opacity of the fade transition that wraps the tooltip content.
double contentOpacity(WidgetTester tester) {
  final fades = tester.widgetList<FadeTransition>(
    find.ancestor(of: contentFinder, matching: find.byType(FadeTransition)),
  );
  return fades.fold<double>(1.0, (value, fade) => value * fade.opacity.value);
}

/// Records the calls to the platform channel used for haptic and acoustic
/// feedback.
List<MethodCall> recordFeedback(WidgetTester tester) {
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate' ||
          call.method == 'SystemSound.play') {
        calls.add(call);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}
