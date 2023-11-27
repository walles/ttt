import 'package:flutter/material.dart';
import 'package:ttt/config.dart';
import 'package:ttt/game.dart';
import 'package:ttt/help_dialog.dart';
import 'package:ttt/stats.dart';
import 'package:ttt/game_config_widget.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const TttApp());
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

  /// The tables the user wants to practice.
  Set<int> _requestedTables = {2, 3, 4, 5, 6, 7, 8, 9, 10};
  bool _multiplication = true;
  bool _division = true;

  Widget _startScreen() {
    List<Widget> children = [];
    if (_stats != null) {
      double totalDurationSeconds = _stats!.duration.inMilliseconds / 1000.0;
      String totalDuration = totalDurationSeconds.toStringAsFixed(1);
      String perQuestionDuration =
          (totalDurationSeconds / _stats!.rightOnFirstAttempt)
              .toStringAsFixed(1);
      String statsText =
          "You got ${_stats!.rightOnFirstAttempt} right answers in $totalDuration seconds at $perQuestionDuration seconds per answer.";

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

    // Add a list widget with numbers 2-10
    children.add(
      GameConfigWidget(
        initialConfig: Config(_requestedTables, _multiplication, _division),
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
      ),
    );

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
          onDone: (Stats stats) {
            setState(() {
              _running = false;
              _stats = stats;
            });
          },
          config: Config(_requestedTables, _multiplication, _division));
    } else {
      child = _startScreen();
    }

    return Scaffold(
      appBar: AppBar(
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
