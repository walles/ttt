import 'package:flutter_test/flutter_test.dart';

import 'package:ttt/main.dart';

void main() {
  testWidgets('Find start button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TttApp());

    // Verify that our counter starts at 0.
    expect(find.text('Timed Times Tables'), findsOneWidget);
  });
}
