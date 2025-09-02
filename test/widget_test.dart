import 'package:flutter_test/flutter_test.dart';
import 'package:scanairz/main.dart';

void main() {
  testWidgets('Welcome screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanairzApp());
    expect(find.text('Scanairz'), findsOneWidget);
    expect(find.text('Professional Barcode Scanner'), findsOneWidget);
  });
}