import '../datasources/word_remote_datasource.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';

class WordRepositoryImpl implements WordRepository {
  final WordRemoteDataSource remoteDataSource;

  WordRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Word> searchWord(String term) {
    return remoteDataSource.fetchWord(term);
  }
}