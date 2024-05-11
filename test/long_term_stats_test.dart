import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ttt/long_term_stats.dart';

import 'package:ttt/question.dart';

void main() {
  test("Top List generation", () {
    LongTermStats base = LongTermStats();

    Question question = Question.generate({2}, true, false, null);
    base.add(question, const Duration(seconds: 1), true, DateTime.now(),
        DateTime.now());
    base.add(question, const Duration(seconds: 2), true, DateTime.now(),
        DateTime.now());
    base.add(question, const Duration(seconds: 3), true, DateTime.now(),
        DateTime.now());

    // For 2x2 we'd get one top list entry for 2. With  2x5 we'd get another one
    // for 5 as well. So either one or two entries are fine.
    var topList = base.getTopList("multiplication", "division");
    expect(topList.isNotEmpty, true);
    expect(topList.length <= 2, true);
    for (var entry in topList) {
      expect(entry.duration, const Duration(seconds: 2));
    }
  });

  test("JSON (de)serialization", () {
    LongTermStats base = LongTermStats();

    Question question = Question.generate({2}, true, false, null);
    base.add(question, const Duration(seconds: 1), true, DateTime.now(),
        DateTime.now());
    base.add(question, const Duration(seconds: 2), false, DateTime.now(),
        DateTime.now());
    base.add(question, const Duration(seconds: 3), true, DateTime.now(),
        DateTime.now());

    String json = jsonEncode(base);
    LongTermStats deserialized = LongTermStats.fromJson(jsonDecode(json));
    expect(deserialized, base);
  });

/**
 * Verify that we can deserialize a StatsEntry with only question and duration.
 */
  test("Deserialize old", () {
    String json =
        '{"question": {"a": 2, "b": 3, "operation": "*", "answer": "6"}, "duration_ms": 1234}';

    var decoded = StatsEntry.fromJson(jsonDecode(json));
    expect(decoded.question.a, 2);
    expect(decoded.question.b, 3);
    expect(decoded.question.operation, Operation.multiplication);
    expect(decoded.duration, const Duration(milliseconds: 1234));
  });

  // We can get just {} from the web browser's local storage, and we should
  // accept that.
  test("Deserialize {}", () {
    LongTermStats empty = LongTermStats();
    LongTermStats deserializedEmpty = LongTermStats.fromJson(jsonDecode("{}"));
    expect(deserializedEmpty, empty);
  });
}
