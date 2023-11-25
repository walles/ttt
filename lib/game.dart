import 'dart:math';

import 'package:flutter/material.dart';

class _GameState extends State<Game> {
  int _questionNumberOneBased = 0;
  String _question = "";

  void _nextQuestion() {
    setState(() {
      _questionNumberOneBased++;
      if (_questionNumberOneBased > 10) {
        widget.onDone();
      }
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    var a = Random().nextInt(9) + 2;
    var b = Random().nextInt(9) + 2;
    setState(() {
      _question = "$a×$b=";
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '$_questionNumberOneBased/10: $_question',
        ),
        ElevatedButton(
            onPressed: _nextQuestion, child: const Text("Next Question")),
      ],
    );
  }
}

class Game extends StatefulWidget {
  const Game({super.key, required this.onDone});

  final Function onDone;

  @override
  State<Game> createState() => _GameState();
}
