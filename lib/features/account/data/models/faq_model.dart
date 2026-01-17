import 'package:equatable/equatable.dart';

class Faq extends Equatable {
  final String id;
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
  final int displayOrder;

  const Faq({
    required this.id,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    required this.displayOrder,
  });

  factory Faq.fromJson(Map<String, dynamic> json) {
    return Faq(
      id: json['id'] as String,
      questionAr: json['question_ar'] as String,
      questionEn: json['question_en'] as String,
      answerAr: json['answer_ar'] as String,
      answerEn: json['answer_en'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  String getQuestion(String languageCode) {
    return languageCode == 'ar' ? questionAr : questionEn;
  }

  String getAnswer(String languageCode) {
    return languageCode == 'ar' ? answerAr : answerEn;
  }

  @override
  List<Object?> get props => [
    id,
    questionAr,
    questionEn,
    answerAr,
    answerEn,
    displayOrder,
  ];
}
