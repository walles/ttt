import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ttt/stats.dart';

class _GameState extends State<Game> {
  int _questionNumberOneBased = 0;
  String _question = "";
  String _answer = "";

  final DateTime _startTime = DateTime.now();

  void _nextQuestion() {
    setState(() {
      _questionNumberOneBased++;
      if (_questionNumberOneBased > 10) {
        widget.onDone(Stats(duration: DateTime.now().difference(_startTime)));
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
    TextEditingController controller = TextEditingController();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_questionNumberOneBased/10: $_question',
            ),
            SizedBox(
              width: 100,
              child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter("100".length),
                  ],
                  onChanged: (text) {
                    if (text == _answer) {
                      controller.clear();
                      _nextQuestion();
                    }
                  }),
            ),
          ],
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
