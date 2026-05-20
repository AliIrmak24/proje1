import '../../core/network/api_client.dart';
import '../models/word_model.dart';

class WordRemoteDataSource {
  final ApiClient apiClient;

  WordRemoteDataSource({required this.apiClient});

  Future<WordModel> fetchWord(String term) async {
    // İŞTE ROTAYI BURADA SWAGGER'DAKİ GERÇEK ADRESLE DEĞİŞTİRDİK!
    final json = await apiClient.get('/api/words/search/$term');
    return WordModel.fromJson(json);
  }
}