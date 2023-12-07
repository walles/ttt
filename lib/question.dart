import 'dart:math';

enum Operation { multiplication, division }

class Question {
  final String answer;

  final int a;
  final Operation operation;
  final int b;

  Question._(this.a, this.operation, this.b, this.answer);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Question &&
            runtimeType == other.runtimeType &&
            a == other.a &&
            operation == other.operation &&
            b == other.b &&
            answer == other.answer;
  }

  @override
  int get hashCode {
    return a.hashCode ^ operation.hashCode ^ b.hashCode ^ answer.hashCode;
  }

  static Question generate(Set<int> tablesToTest, bool multiplication,
      bool division, Question? previousQuestion) {
    Question newQuestion;
    while (true) {
      var a = tablesToTest.elementAt(Random().nextInt(tablesToTest.length));

      // Pick a number to multiply with (2 to 10)
      var b = Random().nextInt(9) + 2;

      if (Random().nextBool()) {
        // Switch places between a and b
        var tmp = a;
        a = b;
        b = tmp;
      }

      Operation operation;
      if (multiplication && division) {
        operation =
            Random().nextBool() ? Operation.multiplication : Operation.division;
      } else {
        operation =
            multiplication ? Operation.multiplication : Operation.division;
      }

      String answer;
      if (operation == Operation.multiplication) {
        answer = (a * b).toString();
      } else {
        answer = b.toString();
      }

      newQuestion = Question._(a, operation, b, answer);
      if (previousQuestion == null || newQuestion != previousQuestion) {
        return newQuestion;
      }
    }
  }

  String getQuestionText() {
    if (operation == Operation.multiplication) {
      return "$a×$b=";
    } else {
      return "${a * b}/$a=";
    }
  }
}
