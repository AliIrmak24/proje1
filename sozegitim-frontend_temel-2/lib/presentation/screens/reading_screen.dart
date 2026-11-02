import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/speech/speaker.dart';
import '../../core/theme/app_colors.dart';
import '../../data/reading_articles.dart';
import '../providers/auth_provider.dart';

class ReadingScreen extends StatefulWidget {
  final VoidCallback onGoBack;

  const ReadingScreen({super.key, required this.onGoBack});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  ReadingArticle? _article;
  String? _levelFilter;
  bool _showSummary = false;
  final Map<int, int> _answers = {};

  void _openArticle(ReadingArticle article) {
    setState(() {
      _article = article;
      _showSummary = false;
      _answers.clear();
    });
  }

  bool get _allAnswered => _answers.length == (_article?.questions.length ?? 0);

  Future<void> _finishReading() async {
    final article = _article!;
    final correct = article.questions.indexed
        .where((entry) => _answers[entry.$1] == entry.$2.correctIndex)
        .length;
    final passed = correct * 2 >= article.questions.length;

    setState(() => _article = null);
    final earnedXp = passed ? await context.read<AuthProvider>().awardActivityXp('reading', 1) : 0;
    if (!mounted) return;

    final total = article.questions.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(earnedXp > 0
            ? 'Tebrikler! $correct/$total doğru (+$earnedXp XP) 🏆'
            : 'Okuma tamamlandı: $correct/$total doğru'),
        backgroundColor: passed ? Colors.green : AppColors.cardNavy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _levelColor(String level) {
    if (level.contains('C')) return Colors.purpleAccent;
    if (level.contains('B')) return AppColors.green;
    return AppColors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final article = _article;
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(child: article == null ? _buildList() : _buildDetail(article)),
    );
  }

  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.white, size: 26),
      ),
    );
  }

  Widget _buildList() {
    final filtered = _levelFilter == null
        ? readingArticles
        : readingArticles.where((a) => a.level.contains(_levelFilter!)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              _backButton(widget.onGoBack),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metin Okuma',
                      style: TextStyle(color: AppColors.yellow, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Seviyeli okuma metinleri',
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _filterChip('Tümü', null),
              const SizedBox(width: 8),
              _filterChip('A1-A2 Başlangıç', 'A'),
              const SizedBox(width: 8),
              _filterChip('B1-B2 Orta', 'B'),
              const SizedBox(width: 8),
              _filterChip('C1-C2 İleri', 'C'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _articleCard(filtered[index]),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _levelFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _levelFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.yellow : AppColors.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.yellow : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.darkNavy : AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _levelBadge(String level) {
    final color = _levelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 0.9),
      ),
      child: Text(level, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _articleCard(ReadingArticle article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _levelBadge(article.level),
                Text(
                  '${article.readingTimeMinutes} dk okuma',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              article.turkishTitle,
              style: const TextStyle(color: AppColors.yellow, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              article.englishContent.split('\n\n').first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(article.category, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(ReadingArticle article) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              _backButton(() => setState(() => _article = null)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.yellow, fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Metni dinle',
                onPressed: () => Speaker.speak(article.englishContent),
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.yellow),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _levelBadge(article.level),
                const SizedBox(height: 14),
                Text(
                  article.englishContent,
                  style: const TextStyle(color: AppColors.white, fontSize: 17, height: 1.6),
                ),
                const SizedBox(height: 20),
                _summaryCard(article),
                const SizedBox(height: 20),
                const Text(
                  'Kilit Kelimeler',
                  style: TextStyle(color: AppColors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...article.keyVocabulary.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${item['word']} (${item['level']}): ${item['translation']}',
                        style: const TextStyle(color: AppColors.grey, fontSize: 14),
                      ),
                    )),
                const SizedBox(height: 20),
                const Text(
                  'Anlama Soruları',
                  style: TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...article.questions.indexed.map((entry) => _questionCard(entry.$1, entry.$2)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.darkNavy,
                      disabledBackgroundColor: AppColors.cardNavy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _allAnswered ? _finishReading : null,
                    child: Text(
                      _allAnswered ? 'Okumayı Bitir' : 'Soruları Cevapla',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(ReadingArticle article) {
    return GestureDetector(
      onTap: () => setState(() => _showSummary = !_showSummary),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Türkçe Özet',
                  style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Icon(
                  _showSummary ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.grey,
                ),
              ],
            ),
            if (_showSummary) ...[
              const SizedBox(height: 8),
              Text(article.turkishSummary, style: const TextStyle(color: AppColors.white, fontSize: 14, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _questionCard(int index, ReadingQuestion question) {
    final selected = _answers[index];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...question.options.indexed.map((option) {
            final isCorrect = option.$1 == question.correctIndex;
            final isSelected = option.$1 == selected;
            Color border = AppColors.cardBorder;
            if (selected != null && isCorrect) border = Colors.greenAccent;
            if (isSelected && !isCorrect) border = Colors.redAccent;

            return GestureDetector(
              onTap: selected == null ? () => setState(() => _answers[index] = option.$1) : null,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Text(option.$2, style: const TextStyle(color: AppColors.white, fontSize: 14)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
