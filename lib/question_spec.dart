import 'dart:developer';
import 'dart:math' hide log;

import 'package:ttt/question.dart';

class QuestionSpec {
  /// Which tables should we test the user on?
  final Set<int> tablesToTest;

  /// Do we want multiplication questions?
  final bool multiplication;

  /// Do we want division questions?
  final bool division;

  final Random _random = Random();

  QuestionSpec(this.tablesToTest, this.multiplication, this.division) {
    if (!multiplication && !division) {
      throw ArgumentError(
          "At least one of multiplication or division must be true.");
    }
  }

  static List<Question> _allPossibleQuestions() {
    List<Question> questions = [];
    for (int a = 2; a <= 10; a++) {
      for (int b = 2; b <= 10; b++) {
        questions.add(Question(a, Operation.multiplication, b, a * b));
        questions.add(Question(a, Operation.division, b, b));
      }
    }
    return questions;
  }

  bool matches(Question question) {
    if (!tablesToTest.contains(question.a) &&
        !tablesToTest.contains(question.b)) {
      return false;
    }
    if (question.operation == Operation.multiplication && !multiplication) {
      return false;
    }
    if (question.operation == Operation.division && !division) {
      return false;
    }
    return true;
  }

  Question pick(List<Question> pile) {
    List<Question> matching = pile.where((q) => matches(q)).toList();
    if (matching.isEmpty) {
      throw ArgumentError("No matching questions in pile.");
    }

    return matching[_random.nextInt(matching.length)];
  }

  Question generate(Question? notThisOne) {
    while (true) {
      Question q = pick(_allPossibleQuestions());
      if (q != notThisOne) {
        log("Random question: $q");
        return q;
      }
    }
  }
}
