import '../../domain/entities/word.dart';

class WordModel extends Word {
  WordModel({
    required super.id,
    required super.word,
    required super.translation,
    required super.level,
    super.phonetic,
    required super.meanings,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] as int? ?? 0,
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
    super.exampleTranslation,
    super.exampleSource,
  });

  factory MeaningModel.fromJson(Map<String, dynamic> json) {
    return MeaningModel(
      partOfSpeech: json['part_of_speech'] ?? json['partOfSpeech'] ?? "",
      definition: json['definition'] ?? "",
      example: json['example'],
      exampleTranslation: json['example_translation'],
      exampleSource: json['example_source'],
    );
  }
}
