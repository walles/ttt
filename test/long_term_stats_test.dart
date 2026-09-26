import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ttt/long_term_stats.dart';

import 'package:ttt/question.dart';
import 'package:ttt/question_spec.dart';

void main() {
  test("Top List generation", () {
    LongTermStats base = LongTermStats();

    Question question = QuestionSpec({2}, true, false).generate(null);
    base.add(question, const Duration(seconds: 1), true, DateTime.now(),
        DateTime.now());
    base.add(question, const Duration(seconds: 2), true, DateTime.now(),
        DateTime.now());
    base.add(question, const Duration(seconds: 3), true, DateTime.now(),
        DateTime.now());

    // For 2x2 we'd get one top list entry for 2. With  2x5 we'd get another one
    // for 5 as well. And in either case, we'll get one entry for the full
    // question. So either two or three entries are fine.
    var topList = base.getTopList("multiplication", "division");
    expect(topList.length >= 2, true);
    expect(topList.length <= 3, true);
    for (var entry in topList) {
      expect(entry.duration, const Duration(seconds: 2));
    }
  });

  // Guessing until you get it right takes time but doesn't count as knowing the
  // answer, so it should rank as needing more practice than answering slowly
  // but correctly.
  test("Top List counts time per first-attempt correct answer", () {
    LongTermStats base = LongTermStats();

    // 2x3=6, answered correctly in 3s every time: 3s per correct answer
    Question multiplication = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, multiplication, const Duration(seconds: 3), true, 3);

    // 6/2=3, guessed quickly, but only right on the first attempt once: 6s of
    // guessing for one correct answer
    Question division = Question(2, Operation.division, 3, 3);
    _addAnswers(base, division, const Duration(seconds: 2), true, 1);
    _addAnswers(base, division, const Duration(seconds: 2), false, 2);

    var topList = base.getTopList("multiplication", "division");
    expect(_topListDuration(topList, "multiplication"),
        const Duration(seconds: 3));
    expect(_topListDuration(topList, "division"), const Duration(seconds: 6));
    expect(_topListIndex(topList, "division"),
        lessThan(_topListIndex(topList, "multiplication")));
  });

  // Something never answered correctly on the first attempt needs more
  // practice than something answered correctly, and has no meaningful time per
  // correct answer
  test("Top List ranks never-correct categories above correct ones", () {
    LongTermStats base = LongTermStats();

    Question multiplication = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, multiplication, const Duration(seconds: 10), true, 3);

    Question division = Question(2, Operation.division, 3, 3);
    _addAnswers(base, division, const Duration(seconds: 1), false, 3);

    var topList = base.getTopList("multiplication", "division");
    expect(_topListDuration(topList, "division"), isNull);
    expect(_topListIndex(topList, "division"),
        lessThan(_topListIndex(topList, "multiplication")));
  });

  // Among never-correct categories, the one with more time spent on wrong
  // answers needs more practice. This is the same ranking the practice
  // question picker uses.
  test("Top List ranks never-correct categories by time spent", () {
    LongTermStats base = LongTermStats();

    Question lessTime = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, lessTime, const Duration(seconds: 1), false, 3);

    Question moreTime = Question(4, Operation.multiplication, 5, 20);
    _addAnswers(base, moreTime, const Duration(seconds: 5), false, 3);

    var topList = base.getTopList("multiplication", "division");
    expect(_topListIndex(topList, "4×5=20"),
        lessThan(_topListIndex(topList, "2×3=6")));
  });

  // An answer that took very long probably means the player was doing
  // something else, so it should only count as moderately slow
  test("Top List caps the time of each answer", () {
    LongTermStats base = LongTermStats();

    Question question = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, question, const Duration(seconds: 2), true, 2);
    _addAnswers(base, question, const Duration(seconds: 100), true, 1);

    // (2s + 2s + 20s) / 3 correct answers = 8s
    var topList = base.getTopList("multiplication", "division");
    expect(_topListDuration(topList, "2×3=6"), const Duration(seconds: 8));
  });

  // Questions that were guessed at should come up for practice more often than
  // questions that were answered correctly
  test("Focus candidates count time per first-attempt correct answer", () {
    LongTermStats base = LongTermStats();

    Question known = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, known, const Duration(seconds: 3), true, 3);

    Question guessed = Question(2, Operation.division, 3, 3);
    _addAnswers(base, guessed, const Duration(seconds: 2), true, 1);
    _addAnswers(base, guessed, const Duration(seconds: 2), false, 2);

    var candidates = base.getFocusCandidates(QuestionSpec({2}, true, true));
    expect(candidates[known], const Duration(seconds: 3));
    expect(candidates[guessed], const Duration(seconds: 6));
  });

  // Questions never answered correctly on the first attempt are timed as if
  // the next answer will be correct, but slow
  test("Focus candidates time never-correct questions", () {
    LongTermStats base = LongTermStats();

    Question question = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, question, const Duration(seconds: 1), false, 3);

    // 3 * 1s of wrong answers, plus 20s for the next one
    var candidates = base.getFocusCandidates(QuestionSpec({2}, true, false));
    expect(candidates[question], const Duration(seconds: 23));
  });

  // A lucky guess shouldn't make a question look easy when the other attempts
  // were guesses as well
  test("Today's hardest question is the one needing the most practice", () {
    LongTermStats base = LongTermStats();

    // 3s per correct answer
    Question known = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, known, const Duration(seconds: 3), true, 3);

    // (1s + 2s + 2s) / 1 correct answer = 5s per correct answer
    Question guessed = Question(4, Operation.division, 5, 5);
    _addAnswers(base, guessed, const Duration(seconds: 1), true, 1);
    _addAnswers(base, guessed, const Duration(seconds: 2), false, 2);

    HardestQuestion hardest = base.getTodaysHardestQuestion()!;
    expect(hardest.question, guessed);
    expect(hardest.bestDuration, const Duration(seconds: 1));
  });

  // Something you got wrong wasn't really answered, no matter how quickly
  test("Today's hardest best time only counts first-attempt correct answers",
      () {
    LongTermStats base = LongTermStats();

    Question question = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, question, const Duration(seconds: 1), false, 1);
    _addAnswers(base, question, const Duration(seconds: 4), true, 1);

    HardestQuestion hardest = base.getTodaysHardestQuestion()!;
    expect(hardest.bestDuration, const Duration(seconds: 4));
  });

  test("Today's hardest has no best time if never right on the first attempt",
      () {
    LongTermStats base = LongTermStats();

    Question question = Question(2, Operation.multiplication, 3, 6);
    _addAnswers(base, question, const Duration(seconds: 1), false, 2);

    HardestQuestion hardest = base.getTodaysHardestQuestion()!;
    expect(hardest.question, question);
    expect(hardest.bestDuration, isNull);
  });

  // Stats from before we recorded correctness should count as correct
  test("Top List counts old stats as correct", () {
    String json = '{"assignments": ['
        '{"question": {"a": 2, "b": 3, "operation": "*", "answer": "6"}, "duration_ms": 1000},'
        '{"question": {"a": 2, "b": 3, "operation": "*", "answer": "6"}, "duration_ms": 2000},'
        '{"question": {"a": 2, "b": 3, "operation": "*", "answer": "6"}, "duration_ms": 3000}'
        ']}';
    LongTermStats base = LongTermStats.fromJson(jsonDecode(json));

    var topList = base.getTopList("multiplication", "division");
    expect(_topListDuration(topList, "2×3=6"), const Duration(seconds: 2));
  });

  test("JSON (de)serialization", () {
    LongTermStats base = LongTermStats();

    Question question = QuestionSpec({2}, true, false).generate(null);
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

void _addAnswers(LongTermStats stats, Question question, Duration duration,
    bool correct, int count) {
  for (var i = 0; i < count; i++) {
    stats.add(question, duration, correct, DateTime.now(), DateTime.now());
  }
}

Duration? _topListDuration(List<TopListEntry> topList, String name) {
  return topList.firstWhere((entry) => entry.name == name).duration;
}

int _topListIndex(List<TopListEntry> topList, String name) {
  return topList.indexWhere((entry) => entry.name == name);
}
