import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/network/api_client.dart';
import '../../core/speech/speaker.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/word_model.dart';
import '../../data/offline_words.dart';

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
  final ApiClient _apiClient = ApiClient();
  Timer? _debounce;

  String _searchQuery = '';
  String? _selectedLevel; // null = Tümü, 'A1', 'A2', 'B1', 'B2', 'C1'
  bool _showLevelCards = true; // Seviye kartları ekranı görünümü

  static const int _pageSize = 50;

  final ScrollController _scrollController = ScrollController();
  List<WordModel> _words = [];
  bool _isSyncing = false;
  bool _hasMore = true;
  bool _isOffline = false;
  Map<String, int> _levelCounts = {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0};
  final Map<String, Map<String, dynamic>> _notes = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchLevelCounts();
    _fetchNotes();
    _reloadWords();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchLevelCounts() async {
    try {
      final res = await _apiClient.get('/api/words/counts');
      if (mounted && res is Map<String, dynamic>) {
        setState(() {
          _levelCounts = res.map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0));
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchNotes() async {
    try {
      final res = await _apiClient.get('/api/notes/my-notes');
      if (mounted && res is List) {
        for (final note in res.cast<Map<String, dynamic>>()) {
          _notes[note['word'].toString().toLowerCase()] = note;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _reloadWords() async {
    if (!mounted) return;
    setState(() {
      _words = [];
      _hasMore = true;
    });
    await _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    if (!mounted || _isSyncing || !_hasMore) return;
    setState(() => _isSyncing = true);

    final query = <String, String>{
      'limit': '$_pageSize',
      'offset': '${_words.length}',
      'level': ?_selectedLevel,
      if (_searchQuery.isNotEmpty) 'search': _searchQuery,
    };

    try {
      final res = await _apiClient.get(Uri(path: '/api/words/', queryParameters: query).toString());
      if (mounted && res is List) {
        setState(() {
          _isOffline = false;
          _words = [..._words, ...res.map((w) => WordModel.fromJson(w as Map<String, dynamic>))];
          _hasMore = res.length == _pageSize;
          _isSyncing = false;
        });
        return;
      }
    } catch (_) {
      await _loadOfflineWords();
    }

    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _loadOfflineWords() async {
    final query = _searchQuery.toLowerCase();
    final offlineWords = (await OfflineWords.load()).where((w) {
      final matchesLevel = _selectedLevel == null || w.level == _selectedLevel;
      return matchesLevel && (w.word.toLowerCase().contains(query) || w.translation.toLowerCase().contains(query));
    }).toList();

    if (mounted) {
      setState(() {
        _isOffline = true;
        _words = offlineWords;
        _hasMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
      if (_searchQuery.isNotEmpty) {
        _showLevelCards = false;
      }
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _reloadWords);
  }

  void _selectLevel(String? level) {
    setState(() {
      _selectedLevel = level;
      _showLevelCards = false;
    });
    _reloadWords();
  }

  Future<void> _saveNote(WordModel word, String text) async {
    final key = word.word.toLowerCase();
    final existing = _notes[key];
    if (text.isEmpty) {
      if (existing != null) {
        await _apiClient.delete('/api/notes/delete/${existing['id']}');
        _notes.remove(key);
      }
      return;
    }
    final saved = await _apiClient.post('/api/notes/add', {
      'word': word.word,
      'translation': word.translation,
      'personal_note': text,
    });
    _notes[key] = saved as Map<String, dynamic>;
  }

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
        return Colors.pinkAccent;
      case 'C2':
        return Colors.redAccent;
      default:
        return AppColors.yellow;
    }
  }

  void _showWordDetailModal(WordModel word) {
    final levelColor = _getLevelColor(word.level);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.darkNavy,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      word.word,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Telaffuzu dinle',
                    onPressed: () => Speaker.speak(word.word),
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.yellow),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColor.withAlpha(45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: levelColor, width: 1.5),
                    ),
                    child: Text(
                      word.level.toUpperCase(),
                      style: TextStyle(
                        color: levelColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 18),
              Container(
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
                    const Text('Türkçe Karşılığı', style: TextStyle(color: AppColors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      word.translation,
                      style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              if (word.meanings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Detaylı Anlam ve Örnek Cümle', style: TextStyle(color: AppColors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...word.meanings.map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.blue.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.partOfSpeech.toUpperCase(),
                                style: const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(m.definition, style: const TextStyle(color: AppColors.white, fontSize: 15)),
                        if (m.example != null && m.example!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('“${m.example}”', style: const TextStyle(color: AppColors.grey, fontStyle: FontStyle.italic, fontSize: 14)),
                          if (m.exampleTranslation != null) ...[
                            const SizedBox(height: 4),
                            Text(m.exampleTranslation!, style: const TextStyle(color: AppColors.blue, fontSize: 13)),
                          ],
                          if (m.exampleSource != null) ...[
                            const SizedBox(height: 4),
                            Text(m.exampleSource!, style: const TextStyle(color: AppColors.grey, fontSize: 10)),
                          ],
                        ],
                      ],
                    ),
                  );
                }),
              ],

              // KİŞİSEL KELİME NOTU
              const SizedBox(height: 16),
              () {
                final noteController = TextEditingController(
                  text: _notes[word.word.toLowerCase()]?['personal_note']?.toString() ?? '',
                );
                String? saveMessage;

                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.yellow.withAlpha(160), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kişisel Notum',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bu kelime için kendi cümleni veya özel anlamını buraya not edebilirsin:',
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          style: const TextStyle(color: AppColors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Örn: Bu kelimeyi bir makalede gördüm veya bu anlamda kullandım...',
                            hintStyle: TextStyle(color: AppColors.grey.withAlpha(120), fontSize: 13),
                            filled: true,
                            fillColor: AppColors.darkNavy,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.yellow),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.yellow,
                              foregroundColor: AppColors.darkNavy,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: Text(
                              saveMessage ?? 'Notu Kaydet',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: () async {
                              try {
                                await _saveNote(word, noteController.text.trim());
                                saveMessage = 'Kaydedildi ✓';
                              } catch (_) {
                                saveMessage = 'Kaydedilemedi, bağlantını kontrol et';
                              }
                              if (context.mounted) setModalState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }(),

              const SizedBox(height: 14),
              const Text(
                'Kaynak: Vikisözlük (CC BY-SA 4.0), örnekler Tatoeba (CC BY 2.0 FR). Ayrıntılar Ayarlar > Hakkımızda bölümünde.',
                style: TextStyle(color: AppColors.grey, fontSize: 11),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat', style: TextStyle(color: AppColors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
              child: _header(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
              child: _searchBar(),
            ),
            Expanded(
              child: _showLevelCards && _searchQuery.isEmpty
                  ? _buildLevelsSection()
                  : _buildWordListSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _squareButton(Icons.arrow_back, widget.onGoHome),
        Row(
          children: [
            const Text(
              'Sözlük',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isSyncing) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow),
              ),
            ],
          ],
        ),
        _squareButton(
          _showLevelCards ? Icons.list_alt_rounded : Icons.grid_view_rounded,
          () {
            setState(() {
              _showLevelCards = !_showLevelCards;
              if (_showLevelCards) {
                _selectedLevel = null;
              }
            });
            _reloadWords();
          },
        ),
      ],
    );
  }

  Widget _squareButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.white, size: 24),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.grey, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.white, fontSize: 17),
              decoration: const InputDecoration(
                hintText: 'Kelime veya anlam ara (örn: apple, meraklı)...',
                hintStyle: TextStyle(color: AppColors.grey, fontSize: 15),
                border: InputBorder.none,
              ),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: const Icon(Icons.close, color: AppColors.grey, size: 22),
            ),
        ],
      ),
    );
  }

  // --- SEVİYE KARTLARI GÖRÜNÜMÜ (Ekran Görüntüsündeki Tasarım + Gerçek Canlı Sayılar) ---
  Widget _buildLevelsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seviye Seç',
                      style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Öğrenme seviyene uygun kelimeleri keşfet.',
                      style: TextStyle(color: AppColors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _selectLevel(null),
                icon: const Icon(Icons.list_alt, color: AppColors.yellow, size: 18),
                label: const Text('Tümü', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _levelCard(
            level: 'A1',
            title: 'A1 - Başlangıç',
            description: 'Temel kelimelerle tanış ve dil yolculuğuna başla.',
            wordCount: _levelCounts['A1'] ?? 0,
            color: AppColors.yellow,
          ),
          _levelCard(
            level: 'A2',
            title: 'A2 - Temel',
            description: 'Günlük hayatta sık kullanılan kelimeler.',
            wordCount: _levelCounts['A2'] ?? 0,
            color: AppColors.blue,
          ),
          _levelCard(
            level: 'B1',
            title: 'B1 - Orta',
            description: 'Daha fazla kelime, daha iyi ifade.',
            wordCount: _levelCounts['B1'] ?? 0,
            color: AppColors.green,
          ),
          _levelCard(
            level: 'B2',
            title: 'B2 - Orta Üstü',
            description: 'Akıcı iletişim için güçlü kelime bilgisi.',
            wordCount: _levelCounts['B2'] ?? 0,
            color: AppColors.purple,
          ),
          _levelCard(
            level: 'C1',
            title: 'C1 - İleri',
            description: 'İleri düzey kelimelerle sınırlarını aş.',
            wordCount: _levelCounts['C1'] ?? 0,
            color: Colors.pinkAccent,
          ),
          _levelCard(
            level: 'C2',
            title: 'C2 - Usta',
            description: 'Anadili seviyesinde zengin ve nüanslı kelimeler.',
            wordCount: _levelCounts['C2'] ?? 0,
            color: Colors.redAccent,
          ),

          const SizedBox(height: 10),
          _recommendationCard(),
        ],
      ),
    );
  }

  Widget _levelCard({
    required String level,
    required String title,
    required String description,
    required int wordCount,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _selectLevel(level),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Center(child: _levelBadge(level, color)),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.grey, fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withAlpha(35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withAlpha(80)),
                    ),
                    child: Text(
                      '$wordCount kelime',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey, size: 32),
          const SizedBox(width: 14),
        ],
      ),
    ),
  ),
);
}

  Widget _levelBadge(String level, Color color) {
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(50),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _recommendationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.yellow, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Senin İçin Öneri',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kelime öğreniminde düzenli tekrar yaparak bilgini kalıcı hale getirebilirsin.',
                  style: TextStyle(color: AppColors.grey, fontSize: 13.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- KELİME LİSTESİ ALANI ---
  Widget _buildWordListSection() {
    final filtered = _words;

    return Column(
      children: [
        // Geri Dön Butonu ve Filtre Çipleri
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showLevelCards = true;
                    _selectedLevel = null;
                  });
                  _reloadWords();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: AppColors.yellow, size: 16),
                      SizedBox(width: 6),
                      Text('Seviyeler', style: TextStyle(color: AppColors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _levelFilterBar()),
            ],
          ),
        ),

        const SizedBox(height: 6),

        if (_isOffline)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Çevrimdışısın: uygulamadaki temel kelimeler gösteriliyor.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12.5),
            ),
          ),

        Expanded(
          child: filtered.isEmpty && !_isSyncing
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search_off_rounded, color: AppColors.grey, size: 64),
                      SizedBox(height: 14),
                      Text(
                        'Aramanıza uygun kelime bulunamadı.',
                        style: TextStyle(color: AppColors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final word = filtered[index];
                    return _wordListItem(word);
                  },
                ),
        ),
      ],
    );
  }

  Widget _levelFilterBar() {
    final levels = [
      {'key': null, 'label': 'Tümü', 'count': _levelCounts.values.fold<int>(0, (a, b) => a + b), 'color': AppColors.yellow},
      {'key': 'A1', 'label': 'A1', 'count': _levelCounts['A1'] ?? 0, 'color': AppColors.yellow},
      {'key': 'A2', 'label': 'A2', 'count': _levelCounts['A2'] ?? 0, 'color': AppColors.blue},
      {'key': 'B1', 'label': 'B1', 'count': _levelCounts['B1'] ?? 0, 'color': AppColors.green},
      {'key': 'B2', 'label': 'B2', 'count': _levelCounts['B2'] ?? 0, 'color': AppColors.purple},
      {'key': 'C1', 'label': 'C1', 'count': _levelCounts['C1'] ?? 0, 'color': Colors.pinkAccent},
      {'key': 'C2', 'label': 'C2', 'count': _levelCounts['C2'] ?? 0, 'color': Colors.redAccent},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = levels[index];
          final key = item['key'] as String?;
          final label = item['label'] as String;
          final count = item['count'] as int;
          final color = item['color'] as Color;
          final bool isSelected = _selectedLevel == key;

          return GestureDetector(
            onTap: () => _selectLevel(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.cardNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.darkNavy : AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black.withAlpha(40) : color.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? AppColors.darkNavy : color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wordListItem(WordModel word) {
    final levelColor = _getLevelColor(word.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showWordDetailModal(word),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: levelColor.withAlpha(40),
                    shape: BoxShape.circle,
                    border: Border.all(color: levelColor, width: 2),
                  ),
                  child: Text(
                    word.level.toUpperCase(),
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              word.word,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (word.phonetic != null && word.phonetic!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                word.phonetic!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.translation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}