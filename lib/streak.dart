import 'package:flutter/material.dart';

class Streak {
  /// Always a day, guaranteed by always running everything through
  /// [DateUtils.dateOnly].
  DateTime _mostRecentDay;

  /// Including the most recent day
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
    if (day.isAfter(_mostRecentDay)) {
      if (day.difference(_mostRecentDay).inDays == 1) {
        _streakLength++;
      } else {
        _streakLength = 1;
      }
      _mostRecentDay = day;
    }
  }
}
