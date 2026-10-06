import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../providers/auth_provider.dart';

enum MatchScreenState {
  lobby,          // Oyun Modu Seçimi ve Lobi
  searching,      // Rakip arama animasyonu
  matchingGame,   // Kelime eşleştirme oyunu
  matchingResult, // Eşleştirme oyun sonucu
  flashcards,     // 3D Kart çevirme modu
  flashcardResult,// Kart çevirme sonucu
  readingList,    // Metin Okuma (Reading) Listesi
  readingDetail,  // Metin Okuma Detayı
}

class ReadingArticle {
  final String id;
  final String title;
  final String turkishTitle;
  final String level;
  final String category;
  final int readingTimeMinutes;
  final String englishContent;
  final String turkishSummary;
  final List<Map<String, String>> keyVocabulary;

  ReadingArticle({
    required this.id,
    required this.title,
    required this.turkishTitle,
    required this.level,
    required this.category,
    required this.readingTimeMinutes,
    required this.englishContent,
    required this.turkishSummary,
    required this.keyVocabulary,
  });
}

class MatchingScreen extends StatefulWidget {
  final VoidCallback onGoHome;

  const MatchingScreen({
    super.key,
    required this.onGoHome,
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class MatchingPair {
  final String english;
  final String turkish;
  final String level;
  final String phonetic;
  final String example;

  MatchingPair({
    required this.english,
    required this.turkish,
    required this.level,
    required this.phonetic,
    required this.example,
  });
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  MatchScreenState _currentState = MatchScreenState.lobby;

  // Lobi Animasyonları
  late AnimationController rotateController;
  late AnimationController arrowController;
  late AnimationController pulseController;

  // Flashcard Çevirme Animasyonu
  late AnimationController flipController;
  late Animation<double> flipAnimation;
  bool isCardFront = true;
  int currentCardIndex = 0;
  int masteredCardCount = 0;
  final List<MatchingPair> _reviewWordsPool = [];

  // Eşleştirme Oyunu Değişkenleri
  Timer? _searchTimer;
  Timer? _gameTimer;
  int _remainingSeconds = 45;
  int _score = 0;
  int _streak = 0;
  int _earnedXp = 0;
  String? _submitMessage;

  String? _selectedEnglish;
  String? _selectedTurkish;
  bool? _lastMatchCorrect;

  final Set<String> _matchedEnglish = {};
  final Set<String> _matchedTurkish = {};

  List<MatchingPair> _allGamePairs = [];
  List<String> _shuffledEnglish = [];
  List<String> _shuffledTurkish = [];

  // Rakip Bilgileri
  String _opponentName = 'Yapay Zeka';
  int _opponentLevel = 2;
  int _opponentScore = 0;
  Timer? _opponentTimer;

  // Başlangıç / Çevrimdışı Sözlük Havuzu
  final List<MatchingPair> _vocabularyPool = [
    MatchingPair(english: 'Ambition', turkish: 'Arzu, hırs, azim', level: 'B2', phonetic: '/æmˈbɪʃ.ən/', example: 'Her ambition is to create great apps.'),
    MatchingPair(english: 'Resilient', turkish: 'Dirençli, çabuk toparlanan', level: 'B2', phonetic: '/rɪˈzɪl.jənt/', example: 'Resilient people bounce back quickly.'),
    MatchingPair(english: 'Curious', turkish: 'Meraklı, ilgili', level: 'A2', phonetic: '/ˈkjʊə.ri.əs/', example: 'Children are curious about nature.'),
    MatchingPair(english: 'Inspire', turkish: 'İlham vermek', level: 'B1', phonetic: '/ɪnˈspaɪər/', example: 'Her work inspires many students.'),
    MatchingPair(english: 'Challenge', turkish: 'Meydan okuma, zorluk', level: 'B1', phonetic: '/ˈtʃæl.ɪndʒ/', example: 'Learning languages is a noble challenge.'),
    MatchingPair(english: 'Brave', turkish: 'Cesur, korkusuz', level: 'A1', phonetic: '/breɪv/', example: 'The brave soldier protected everyone.'),
    MatchingPair(english: 'Knowledge', turkish: 'Bilgi, birikim', level: 'A2', phonetic: '/ˈnɒl.ɪdʒ/', example: 'Knowledge brings freedom.'),
    MatchingPair(english: 'Persevere', turkish: 'Sebat etmek, azmetmek', level: 'C1', phonetic: '/ˌpɜː.sɪˈvɪər/', example: 'Persevere through all difficulties.'),
  ];

  ReadingArticle? _selectedArticle;
  String? _readingFilterLevel;
  bool _showTurkishTranslation = false;

  final List<ReadingArticle> _articlesPool = [
    ReadingArticle(
      id: '1',
      title: 'The Magic of Morning Walks',
      turkishTitle: 'Sabah Yürüyüşlerinin Sihri',
      level: 'A1-A2',
      category: 'Sağlık & Yaşam',
      readingTimeMinutes: 2,
      englishContent: '''Walking in the morning is one of the simplest habits for a healthy life. When you wake up early and step outside, the fresh air gives you energy. The city is still quiet, and the sun rises gently in the sky.

Scientists say that walking twenty minutes every day makes your heart stronger and improves your mood. You can listen to gentle music, watch birds in the trees, or simply enjoy the peaceful silence.

Start your tomorrow with a short walk. You will feel energized, positive, and ready for all challenges of the day!''',
      turkishSummary: 'Sabahları erken saatte yapılan kısa yürüyüşler hem kalp sağlığını güçlendirir hem de güne zinde ve pozitif başlamanızı sağlar. Sessiz sokaklar ve temiz hava gün boyu odaklanmanıza yardımcı olur.',
      keyVocabulary: [
        {'word': 'Habit', 'translation': 'Alışkanlık', 'level': 'A2'},
        {'word': 'Peaceful', 'translation': 'Huzurlu, sakin', 'level': 'A2'},
        {'word': 'Improve', 'translation': 'Geliştirmek, iyileştirmek', 'level': 'A2'},
        {'word': 'Challenge', 'translation': 'Zorluk, meydan okuma', 'level': 'B1'},
      ],
    ),
    ReadingArticle(
      id: '2',
      title: 'Coffee Culture Around the World',
      turkishTitle: 'Dünya Genelinde Kahve Kültürü',
      level: 'A1-A2',
      category: 'Kültür & Seyahat',
      readingTimeMinutes: 2,
      englishContent: '''Coffee is much more than a hot drink; it is a global tradition that connects millions of people every day. In Italy, people drink a quick espresso at the bar counter before heading to work. In Turkey, Turkish coffee is served with water and sweet delight, celebrated for deep conversations and hospitality.

In modern Scandinavian countries, the concept of "Fika" means taking a dedicated break with colleagues to drink coffee and eat cinnamon buns. Wherever you travel in the world, sharing a cup of coffee opens doors to new friendships.''',
      turkishSummary: 'Kahve sadece bir içecek değil, insanları bir araya getiren evrensel bir gelenektir. İtalya\'daki hızlı espresso kültüründen Türkiye\'deki dostluk kahvesine ve İskandinav "Fika" molasına kadar her kültür kahveye özel bir anlam yükler.',
      keyVocabulary: [
        {'word': 'Tradition', 'translation': 'Gelenek, anane', 'level': 'A2'},
        {'word': 'Hospitality', 'translation': 'Misafirperverlik', 'level': 'B1'},
        {'word': 'Connect', 'translation': 'Bağlamak, birleştirmek', 'level': 'A2'},
        {'word': 'Colleague', 'translation': 'İş arkadaşı, meslektaş', 'level': 'B1'},
      ],
    ),
    ReadingArticle(
      id: '3',
      title: 'Artificial Intelligence and Future Jobs',
      turkishTitle: 'Yapay Zeka ve Geleceğin Meslekleri',
      level: 'B1-B2',
      category: 'Teknoloji & Bilim Haberi',
      readingTimeMinutes: 3,
      englishContent: '''Artificial intelligence is transforming industries at an extraordinary pace. From healthcare and education to software development and automated finance, intelligent systems can analyze vast amounts of data in seconds.

While routine and repetitive tasks are increasingly automated, experts emphasize that human creativity, critical thinking, and emotional empathy can never be replaced by algorithms. The professionals of tomorrow will not compete against AI; instead, they will collaborate with intelligent tools to solve complex global challenges.

Lifelong learning and adaptability have therefore become the most vital skills of the modern economic era.''',
      turkishSummary: 'Yapay zeka teknolojileri rutin işleri otomatikleştirirken; yaratıcılık, empati ve eleştirel düşünme insanı vazgeçilmez kılmaya devam ediyor. Geleceğin başarılı çalışanları yapay zekayla rekabet etmek yerine onunla işbirliği yapabilen ve sürekli öğrenen bireyler olacaktır.',
      keyVocabulary: [
        {'word': 'Transform', 'translation': 'Dönüştürmek, başkalaştırmak', 'level': 'B2'},
        {'word': 'Extraordinary', 'translation': 'Olağanüstü, fevkalade', 'level': 'B1'},
        {'word': 'Collaborate', 'translation': 'İşbirliği yapmak', 'level': 'B2'},
        {'word': 'Adaptability', 'translation': 'Uyum yeteneği, esneklik', 'level': 'B2'},
      ],
    ),
    ReadingArticle(
      id: '4',
      title: 'Renewable Energy: The Solar Revolution',
      turkishTitle: 'Yenilenebilir Enerji: Güneş Devrimi',
      level: 'B1-B2',
      category: 'Çevre & Dünya Haberi',
      readingTimeMinutes: 3,
      englishContent: '''As global climate concerns intensify, renewable energy has evolved from an alternative idea into the cornerstone of global infrastructure. Over the past decade, the cost of manufacturing solar photovoltaic panels has plummeted by more than eighty percent.

Nations across Europe and Asia are constructing massive solar parks that power millions of homes without generating greenhouse gases. Breakthroughs in battery storage technology are addressing the intermittency problem, ensuring electricity remains available even when clouds gather.

The transition toward green energy represents the greatest industrial transformation of our century, fostering economic growth while preserving the biosphere for posterity.''',
      turkishSummary: 'Güneş panellerinin maliyetlerindeki büyük düşüş ve batarya teknolojilerindeki devrimler, yenilenebilir enerjiyi küresel enerjinin temeli haline getiriyor. Bu yeşil dönüşüm hem ekonomik kalkınma sağlıyor hem de gezegenimizi koruyor.',
      keyVocabulary: [
        {'word': 'Infrastructure', 'translation': 'Altyapı', 'level': 'B2'},
        {'word': 'Plummet', 'translation': 'Hızla düşmek, çakılmak', 'level': 'B2'},
        {'word': 'Intermittent', 'translation': 'Aralıklı, kesintili', 'level': 'B2'},
        {'word': 'Posterity', 'translation': 'Gelecek nesiller, ahfad', 'level': 'C1'},
      ],
    ),
    ReadingArticle(
      id: '5',
      title: 'The Cognitive Architecture of Memory',
      turkishTitle: 'Hafızanın Bilişsel Mimarisi',
      level: 'C1-C2',
      category: 'Bilim & Psikoloji',
      readingTimeMinutes: 4,
      englishContent: '''Human memory is not a passive archive storing pristine records of the past; rather, it is a dynamic, reconstructive cognitive apparatus shaped by neuroplasticity. Contemporary neuroscience demonstrates that every act of recollection subtly recalibrates the underlying synaptic configuration.

Through the mechanism of long-term potentiation, neurons forge robust conduits in response to repeated intellectual stimulation. When learners engage in active recall and spaced repetition, knowledge transcends ephemeral working memory and crystallizes into semantic frameworks within the cerebral cortex.

Understanding these neurobiological principles empowers language learners to orchestrate highly efficacious study paradigms, overcoming the inevitable decay of forgotten information.''',
      turkishSummary: 'Hafıza pasif bir kayıt deposu değil, her hatırlamada yeniden inşa edilen dinamik bir sinirsel ağdır. Aktif hatırlama ve aralıklı tekrar yöntemleri, bilgiyi geçici hafızadan kalıcı serebral korteks yapılarına aktararak kusursuz bir dil öğrenme verimliliği sağlar.',
      keyVocabulary: [
        {'word': 'Neuroplasticity', 'translation': 'Beyin esnekliği, nöroplastisite', 'level': 'C2'},
        {'word': 'Recalibrate', 'translation': 'Yeniden ayarlamak', 'level': 'C1'},
        {'word': 'Ephemeral', 'translation': 'Geçici, uçucu', 'level': 'C2'},
        {'word': 'Efficacious', 'translation': 'Son derece etkili, yararlı', 'level': 'C1'},
      ],
    ),
    ReadingArticle(
      id: '6',
      title: 'Philosophy of Resilience in the Digital Era',
      turkishTitle: 'Dijital Çağda Dirayet ve Felsefe',
      level: 'C1-C2',
      category: 'Felsefe & Kültür',
      readingTimeMinutes: 4,
      englishContent: '''In an era characterized by relentless notifications and hyper-connectivity, cultivating philosophical fortitude has become an indispensable imperative. The ancient Stoics posited that tranquility is derived not from controlling extraneous circumstances, but from mastering one's internal cognitive interpretations.

Modern psychological research vindicates this venerable axiom. Individuals endowed with cognitive equanimity navigate algorithmic noise without relinquishing their moral agency. By prioritizing deliberateness over frantic reactivity, one develops an unassailable sanctuary of mental peace.

True intellectual maturity lies in the discernment between the mutable ephemeral and the transcendent eternal.''',
      turkishSummary: 'Sürekli bildirim ve uyaran bombardımanı altında geçen dijital çağda zihinsel dirayet vazgeçilmez bir erdemdir. Stoacı felsefe ve modern psikoloji, huzurun dış dünyayı değil kendi içsel tepkilerimizi yönetmekten geçtiğini doğrulamaktadır.',
      keyVocabulary: [
        {'word': 'Fortitude', 'translation': 'Metanet, ruh gücü, dirayet', 'level': 'C1'},
        {'word': 'Extraneous', 'translation': 'Dışsal, konu dışı', 'level': 'C1'},
        {'word': 'Equanimity', 'translation': 'Sükunet, soğukkanlılık', 'level': 'C2'},
        {'word': 'Discernment', 'translation': 'Basiret, ince kavrayış, sezgi', 'level': 'C2'},
      ],
    ),
  ];


  @override
  void initState() {
    super.initState();

    rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.92,
      upperBound: 1.08,
    )..repeat(reverse: true);

    flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: flipController, curve: Curves.easeInOut),
    );

    _loadWordsFromBackend();
  }

