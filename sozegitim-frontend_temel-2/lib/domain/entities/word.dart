class Word {
  final String word;
  final String translation;
  final String level;
  final String? phonetic;
  final List<Meaning> meanings;

  Word({
    required this.word,
    required this.translation,
    required this.level,
    this.phonetic,
    required this.meanings,
  });
}

class Meaning {
  final String partOfSpeech;
  final String definition;
  final String? example;

  Meaning({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });
}
