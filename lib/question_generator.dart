import 'dart:developer';
import 'dart:math' hide log;

import 'package:ttt/long_term_stats.dart';
import 'package:ttt/question.dart';
import 'package:ttt/question_spec.dart';

class QuestionGenerator {
  // Every focusInterval question will be a focus question
  static const focusInterval = 4;

  final Random _random = Random();

  Question generate(
      QuestionSpec spec, LongTermStats stats, Question? notThisOne) {
    if (_random.nextInt(focusInterval) > 0) {
      return spec.generate(notThisOne);
    }

    // We should make a focus question

    final focusCandidates = stats.getFocusCandidates(spec);
    focusCandidates.remove(notThisOne);

    // If we have no focus candidates, then just generate a random question
    if (focusCandidates.isEmpty) {
      return spec.generate(notThisOne);
    }

    // If the slowest question isn't at least 2x slower than the fastest
    // question, generate a random question
    int slowestDurationMs = 0;
    int fastestDurationMs = -1;
    for (final duration in focusCandidates.values) {
      final milliseconds = duration.inMilliseconds;
      if (fastestDurationMs == -1 || milliseconds < fastestDurationMs) {
        fastestDurationMs = milliseconds;
      }
      if (milliseconds > slowestDurationMs) {
        slowestDurationMs = milliseconds;
      }
    }
    if (slowestDurationMs < 2 * fastestDurationMs) {
      log("Slowest question (${slowestDurationMs}ms) is not at least 2x slower than fastest question (${fastestDurationMs}ms), falling back on random questions");
      return spec.generate(notThisOne);
    }

    // We have at least one focus candidate, so fastest should have been updated
    // at least once.
    assert(fastestDurationMs != -1);

    // Return the slowest question
    for (final entry in focusCandidates.entries) {
      if (entry.value.inMilliseconds == slowestDurationMs) {
        log("Focus question: ${entry.key}");
        return entry.key;
      }
    }

    // We should have found the slowest duration in the list
    assert(false);

    // The assert should prevent us from getting here, but this statement is
    // needed to make the analyzer happy.
    return spec.generate(notThisOne);
  }
}
