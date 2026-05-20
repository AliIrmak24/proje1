import '../../domain/entities/word.dart';

class WordModel extends Word {
  WordModel({
    required super.word,
    required super.translation,
    required super.level,
    super.phonetic,
    required super.meanings,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      word: json['word'] ?? "Bilinmiyor",
      translation: json['translation'] ?? "Çeviri yok",
      level: json['level'] ?? "A1",
      phonetic: json['phonetic'],
      meanings: json['meanings'] != null
          ? (json['meanings'] as List)
              .map((m) => MeaningModel.fromJson(m))
              .toList()
          : [], // Hata çıkmasın diye boş liste
    );
  }
}

class MeaningModel extends Meaning {
  MeaningModel({
    required super.partOfSpeech,
    required super.definition,
    super.example,
  });

  factory MeaningModel.fromJson(Map<String, dynamic> json) {
    return MeaningModel(
      partOfSpeech: json['partOfSpeech'] ?? "",
      definition: json['definition'] ?? "",
      example: json['example'],
    );
  }
}
