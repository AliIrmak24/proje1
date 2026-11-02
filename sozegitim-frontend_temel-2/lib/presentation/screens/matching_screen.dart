import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/speech/speaker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/offline_words.dart';
import '../providers/auth_provider.dart';
import 'reading_screen.dart';

enum MatchScreenState {
  lobby,          // Oyun Modu Seçimi ve Lobi
  searching,      // Rakip arama animasyonu
  matchingGame,   // Kelime eşleştirme oyunu
  matchingResult, // Eşleştirme oyun sonucu
  flashcards,     // 3D Kart çevirme modu
  flashcardResult,// Kart çevirme sonucu
  reading,        // Metin Okuma (Reading)
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
  final int? id; // Sunucudan gelen kelimelerde ilerleme kaydı için
  final String english;
  final String turkish;
  final String level;
  final String phonetic;
  final String example;

  MatchingPair({
    this.id,
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
  List<MatchingPair> _flashcards = [];
  bool _flashcardsOffline = false;
  int _flashcardXp = 0;

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

  // --- EŞLEŞTİRME OYUNU BAŞLATMA ---
  void _startSearchingOpponent() {
    setState(() {
      _currentState = MatchScreenState.searching;
    });

    _opponentName = 'Alıştırma Botu';
    _opponentLevel = Random().nextInt(3) + 1;

    // 2.5 saniye sonra oyunu başlat
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 1200), () async {
      final pairs = await _loadGamePairs();
      if (!mounted || _currentState != MatchScreenState.searching) return;
      _initMatchingGame(pairs);
    });
  }

  MatchingPair _pairFromJson(Map<String, dynamic> map) {
    final meanings = map['meanings'] as List?;
    return MatchingPair(
      id: map['id'] as int?,
      english: map['word']?.toString() ?? '',
      turkish: map['translation']?.toString() ?? '',
      level: map['level']?.toString() ?? 'A1',
      phonetic: map['phonetic']?.toString() ?? '',
      example: meanings != null && meanings.isNotEmpty ? meanings[0]['example']?.toString() ?? '' : '',
    );
  }

  Future<List<MatchingPair>> _offlinePairs(int count) async {
    final words = [...await OfflineWords.load()]..shuffle();
    final seen = <String>{};
    return words
        .where((w) => seen.add(w.translation))
        .take(count)
        .map((w) => MatchingPair(
              english: w.word,
              turkish: w.translation,
              level: w.level,
              phonetic: w.phonetic ?? '',
              example: w.meanings.isNotEmpty ? w.meanings.first.example ?? '' : '',
            ))
        .toList();
  }

  Future<List<MatchingPair>> _loadGamePairs() async {
    try {
      final level = context.read<AuthProvider>().currentUser?.cefrLevel;
      final res = await _apiClient.get('/api/words/random?count=5${level == null ? '' : '&level=$level'}');
      final pairs = (res as List<dynamic>).map((w) => _pairFromJson(w as Map<String, dynamic>)).toList();
      if (pairs.length == 5) return pairs;
    } catch (_) {}
    return _offlinePairs(5);
  }

  void _initMatchingGame(List<MatchingPair> selectedPairs) {
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
      final earnedXp = await auth.awardActivityXp('matching', correctMatches + (timeBonus ~/ 10));
      if (mounted) {
        setState(() {
          _earnedXp = earnedXp;
          _submitMessage = earnedXp > 0
              ? 'Tebrikler! Puanların liderlik tablosuna kaydedildi.'
              : 'Bu oyundan XP kazanılamadı (bağlantı yok veya günlük sınır doldu).';
        });
      }
    } else {
      _submitMessage = 'Misafir Modu: Puanlarını liderlik tablosuna kaydetmek için giriş yapmalısın!';
    }
  }

  // --- FLASHCARDS MODU ---
  Future<void> _startFlashcards() async {
    List<MatchingPair> cards;
    _flashcardsOffline = false;
    try {
      final res = await _apiClient.get('/api/learn/session?limit=10') as List<dynamic>;
      cards = res.map((item) => _pairFromJson(item['word'] as Map<String, dynamic>)).toList();
    } catch (_) {
      _flashcardsOffline = true;
      cards = await _offlinePairs(10);
    }
    if (!mounted || cards.isEmpty) return;

    setState(() {
      _flashcards = cards;
      _currentState = MatchScreenState.flashcards;
      currentCardIndex = 0;
      masteredCardCount = 0;
      _flashcardXp = 0;
      _reviewWordsPool.clear();
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

  Future<void> _recordFlashcard(MatchingPair pair, bool mastered) async {
    if (pair.id == null) return;
    try {
      final res = await _apiClient.post('/api/learn/review', {'word_id': pair.id, 'known': mastered});
      _flashcardXp += (res['earned_xp'] as num).toInt();
      if (mounted) {
        await context.read<AuthProvider>().applyXpResult(res as Map<String, dynamic>);
      }
    } catch (_) {
      // Bağlantı koparsa kart oturumu sürer, sonuç kaydedilmez
    }
  }

  void _onFlashcardAnswer(bool mastered) {
    final currentPair = _flashcards[currentCardIndex];
    _recordFlashcard(currentPair, mastered);
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

    if (currentCardIndex < _flashcards.length - 1) {
      setState(() {
        currentCardIndex++;
        isCardFront = true;
      });
      flipController.reset();
    } else {
      _finishFlashcards();
    }
  }

  void _finishFlashcards() {
    setState(() {
      _earnedXp = _flashcardXp;
      _submitMessage = _flashcardsOffline ? 'Çevrimdışı çalışmada ilerleme kaydedilmez.' : null;
      _currentState = MatchScreenState.flashcardResult;
    });
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
      case MatchScreenState.reading:
        return ReadingScreen(
          onGoBack: () => setState(() => _currentState = MatchScreenState.lobby),
        );
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
                title: 'Kelime Eşleştirme',
                description: '45 saniyede İngilizce ve Türkçe kelimeleri eşleştir, alıştırma botunu geç!',
                color: AppColors.yellow,
                badge: 'Popüler & Hızlı',
                onTap: _startSearchingOpponent,
              ),

              const SizedBox(height: 20),

              // MOD 2: Akıllı 3D Kart Çevirme (Flashcards)
              _gameModeCard(
                icon: Icons.style_rounded,
                title: 'Kelime Kartları (Aralıklı Tekrar)',
                description: 'Tekrarı gelen kelimeleri çalış, telaffuzu dinle ve yeni kelimeler öğren!',
                color: AppColors.blue,
                badge: 'Öğren & Tekrar Et',
                onTap: _startFlashcards,
              ),

              const SizedBox(height: 20),

              // MOD 3: Seviyeli Metin Okuma (Reading)
              _gameModeCard(
                icon: Icons.menu_book_rounded,
                title: 'Metin Okuma',
                description: 'Seviyeli metinleri oku, kilit kelimeleri öğren ve anlama sorularını çöz!',
                color: Colors.orangeAccent,
                badge: 'Yeni 📰',
                onTap: () {
                  setState(() => _currentState = MatchScreenState.reading);
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
                'Alıştırma Hazırlanıyor',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Alıştırma botu ve kelimeler hazırlanıyor...',
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
    final pair = _flashcards[currentCardIndex];
    final totalCards = _flashcards.length;

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
          const SizedBox(height: 14),
          IconButton(
            tooltip: 'Telaffuzu dinle',
            onPressed: () => Speaker.speak(pair.english),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.yellow, size: 34),
          ),
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
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.cardNavy,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.cardBorder),
    );
  }

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
              'İptal Et',
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
