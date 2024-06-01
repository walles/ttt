import 'dart:math';

import 'package:ttt/long_term_stats.dart';
import 'package:ttt/question.dart';
import 'package:ttt/question_spec.dart';

class QuestionGenerator {
  // Every focusFrequency question will be a focus question
  static const focusFrequency = 4;

  final Random _random = Random();

  Question generate(
      QuestionSpec spec, LongTermStats stats, Question? notThisOne) {
    if (_random.nextInt(focusFrequency) > 0) {
      return spec.generate(notThisOne);
    }

    // We should make a focus question

    // FIXME: List all stats entries matching this spec

    // FIXME: If nothing found, just generate a random question

    // FIXME: If the slowest question isn't at least 2x slower than the fastest
    //      question, generate a random question

    // FIXME: Return the slowest question

    return spec.generate(notThisOne); // FIXME: Remove this line
  }
}
