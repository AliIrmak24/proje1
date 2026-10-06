import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/word_model.dart';

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

  // Çevrimdışı ve ilk açılış için zengin kelime havuzu
  static final List<WordModel> _defaultWords = [
    // A1 (8 kelime)
    WordModel(word: 'Apple', translation: 'Elma', level: 'A1', phonetic: '/ˈæp.əl/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Ağaçta yetişen yuvarlak, tatlı meyve.', example: 'I eat an apple every morning.')
    ]),
    WordModel(word: 'Book', translation: 'Kitap', level: 'A1', phonetic: '/bʊk/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Okumak veya yazmak için ciltlenmiş yapraklar.', example: 'She is reading a wonderful book.')
    ]),
    WordModel(word: 'Friend', translation: 'Arkadaş, dost', level: 'A1', phonetic: '/frend/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Karşılıklı sevgi ve güven duyulan kişi.', example: 'He is my best friend from school.')
    ]),
    WordModel(word: 'Water', translation: 'Su', level: 'A1', phonetic: '/ˈwɔː.tər/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Yaşam için vazgeçilmez berrak sıvı.', example: 'Drink plenty of water every day.')
    ]),
    WordModel(word: 'House', translation: 'Ev, konut', level: 'A1', phonetic: '/haʊs/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'İnsanların barındığı yapı.', example: 'They bought a new house near the park.')
    ]),
    WordModel(word: 'Happy', translation: 'Mutlu, sevinçli', level: 'A1', phonetic: '/ˈhæp.i/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'İyi hissetme ve tatmin olma durumu.', example: 'We are very happy to meet you.')
    ]),
    WordModel(word: 'Brave', translation: 'Cesur, korkusuz', level: 'A1', phonetic: '/breɪv/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Tehlikelerden korkmayan, yürekli.', example: 'The brave firefighter saved the cat.')
    ]),
    WordModel(word: 'Family', translation: 'Aile', level: 'A1', phonetic: '/ˈfæm.əl.i/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Anne, baba ve çocuklardan oluşan topluluk.', example: 'Family comes first in life.')
    ]),

    // A2 (11 kelime)
    WordModel(word: 'Curious', translation: 'Meraklı, ilgili', level: 'A2', phonetic: '/ˈkjʊə.ri.əs/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Bir şeyi öğrenmek veya bilmek isteyen.', example: 'Children are naturally curious about nature.')
    ]),
    WordModel(word: 'Travel', translation: 'Seyahat etmek, gezmek', level: 'A2', phonetic: '/ˈtræv.əl/', meanings: [
      MeaningModel(partOfSpeech: 'fiil', definition: 'Bir yerden bir yere gitmek.', example: 'They love to travel around the world.')
    ]),
    WordModel(word: 'Knowledge', translation: 'Bilgi, birikim', level: 'A2', phonetic: '/ˈnɒl.ɪdʒ/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Öğrenme veya gözlem yoluyla kazanılan şey.', example: 'Reading is the foundation of knowledge.')
    ]),
    WordModel(word: 'Advice', translation: 'Tavsiye, öğüt', level: 'A2', phonetic: '/ədˈvaɪs/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Yol gösterici öneri.', example: 'She gave me valuable advice on my career.')
    ]),
    WordModel(word: 'Healthy', translation: 'Sağlıklı, sıhhatli', level: 'A2', phonetic: '/ˈhel.θi/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Bedensel ve ruhsal olarak iyi durumda olan.', example: 'Daily exercise keeps you healthy.')
    ]),
    WordModel(word: 'Simple', translation: 'Basit, sade', level: 'A2', phonetic: '/ˈsɪm.pəl/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Anlaşılması veya yapılması kolay olan.', example: 'The solution was surprisingly simple.')
    ]),
    WordModel(word: 'Growth', translation: 'Büyüme, gelişim', level: 'A2', phonetic: '/ɡrəʊθ/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Zamanla olgunlaşma ve genişleme.', example: 'Personal growth requires continuous effort.')
    ]),
    WordModel(word: 'Goal', translation: 'Hedef, amaç', level: 'A2', phonetic: '/ɡəʊl/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Ulaşılmak istenen nokta veya gaye.', example: 'Setting clear goals is the first step.')
    ]),
    WordModel(word: 'Success', translation: 'Başarı, muvaffakiyet', level: 'A2', phonetic: '/səkˈses/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'İstenen sonuca ulaşma durumu.', example: 'Success comes with consistent practice.')
    ]),
    WordModel(word: 'Freedom', translation: 'Özgürlük, hürriyet', level: 'A2', phonetic: '/ˈfriː.dəm/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Kendi iradesiyle karar verebilme.', example: 'Education brings true freedom.')
    ]),
    WordModel(word: 'Honesty', translation: 'Dürüstlük, doğruluk', level: 'A2', phonetic: '/ˈɒn.ə.sti/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Doğru ve samimi davranma ilkesi.', example: 'Honesty is always the best policy.')
    ]),

    // B1 (10 kelime)
    WordModel(word: 'Challenge', translation: 'Meydan okuma, zorluk', level: 'B1', phonetic: '/ˈtʃæl.ɪndʒ/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Yetenek ve çaba gerektiren güç durum.', example: 'Learning coding is an exciting challenge.')
    ]),
    WordModel(word: 'Inspire', translation: 'İlham vermek, esinlendirmek', level: 'B1', phonetic: '/ɪnˈspaɪər/', meanings: [
      MeaningModel(partOfSpeech: 'fiil', definition: 'Birinde bir şey yapma isteği uyandırmak.', example: 'Her courage inspired everyone in the team.')
    ]),
    WordModel(word: 'Opportunity', translation: 'Fırsat, imkan', level: 'B1', phonetic: '/ˌɒp.əˈtʃuː.nə.ti/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Bir işi gerçekleştirmeye elverişli durum.', example: 'This internship is a great career opportunity.')
    ]),
    WordModel(word: 'Courage', translation: 'Cesaret, yüreklilik', level: 'B1', phonetic: '/ˈkʌr.ɪdʒ/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Korku karşısında yılmama gücü.', example: 'It takes courage to speak in front of people.')
    ]),
    WordModel(word: 'Generous', translation: 'Cömert, eli açık', level: 'B1', phonetic: '/ˈdʒen.ər.əs/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Varlığını paylaşmaktan kaçınmayan.', example: 'He was generous enough to help the students.')
    ]),
    WordModel(word: 'Confidence', translation: 'Özgüven, inanç', level: 'B1', phonetic: '/ˈkɒn.fɪ.dəns/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Kişinin kendine ve yeteneklerine olan güveni.', example: 'Practice builds self-confidence.')
    ]),
    WordModel(word: 'Adventure', translation: 'Macera, serüven', level: 'B1', phonetic: '/ədˈven.tʃər/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Heyecan ve tehlike içeren deneyim.', example: 'Their trip to the Alps was a real adventure.')
    ]),
    WordModel(word: 'Patience', translation: 'Sabır, tahammül', level: 'B1', phonetic: '/ˈpeɪ.ʃəns/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Zorluklara karşı sükunetle bekleme gücü.', example: 'Patience is a bitter plant with sweet fruit.')
    ]),
    WordModel(word: 'Achieve', translation: 'Başarmak, elde etmek', level: 'B1', phonetic: '/əˈtʃiːv/', meanings: [
      MeaningModel(partOfSpeech: 'fiil', definition: 'Çalışarak amaca ulaşmak.', example: 'You will achieve great things with dedication.')
    ]),
    WordModel(word: 'Discovery', translation: 'Keşif, buluş', level: 'B1', phonetic: '/dɪˈskʌv.ər.i/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Bilinmeyen bir şeyi ortaya çıkarma.', example: 'Scientific discovery drives civilization.')
    ]),

    // B2 (6 kelime)
    WordModel(word: 'Ambition', translation: 'Büyük başarı arzusu, hırs, azim', level: 'B2', phonetic: '/æmˈbɪʃ.ən/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Büyük bir hedefe ulaşma kararlılığı ve isteği.', example: 'Her ambition is to become a leading software architect.')
    ]),
    WordModel(word: 'Resilient', translation: 'Dirençli, çabuk toparlanan', level: 'B2', phonetic: '/rɪˈzɪl.jənt/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Zorluklar karşısında yılmayan ve toparlanabilen.', example: 'Humans are remarkably resilient when faced with adversity.')
    ]),
    WordModel(word: 'Dedication', translation: 'Adanmışlık, bağlılık', level: 'B2', phonetic: '/ˌded.ɪˈkeɪ.ʃən/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Kendini bir amaca veya göreve verme.', example: 'Success requires immense dedication and patience.')
    ]),
    WordModel(word: 'Wisdom', translation: 'Bilgelik, akıl', level: 'B2', phonetic: '/ˈwɪz.dəm/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Doğru karar verme yeteneği ve deneyim birikimi.', example: 'With age comes deep wisdom and calm.')
    ]),
    WordModel(word: 'Empathy', translation: 'Eşduyum, empati', level: 'B2', phonetic: '/ˈem.pə.θi/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Başkasının hislerini anlama yeteneği.', example: 'Empathy is essential for compassionate leadership.')
    ]),
    WordModel(word: 'Brilliant', translation: 'Parlak, zeki, muazzam', level: 'B2', phonetic: '/ˈbrɪl.jənt/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Olağanüstü zeka veya parlaklık gösteren.', example: 'The scientist proposed a brilliant solution.')
    ]),

    // C1 (5 kelime)
    WordModel(word: 'Persevere', translation: 'Sebat etmek, azmetmek', level: 'C1', phonetic: '/ˌpɜː.sɪˈvɪər/', meanings: [
      MeaningModel(partOfSpeech: 'fiil', definition: 'Tüm zorluklara ve engellere rağmen vazgeçmemek.', example: 'You must persevere through setbacks to master a craft.')
    ]),
    WordModel(word: 'Eloquent', translation: 'Güzel konuşan, beliğ, etkileyici', level: 'C1', phonetic: '/ˈel.ə.kwənt/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Düşüncelerini akıcı ve etkileyici aktaran.', example: 'He gave an eloquent speech at the global summit.')
    ]),
    WordModel(word: 'Meticulous', translation: 'Titiz, kılı kırk yaran', level: 'C1', phonetic: '/məˈtɪk.jə.ləs/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Ayrıntılara aşırı özen gösteren.', example: 'The researcher kept meticulous records of every experiment.')
    ]),
    WordModel(word: 'Inevitable', translation: 'Kaçınılmaz, önüne geçilemez', level: 'C1', phonetic: '/ɪnˈev.ɪ.tə.bəl/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Gerçekleşmesi mutlak olan durum.', example: 'Change is an inevitable reality in technological progress.')
    ]),
    WordModel(word: 'Profound', translation: 'Derin, köklü, nüfuz edici', level: 'C1', phonetic: '/prəˈfaʊnd/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Çok büyük ve derin etki bırakan düşünce veya durum.', example: 'His words had a profound impact on my perspective.')
    ]),

    // C2 (4 kelime)
    WordModel(word: 'Ubiquitous', translation: 'Her yerde bulunan, yaygın', level: 'C2', phonetic: '/juːˈbɪk.wɪ.təs/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Her yerde aynı anda var gibi görünen.', example: 'Mobile phones have become ubiquitous in modern society.')
    ]),
    WordModel(word: 'Ephemeral', translation: 'Geçici, kısa ömürlü', level: 'C2', phonetic: '/ɪˈfem.ər.əl/', meanings: [
      MeaningModel(partOfSpeech: 'sıfat', definition: 'Çok kısa süre devam eden.', example: 'Fame can be ephemeral in the age of social media.')
    ]),
    WordModel(word: 'Paradigm', translation: 'Örüntü, model, paradigma', level: 'C2', phonetic: '/ˈpær.ə.daɪm/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Bir alandaki temel düşünce veya davranış kalıbı.', example: 'The internet created a new paradigm for communication.')
    ]),
    WordModel(word: 'Serendipity', translation: 'Şans eseri keşif, tesadüfi buluş', level: 'C2', phonetic: '/ˌser.ənˈdɪp.ə.ti/', meanings: [
      MeaningModel(partOfSpeech: 'isim', definition: 'Tesadüfen güzel ve değerli bir şey bulmak.', example: 'Their meeting was pure serendipity.')
    ]),
  ];

  late List<WordModel> _allWords;
  bool _isSyncing = false;
  Map<String, int> _levelCounts = {
    'A1': 729,
    'A2': 738,
    'B1': 1383,
    'B2': 766,
    'C1': 1368,
    'C2': 111,
  };

  @override
  void initState() {
    super.initState();
    _allWords = List.from(_defaultWords);
    _recalculateCounts();
    _fetchLevelCounts();
    _fetchFromBackend();
  }

  void _recalculateCounts() {
    if (_allWords.length <= _defaultWords.length) return;
    final counts = {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0};
    for (final w in _allWords) {
      final lvl = w.level.toUpperCase();
      if (counts.containsKey(lvl)) {
        counts[lvl] = (counts[lvl] ?? 0) + 1;
      }
    }
    _levelCounts = counts;
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

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchFromBackend() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);

    try {
      final res = await _apiClient.get('/api/words/?limit=6000');
      if (mounted && res is List && res.isNotEmpty) {
        final serverWords = res.map((w) => WordModel.fromJson(w as Map<String, dynamic>)).toList();
        
        final wordMap = <String, WordModel>{};
        for (final w in _defaultWords) {
          wordMap[w.word.toLowerCase()] = w;
        }
        for (final w in serverWords) {
          wordMap[w.word.toLowerCase()] = w;
        }

        setState(() {
          _allWords = wordMap.values.toList();
          _recalculateCounts();
          _isSyncing = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
      if (_searchQuery.isNotEmpty) {
        _showLevelCards = false;
      }
    });
  }

  List<WordModel> get _filteredWords {
    return _allWords.where((w) {
      final matchesLevel = _selectedLevel == null ||
          w.level.toUpperCase() == _selectedLevel!.toUpperCase();

      if (_searchQuery.isEmpty) {
        return matchesLevel;
      }

      final query = _searchQuery.toLowerCase();
      final matchesWord = w.word.toLowerCase().contains(query);
      final matchesTranslation = w.translation.toLowerCase().contains(query);

      return matchesLevel && (matchesWord || matchesTranslation);
    }).toList();
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
                        ],
                      ],
                    ),
                  );
                }),
              ],

              // 👑 PREMİUM ÖZEL KELİME NOTU KUTUSU
              const SizedBox(height: 16),
              () {
                final noteKey = 'custom_note_${word.word.toLowerCase()}';
                final noteController = TextEditingController();
                bool isSaved = false;

                return StatefulBuilder(
                  builder: (context, setModalState) {
                    // Önceki kaydedilmiş notu getir
                    SharedPreferences.getInstance().then((prefs) {
                      final savedText = prefs.getString(noteKey);
                      if (savedText != null && savedText.isNotEmpty && noteController.text.isEmpty) {
                        noteController.text = savedText;
                        setModalState(() {});
                      }
                    });

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
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium, color: AppColors.yellow, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Premium Özel Notum',
                              style: TextStyle(
                                color: AppColors.yellow,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.yellow.withAlpha(35),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.yellow),
                              ),
                              child: const Text(
                                '👑 Premium Özellik',
                                style: TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
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
                              isSaved ? 'Kaydedildi ✓' : 'Notu Kaydet',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: () async {
                              final text = noteController.text.trim();
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString(noteKey, text);
                              setModalState(() {
                                isSaved = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }(),

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
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
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showLevelCards = false;
                    _selectedLevel = null;
                  });
                },
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
            wordCount: _levelCounts['A1'] ?? 729,
            color: AppColors.yellow,
          ),
          _levelCard(
            level: 'A2',
            title: 'A2 - Temel',
            description: 'Günlük hayatta sık kullanılan kelimeler.',
            wordCount: _levelCounts['A2'] ?? 738,
            color: AppColors.blue,
          ),
          _levelCard(
            level: 'B1',
            title: 'B1 - Orta',
            description: 'Daha fazla kelime, daha iyi ifade.',
            wordCount: _levelCounts['B1'] ?? 1383,
            color: AppColors.green,
          ),
          _levelCard(
            level: 'B2',
            title: 'B2 - Orta Üstü',
            description: 'Akıcı iletişim için güçlü kelime bilgisi.',
            wordCount: _levelCounts['B2'] ?? 766,
            color: AppColors.purple,
          ),
          _levelCard(
            level: 'C1',
            title: 'C1 - İleri',
            description: 'İleri düzey kelimelerle sınırlarını aş.',
            wordCount: _levelCounts['C1'] ?? 1368,
            color: Colors.pinkAccent,
          ),
          _levelCard(
            level: 'C2',
            title: 'C2 - Usta',
            description: 'Anadili seviyesinde zengin ve nüanslı kelimeler.',
            wordCount: _levelCounts['C2'] ?? 111,
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
      onTap: () {
        setState(() {
          _selectedLevel = level;
          _showLevelCards = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
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
            const SizedBox(width: 18),
            _levelBadge(level, color),
            const SizedBox(width: 18),
            Expanded(
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
            const Icon(Icons.chevron_right, color: AppColors.grey, size: 32),
            const SizedBox(width: 14),
          ],
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
    final filtered = _filteredWords;

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

        Expanded(
          child: filtered.isEmpty
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
      {'key': null, 'label': 'Tümü', 'count': _allWords.length > 50 ? _allWords.length : 5095, 'color': AppColors.yellow},
      {'key': 'A1', 'label': 'A1', 'count': _levelCounts['A1'] ?? 729, 'color': AppColors.yellow},
      {'key': 'A2', 'label': 'A2', 'count': _levelCounts['A2'] ?? 738, 'color': AppColors.blue},
      {'key': 'B1', 'label': 'B1', 'count': _levelCounts['B1'] ?? 1383, 'color': AppColors.green},
      {'key': 'B2', 'label': 'B2', 'count': _levelCounts['B2'] ?? 766, 'color': AppColors.purple},
      {'key': 'C1', 'label': 'C1', 'count': _levelCounts['C1'] ?? 1368, 'color': Colors.pinkAccent},
      {'key': 'C2', 'label': 'C2', 'count': _levelCounts['C2'] ?? 111, 'color': Colors.redAccent},
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
            onTap: () {
              setState(() {
                _selectedLevel = key;
              });
            },
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
                            Text(
                              word.phonetic!,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.translation,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
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