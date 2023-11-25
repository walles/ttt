import 'package:flutter/material.dart';

class _GameState extends State<Game> {
  int _questionNumberZeroBased = 0;

  void _nextQuestion() {
    setState(() {
      _questionNumberZeroBased++;
      if (_questionNumberZeroBased >= 10) {
        FIXME: Tell our parent we're done
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Question number (0 based): $_questionNumberZeroBased',
        ),
        ElevatedButton(onPressed: _nextQuestion, child: const Text("Start!")),
      ],
    );
  }
}

class Game extends StatefulWidget {
  const Game({Key? key}) : super(key: key);

  @override
  State<Game> createState() => _GameState();
}
