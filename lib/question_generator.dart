import 'dart:developer';
import 'dart:math' hide log;

import 'package:ttt/long_term_stats.dart';
import 'package:ttt/question.dart';
import 'package:ttt/question_spec.dart';

/// Generates the questions of one round. Use a new generator for each round.
class QuestionGenerator {
  // Every focusInterval question will be a focus question
  static const focusInterval = 4;

  // Random questions are dealt as a hand from the deck of all questions, so
  // that a round doesn't repeat them. A hand holds about as many questions as
  // a round has random ones.
  static const _handSize = 14;

  // Half of every hand is the questions asked longest ago, so that all
  // questions come up regularly...
  static const _alwaysDealtCount = _handSize ~/ 2;

  // ... and the rest is picked at random among the next one and a half hands'
  // worth of questions. Otherwise the same questions would keep coming up
  // together.
  static const _dealPoolSize = _handSize * 3 ~/ 2;

  final Random _random = Random();

  List<Question> _hand = [];

  Question generate(
      QuestionSpec spec, LongTermStats stats, Question? notThisOne) {
    if (_random.nextInt(focusInterval) > 0) {
      return _randomQuestion(spec, stats, notThisOne);
    }

    // We should make a focus question

    final focusCandidates = stats.getFocusCandidates(spec);
    focusCandidates.remove(notThisOne);

    // If we have no focus candidates, then just generate a random question
    if (focusCandidates.isEmpty) {
      return _randomQuestion(spec, stats, notThisOne);
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
      return _randomQuestion(spec, stats, notThisOne);
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
    return _randomQuestion(spec, stats, notThisOne);
  }

  Question _randomQuestion(
      QuestionSpec spec, LongTermStats stats, Question? notThisOne) {
    // notThisOne was just asked, maybe as a focus question, so it doesn't
    // need to come up again from this hand
    _hand.remove(notThisOne);

    if (_hand.isEmpty) {
      _dealHand(spec, stats, notThisOne);
    }
    if (_hand.isEmpty) {
      throw ArgumentError("No question candidates");
    }

    final question = _hand.removeLast();
    log("Random question: $question");
    return question;
  }

  /// Replaces the hand with a new one of questions matching `spec`, preferring
  /// the ones `stats` shows were asked least recently. `notThisOne` is never
  /// dealt.
  void _dealHand(QuestionSpec spec, LongTermStats stats, Question? notThisOne) {
    final candidates = spec.allMatching();
    candidates.remove(notThisOne);

    // Puts never asked questions in random order
    candidates.shuffle(_random);
    final leastRecentlyAskedFirst = stats.sortedByLastAsked(candidates);

    final hand = leastRecentlyAskedFirst.take(_alwaysDealtCount).toList();
    final pool = leastRecentlyAskedFirst
        .skip(_alwaysDealtCount)
        .take(_dealPoolSize)
        .toList();
    pool.shuffle(_random);
    hand.addAll(pool.take(_handSize - _alwaysDealtCount));

    hand.shuffle(_random);
    _hand = hand;
  }
}
