import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets the zero-duration show timer of a tapped tooltip fire and its fade in
/// animation complete.
Future<void> pumpShow(WidgetTester tester) async {
  await tester.pump(Duration.zero);
  await tester.pump(const Duration(milliseconds: 200));
}

/// Taps the barrier of a modal tooltip, next to the left edge of the screen
/// where the tooltips never are because of their margin, and waits until the
/// tooltip is hidden.
Future<void> tapBarrier(WidgetTester tester) async {
  await tester.tapAt(const Offset(2, 300));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

void main() {
  testWidgets('home page lists the examples', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Example app'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'default'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'scroll'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'tooltipArea'), findsOneWidget);
  });

  testWidgets('default page shows the tooltip after two seconds',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('default'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sed ut perspiciatis'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Sed ut perspiciatis'), findsOneWidget);

    // The tooltip is modal: tapping outside of it hides it.
    await tapBarrier(tester);
    expect(find.textContaining('Sed ut perspiciatis'), findsNothing);

    // The floating buttons use the controller.
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Sed ut perspiciatis'), findsOneWidget);

    await tapBarrier(tester);
    expect(find.textContaining('Sed ut perspiciatis'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Example app'), findsOneWidget);
  });

  testWidgets('leaving the default page before the tooltip is shown',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('default'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Example app'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll page shows the tooltip of the list item', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('scroll'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byIcon(Icons.touch_app), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.touch_app));
    await pumpShow(tester);
    expect(find.textContaining('Quia ducimus'), findsOneWidget);

    await tapBarrier(tester);
    expect(find.textContaining('Quia ducimus'), findsNothing);
  });

  testWidgets('tooltip area page shows the tooltip below the app bar',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('tooltipArea'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byIcon(Icons.touch_app), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.touch_app));
    await pumpShow(tester);
    expect(find.text('exercises'), findsOneWidget);
    expect(find.text('course'), findsOneWidget);

    await tapBarrier(tester);
    expect(find.text('exercises'), findsNothing);
  });
}
