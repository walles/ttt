import 'package:flutter/material.dart';

class Streak {
  /// Always a day, guaranteed by always running everything through
  /// [DateUtils.dateOnly].
  DateTime _mostRecentDay;

  /// Including the most recent day. Always at least 1.
  int _streakLength;

  Streak()
      : _mostRecentDay = DateUtils.dateOnly(DateTime.now()),
        _streakLength = 1;

  Streak.fromJson(Map<String, dynamic> json)
      : _mostRecentDay =
            DateUtils.dateOnly(DateTime.parse(json['most_recent_day'])),
        _streakLength = json['streak_length'] {
    assert(_streakLength > 0);
  }

  Map<String, dynamic> toJson() => {
        'most_recent_day': _mostRecentDay.toIso8601String(),
        'streak_length': _streakLength,
      };

  void update(DateTime timestamp) {
    DateTime day = DateUtils.dateOnly(timestamp);
    if (!day.isAfter(_mostRecentDay)) {
      // Already updated for today
      return;
    }

    final playedYesterday = day.difference(_mostRecentDay).inDays == 1;
    if (playedYesterday) {
      // Played yesterday, streak is extended
      _streakLength++;
    } else {
      // Did not play yesterday, start a new streak
      _streakLength = 1;
    }

    _mostRecentDay = day;
  }

  bool playedToday() {
    return DateUtils.dateOnly(DateTime.now()).isAtSameMomentAs(_mostRecentDay);
  }

  int length() {
    if (playedToday()) {
      return _streakLength;
    }

    final playedYesterday =
        DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 1)))
            .isAtSameMomentAs(_mostRecentDay);
    if (playedYesterday) {
      return _streakLength;
    }

    // The streak was broken
    return 0;
  }
}
