import 'package:flutter_test/flutter_test.dart';
import 'package:ttt/long_term_stats.dart';
import 'package:ttt/question.dart';
import 'package:ttt/question_generator.dart';
import 'package:ttt/question_spec.dart';

void main() {
  /// Adds one correct 3s answer to `stats` for each multiplication question
  /// matching `spec`.
  ///
  /// With all answers equally fast there is nothing to focus practice on, so
  /// all questions generated afterwards are random picks.
  ///
  /// Returns the answered questions in the order they were answered, so the
  /// least recently asked question comes first.
  List<Question> answerEachOnce(LongTermStats stats, QuestionSpec spec) {
    final List<Question> questions = [];
    for (int a = 2; a <= 10; a++) {
      for (int b = 2; b <= 10; b++) {
        final question = Question(a, Operation.multiplication, b, a * b);
        if (!spec.matches(question)) {
          continue;
        }

        questions.add(question);
        stats.add(question, const Duration(seconds: 3), true, DateTime.now(),
            DateTime.now());
      }
    }
    return questions;
  }

  /// Generates the 14 questions of a typical round from one generator,
  /// without answering any of them.
  List<Question> generateRound(
      QuestionGenerator generator, QuestionSpec spec, LongTermStats stats) {
    final List<Question> round = [];
    Question? previous;
    for (int i = 0; i < 14; i++) {
      previous = generator.generate(spec, stats, previous);
      round.add(previous);
    }
    return round;
  }

  // Every question should come up regularly, so that we notice when something
  // is hard
  test("A round asks the seven least recently asked questions", () {
    final spec = QuestionSpec({2}, true, false);
    for (int attempt = 0; attempt < 20; attempt++) {
      final stats = LongTermStats();
      final leastRecentlyAskedFirst = answerEachOnce(stats, spec);

      final round = generateRound(QuestionGenerator(), spec, stats);
      for (final question in leastRecentlyAskedFirst.take(7)) {
        expect(round, contains(question));
      }
    }
  });

  test("A round doesn't repeat random questions", () {
    final spec = QuestionSpec({2}, true, false);
    for (int attempt = 0; attempt < 20; attempt++) {
      final stats = LongTermStats();
      answerEachOnce(stats, spec);

      final round = generateRound(QuestionGenerator(), spec, stats);
      // A set keeps only one of each question, so it is as long as the round
      // only if the round has no duplicates
      expect(round.toSet().length, round.length);
    }
  });
}
