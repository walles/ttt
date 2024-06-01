import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ttt/question.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ttt/question_spec.dart';
import 'package:ttt/streak.dart';

const _maxQuestions = 150;

class TopListEntry {
  final String name;

  final Duration duration;

  TopListEntry(this.name, this.duration);
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

  static _median(List<Duration> durations) {
    if (durations.isEmpty) {
      throw ArgumentError("Cannot calculate median of empty list");
    }

    final sorted = List<Duration>.from(durations)..sort();
    if (sorted.length.isOdd) {
      return sorted[(sorted.length - 1) ~/ 2];
    }

    final beforeMidpoint = sorted.length ~/ 2 - 1;
    final afterMidpoint = sorted.length ~/ 2;
    final averageMs = (sorted[beforeMidpoint].inMilliseconds +
            sorted[afterMidpoint].inMilliseconds) /
        2;
    return Duration(milliseconds: averageMs.round());
  }

  void add(Question question, Duration duration, bool correct,
      DateTime timestamp, DateTime roundStart) {
    _assignments
        .add(StatsEntry(question, duration, correct, timestamp, roundStart));

    final midnight = DateUtils.dateOnly(DateTime.now());
    while (_assignments.length > _maxQuestions) {
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

  /// A top list of at most five entries.
  ///
  /// The duration of each entry is the median of the durations of the
  /// assignments in that category.
  ///
  /// The name can be a number 2-10. If either a or b is 4, then that counts
  /// towards the top list entry for "4".
  ///
  /// The name can also be "Multiplication" or "Division" (localized). If we
  /// have data for both we show both, otherwise neither.
  ///
  /// The list is sorted by duration, longest (needs most practice) first.
  ///
  /// To be in the list, a category must have at least three members.
  List<TopListEntry> getTopList(String multiplication, String division) {
    final Map<String, List<Duration>> durations = {};

    for (final assignment in _assignments) {
      durations
          .putIfAbsent(assignment.question.a.toString(), () => [])
          .add(assignment.duration);
      durations
          .putIfAbsent(assignment.question.b.toString(), () => [])
          .add(assignment.duration);

      final opName = assignment.question.operation == Operation.multiplication
          ? multiplication
          : division;
      durations.putIfAbsent(opName, () => []).add(assignment.duration);
    }

    // Drop any entries with fewer than three entries
    durations.removeWhere((key, value) => value.length < 3);

    // Ensure either both or neither of multiplication and division are in the
    // list.
    if (durations.containsKey(multiplication) !=
        durations.containsKey(division)) {
      durations.remove(multiplication);
      durations.remove(division);
    }

    // Calculate the median duration for each category
    final List<TopListEntry> topList = [];
    for (final entry in durations.entries) {
      final durations = entry.value;
      topList.add(TopListEntry(entry.key, _median(durations)));
    }

    // Sort the list by duration, longest first
    topList.sort((a, b) => b.duration.compareTo(a.duration));

    // Limit to five entries, but multiplication and division should always be
    // kept.
    while (topList.length > 5) {
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

  /// Returns a map of questions to the median response time of that question.
  Map<Question, Duration> getFocusCandidates(QuestionSpec spec) {
    // Collect all durations for all questions matching the spec
    final Map<Question, List<Duration>> durationsPerQuestion = {};
    for (final assignment in _assignments) {
      if (!spec.matches(assignment.question)) {
        continue;
      }

      durationsPerQuestion
          .putIfAbsent(assignment.question, () => [])
          .add(assignment.duration);
    }

    final Map<Question, Duration> focusCandidates = {};
    for (final entry in durationsPerQuestion.entries) {
      final durations = entry.value;
      focusCandidates[entry.key] = _median(durations);
    }

    return focusCandidates;
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

  /// "Today's hardest question was 3x4=12, which took you 5.3s at best."
  ///
  /// If there are no assignments today, return null.
  String? getTodaysHardest(BuildContext context) {
    final assignments = _assignmentsToday();
    if (assignments.isEmpty) {
      return null;
    }

    // Figure out the fastest time for each assignment
    final fastestTime = <Question, Duration>{};
    for (final assignment in assignments) {
      final current = fastestTime[assignment.question];
      if (current == null || assignment.duration < current) {
        fastestTime[assignment.question] = assignment.duration;
      }
    }

    // Find the hardest question
    final hardest =
        fastestTime.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Note that we need to explicitly pass the locale to NumberFormat,
    // otherwise we get "." decimal separators even in Swedish.
    final NumberFormat oneDecimal =
        NumberFormat('#0.0', Localizations.localeOf(context).toString());

    // "Today's hardest question was 3x4=12, which took you 5.3s at best."
    return AppLocalizations.of(context)!.todays_hardest(
        hardest.key.getQuestionText() + hardest.key.answer.toString(),
        oneDecimal.format(hardest.value.inMilliseconds / 1000.0));
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
