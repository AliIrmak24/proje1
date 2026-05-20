import 'package:flutter/foundation.dart';
import '../../domain/entities/word.dart';
import '../../domain/usecases/search_word_usecase.dart';

class DictionaryProvider extends ChangeNotifier {
  final SearchWordUseCase searchWordUseCase;

  DictionaryProvider({required this.searchWordUseCase});

  Word? _word;
  bool _isLoading = false;
  String? _error;

  Word? get word => _word;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> search(String term) async {
    if (term.isEmpty) {
      _error = 'Lütfen aramak için bir kelime girin.';
      _word = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _word = null;
    notifyListeners();

    try {
      final result = await searchWordUseCase.execute(term.trim());
      _word = result;
    } catch (exception) {
      _error = 'Hata Detayı: $exception';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}