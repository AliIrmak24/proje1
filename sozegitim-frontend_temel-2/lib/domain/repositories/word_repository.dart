import 'package:my_app/domain/entities/word.dart';

abstract class WordRepository {
  Future<Word> searchWord(String term);
}
