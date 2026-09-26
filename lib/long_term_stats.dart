import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ttt/question.dart';
import 'package:ttt/l10n/app_localizations.dart';
import 'package:ttt/question_spec.dart';
import 'package:ttt/streak.dart';

// Enough to remember when each of the 162 questions was last asked, even with
// focus questions repeating
const _maxStatEntries = 400;
const _maxTopListLength = 10;

// Answers slower than this probably mean the player was doing something else
const _maxCountedDuration = Duration(seconds: 20);

// The top list and picking practice questions only look at this many of the
// latest answers to each question, so that learning something shows quickly
const _countedAnswersPerQuestion = 3;

class TopListEntry {
  final String name;

  /// Time spent per first-attempt correct answer, null if there were none
  final Duration? duration;

  TopListEntry(this.name, this.duration);
}

class HardestQuestion {
  final Question question;

  /// The fastest first-attempt correct answer, null if there were none
  final Duration? bestDuration;

  HardestQuestion(this.question, this.bestDuration);
}

@visibleForTesting
class StatsEntry {
  final Question question;
  final Duration duration;
  final bool? correct;
  final DateTime? timestamp;
  final DateTime? roundStart;

  StatsEntry(this.question, this.duration, this.correct, this.timestamp,
      this.roundStart);

  Map<String, dynamic> toJson() => {
        'question': question.toJson(),
        'duration_ms': duration.inMilliseconds,
        'correct': correct,
        'timestamp': timestamp?.toUtc().toIso8601String(),
        'round_start': roundStart?.toUtc().toIso8601String(),
      };

  StatsEntry.fromJson(Map<String, dynamic> json)
      : question = Question.fromJson(json['question']),
        duration = Duration(milliseconds: json['duration_ms']),
        correct = json['correct'],
        timestamp = json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : null,
        roundStart = json['round_start'] != null
            ? DateTime.parse(json['round_start'])
            : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsEntry &&
          runtimeType == other.runtimeType &&
          question == other.question &&
          duration == other.duration;

  @override
  int get hashCode => question.hashCode ^ duration.hashCode;
}

class LongTermStats {
  final List<StatsEntry> _assignments;
  Streak? _streak;

