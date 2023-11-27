import 'dart:math';

class Question {
  final String question;
  final String answer;

  Question._(this.question, this.answer);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Question &&
            runtimeType == other.runtimeType &&
            question == other.question &&
            answer == other.answer;
  }

  @override
  int get hashCode {
    return question.hashCode ^ answer.hashCode;
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

      bool isMultiplication; // Else division
      if (multiplication && division) {
        isMultiplication = Random().nextBool();
      } else {
        isMultiplication = multiplication;
      }

      String question;
      String answer;
      if (isMultiplication) {
        question = "$a×$b=";
        answer = (a * b).toString();
      } else {
        question = "${a * b}/$a=";
        answer = b.toString();
      }

      newQuestion = Question._(question, answer);
      if (previousQuestion == null || newQuestion != previousQuestion) {
        return newQuestion;
      }
    }
  }
}
