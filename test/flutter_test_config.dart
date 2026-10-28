import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Configuration shared by all the tests of this package.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Undisposed controllers, overlay entries, animations, etc. fail the test
  // that created them.
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings.withIgnored(
    createdByTestHelpers: true,
  );

  // Verifies that the intrinsic and dry layout sizes of the render objects
  // are consistent with their actual layout.
  debugCheckIntrinsicSizes = true;

  // Make tap() et al fail if the given finder specifies a widget that would
  // not receive the event.
  WidgetController.hitTestWarningShouldBeFatal = true;

  await testMain();
}
