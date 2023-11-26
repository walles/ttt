import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ttt/stats.dart';

class _GameState extends State<Game> {
  // Game state
  int _questionNumberOneBased = 0;
  late String _question;
  late String _answer;
  late bool _currentHasBeenWrong;
  int _rightOnFirstAttempt = 0;

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

  void _generateQuestion() {
    var a = Random().nextInt(9) + 2;
    var b = Random().nextInt(9) + 2;
    setState(() {
      _question = "$a×$b=";
      _answer = (a * b).toString();
      _currentHasBeenWrong = false;
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
    InputDecoration inputDecoration;
    if (_currentHasBeenWrong) {
      inputDecoration = const InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.red,
      );
    } else {
      inputDecoration = const InputDecoration(
        border: OutlineInputBorder(),
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
                    if (!_answer.startsWith(text)) {
                      setState(() {
                        _currentHasBeenWrong = true;
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
  const Game({super.key, required this.onDone});

  final Function(Stats stats) onDone;

  @override
  State<Game> createState() => _GameState();
}
