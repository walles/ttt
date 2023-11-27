import 'package:flutter/material.dart';
import 'package:ttt/config.dart';
import 'package:ttt/game.dart';
import 'package:ttt/stats.dart';
import 'package:ttt/tables_selector_widget.dart';

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
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TttHomeScreen(title: 'Timed Times Tables'),
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
    }
    children.add(ElevatedButton(
        onPressed: () {
          setState(() {
            _running = true;
          });
        },
        child: const Text("Start!")));

    // Add a list widget with numbers 2-10
    children.add(Expanded(
      child: TablesSelectorWidget(
          initialSelection: _requestedTables,
          onSelectionChanged: (Set<int> tables) {
            setState(() {
              _requestedTables = tables;
            });
          }),
    ));

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
          config: Config(_requestedTables));
    } else {
      child = _startScreen();
    }

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
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
