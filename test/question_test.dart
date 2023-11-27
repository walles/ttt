import 'package:flutter_test/flutter_test.dart';

import 'package:ttt/question.dart';

void main() {
  testWidgets("Don't repeat the same question", (WidgetTester tester) async {
    // This can generate 16 different questions if my maths is correct
    Question base = Question.generate({2}, true, false, null);

    // Make likely no other questions are the same
    for (int i = 0; i < 1000; i++) {
      Question q = Question.generate({2}, true, false, base);
      expect(q, isNot(base));
    }
  });
}
