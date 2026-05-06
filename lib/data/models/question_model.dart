class QuestionModel {
  final String id;
  final String question;
  final String optionA;
  final String optionB;
  final int votesA;
  final int votesB;
  final bool active;
  final DateTime createdAt;

  const QuestionModel({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.votesA,
    required this.votesB,
    required this.active,
    required this.createdAt,
  });

  factory QuestionModel.fromMap(String id, Map<String, dynamic> map) {
    return QuestionModel(
      id: id,
      question: map['question'] ?? '',
      optionA: map['optionA'] ?? 'Evet',
      optionB: map['optionB'] ?? 'Hayır',
      votesA: map['votesA'] ?? 0,
      votesB: map['votesB'] ?? 0,
      active: map['active'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'optionA': optionA,
      'optionB': optionB,
      'votesA': votesA,
      'votesB': votesB,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
