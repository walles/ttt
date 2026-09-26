import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ttt/question.dart';

void main() {
  test("JSON (de)serialization", () {
    Question q1 = Question(2, Operation.multiplication, 3, 6);
    String json = jsonEncode(q1);
    Question q2 = Question.fromJson(jsonDecode(json));
    expect(q2, q1);
  });
}
