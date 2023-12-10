import 'dart:convert';

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

  test("JSON (de)serialization", () {
    Question q1 = Question.generate({2}, true, false, null);
    String json = jsonEncode(q1);
    Question q2 = Question.fromJson(jsonDecode(json));
    expect(q2, q1);
  });
}
