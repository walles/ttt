import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ttt/countdown_widget.dart';
import 'package:ttt/effects_player.dart';
import 'package:ttt/long_term_stats.dart';
import 'package:ttt/question.dart';
import 'package:ttt/question_generator.dart';
import 'package:ttt/question_spec.dart';
import 'package:ttt/stats.dart';

/// We want the user to be this quick or better at all questions
const Duration _targetDuration = Duration(seconds: 5);

/// Show hint after this delay
final Duration _hintDelay = _targetDuration * 2;

class _GameState extends State<Game> {
  _GameState();

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
  late DateTime _gameStartTime;
  late DateTime _questionStartTime;

  final TextEditingController _controller = TextEditingController();

  final DateTime _roundStart = DateTime.now();

  void _initState() {
    setState(() {
      _countingDown = false;
      _gameStartTime = DateTime.now();

      _progressTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _elapsedSeconds =
              DateTime.now().difference(_gameStartTime).inMilliseconds / 1000.0;
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

      widget.onQuestionAnswered(
          _question!,
          DateTime.now().difference(_questionStartTime),
          !_currentHasBeenWrong,
          _questionStartTime,
          _roundStart);

      var gameDuration = DateTime.now().difference(_gameStartTime);
      if (gameDuration > widget.duration) {
        widget.onDone(Stats(
            duration: gameDuration, rightOnFirstAttempt: _rightOnFirstAttempt));
      }
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    setState(() {
      _question = widget._questionGenerator
          .generate(widget.questionSpec, widget.stats, _question);
      _currentHasBeenWrong = false;
      _currentIsOnTheRightTrack = true;

      _tooSlowTimer?.cancel();

      _tooSlow = false;
      _tooSlowTimer = Timer(_hintDelay, () {
        setState(() {
          _tooSlow = true;
        });
      });

      _questionStartTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_countingDown) {
      return CountdownWidget(onFinished: _initState);
    }

    String? hintText = _tooSlow ? _question!.answer.toString() : null;

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
                    if (text == _question!.answer.toString()) {
                      widget.effectsPlayer.playDing();
                      _controller.clear();
                      _nextQuestion();
                      return;
                    }
                    if (_question!.answer.toString().startsWith(text)) {
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
  Game({
    super.key,
    required this.questionSpec,
    required duration,
    required this.stats,
    required this.effectsPlayer,
    required this.onQuestionAnswered,
    required this.onDone,
  }) : duration = kDebugMode ? const Duration(seconds: 10) : duration;

  final QuestionGenerator _questionGenerator = QuestionGenerator();

  final QuestionSpec questionSpec;
  final Duration duration;
  final LongTermStats stats;

  final EffectsPlayer effectsPlayer;
  final Function(Question question, Duration duration, bool correct,
      DateTime timestamp, DateTime roundStart) onQuestionAnswered;
  final Function(Stats stats) onDone;

  @override
  State<Game> createState() => _GameState();
}
