class Stats {
  /// How long did it take to finish?
  final Duration duration;

  /// How many questions were answered correctly on the first attempt?
  final int rightOnFirstAttempt;

  Stats({required this.duration, required this.rightOnFirstAttempt});
}
