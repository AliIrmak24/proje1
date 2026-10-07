import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onGoDictionary;
  final VoidCallback onGoQuiz;
  final VoidCallback onGoProfile;
  final VoidCallback onGoMatching;

  const HomeScreen({
    super.key,
    required this.onGoDictionary,
    required this.onGoQuiz,
    required this.onGoProfile,
    required this.onGoMatching,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _leaderboard = [];
  bool _loadingLeaderboard = true;
  Map<String, dynamic>? _wordOfDay;
  bool _loadingWordOfDay = true;

  // Rastgele Dinamik Mini Quiz
  String _miniQuizWord = 'Ambition';
  String _miniQuizCorrect = 'Arzu, hırs, azim';
  List<String> _miniQuizOptions = ['Başarısızlık', 'Arzu, hırs, azim'];
  int? _miniQuizSelectedIndex;

  static final List<Map<String, String>> _quizQuestionBank = [
    {'w': 'Ambition', 'c': 'Arzu, hırs, azim', 'd': 'Korku, kaygı'},
    {'w': 'Resilient', 'c': 'Dirençli, güçlü', 'd': 'Kırılgan, zayıf'},
    {'w': 'Curious', 'c': 'Meraklı, hevesli', 'd': 'Duyarsız, ilgisiz'},
    {'w': 'Knowledge', 'c': 'Bilgi, birikim', 'd': 'Cahillik, yanılgı'},
    {'w': 'Patience', 'c': 'Sabır, tahammül', 'd': 'Öfke, telaş'},
    {'w': 'Brave', 'c': 'Cesur, yiğit', 'd': 'Korkak, çekingen'},
    {'w': 'Inspire', 'c': 'İlham vermek', 'd': 'Umut kırmak'},
    {'w': 'Opportunity', 'c': 'Fırsat, imkan', 'd': 'Engelleme, engel'},
    {'w': 'Wisdom', 'c': 'Bilgelik, hikmet', 'd': 'Akılsızlık, cehalet'},
    {'w': 'Serenity', 'c': 'Huzur, dinginlik', 'd': 'Kargaşa, telaş'},
    {'w': 'Persevere', 'c': 'Sebat etmek', 'd': 'Vazgeçmek, pes etmek'},
    {'w': 'Ubiquitous', 'c': 'Her yerde bulunan', 'd': 'Nadir, eşsiz'},
    {'w': 'Ephemeral', 'c': 'Geçici, kısa ömürlü', 'd': 'Sonsuz, kalıcı'},
    {'w': 'Paradigm', 'c': 'Örüntü, model', 'd': 'Düzensizlik, karmaşa'},
    {'w': 'Benevolent', 'c': 'Hayırsever, iyi', 'd': 'Kötü niyetli, hain'},
    {'w': 'Clarity', 'c': 'Açıklık, berraklık', 'd': 'Belirsizlik, sis'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
    _generateRandomMiniQuiz();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWordOfDay();
    });
  }

  void _generateRandomMiniQuiz() {
    final shuffled = List<Map<String, String>>.from(_quizQuestionBank)..shuffle();
    final item = shuffled.first;
    final options = [item['c']!, item['d']!]..shuffle();

    setState(() {
      _miniQuizWord = item['w']!;
      _miniQuizCorrect = item['c']!;
      _miniQuizOptions = options;
      _miniQuizSelectedIndex = null;
    });
  }

  void _handleOptionSelect(int index) {
    if (_miniQuizSelectedIndex != null) return;

    final selectedText = _miniQuizOptions[index];
    final isCorrect = selectedText == _miniQuizCorrect;

    setState(() {
      _miniQuizSelectedIndex = index;
    });

    if (isCorrect) {
      context.read<AuthProvider>().addXp(5);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tebrikler! Doğru cevap (+5 XP) 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 1.8 saniye sonra otomatik yeni random soru getir
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _generateRandomMiniQuiz();
      }
    });
  }

  Future<void> _fetchWordOfDay() async {
    try {
      final auth = context.read<AuthProvider>();
      final userLevel = auth.currentUser?.level ?? 1;

      // Kullanıcının seviyesine göre CEFR belirle
      String cefr = 'A1';
      if (userLevel <= 3) {
        cefr = 'A1';
      } else if (userLevel <= 6) {
        cefr = 'A2';
      } else if (userLevel <= 10) {
        cefr = 'B1';
      } else if (userLevel <= 14) {
        cefr = 'B2';
      } else if (userLevel <= 18) {
        cefr = 'C1';
      } else {
        cefr = 'C2';
      }

      final res = await _apiClient.get('/api/words/word-of-the-day?level=$cefr');
      if (res is Map<String, dynamic>) {
        setState(() {
          _wordOfDay = res;
          _loadingWordOfDay = false;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _loadingWordOfDay = false;
    });
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final res = await _apiClient.get('/api/quiz/leaderboard');
      if (res is List) {
        setState(() {
          _leaderboard = res;
          _loadingLeaderboard = false;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _loadingLeaderboard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 640;

            return SingleChildScrollView(
              physics: isSmallScreen
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxHeight: isSmallScreen ? double.infinity : constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: isSmallScreen ? 6 : 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Logo Alanı
                      _logoArea(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 6 : 10),

                      // 2. Günün Kelimesi & Mini Quiz (Yan Yana, Eşit Yükseklik)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _wordOfDayCard(isSmallScreen)),
                            const SizedBox(width: 10),
                            Expanded(child: _miniQuizCard(isSmallScreen)),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 10),

                      // 3. Skor Tablosu
                      if (isSmallScreen)
                        SizedBox(
                          height: 140,
                          child: _leaderboardCard(isSmallScreen: true),
                        )
                      else
                        Expanded(child: _leaderboardCard(isSmallScreen: false)),
                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // 4. Alt İşlem Tuşları
                      _bottomActions(isSmallScreen),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _logoArea(bool isSmallScreen) {
    return Column(
      children: [
        Text(
          'SözEğitim',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: isSmallScreen ? 22 : 25,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Learn. ', style: TextStyle(color: AppColors.blue)),
              TextSpan(text: 'Play. ', style: TextStyle(color: AppColors.purple)),
              TextSpan(text: 'Compete.', style: TextStyle(color: AppColors.yellow)),
            ],
          ),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _wordOfDayCard(bool isSmallScreen) {
    final word = _wordOfDay?['word'] ?? 'Knowledge';
    final phonetic = _wordOfDay?['phonetic'] ?? '/ˈnɒl.ɪdʒ/';
    final translation = _wordOfDay?['translation'] ?? 'Bilgi, ilim, birikim.';
    final level = _wordOfDay?['level']?.toString() ?? 'A2';

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: _cardDecoration(AppColors.blue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: AppColors.blue, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'Günün Kelimesi',
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.blue, width: 0.8),
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              if (_loadingWordOfDay)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: AppColors.blue, strokeWidth: 2),
                    ),
                  ),
                )
              else ...[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    word,
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: isSmallScreen ? 17 : 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (phonetic != null && phonetic.isNotEmpty)
                  Text(
                    phonetic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.grey, fontStyle: FontStyle.italic, fontSize: 10.5),
                  ),
                const SizedBox(height: 3),
                Text(
                  translation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.grey, fontSize: 11, height: 1.2),
                ),
              ],
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _compactButton('Sözlüğe Git', Icons.arrow_forward_ios, widget.onGoDictionary),
        ],
      ),
    );
  }

  Widget _miniQuizCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: _cardDecoration(AppColors.purple),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sports_esports, color: AppColors.purple, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'Mini Quiz',
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _generateRandomMiniQuiz,
                    child: const Icon(Icons.refresh_rounded, color: AppColors.yellow, size: 16),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Text(
                '“$_miniQuizWord” anlamı?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              ..._miniQuizOptions.asMap().entries.map((entry) {
                final idx = entry.key;
                final opt = entry.value;
                final letter = idx == 0 ? 'A' : 'B';
                return _dynamicOption(letter, opt, idx);
              }),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _compactButton('Tüm Testler', Icons.arrow_forward_ios, widget.onGoQuiz),
        ],
      ),
    );
  }

  Widget _dynamicOption(String letter, String text, int index) {
    Color bgColor = AppColors.navy;
    Color borderColor = AppColors.cardBorder;

    if (_miniQuizSelectedIndex != null) {
      if (text == _miniQuizCorrect) {
        bgColor = Colors.green.withAlpha(80);
        borderColor = Colors.green;
      } else if (_miniQuizSelectedIndex == index) {
        bgColor = Colors.redAccent.withAlpha(80);
        borderColor = Colors.redAccent;
      }
    }

    return GestureDetector(
      onTap: () => _handleOptionSelect(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.9),
        ),
        child: Row(
          children: [
            Text(letter, style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.white, fontSize: 10.5),
              ),
            ),
            if (_miniQuizSelectedIndex != null && text == _miniQuizCorrect)
              const Icon(Icons.check, color: Colors.greenAccent, size: 13)
            else if (_miniQuizSelectedIndex == index && text != _miniQuizCorrect)
              const Icon(Icons.close, color: Colors.redAccent, size: 13),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardCard({bool isSmallScreen = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: isSmallScreen ? 6 : 10),
      decoration: _cardDecoration(AppColors.cardBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.yellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Skor Tablosu',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchLeaderboard,
                child: const Icon(Icons.refresh, color: AppColors.grey, size: 17),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Expanded(
            child: _loadingLeaderboard
                ? const Center(child: CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 2))
                : _leaderboard.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz kayıtlı skor bulunmuyor.',
                          style: TextStyle(color: AppColors.grey, fontSize: 11),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _leaderboard.take(3).length,
                        itemBuilder: (context, index) {
                          final user = _leaderboard[index] as Map<String, dynamic>;
                          final rank = index + 1;
                          final username = user['username']?.toString() ?? 'Kullanıcı';
                          final xp = '${user['xp'] ?? 0} XP';
                          final isTop = rank == 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isTop ? AppColors.navy : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isTop ? Border.all(color: AppColors.yellow.withAlpha(80), width: 1) : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isTop ? AppColors.yellow : AppColors.navy,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      color: isTop ? AppColors.darkNavy : AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    username,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isTop ? AppColors.yellow : AppColors.white,
                                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  xp,
                                  style: const TextStyle(color: AppColors.yellow, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(bool isSmallScreen) {
    final sideSize = isSmallScreen ? 48.0 : 54.0;
    final bigSize = isSmallScreen ? 72.0 : 80.0;
    final bigIcon = isSmallScreen ? 24.0 : 28.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(Icons.person_outline, 'Profil', AppColors.blue, widget.onGoProfile, size: sideSize),
        _bigStartButton(size: bigSize, iconSize: bigIcon),
        _actionButton(Icons.menu_book_outlined, 'Sözlük', AppColors.blue, widget.onGoDictionary, size: sideSize),
      ],
    );
  }

  Widget _bigStartButton({double size = 80, double iconSize = 28}) {
    return GestureDetector(
      onTap: widget.onGoMatching,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.yellow, width: 2.5),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA000), Color(0xFFFFD54F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withAlpha((0.4 * 255).round()),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_kabaddi, color: AppColors.darkNavy, size: iconSize),
            const SizedBox(height: 2),
            const Text(
              'BAŞLA',
              style: TextStyle(
                color: AppColors.darkNavy,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap, {double size = 54}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(120), width: 1.5),
              color: AppColors.cardNavy,
            ),
            child: Icon(icon, color: color, size: size * 0.44),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _compactButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(width: 4),
            Icon(icon, color: AppColors.yellow, size: 12),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(Color borderColor) {
    return BoxDecoration(
      color: AppColors.cardNavy,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor.withAlpha((0.6 * 255).round())),
    );
  }
}