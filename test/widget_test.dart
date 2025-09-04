
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanairz/main.dart';

void main() {
  testWidgets('App main widget renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ScanairzApp()));

    // Verify that the main app widget is present.
    expect(find.byType(ScanairzApp), findsOneWidget);
  });
}
