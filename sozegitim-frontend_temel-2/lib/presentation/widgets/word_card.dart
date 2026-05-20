import 'package:flutter/material.dart';
import 'package:my_app/domain/entities/word.dart';

class WordCard extends StatelessWidget {
  final Word word;

  const WordCard({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.word,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 12),
            Text(
              word.translation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            if (word.phonetic != null) ...[
              const SizedBox(height: 8),
              Text(
                word.phonetic!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (word.meanings.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Anlamlar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...word.meanings.map(
                (meaning) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meaning.partOfSpeech}: ${meaning.definition}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (meaning.example != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Örnek: ${meaning.example}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
