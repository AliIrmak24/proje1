import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../providers/auth_provider.dart';

class QuizScreen extends StatefulWidget {
  final VoidCallback onGoHome;

  const QuizScreen({
    super.key,
    required this.onGoHome,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class QuizQuestion {
  final int id;
  final String question;
  final String word;
  final List<String> options;
  final int correctIndex;
  final String level;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.word,
    required this.options,
    required this.correctIndex,
    this.level = 'A1',
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      word: json['word'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      correctIndex: json['correct_index'] as int? ?? 0,
      level: json['level'] as String? ?? 'A1',
    );
  }
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiClient _apiClient = ApiClient();
  bool isLoading = true;
  int currentIndex = 0;
  int? selectedIndex;
  int correctCount = 0;
  bool quizFinished = false;
  bool isSubmitting = false;
  int earnedXp = 0;
  int totalXp = 0;
  int currentLevel = 1;
  String? submitMessage;

  List<QuizQuestion> questions = [];

  // Çevrimdışı zengin kelime havuzundan dinamik soru listesi
  static final List<Map<String, dynamic>> _wordBank = [
    {'w': 'Ambition', 't': 'Arzu, hırs, azim', 'l': 'B2'},
    {'w': 'Goal', 't': 'Hedef, amaç', 'l': 'A2'},
    {'w': 'Resilient', 't': 'Dirençli, çabuk toparlanan', 'l': 'B2'},
    {'w': 'Discovery', 't': 'Keşif, buluş', 'l': 'B1'},
    {'w': 'Curious', 't': 'Meraklı, ilgili', 'l': 'A2'},
    {'w': 'Apple', 't': 'Elma', 'l': 'A1'},
    {'w': 'Book', 't': 'Kitap', 'l': 'A1'},
    {'w': 'Friend', 't': 'Arkadaş, dost', 'l': 'A1'},
    {'w': 'Brave', 't': 'Cesur, korkusuz', 'l': 'A1'},
    {'w': 'Knowledge', 't': 'Bilgi, birikim', 'l': 'A2'},
    {'w': 'Healthy', 't': 'Sağlıklı, sıhhatli', 'l': 'A2'},
    {'w': 'Challenge', 't': 'Meydan okuma, zorluk', 'l': 'B1'},
    {'w': 'Inspire', 't': 'İlham vermek, esinlendirmek', 'l': 'B1'},
    {'w': 'Opportunity', 't': 'Fırsat, imkan', 'l': 'B1'},
    {'w': 'Wisdom', 't': 'Bilgelik, akıl', 'l': 'B2'},
    {'w': 'Empathy', 't': 'Eşduyum, empati', 'l': 'B2'},
    {'w': 'Persevere', 't': 'Sebat etmek, azmetmek', 'l': 'C1'},
    {'w': 'Eloquent', 't': 'Güzel konuşan, etkileyici', 'l': 'C1'},
    {'w': 'Meticulous', 't': 'Titiz, kılı kırk yaran', 'l': 'C1'},
    {'w': 'Ubiquitous', 't': 'Her yerde bulunan, yaygın', 'l': 'C2'},
    {'w': 'Ephemeral', 't': 'Geçici, kısa ömürlü', 'l': 'C2'},
    {'w': 'Paradigm', 't': 'Örüntü, model, paradigma', 'l': 'C2'},
  ];

  List<QuizQuestion> _generateOfflineQuestions() {
    final shuffled = List<Map<String, dynamic>>.from(_wordBank)..shuffle();
    final selectedWords = shuffled.take(5).toList();
    final List<QuizQuestion> generated = [];

    for (int i = 0; i < selectedWords.length; i++) {
      final current = selectedWords[i];
      final correctTranslation = current['t'] as String;
      
      // Diğer kelimelerden 3 çeldirici seç
      final distractors = _wordBank
          .where((w) => w['t'] != correctTranslation)
          .map((w) => w['t'] as String)
          .toList()
        ..shuffle();
      final options = distractors.take(3).toList();
      options.add(correctTranslation);
      options.shuffle();

      generated.add(QuizQuestion(
        id: i + 1,
        question: '“${current['w']}” kelimesinin Türkçe karşılığı hangisidir?',
        word: current['w'] as String,
        options: options,
        correctIndex: options.indexOf(correctTranslation),
        level: current['l'] as String,
      ));
    }
    return generated;
  }

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      quizFinished = false;
      currentIndex = 0;
      selectedIndex = null;
      correctCount = 0;
      earnedXp = 0;
      submitMessage = null;
    });

