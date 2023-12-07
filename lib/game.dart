import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ttt/config.dart';
import 'package:ttt/countdown_widget.dart';
import 'package:ttt/effects_player.dart';
import 'package:ttt/question.dart';
import 'package:ttt/stats.dart';

/// We want the user to be this quick or better at all questions
const Duration _targetDuration = Duration(seconds: 5);

/// Show hint after this delay
final Duration _hintDelay = _targetDuration * 2;

class _GameState extends State<Game> {
  // Game state
  Question? _question;
  late bool _currentHasBeenWrong;
  late bool _currentIsOnTheRightTrack;
  int _rightOnFirstAttempt = 0;

  bool _countingDown = true;

  bool _tooSlow = false;
  Timer? _tooSlowTimer;

  late Timer _progressTimer;

  // Used for ensuring the display gets updated as time passes
  double _elapsedSeconds = 0.0;

  // Stats state
  late DateTime _startTime;

  final TextEditingController _controller = TextEditingController();

  void _initState() {
    setState(() {
      _countingDown = false;
      _startTime = DateTime.now();

      _progressTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _elapsedSeconds =
              DateTime.now().difference(_startTime).inMilliseconds / 1000.0;
        });
      });

      _generateQuestion();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tooSlowTimer?.cancel();
    _progressTimer.cancel();
    super.dispose();
  }

  void _nextQuestion() {
    setState(() {
      if (!_currentHasBeenWrong) {
        _rightOnFirstAttempt++;
      }

      var gameDuration = DateTime.now().difference(_startTime);
      if (gameDuration > widget.duration) {
        widget.onDone(Stats(
            duration: gameDuration, rightOnFirstAttempt: _rightOnFirstAttempt));
      }
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    setState(() {
      final c = widget.config;
      _question = Question.generate(
          c.tablesToTest, c.multiplication, c.division, _question);
      _currentHasBeenWrong = false;
      _currentIsOnTheRightTrack = true;

      _tooSlowTimer?.cancel();

      _tooSlow = false;
      _tooSlowTimer = Timer(_hintDelay, () {
        setState(() {
          _tooSlow = true;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_countingDown) {
      return CountdownWidget(onFinished: _initState);
    }

    String? hintText = _tooSlow ? _question!.answer : null;

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

    bool gameOverTime = _elapsedSeconds > widget.duration.inSeconds;
    double? progress =
        gameOverTime ? null : _elapsedSeconds / widget.duration.inSeconds;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _question!.getQuestionText(),
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
                    if (text == _question!.answer) {
                      widget.effectsPlayer.playDing();
                      _controller.clear();
                      _nextQuestion();
                      return;
                    }
                    if (_question!.answer.startsWith(text)) {
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
          value: progress,
        ),
      ],
    );
  }
}

class Game extends StatefulWidget {
  Game(
      {super.key,
      required this.config,
      required this.effectsPlayer,
      required this.onDone})
      : duration = kDebugMode ? const Duration(seconds: 10) : config.duration;

  final Config config;

  final EffectsPlayer effectsPlayer;
  final Function(Stats stats) onDone;
  final Duration duration;

  @override
  State<Game> createState() => _GameState();
}
