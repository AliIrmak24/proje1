import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../providers/dictionary_provider.dart';
import '../widgets/word_card.dart';

class DictionaryScreen extends StatefulWidget {
  final VoidCallback onGoHome;

  const DictionaryScreen({
    super.key,
    required this.onGoHome,
  });

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _performSearch() {
    final term = _searchController.text;
    if (term.trim().isNotEmpty) {
      context.read<DictionaryProvider>().search(term);
      FocusScope.of(context).unfocus();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.trim().isNotEmpty) {
        context.read<DictionaryProvider>().search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 28),
              _searchBar(),
              const SizedBox(height: 32),

              Consumer<DictionaryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: CircularProgressIndicator(color: AppColors.yellow),
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(25), // DÜZELTİLDİ
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withAlpha(76)), // DÜZELTİLDİ
                      ),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                      ),
                    );
                  }

                  if (provider.word != null) {
                    return WordCard(word: provider.word!);
                  }

                  return _buildLevelsSection();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _squareButton(Icons.arrow_back, widget.onGoHome),
        const Text(
          'Sözlük',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        _squareButton(Icons.bookmark_border, () {}),
      ],
    );
  }

  Widget _squareButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.white, size: 30),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.grey, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.white, fontSize: 20),
              decoration: const InputDecoration(
                hintText: 'Kelime ara...',
                hintStyle: TextStyle(color: AppColors.grey, fontSize: 20),
                border: InputBorder.none,
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          GestureDetector(
            onTap: _performSearch,
            child: const Icon(Icons.mic_none, color: AppColors.blue, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seviye Seç',
          style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Öğrenme seviyene uygun kelimeleri keşfet.',
          style: TextStyle(color: AppColors.grey, fontSize: 17),
        ),
        const SizedBox(height: 24),
        _levelCard(level: 'A1', title: 'A1 - Başlangıç', description: 'Temel kelimelerle tanış ve dil yolculuğuna başla.', wordCount: 0, color: AppColors.yellow),
        _levelCard(level: 'A2', title: 'A2 - Temel', description: 'Günlük hayatta sık kullanılan kelimeler.', wordCount: 0, color: AppColors.blue),
        _levelCard(level: 'B1', title: 'B1 - Orta', description: 'Daha fazla kelime, daha iyi ifade.', wordCount: 0, color: AppColors.green),
        _levelCard(level: 'B2', title: 'B2 - Orta Üstü', description: 'Akıcı iletişim için güçlü kelime bilgisi.', wordCount: 0, color: AppColors.purple),
        _levelCard(level: 'C1', title: 'C1 - İleri', description: 'İleri düzey kelimelerle sınırlarını aş.', wordCount: 0, color: Colors.pinkAccent),
        const SizedBox(height: 12),
        _recommendationCard(),
      ],
    );
  }

  Widget _levelCard({required String level, required String title, required String description, required int wordCount, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), bottomLeft: Radius.circular(22))),
          ),
          const SizedBox(width: 22),
          _levelBadge(level, color),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(description, style: const TextStyle(color: AppColors.grey, fontSize: 15.5)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(31), // DÜZELTİLDİ
                    borderRadius: BorderRadius.circular(18), 
                    border: Border.all(color: color.withAlpha(64)) // DÜZELTİLDİ
                  ),
                  child: Text('$wordCount kelime', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey, size: 38),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _levelBadge(String level, Color color) {
    return Container(
      width: 94,
      height: 94,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(56), // DÜZELTİLDİ
            blurRadius: 18, 
            spreadRadius: 1
          )
        ],
      ),
      child: Text(level, style: TextStyle(color: color, fontSize: 34, fontWeight: FontWeight.bold)),
    );
  }

  Widget _recommendationCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.cardBorder)),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.yellow, size: 46),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Senin İçin Öneri', style: TextStyle(color: AppColors.yellow, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Kelime öğreniminde düzenli tekrar yaparak bilgini kalıcı hale getirebilirsin.', style: TextStyle(color: AppColors.grey, fontSize: 15.5, height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.yellow, size: 34),
        ],
      ),
    );
  }
}