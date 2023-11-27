/// Configuration for a single game. Set up on the start screen.
///
/// If / when we start presenting high score tables, we should keep individual
/// high score tables for each config.
class Config {
  /// Which tables should we test the user on?
  final Set<int> tablesToTest;

  final bool multiplication;
  final bool division;

  Config(this.tablesToTest, this.multiplication, this.division);
}
