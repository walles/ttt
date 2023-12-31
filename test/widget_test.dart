import 'package:flutter_test/flutter_test.dart';

import 'package:ttt/main.dart';

void main() {
  testWidgets('Find start button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TttApp());

    // Ref: https://stackoverflow.com/a/68257038/473672
    await tester.pumpAndSettle();

    // Verify that our counter starts at 0.
    expect(find.text('Timed Times Tables'), findsOneWidget);
  });
}
