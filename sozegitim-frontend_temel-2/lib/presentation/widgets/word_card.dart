import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/word.dart';

class WordCard extends StatelessWidget {
  final Word word;

  const WordCard({super.key, required this.word});

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return AppColors.yellow;
      case 'A2':
        return AppColors.blue;
      case 'B1':
        return AppColors.green;
      case 'B2':
        return AppColors.purple;
      case 'C1':
      case 'C2':
        return Colors.pinkAccent;
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(word.level);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Satırı: Kelime + Seviye Etiketi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  word.word,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: levelColor, width: 1.5),
                ),
                child: Text(
                  word.level.toUpperCase(),
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          if (word.phonetic != null && word.phonetic!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              word.phonetic!,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),
          // Türkçe Çeviri Bölümü
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withAlpha(120)),
            ),
            child: Row(
              children: [
                const Icon(Icons.translate, color: AppColors.yellow, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    word.translation,
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Anlamlar ve Örnek Cümleler
          if (word.meanings.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Açıklamalar & Örnekler',
              style: TextStyle(
                color: AppColors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...word.meanings.map(
              (meaning) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (meaning.partOfSpeech.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              meaning.partOfSpeech,
                              style: const TextStyle(
                                color: AppColors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            meaning.definition,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (meaning.example != null && meaning.example!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: const Border(
                            left: BorderSide(color: AppColors.yellow, width: 3),
                          ),
                          color: AppColors.darkNavy.withAlpha(120),
                        ),
                        child: Text(
                          '“${meaning.example}”',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
