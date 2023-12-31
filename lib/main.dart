import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:ttt/config.dart';
import 'package:ttt/effects_player.dart';
import 'package:ttt/game.dart';
import 'package:ttt/help_dialog.dart';
import 'package:ttt/long_term_stats.dart';
import 'package:ttt/question.dart';
import 'package:ttt/stats.dart';
import 'package:ttt/game_config_widget.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const longTermStatsKey = "longTermStats";

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(const TttApp());
  });
}

class TttApp extends StatelessWidget {
  const TttApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timed Times Tables', // FIXME: Get this from some metadata file

      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      home: const TttHomeScreen(title: 'Timed Times Tables'),

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
    );
  }
}

class TttHomeScreen extends StatefulWidget {
  const TttHomeScreen({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<TttHomeScreen> createState() => _TttHomeScreenState();
}

class _TttHomeScreenState extends State<TttHomeScreen> {
  bool _running = false;
  Stats? _stats;
  late LongTermStats _longTermStats;

  /// The tables the user wants to practice.
  Set<int> _requestedTables = {2, 3, 4, 5, 6, 7, 8, 9, 10};
  bool _multiplication = true;
  bool _division = true;
  Duration _duration = const Duration(seconds: 60);

  final _effectsPlayer = EffectsPlayer();

  @override
  void initState() {
    super.initState();

    if (GetStorage().hasData(longTermStatsKey)) {
      _longTermStats =
          LongTermStats.fromJson(GetStorage().read(longTermStatsKey));
    } else {
      _longTermStats = LongTermStats();
    }
  }

  @override
  void dispose() {
    _effectsPlayer.dispose();
    super.dispose();
  }

  Widget _startScreen() {
    // Note that we need to explicitly pass the locale to NumberFormat,
    // otherwise we get "." decimal separators even in Swedish.
    final NumberFormat oneDecimal =
        NumberFormat('#0.0', Localizations.localeOf(context).toString());

    List<Widget> children = [];
    if (_stats != null) {
      double totalDurationSeconds = _stats!.duration.inMilliseconds / 1000.0;
      String totalDuration = oneDecimal.format(totalDurationSeconds);
      String perQuestionDuration = oneDecimal
          .format((totalDurationSeconds / _stats!.rightOnFirstAttempt));
      String statsText = AppLocalizations.of(context)!.done_stats(
          _stats!.rightOnFirstAttempt, totalDuration, perQuestionDuration);

      children.add(Text(statsText));

      children.add(const SizedBox(height: 10));
    }

    children.add(ElevatedButton(
        onPressed: () {
          setState(() {
            _running = true;
          });
        },
        child: Text(AppLocalizations.of(context)!.start_excl)));

    children.add(const SizedBox(height: 10));

    children.add(
      GameConfigWidget(
        initialConfig:
            Config(_requestedTables, _multiplication, _division, _duration),
        onTableSelectionChanged: (Set<int> tables) {
          setState(() {
            _requestedTables = tables;
          });
        },
        onOperationChanged: (bool multiplication, bool division) {
          setState(() {
            _multiplication = multiplication;
            _division = division;
          });
        },
        onDurationChanged: (Duration duration) {
          setState(() {
            _duration = duration;
          });
        },
      ),
    );

    List<TopListEntry> topList = _longTermStats.getTopList(
        AppLocalizations.of(context)!.multiplication,
        AppLocalizations.of(context)!.division);

    // Having just one line in the top list looks a bit weird, so let's show it
    // when there are at least two entries.
    if (topList.length >= 2) {
      children.add(const SizedBox(height: 10));
      children.add(Text(AppLocalizations.of(context)!.statistics));
      children.add(
        // Regarding Expanded + SingleChildScrollView:
        // https://stackoverflow.com/a/58567624/473672
        //
        // FIXME: I would prefer to use Expanded only when the stats table is
        // high enough to need scrolling.
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: topList.map((TopListEntry entry) {
                return TableRow(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(
                        right:
                            8.0, // FIXME: What is the unit here? How will this look on different devices?
                      ),
                      child: Text(entry.name),
                    ),
                    Container(
                      alignment: Alignment.centerRight,
                      child: Text(
                          "${oneDecimal.format(entry.duration.inMilliseconds / 1000.0)}s"),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_running) {
      child = Game(
        config: Config(_requestedTables, _multiplication, _division, _duration),
        effectsPlayer: _effectsPlayer,
        onDone: (Stats stats) {
          setState(() {
            _running = false;
            _stats = stats;
          });
        },
        onQuestionAnswered: (Question question, Duration duration) {
          // FIXME: Do this in a setState() block?
          _longTermStats.add(question, duration);

          // Persist the new state
          GetStorage().write(longTermStatsKey, _longTermStats);
        },
      );
    } else {
      child = _startScreen();
    }

    return Scaffold(
      appBar: AppBar(
        leading: _running
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _running = false;
                    _stats = null;
                  });
                },
              )
            : null,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () {
              showHelpDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          constraints: const BoxConstraints(
            maxWidth:
                400, // FIXME: What is the unit here? How will this look on different devices?
          ),
          child: child,
        ),
      ),
    );
  }
}
