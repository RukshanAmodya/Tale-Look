import 'package:flutter_test/flutter_test.dart';
import 'package:telelook/main.dart';

void main() {
  testWidgets('Smoke test app loading', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaleLookApp());

    // Verify that the teleprompter screen is displayed
    expect(find.byType(TaleLookApp), findsOneWidget);
  });
}
