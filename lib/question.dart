enum Operation { multiplication, division }

class Question {
  final int answer;

  final int a;
  final Operation operation;
  final int b;

  Question(this.a, this.operation, this.b, this.answer);

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

  String getQuestionText() {
    if (operation == Operation.multiplication) {
      return "$a×$b=";
    } else {
      return "${a * b}/$a=";
    }
  }

  Map<String, dynamic> toJson() => {
        'a': a,
        'operation': operation == Operation.multiplication ? '*' : '/',
        'b': b,
        'answer': answer,
      };

  Question.fromJson(Map<String, dynamic> json)
      : a = json['a'],
        operation = json['operation'] == '*'
            ? Operation.multiplication
            : Operation.division,
        b = json['b'],
        answer = int.parse(json['answer'].toString());
}
