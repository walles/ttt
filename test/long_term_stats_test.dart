import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ttt/long_term_stats.dart';

import 'package:ttt/question.dart';

void main() {
  test("Top List generation", () {
    LongTermStats base = LongTermStats();

    Question question = Question.generate({2}, true, false, null);
    base.add(question, const Duration(seconds: 1));
    base.add(question, const Duration(seconds: 2));
    base.add(question, const Duration(seconds: 3));

    // For 2x2 we'd get one top list entry for 2. With  2x5 we'd get another one
    // for 5 as well. So either one or two entries are fine.
    var topList = base.getTopList("multiplication", "division");
    expect(topList.isNotEmpty, true);
    expect(topList.length <= 2, true);
    for (var entry in topList) {
      expect(entry.duration, const Duration(seconds: 2));
    }
  });

  // FIXME: Test even and odd length medians

  test("JSON (de)serialization", () {
    LongTermStats base = LongTermStats();

    Question question = Question.generate({2}, true, false, null);
    base.add(question, const Duration(seconds: 1));
    base.add(question, const Duration(seconds: 2));
    base.add(question, const Duration(seconds: 3));

    String json = jsonEncode(base);
    LongTermStats deserialized = LongTermStats.fromJson(jsonDecode(json));
    expect(base, deserialized);
  });

  // We can get just {} from the web browser's local storage, and we should
  // accept that.
  test("Deserialize {}", () {
    LongTermStats empty = LongTermStats();
    LongTermStats deserializedEmpty = LongTermStats.fromJson(jsonDecode("{}"));
    expect(deserializedEmpty, empty);
  });
}
