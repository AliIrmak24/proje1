import 'dart:convert';
import 'package:flutter/services.dart';
import 'models/word_model.dart';

/// Sunucuya ulaşılamadığında kullanılan, uygulamayla gelen küçük kelime havuzu.
class OfflineWords {
  OfflineWords._();

  static List<WordModel>? _cache;

  static Future<List<WordModel>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/offline_words.json');
    _cache = (json.decode(raw) as List<dynamic>)
        .map((item) => WordModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