    try {
      final response = await _apiClient.get('/api/quiz/questions?count=5');
      if (mounted && response is List && response.isNotEmpty) {
        setState(() {
          questions = response
              .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList();
          isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Hata durumunda dinamik çevrimdışı soruları üret
    }

    if (mounted) {
      setState(() {
        questions = _generateOfflineQuestions();
        isLoading = false;
      });
    }
  }

  void selectAnswer(int index) {
    if (selectedIndex != null) return;

    setState(() {
      selectedIndex = index;
      if (index == questions[currentIndex].correctIndex) {
        correctCount++;
      }
    });
  }

  Future<void> nextQuestion() async {
    if (selectedIndex == null) return;

    if (currentIndex == questions.length - 1) {
      if (mounted) {
        setState(() {
          quizFinished = true;
        });
      }
      await submitResults();
    } else {
      if (mounted) {
        setState(() {
          currentIndex++;
          selectedIndex = null;
        });
      }
    }
  }

  Future<void> submitResults() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() {
          earnedXp = correctCount * 10;
          submitMessage = 'Misafir Modu: Puanlarını liderlik tablosuna kaydetmek için giriş yapmalısın!';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isSubmitting = true;
      });
    }

    try {
      final res = await _apiClient.post('/api/quiz/submit', {
        'correct_answers': correctCount,
      });

      if (mounted) {
        setState(() {
          earnedXp = (res['earned_xp'] as num?)?.toInt() ?? (correctCount * 10);
          totalXp = (res['total_xp'] as num?)?.toInt() ?? 0;
          currentLevel = (res['current_level'] as num?)?.toInt() ?? 1;
          submitMessage = 'Tebrikler! Puanların hesabına kaydedildi.';
        });
      }

      // Profil bilgilerini anında yerelde güncelle
      await auth.addXp(earnedXp);
    } catch (e) {
      if (mounted) {
        setState(() {
          earnedXp = correctCount * 10;
          submitMessage = 'Tebrikler! Puanın kaydedildi (+${correctCount * 10} XP).';
        });
      }
      // Çevrimdışı modda yerel XP'yi artır
      await auth.addXp(correctCount * 10);
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void restartQuiz() {
    loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.yellow),
              SizedBox(height: 20),
              Text(
                'Sorular Hazırlanıyor...',
                style: TextStyle(color: AppColors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (quizFinished) {
      return _resultScreen();
    }

    final question = questions[currentIndex];

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: questions.isEmpty ? 0 : (currentIndex + 1) / questions.length,
                backgroundColor: AppColors.navy,
                color: AppColors.yellow,
                minHeight: 8,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 12),
              Text(
                'Soru ${currentIndex + 1} / ${questions.length}',
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      question.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(
                      question.options.length,
                      (index) => _option(index, question.options[index]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: nextQuestion,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: selectedIndex == null
                        ? AppColors.cardNavy
                        : AppColors.yellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    currentIndex == questions.length - 1
                        ? 'Sonucu Gör'
                        : 'Sonraki Soru',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selectedIndex == null
                          ? AppColors.grey
                          : AppColors.darkNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(int index, String text) {
    final question = questions[currentIndex];
    final bool isSelected = selectedIndex == index;
    final bool isCorrect = question.correctIndex == index;

    Color bgColor = AppColors.navy;
    Color borderColor = AppColors.cardBorder;
    IconData? icon;

    if (selectedIndex != null) {
      if (isSelected && isCorrect) {
        bgColor = Colors.green.withAlpha((0.75 * 255).round());
        borderColor = Colors.greenAccent;
        icon = Icons.check_circle;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.withAlpha((0.75 * 255).round());
        borderColor = Colors.redAccent;
        icon = Icons.cancel;
      } else if (isCorrect) {
        bgColor = Colors.green.withAlpha((0.35 * 255).round());
        borderColor = Colors.greenAccent;
        icon = Icons.check_circle_outline;
      }
    }

    return GestureDetector(
      onTap: () => selectAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(
              String.fromCharCode(65 + index),
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                ),
              ),
            ),
            if (icon != null)
              Icon(
                icon,
                color: AppColors.white,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onGoHome,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 26,
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Mini Quiz',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 52),
      ],
    );
  }

  Widget _resultScreen() {
    final int wrongCount = questions.length - correctCount;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: AppColors.yellow,
                      size: 76,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Quiz Tamamlandı!',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                            '+$earnedXp XP',
                            style: const TextStyle(
                              color: AppColors.yellow,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$correctCount / ${questions.length} doğru',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yanlış sayısı: $wrongCount',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 16,
                      ),
                    ),
                    if (submitMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        submitMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _resultButton(
                      text: 'Tekrar Çöz',
                      color: AppColors.yellow,
                      textColor: AppColors.darkNavy,
                      onTap: restartQuiz,
                    ),
                    const SizedBox(height: 14),
                    _resultButton(
                      text: 'Ana Sayfaya Dön',
                      color: AppColors.navy,
                      textColor: AppColors.white,
                      onTap: widget.onGoHome,
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

  Widget _resultButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
