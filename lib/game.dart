import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ttt/config.dart';
import 'package:ttt/stats.dart';

class _GameState extends State<Game> {
  // Game state
  int _questionNumberOneBased = 0;
  late String _question;
  late String _answer;
  late bool _currentHasBeenWrong;
  late bool _currentIsOnTheRightTrack;
  int _rightOnFirstAttempt = 0;

  bool _tooSlow = false;
  Timer? _tooSlowTimer;

  // Stats state
  final DateTime _startTime = DateTime.now();

  final TextEditingController _controller = TextEditingController();

  void _nextQuestion() {
    setState(() {
      if (!_currentHasBeenWrong) {
        _rightOnFirstAttempt++;
      }

      _questionNumberOneBased++;
      if (_questionNumberOneBased > 10) {
        widget.onDone(Stats(
            duration: DateTime.now().difference(_startTime),
            rightOnFirstAttempt: _rightOnFirstAttempt));
      }
      _generateQuestion();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tooSlowTimer?.cancel();
    super.dispose();
  }

  void _generateQuestion() {
    // Pick a random entry in the tables to test
    var a = widget.config.tablesToTest
        .elementAt(Random().nextInt(widget.config.tablesToTest.length));

    // Pick a number to multiply with (2 to 10)
    var b = Random().nextInt(9) + 2;

    if (Random().nextBool()) {
      // Switch places between a and b
      var tmp = a;
      a = b;
      b = tmp;
    }

    setState(() {
      _question = "$a×$b=";
      _answer = (a * b).toString();
      _currentHasBeenWrong = false;
      _currentIsOnTheRightTrack = true;

      _tooSlowTimer?.cancel();

      _tooSlow = false;
      _tooSlowTimer = Timer(const Duration(seconds: 5), () {
        setState(() {
          _tooSlow = true;
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _questionNumberOneBased = 1;
    _generateQuestion();
  }

  @override
  Widget build(BuildContext context) {
    String? hintText = _tooSlow ? _answer : null;

    InputDecoration inputDecoration;
    if (_currentIsOnTheRightTrack) {
      inputDecoration = InputDecoration(
        border: const OutlineInputBorder(),
        suffixText: hintText,
      );
    } else {
      inputDecoration = InputDecoration(
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.red,
        suffixText: hintText,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _question,
            ),
            SizedBox(
              width: 100,
              child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter("100".length),
                  ],
                  onChanged: (text) {
                    if (text == _answer) {
                      _controller.clear();
                      _nextQuestion();
                      return;
                    }
                    if (_answer.startsWith(text)) {
                      setState(() {
                        _currentIsOnTheRightTrack = true;
                      });
                    } else {
                      setState(() {
                        _currentHasBeenWrong = true;
                        _currentIsOnTheRightTrack = false;
                      });
                    }
                  }),
            ),
          ],
        ),
        LinearProgressIndicator(
          value: (_questionNumberOneBased - 1) / 10,
        ),
      ],
    );
  }
}

class Game extends StatefulWidget {
  const Game({super.key, required this.onDone, required this.config});

  final Function(Stats stats) onDone;
  final Config config;

  @override
  State<Game> createState() => _GameState();
}
