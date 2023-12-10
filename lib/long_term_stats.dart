import 'package:ttt/question.dart';

const _maxQuestions = 50;

class TopListEntry {
  final String name;

  final Duration duration;

  TopListEntry(this.name, this.duration);
}

class _StatsEntry {
  final Question question;

  final Duration duration;

  _StatsEntry(this.question, this.duration);

  Map<String, dynamic> toJson() => {
        'question': question.toJson(),
        'duration_ms': duration.inMilliseconds,
      };

  _StatsEntry.fromJson(Map<String, dynamic> json)
      : question = Question.fromJson(json['question']),
        duration = Duration(milliseconds: json['duration_ms']);
}

class LongTermStats {
  final List<_StatsEntry> _assignments;

  LongTermStats() : _assignments = [];

  void add(Question question, Duration duration) {
    _assignments.add(_StatsEntry(question, duration));
    if (_assignments.length > _maxQuestions) {
      _assignments.removeAt(0);
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
      durations.sort();
      final median = durations[durations.length ~/ 2];
      topList.add(TopListEntry(entry.key, median));
    }

    // Sort the list by duration, longest first
    topList.sort((a, b) => b.duration.compareTo(a.duration));

    return topList;
  }

  Map<String, dynamic> toJson() => {
        'assignments':
            _assignments.map((e) => e.toJson()).toList(growable: false),
      };

  LongTermStats.fromJson(Map<String, dynamic> json)
      : _assignments = (json['assignments'] as List<dynamic>)
            .map((e) => _StatsEntry.fromJson(e))
            .toList();
}
