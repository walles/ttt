import 'dart:async';

import 'package:flutter/material.dart';

class CountdownWidget extends StatefulWidget {
  const CountdownWidget({
    super.key,
    required this.onFinished,
  });

  final VoidCallback onFinished;

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _countdown--;
        if (_countdown == 0) {
          _timer.cancel();
          widget.onFinished();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _countdown.toString(),
        style: Theme.of(context).textTheme.displayLarge,
      ),
    );
  }
}