  @override
  void dispose() {
    rotateController.dispose();
    arrowController.dispose();
    pulseController.dispose();
    flipController.dispose();
    _searchTimer?.cancel();
    _gameTimer?.cancel();
    _opponentTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWordsFromBackend() async {
    try {
      final res = await _apiClient.get('/api/words/');
      if (mounted && res is List && res.isNotEmpty) {
        final List<MatchingPair> loaded = [];
        for (final item in res) {
          final map = item as Map<String, dynamic>;
          final meanings = map['meanings'] as List?;
          String ex = '';
          if (meanings != null && meanings.isNotEmpty) {
            ex = meanings[0]['example']?.toString() ?? '';
          }
          loaded.add(
            MatchingPair(
              english: map['word']?.toString() ?? '',
              turkish: map['translation']?.toString() ?? '',
              level: map['level']?.toString() ?? 'A1',
              phonetic: map['phonetic']?.toString() ?? '',
              example: ex,
            ),
          );
        }
        if (loaded.length >= 5) {
          setState(() {
            _vocabularyPool.clear();
            _vocabularyPool.addAll(loaded);
          });
        }
      }
    } catch (_) {}
  }

  // --- EŞLEŞTİRME OYUNU BAŞLATMA ---
  void _startSearchingOpponent() {
    setState(() {
      _currentState = MatchScreenState.searching;
    });

    final opponents = ['Alex (İngiltere)', 'Mehmet (Türkiye)', 'Emma (Kanada)', 'AI Öğretmen'];
    _opponentName = opponents[Random().nextInt(opponents.length)];
    _opponentLevel = Random().nextInt(3) + 1;

    // 2.5 saniye sonra oyunu başlat
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _initMatchingGame();
    });
  }

  void _initMatchingGame() {
    _vocabularyPool.shuffle();
    final selectedPairs = _vocabularyPool.take(5).toList();

    _allGamePairs = List.from(selectedPairs);
    _shuffledEnglish = selectedPairs.map((p) => p.english).toList()..shuffle();
    _shuffledTurkish = selectedPairs.map((p) => p.turkish).toList()..shuffle();

    _matchedEnglish.clear();
    _matchedTurkish.clear();
    _selectedEnglish = null;
    _selectedTurkish = null;
    _lastMatchCorrect = null;

    _remainingSeconds = 45;
    _score = 0;
    _streak = 0;
    _opponentScore = 0;
    _earnedXp = 0;
    _submitMessage = null;

    setState(() {
      _currentState = MatchScreenState.matchingGame;
    });

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _finishMatchingGame();
      }
    });

    // Rakip botun rastgele puan kazanması
    _opponentTimer?.cancel();
    _opponentTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted || _currentState != MatchScreenState.matchingGame) return;
      setState(() {
        _opponentScore += 100;
      });
    });
  }

  void _onEnglishCardTapped(String word) {
    if (_matchedEnglish.contains(word)) return;
    setState(() {
      _selectedEnglish = word;
      _checkMatchIfBothSelected();
    });
  }

  void _onTurkishCardTapped(String translation) {
    if (_matchedTurkish.contains(translation)) return;
    setState(() {
      _selectedTurkish = translation;
      _checkMatchIfBothSelected();
    });
  }

  void _checkMatchIfBothSelected() {
    if (_selectedEnglish == null || _selectedTurkish == null) return;

    final targetPair = _allGamePairs.firstWhere(
      (p) => p.english == _selectedEnglish,
      orElse: () => MatchingPair(english: '', turkish: '', level: '', phonetic: '', example: ''),
    );

    if (targetPair.turkish == _selectedTurkish) {
      // DOĞRU EŞLEŞTİRME
      _matchedEnglish.add(_selectedEnglish!);
      _matchedTurkish.add(_selectedTurkish!);
      _streak++;
      _score += 100 * _streak;
      _lastMatchCorrect = true;

      _selectedEnglish = null;
      _selectedTurkish = null;

      if (_matchedEnglish.length == _allGamePairs.length) {
        _finishMatchingGame();
      }
    } else {
      // YANLIŞ EŞLEŞTİRME
      _streak = 0;
      _lastMatchCorrect = false;

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _selectedEnglish = null;
          _selectedTurkish = null;
          _lastMatchCorrect = null;
        });
      });
    }
  }

  Future<void> _finishMatchingGame() async {
    _gameTimer?.cancel();
    _opponentTimer?.cancel();

    final correctMatches = _matchedEnglish.length;
    final timeBonus = _remainingSeconds > 0 ? (_remainingSeconds ~/ 3) : 0;
    _earnedXp = (correctMatches * 10) + timeBonus;

    setState(() {
      _currentState = MatchScreenState.matchingResult;
    });

    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      try {
        final res = await _apiClient.post('/api/quiz/submit', {
          'correct_answers': correctMatches + (timeBonus ~/ 10),
        });
        if (mounted) {
          setState(() {
            _earnedXp = (res['earned_xp'] as num?)?.toInt() ?? _earnedXp;
            _submitMessage = 'Tebrikler! Puanların liderlik tablosuna kaydedildi.';
          });
        }
        await auth.fetchUserProfile();
      } catch (_) {
        if (mounted) {
          setState(() {
            _submitMessage = 'Puanın başarıyla hesaplandı (+$_earnedXp XP).';
          });
        }
      }
    } else {
      _submitMessage = 'Misafir Modu: Puanlarını liderlik tablosuna kaydetmek için giriş yapmalısın!';
    }
  }

  // --- FLASHCARDS MODU ---
  void _startFlashcards() {
    _vocabularyPool.shuffle();
    setState(() {
      _currentState = MatchScreenState.flashcards;
      currentCardIndex = 0;
      masteredCardCount = 0;
      isCardFront = true;
    });
    flipController.reset();
  }

  void _flipCard() {
    if (flipController.isAnimating) return;
    if (isCardFront) {
      flipController.forward();
    } else {
      flipController.reverse();
    }
    setState(() {
      isCardFront = !isCardFront;
    });
  }

  void _onFlashcardAnswer(bool mastered) {
    final currentPair = _vocabularyPool[currentCardIndex];
    if (mastered) {
      masteredCardCount++;
    } else {
      // Bilemediğimde öğrenilecek yeni kelimeler havuzuna at
      if (!_reviewWordsPool.any((p) => p.english == currentPair.english)) {
        _reviewWordsPool.add(currentPair);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📌 "${currentPair.english}" öğrenilecek kelimeler havuzuna eklendi!'),
          duration: const Duration(milliseconds: 1300),
          backgroundColor: AppColors.cardNavy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (currentCardIndex < min(10, _vocabularyPool.length) - 1) {
      setState(() {
        currentCardIndex++;
        isCardFront = true;
      });
      flipController.reset();
    } else {
      _finishFlashcards();
    }
  }

  Future<void> _finishFlashcards() async {
    _earnedXp = masteredCardCount * 10;
    setState(() {
      _currentState = MatchScreenState.flashcardResult;
    });

    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      try {
        await _apiClient.post('/api/quiz/submit', {
          'correct_answers': masteredCardCount,
        });
        await auth.fetchUserProfile();
        if (mounted) {
          setState(() {
            _submitMessage = 'Tebrikler! Kart puanların profilinize eklendi.';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _submitMessage = 'Harika çalışma! +$_earnedXp XP kazandın.';
          });
        }
      }
    } else {
      _submitMessage = 'Misafir Modu: Puanlarını kaydetmek için giriş yapmalısın!';
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case MatchScreenState.lobby:
        return _buildLobbyScreen();
      case MatchScreenState.searching:
        return _buildSearchingScreen();
      case MatchScreenState.matchingGame:
        return _buildMatchingGameScreen();
      case MatchScreenState.matchingResult:
        return _buildMatchingResultScreen();
      case MatchScreenState.flashcards:
        return _buildFlashcardsScreen();
      case MatchScreenState.flashcardResult:
        return _buildFlashcardResultScreen();
      case MatchScreenState.readingList:
        return _buildReadingListScreen();
      case MatchScreenState.readingDetail:
        return _buildReadingDetailScreen();
    }
  }

  // 1. LOBİ EKRANI (Oyun Modu Seçimi)
  Widget _buildLobbyScreen() {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final username = user?.username ?? 'Misafir';
    final userLevel = user?.level ?? 1;
    final userXp = '${user?.xp ?? 0} XP';

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 24),
              const Text(
                'SözEğitim Arena',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Oyun modunu seç, kelimeleri pekiştir ve XP kazan!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 16),
              ),
              const SizedBox(height: 28),

              // Kullanıcı Kartı
              Container(
                padding: const EdgeInsets.all(18),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.yellow,
                      child: Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.darkNavy,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seviye $userLevel',
                            style: const TextStyle(color: AppColors.blue, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        userXp,
                        style: const TextStyle(
                          color: AppColors.yellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // MOD 1: Hızlı Kelime Eşleştirme
              _gameModeCard(
                icon: Icons.sports_kabaddi,
                title: 'Kelime Eşleştirme Düellosu',
                description: '45 saniyede İngilizce ve Türkçe kelimeleri doğru eşleştir, rakibini yen!',
                color: AppColors.yellow,
                badge: 'Popüler & Hızlı',
                onTap: _startSearchingOpponent,
              ),

              const SizedBox(height: 20),

              // MOD 2: Akıllı 3D Kart Çevirme (Flashcards)
              _gameModeCard(
                icon: Icons.style_rounded,
                title: 'Akıllı Kart Çevirme (Flashcards)',
                description: 'Kelimeleri 3D kart çevirerek öğren, telaffuz ve örnek cümlelerle hafızana kazı!',
                color: AppColors.blue,
                badge: 'Öğren & Tekrar Et',
                onTap: _startFlashcards,
              ),

              const SizedBox(height: 20),

              // MOD 3: Seviyeli Metin Okuma (Reading)
              _gameModeCard(
                icon: Icons.menu_book_rounded,
                title: 'Metin Okuma (Reading & Haberler)',
                description: 'A1-C2 seviyeli yabancı haberler ve makaleler oku, kilit kelimeleri öğren!',
                color: Colors.orangeAccent,
                badge: 'Yeni 📰',
                onTap: () {
                  setState(() {
                    _currentState = MatchScreenState.readingList;
                    _readingFilterLevel = null;
                  });
                },
              ),

              const SizedBox(height: 28),
              _tipCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameModeCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(120), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withAlpha(80)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppColors.grey, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Hemen Oyna',
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: color, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. RAKİP ARAMA EKRANI
  Widget _buildSearchingScreen() {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final username = user?.username ?? 'Sen';
    final userLevel = user?.level ?? 1;
    final userXp = '${user?.xp ?? 0} XP';

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            children: [
              _header(onBackOverride: () {
                _searchTimer?.cancel();
                setState(() => _currentState = MatchScreenState.lobby);
              }),
              const SizedBox(height: 28),
              const Icon(Icons.sports_kabaddi, color: AppColors.yellow, size: 48),
              const SizedBox(height: 14),
              const Text(
                'Yarışma Eşleşmesi',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sana uygun bir rakip aranıyor...',
                style: TextStyle(color: AppColors.grey, fontSize: 17),
              ),
              const SizedBox(height: 36),

              // Radar Alanı
              SizedBox(
                height: 260,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _playerSide(
                      icon: Icons.person_outline,
                      title: username,
                      subtitle: 'Seviye $userLevel',
                      xp: userXp,
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: rotateController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: rotateController.value * 2 * pi,
                                child: CustomPaint(
                                  size: const Size(200, 200),
                                  painter: MatchingCirclePainter(),
                                ),
                              );
                            },
                          ),
                          ScaleTransition(
                            scale: pulseController,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.cardNavy,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.yellow.withAlpha(120),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(color: AppColors.yellow, width: 3.5),
                              ),
                              child: const Icon(Icons.search, color: AppColors.yellow, size: 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _opponentSide(),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              _infoCard(),
              const SizedBox(height: 28),
              _cancelButton(() {
                _searchTimer?.cancel();
                setState(() => _currentState = MatchScreenState.lobby);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 3. EŞLEŞTİRME OYUNU SAHASI
  Widget _buildMatchingGameScreen() {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            children: [
              // Üst Göstergeler (Süre, Skor, Kombo, Çıkış)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _gameTimer?.cancel();
                      _opponentTimer?.cancel();
                      setState(() => _currentState = MatchScreenState.lobby);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.close, color: AppColors.white, size: 22),
                    ),
                  ),

                  // Süre Sayacı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _remainingSeconds <= 10
                          ? Colors.redAccent.withAlpha(40)
                          : AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _remainingSeconds <= 10 ? Colors.redAccent : AppColors.blue,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: _remainingSeconds <= 10 ? Colors.redAccent : AppColors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '00:${_remainingSeconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _remainingSeconds <= 10 ? Colors.redAccent : AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Skor & Kombo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.yellow),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: AppColors.yellow, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          '$_score P',
                          style: const TextStyle(
                            color: AppColors.yellow,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_streak > 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            'x$_streak',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Rakip Canlı Durumu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_outlined, color: AppColors.blue, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rakip: $_opponentName',
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '$_opponentScore P',
                      style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Talimat
              const Text(
                'Soldaki İngilizce kelime ile sağdaki Türkçe anlamını eşleştir!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 14.5),
              ),

              const SizedBox(height: 16),

              // İki Sütunlu Eşleştirme Kartları
              Expanded(
                child: Row(
                  children: [
                    // Sol Sütun: İngilizce
                    Expanded(
                      child: ListView.builder(
                        itemCount: _shuffledEnglish.length,
                        itemBuilder: (context, index) {
                          final word = _shuffledEnglish[index];
                          final bool isMatched = _matchedEnglish.contains(word);
                          final bool isSelected = _selectedEnglish == word;

                          return _matchingCard(
                            text: word,
                            isMatched: isMatched,
                            isSelected: isSelected,
                            onTap: () => _onEnglishCardTapped(word),
                            isEnglish: true,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Sağ Sütun: Türkçe
                    Expanded(
                      child: ListView.builder(
                        itemCount: _shuffledTurkish.length,
                        itemBuilder: (context, index) {
                          final trans = _shuffledTurkish[index];
                          final bool isMatched = _matchedTurkish.contains(trans);
                          final bool isSelected = _selectedTurkish == trans;

                          return _matchingCard(
                            text: trans,
                            isMatched: isMatched,
                            isSelected: isSelected,
                            onTap: () => _onTurkishCardTapped(trans),
                            isEnglish: false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchingCard({
    required String text,
    required bool isMatched,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isEnglish,
  }) {
    Color bgColor = AppColors.cardNavy;
    Color borderColor = AppColors.cardBorder;
    Color textColor = AppColors.white;

    if (isMatched) {
      bgColor = Colors.green.withAlpha(35);
      borderColor = Colors.greenAccent;
      textColor = Colors.greenAccent;
    } else if (isSelected) {
      if (_lastMatchCorrect == false) {
        bgColor = Colors.redAccent.withAlpha(50);
        borderColor = Colors.redAccent;
      } else {
        bgColor = AppColors.blue.withAlpha(45);
        borderColor = AppColors.blue;
      }
    }

    return GestureDetector(
      onTap: isMatched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withAlpha(80),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: isMatched ? TextDecoration.lineThrough : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isMatched)
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
          ],
        ),
      ),
    );
  }

  // 4. EŞLEŞTİRME OYUN SONUCU EKRANI
  Widget _buildMatchingResultScreen() {
    final bool isWinner = _score >= _opponentScore;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _header(onBackOverride: () {
                setState(() => _currentState = MatchScreenState.lobby);
              }),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    Icon(
                      isWinner ? Icons.emoji_events : Icons.military_tech,
                      color: isWinner ? AppColors.yellow : AppColors.blue,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isWinner ? 'Zafer Senin!' : 'Harika Mücadele!',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isWinner
                          ? 'Rakibini geride bırakarak maçı kazandın.'
                          : 'Kelime bilgin hızla gelişiyor!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // XP Rozeti
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.yellow, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: AppColors.yellow, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '+$_earnedXp XP',
                            style: const TextStyle(
                              color: AppColors.yellow,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Senin Skorun: $_score P',
                      style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rakip Skoru: $_opponentScore P',
                      style: const TextStyle(color: AppColors.grey, fontSize: 16),
                    ),

                    if (_submitMessage != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        _submitMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 15),
                      ),
                    ],

                    const SizedBox(height: 30),
                    _actionButton(
                      text: 'Tekrar Oyna',
                      color: AppColors.yellow,
                      textColor: AppColors.darkNavy,
                      onTap: _startSearchingOpponent,
                    ),
                    const SizedBox(height: 14),
                    _actionButton(
                      text: 'Lobiye Dön',
                      color: AppColors.navy,
                      textColor: AppColors.white,
                      onTap: () {
                        setState(() => _currentState = MatchScreenState.lobby);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. FLASHCARDS (3D KART ÇEVİRME) EKRANI
  Widget _buildFlashcardsScreen() {
    final pair = _vocabularyPool[currentCardIndex];
    final totalCards = min(10, _vocabularyPool.length);

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            children: [
              _header(onBackOverride: () {
                setState(() => _currentState = MatchScreenState.lobby);
              }),
              const SizedBox(height: 20),

              // İlerleme Barı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kart ${currentCardIndex + 1} / $totalCards',
                    style: const TextStyle(color: AppColors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Öğrenilen: $masteredCardCount',
                    style: const TextStyle(color: AppColors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (currentCardIndex + 1) / totalCards,
                backgroundColor: AppColors.navy,
                color: AppColors.blue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),

              const SizedBox(height: 28),

              // 3D ÇEVRİLEN KART ALANI
              Expanded(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: flipAnimation,
                    builder: (context, child) {
                      final angle = flipAnimation.value * pi;
                      final isUnder = flipAnimation.value > 0.5;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: isUnder
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: _buildFlashcardBack(pair),
                              )
                            : _buildFlashcardFront(pair),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Çevirme İpucu
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, color: AppColors.grey, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Kartın arkasını görmek için dokun',
                    style: TextStyle(color: AppColors.grey, fontSize: 14.5),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Değerlendirme Butonları (Öğrendim / Tekrar Et)
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      text: 'Tekrar Et',
                      color: AppColors.cardNavy,
                      textColor: AppColors.white,
                      icon: Icons.refresh_rounded,
                      onTap: () => _onFlashcardAnswer(false),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _actionButton(
                      text: 'Öğrendim',
                      color: Colors.greenAccent.shade700,
                      textColor: AppColors.white,
                      icon: Icons.check_circle_outline,
                      onTap: () => _onFlashcardAnswer(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardFront(MatchingPair pair) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue.withAlpha(35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.blue),
            ),
            child: Text(
              pair.level,
              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            pair.english,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (pair.phonetic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              pair.phonetic,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardBack(MatchingPair pair) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.yellow, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellow.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Türkçe Karşılığı',
            style: TextStyle(color: AppColors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            pair.turkish,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (pair.example.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkNavy,
                borderRadius: BorderRadius.circular(14),
                border: const Border(
                  left: BorderSide(color: AppColors.yellow, width: 3),
                ),
              ),
              child: Text(
                '“${pair.example}”',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey, fontSize: 15, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 6. FLASHCARDS SONUCU
  Widget _buildFlashcardResultScreen() {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _header(onBackOverride: () {
                setState(() => _currentState = MatchScreenState.lobby);
              }),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.yellow, size: 80),
                    const SizedBox(height: 20),
                    const Text(
                      'Tebrikler!',
                      style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$masteredCardCount kelimeyi başarıyla pekiştirdin.',
                      style: const TextStyle(color: AppColors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // XP Rozeti
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.yellow, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: AppColors.yellow, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '+$_earnedXp XP',
                            style: const TextStyle(
                              color: AppColors.yellow,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_reviewWordsPool.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.orangeAccent.withAlpha(120)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bookmark_border_rounded, color: Colors.orangeAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Öğrenilecek Kelimeler Havuzu (${_reviewWordsPool.length})',
                                  style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._reviewWordsPool.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Text('• ${p.english}: ', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Expanded(child: Text(p.turkish, style: const TextStyle(color: AppColors.grey, fontSize: 13))),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),
                    _actionButton(
                      text: 'Tekrar Çalış',
                      color: AppColors.yellow,
                      textColor: AppColors.darkNavy,
                      onTap: _startFlashcards,
                    ),
                    const SizedBox(height: 14),
                    _actionButton(
                      text: 'Lobiye Dön',
                      color: AppColors.navy,
                      textColor: AppColors.white,
                      onTap: () {
                        setState(() => _currentState = MatchScreenState.lobby);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI BİLEŞENLER ---
  Widget _header({VoidCallback? onBackOverride}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _squareButton(Icons.arrow_back, onBackOverride ?? widget.onGoHome),
        _squareButton(Icons.home_outlined, widget.onGoHome),
      ],
    );
  }

  Widget _squareButton(IconData icon, VoidCallback onTap) {
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
        child: Icon(icon, color: AppColors.white, size: 26),
      ),
    );
  }

  Widget _playerSide({
    required IconData icon,
    required String title,
    required String subtitle,
    required String xp,
  }) {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleIcon(icon, AppColors.blue),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.blue, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              '🏆 $xp',
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opponentSide() {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleIcon(Icons.smart_toy, AppColors.yellow),
          const SizedBox(height: 12),
          Text(
            _opponentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Seviye $_opponentLevel',
            style: const TextStyle(color: AppColors.yellow, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navy,
        border: Border.all(color: color, width: 2.5),
      ),
      child: Icon(icon, color: color, size: 40),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.access_time, color: AppColors.blue, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahmini Bekleme', style: TextStyle(color: AppColors.grey, fontSize: 13)),
                SizedBox(height: 4),
                Text('2 - 5 saniye', style: TextStyle(color: AppColors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.groups_outlined, color: AppColors.yellow, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aktif Oyuncu', style: TextStyle(color: AppColors.grey, fontSize: 13)),
                SizedBox(height: 4),
                Text('1.420 Kişi', style: TextStyle(color: AppColors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.yellow, size: 28),
              SizedBox(width: 10),
              Text(
                'Oyun İpuçları',
                style: TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Hızlı eşleştirme yaparak kombo çarpanını artırabilir ve maç başına ekstra bonus XP kazanabilirsin!',
            style: TextStyle(color: AppColors.grey, fontSize: 14.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _cancelButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.redAccent, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              'Aramayı İptal Et',
              style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. METİN OKUMA LİSTESİ EKRANI
  Widget _buildReadingListScreen() {
    final filtered = _readingFilterLevel == null
        ? _articlesPool
        : _articlesPool.where((a) => a.level.contains(_readingFilterLevel!)).toList();

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  _squareButton(Icons.arrow_back, () {
                    setState(() => _currentState = MatchScreenState.lobby);
                  }),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metin Okuma (Reading)',
                          style: TextStyle(color: AppColors.yellow, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Yabancı haberler ve seviyeli makaleler',
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Seviye Filtre Çipleri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _readingFilterChip('Tümü', null),
                  const SizedBox(width: 8),
                  _readingFilterChip('A1-A2 Başlangıç', 'A'),
                  const SizedBox(width: 8),
                  _readingFilterChip('B1-B2 Orta', 'B'),
                  const SizedBox(width: 8),
                  _readingFilterChip('C1-C2 İleri', 'C'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Metin Kartları Listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final article = filtered[index];
                  return _readingArticleCard(article);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readingFilterChip(String label, String? key) {
    final isSelected = _readingFilterLevel == key;
    return GestureDetector(
      onTap: () {
        setState(() => _readingFilterLevel = key);
      },
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

  Widget _readingArticleCard(ReadingArticle article) {
    Color levelColor = AppColors.blue;
    if (article.level.contains('B')) levelColor = AppColors.green;
    if (article.level.contains('C')) levelColor = Colors.purpleAccent;

    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: levelColor, width: 0.9),
                ),
                child: Text(
                  article.level,
                  style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${article.readingTimeMinutes} dk okuma',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                ],
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏷️ ${article.category}',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.menu_book, size: 16),
                label: const Text('Metni Oku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  setState(() {
                    _selectedArticle = article;
                    _showTurkishTranslation = false;
                    _currentState = MatchScreenState.readingDetail;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. METİN DETAY EKRANI
  Widget _buildReadingDetailScreen() {
    final article = _selectedArticle;
    if (article == null) {
      return _buildReadingListScreen();
    }

    Color levelColor = AppColors.blue;
    if (article.level.contains('B')) levelColor = AppColors.green;
    if (article.level.contains('C')) levelColor = Colors.purpleAccent;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  _squareButton(Icons.arrow_back, () {
                    setState(() => _currentState = MatchScreenState.readingList);
                  }),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${article.level} • ${article.category}',
                          style: TextStyle(color: levelColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Orijinal İngilizce Metin Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.article_outlined, color: AppColors.yellow, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                'İngilizce Orijinal Metin',
                                style: TextStyle(color: AppColors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                '⏱️ ${article.readingTimeMinutes} dk',
                                style: const TextStyle(color: AppColors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          const Divider(color: AppColors.cardBorder, height: 24),
                          Text(
                            article.englishContent,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              height: 1.6,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Katlanabilir Türkçe Çeviri / Özet Kartı
                    GestureDetector(
                      onTap: () {
                        setState(() => _showTurkishTranslation = !_showTurkishTranslation);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.blue.withAlpha(120)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.translate_rounded, color: AppColors.blue, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Türkçe Çeviri & Özet',
                                    style: TextStyle(color: AppColors.blue, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Icon(
                                  _showTurkishTranslation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: AppColors.grey,
                                ),
                              ],
                            ),
                            if (_showTurkishTranslation) ...[
                              const SizedBox(height: 12),
                              Text(
                                article.turkishSummary,
                                style: const TextStyle(color: AppColors.white, fontSize: 14.5, height: 1.5),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Kilit Kelimeler Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.yellow.withAlpha(100)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.vpn_key_outlined, color: AppColors.yellow, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '📌 Metindeki Kilit Kelimeler',
                                style: TextStyle(color: AppColors.yellow, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...article.keyVocabulary.map((vocab) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.yellow.withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      vocab['level'] ?? 'B1',
                                      style: const TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${vocab['word']}: ',
                                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Expanded(
                                    child: Text(
                                      vocab['translation'] ?? '',
                                      style: const TextStyle(color: AppColors.grey, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "Okumayı Bitirdim" Butonu
                    GestureDetector(
                      onTap: () {
                        context.read<AuthProvider>().addXp(15);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tebrikler! Okuma tamamlandı (+15 XP kazandın) 🏆'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        setState(() => _currentState = MatchScreenState.readingList);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.yellow, Color(0xFFFFA726)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellow.withAlpha(80),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.darkNavy, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Okumayı Bitirdim (+15 XP)',
                              style: TextStyle(
                                color: AppColors.darkNavy,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.cardNavy,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.cardBorder),
    );
  }
}

class MatchingCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.cardBorder.withAlpha(100);

    final bluePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.blue;

    final yellowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.yellow;

    canvas.drawCircle(center, 95, basePaint);
    canvas.drawCircle(center, 70, basePaint);
    canvas.drawCircle(center, 46, basePaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 78),
      -pi / 2,
      pi * 1.15,
      false,
      bluePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 78),
      pi / 6,
      pi * 0.55,
      false,
      yellowPaint,
    );

    final dotPaint = Paint()..color = AppColors.blue.withAlpha(140);

    for (int i = 0; i < 16; i++) {
      final angle = (2 * pi / 16) * i;
      final dx = center.dx + cos(angle) * 58;
      final dy = center.dy + sin(angle) * 58;
      canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