  LongTermStats() : _assignments = [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LongTermStats &&
          runtimeType == other.runtimeType &&
          listEquals(_assignments, other._assignments);

  @override
  int get hashCode => _assignments.hashCode;

  int get length => _assignments.length;

  /// Total time spent on these assignments, with each one capped at
  /// `_maxCountedDuration`.
  static Duration _cappedTotalDuration(List<StatsEntry> assignments) {
    var total = Duration.zero;
    for (final assignment in assignments) {
      if (assignment.duration > _maxCountedDuration) {
        total += _maxCountedDuration;
        continue;
      }

      total += assignment.duration;
    }

    return total;
  }

  /// Time spent per first-attempt correct answer, with each assignment's time
  /// capped at `_maxCountedDuration`.
  ///
  /// Wrong answers add time but no correct answers, so guessing until you get
  /// it right scores worse than thinking first.
  ///
  /// Returns null if none of the assignments were correct on the first
  /// attempt.
  static Duration? _durationPerCorrectAnswer(List<StatsEntry> assignments) {
    var correctCount = 0;
    for (final assignment in assignments) {
      // Old stats don't know, give them the benefit of the doubt
      if (assignment.correct ?? true) {
        correctCount++;
      }
    }

    if (correctCount == 0) {
      return null;
    }

    return _cappedTotalDuration(assignments) ~/ correctCount;
  }

  /// How much practice these assignments show a need for. Longer means more.
  ///
  /// This is the time spent per first-attempt correct answer. If none were
  /// correct, the assignments are timed as if the next answer will be correct,
  /// but slow.
  static Duration _practiceNeed(List<StatsEntry> assignments) {
    final durationPerCorrectAnswer = _durationPerCorrectAnswer(assignments);
    if (durationPerCorrectAnswer == null) {
      return _cappedTotalDuration(assignments) + _maxCountedDuration;
    }

    return durationPerCorrectAnswer;
  }

  void add(Question question, Duration duration, bool correct,
      DateTime timestamp, DateTime roundStart) {
    _assignments
        .add(StatsEntry(question, duration, correct, timestamp, roundStart));

    final midnight = DateUtils.dateOnly(DateTime.now());
    while (_assignments.length > _maxStatEntries) {
      final candidate = _assignments.first;
      if (candidate.timestamp != null &&
          candidate.timestamp!.isAfter(midnight)) {
        // Don't remove any info from today
        break;
      }

      _assignments.removeAt(0);
    }

    // Update the streak
    if (_streak == null) {
      _streak = Streak();
    } else {
      _streak!.update(timestamp);
    }
  }

  /// A top list of at most `_maxTopListLength` entries.
  ///
  /// The duration of each entry is the time spent per first-attempt correct
  /// answer in that category, with each answer's time capped. It is null if no
  /// answer in the category was correct on the first attempt. Only the latest
  /// `_countedAnswersPerQuestion` answers to each question count.
  ///
  /// The name can be a number 2-10. If either a or b is 4, then that counts
  /// towards the top list entry for "4".
  ///
  /// The name can also be "Multiplication" or "Division" (localized). If we
  /// have data for both we show both, otherwise neither.
  ///
  /// The list is sorted by need for practice, most first. This is the same
  /// ranking `getFocusCandidates` uses. Where durations are known, longer ones
  /// come first.
  ///
  /// To be in the list, a category must have at least three members.
  List<TopListEntry> getTopList(String multiplication, String division) {
    final List<StatsEntry> counted = [];
    for (final latest in _latestAnswersPerQuestion().values) {
      counted.addAll(latest);
    }

    final Map<String, List<StatsEntry>> categories = {};
    for (final assignment in counted) {
      categories
          .putIfAbsent(assignment.question.a.toString(), () => [])
          .add(assignment);
      if (assignment.question.b != assignment.question.a) {
        categories
            .putIfAbsent(assignment.question.b.toString(), () => [])
            .add(assignment);
      }

      final qna = assignment.question.getQuestionText() +
          assignment.question.answer.toString();
      categories.putIfAbsent(qna, () => []).add(assignment);

      final opName = assignment.question.operation == Operation.multiplication
          ? multiplication
          : division;
      categories.putIfAbsent(opName, () => []).add(assignment);
    }

    // Drop any entries with fewer than three entries
    categories.removeWhere((key, value) => value.length < 3);

    // Ensure either both or neither of multiplication and division are in the
    // list.
    if (categories.containsKey(multiplication) !=
        categories.containsKey(division)) {
      categories.remove(multiplication);
      categories.remove(division);
    }

    final Map<String, Duration> practiceNeeds = {};
    for (final entry in categories.entries) {
      practiceNeeds[entry.key] = _practiceNeed(entry.value);
    }

    // Most practice needed first
    final names = categories.keys.toList();
    names.sort((a, b) => practiceNeeds[b]!.compareTo(practiceNeeds[a]!));

    final List<TopListEntry> topList = [];
    for (final name in names) {
      topList.add(
          TopListEntry(name, _durationPerCorrectAnswer(categories[name]!)));
    }

    // Limit the number of entries, but multiplication and division should
    // always be kept.
    while (topList.length > _maxTopListLength) {
      // Iterate from the end of the list to find a removal candidate
      for (var i = topList.length - 1; i >= 0; i--) {
        if (topList[i].name == multiplication || topList[i].name == division) {
          // Don't remove multiplication or division
          continue;
        }

        topList.removeAt(i);
        break;
      }
    }

    return topList;
  }

  /// Returns a map of the questions matching the spec to how much practice
  /// each one needs. Longer means more.
  ///
  /// This is the time spent per first-attempt correct answer, over the latest
  /// `_countedAnswersPerQuestion` answers to each question. Questions without
  /// any first-attempt correct answers among those are timed as if their next
  /// answer will be correct, but slow.
  Map<Question, Duration> getFocusCandidates(QuestionSpec spec) {
    final Map<Question, Duration> focusCandidates = {};
    for (final entry in _latestAnswersPerQuestion().entries) {
      if (!spec.matches(entry.key)) {
        continue;
      }

      focusCandidates[entry.key] = _practiceNeed(entry.value);
    }

    return focusCandidates;
  }

  /// The latest `_countedAnswersPerQuestion` answers to each question in the
  /// stats, oldest first.
  Map<Question, List<StatsEntry>> _latestAnswersPerQuestion() {
    final Map<Question, List<StatsEntry>> answersPerQuestion = {};
    for (final assignment in _assignments) {
      answersPerQuestion
          .putIfAbsent(assignment.question, () => [])
          .add(assignment);
    }

    for (final answers in answersPerQuestion.values) {
      if (answers.length <= _countedAnswersPerQuestion) {
        continue;
      }

      answers.removeRange(0, answers.length - _countedAnswersPerQuestion);
    }

    return answersPerQuestion;
  }

  /// Returns these questions sorted by when they were last asked, least
  /// recently asked first.
  ///
  /// Questions not in the stats, because they were never asked or were asked
  /// too long ago to be remembered, come first, in the order given.
  List<Question> sortedByLastAsked(List<Question> questions) {
    // Later answers overwrite earlier ones, so this ends up with the index of
    // the latest answer to each question
    final Map<Question, int> lastAskedIndex = {};
    for (var i = 0; i < _assignments.length; i++) {
      lastAskedIndex[_assignments[i].question] = i;
    }

    final List<Question> neverAsked = [];
    final List<Question> asked = [];
    for (final question in questions) {
      if (lastAskedIndex.containsKey(question)) {
        asked.add(question);
        continue;
      }

      neverAsked.add(question);
    }

    // Each asked question has an index of its own, so there are no ties
    asked.sort((a, b) => lastAskedIndex[a]!.compareTo(lastAskedIndex[b]!));
    return neverAsked + asked;
  }

  List<StatsEntry> _assignmentsToday() {
    final today = DateTime.now();
    return _assignments
        .where((element) =>
            element.timestamp != null &&
            element.timestamp!.day == today.day &&
            element.timestamp!.month == today.month &&
            element.timestamp!.year == today.year)
        .toList();
  }

  /// "Today you spent 3m11s on 20 assignments over 3 rounds."
  String getTodayStats(BuildContext context) {
    final assignments = _assignmentsToday();
    final rounds = assignments
        .map((e) => e.roundStart)
        .toSet()
        // roundStart can be null for old stats
        .where((element) => element != null)
        .length;
    final totalDuration = assignments.map((e) => e.duration).fold(
        Duration.zero, (previousValue, element) => previousValue + element);

    // "Today you spent 3m11s on 20 assignments over 3 rounds."
    return AppLocalizations.of(context)!.today_stats(assignments.length,
        totalDuration.inMinutes, rounds, totalDuration.inSeconds % 60);
  }

  /// The question answered today that needs the most practice, with the
  /// fastest time it was answered correctly on the first attempt.
  ///
  /// If there are no assignments today, return null.
  HardestQuestion? getTodaysHardestQuestion() {
    final assignments = _assignmentsToday();
    if (assignments.isEmpty) {
      return null;
    }

    final Map<Question, List<StatsEntry>> assignmentsPerQuestion = {};
    for (final assignment in assignments) {
      assignmentsPerQuestion
          .putIfAbsent(assignment.question, () => [])
          .add(assignment);
    }

    // Find the question needing the most practice
    Question? hardest;
    Duration? hardestPracticeNeed;
    for (final entry in assignmentsPerQuestion.entries) {
      final practiceNeed = _practiceNeed(entry.value);
      if (hardestPracticeNeed != null && practiceNeed <= hardestPracticeNeed) {
        continue;
      }

      hardest = entry.key;
      hardestPracticeNeed = practiceNeed;
    }

    return HardestQuestion(
        hardest!, _fastestCorrectDuration(assignmentsPerQuestion[hardest]!));
  }

  /// The fastest first-attempt correct answer, null if there were none
  static Duration? _fastestCorrectDuration(List<StatsEntry> assignments) {
    Duration? fastest;
    for (final assignment in assignments) {
      // Old stats don't know, give them the benefit of the doubt
      if (!(assignment.correct ?? true)) {
        continue;
      }
      if (fastest != null && assignment.duration >= fastest) {
        continue;
      }

      fastest = assignment.duration;
    }

    return fastest;
  }

  /// "Today's hardest question was 3x4=12. At best it took you 5.3s."
  ///
  /// If there are no assignments today, return null.
  String? getTodaysHardest(BuildContext context) {
    final hardest = getTodaysHardestQuestion();
    if (hardest == null) {
      return null;
    }

    final questionWithAnswer =
        hardest.question.getQuestionText() + hardest.question.answer.toString();

    final bestDuration = hardest.bestDuration;
    if (bestDuration == null) {
      // "Today's hardest question was 3x4=12. Try getting it right on the first
      // attempt!"
      return AppLocalizations.of(context)!
          .todays_hardest_never_right(questionWithAnswer);
    }

    // Note that we need to explicitly pass the locale to NumberFormat,
    // otherwise we get "." decimal separators even in Swedish.
    final NumberFormat oneDecimal =
        NumberFormat('#0.0', Localizations.localeOf(context).toString());

    // "Today's hardest question was 3x4=12. At best it took you 5.3s."
    return AppLocalizations.of(context)!.todays_hardest(questionWithAnswer,
        oneDecimal.format(bestDuration.inMilliseconds / 1000.0));
  }

  String getStreak(BuildContext context) {
    if (_streak == null) {
      return AppLocalizations.of(context)!.streak_play_to_start_a_new_one;
    }

    if (_streak!.length() == 0) {
      return AppLocalizations.of(context)!.streak_play_to_start_a_new_one;
    }

    if (_streak!.playedToday()) {
      return AppLocalizations.of(context)!
          .streak_you_have_an_n_day_streak(_streak!.length());
    }

    return AppLocalizations.of(context)!
        .streak_play_today_to_extend(_streak!.length(), _streak!.length() + 1);
  }

  Map<String, dynamic> toJson() => {
        'assignments':
            _assignments.map((e) => e.toJson()).toList(growable: false),
        'streak': _streak?.toJson(),
      };

  LongTermStats.fromJson(Map<String, dynamic> json)
      : _assignments = json.containsKey("assignments")
            ? (json['assignments'] as List<dynamic>)
                .map((e) => StatsEntry.fromJson(e))
                .toList()
            : [],
        _streak =
            json["streak"] != null ? Streak.fromJson(json['streak']) : null;
}
