import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/speech/speaker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/offline_words.dart';
import '../providers/auth_provider.dart';

const List<String> cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

/// Seviye belirleme testini tam ekran açar.
void openPlacementTest(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (routeContext) => QuizScreen(
        placement: true,
        onGoHome: () => Navigator.of(routeContext).pop(),
      ),
    ),
  );
}

class QuizScreen extends StatefulWidget {
  final VoidCallback onGoHome;
  final bool placement;

  const QuizScreen({
    super.key,
    required this.onGoHome,
    this.placement = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class QuizQuestion {
  final int id;
  final String kind;
  final String question;
  final String? speakText;
  final List<String> options;
  // Sunucu sorularında cevap verilene kadar bilinmez
  int? correctIndex;
  final String level;

  QuizQuestion({
    required this.id,
    this.kind = 'en_tr',
    required this.question,
    this.speakText,
    required this.options,
    this.correctIndex,
    this.level = 'A1',
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'en_tr',
      question: json['question'] as String? ?? '',
      speakText: json['speak_text'] as String?,
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
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
  String? sessionId; // null ise çevrimdışı sorular kullanılıyor
  bool isCheckingAnswer = false;
  bool quizFinished = false;
  bool isSubmitting = false;
  int earnedXp = 0;
  String? submitMessage;
  String? selectedLevel; // null ise kullanıcının kendi seviyesi
  String? placementLevel;
  List<Map<String, dynamic>> reviewWords = [];

  List<QuizQuestion> questions = [];

  // Uygulamayla gelen kelime havuzundan çevrimdışı sorular üretir
  Future<List<QuizQuestion>> _generateOfflineQuestions() async {
    final words = await OfflineWords.load();
    final shuffled = [...words]..shuffle();
    final List<QuizQuestion> generated = [];

    for (final current in shuffled.take(5)) {
      final distractors = words
          .where((w) => w.translation != current.translation)
          .map((w) => w.translation)
          .toSet()
          .toList()
        ..shuffle();
      final options = distractors.take(3).toList()
        ..add(current.translation)
        ..shuffle();

      generated.add(QuizQuestion(
        id: generated.length + 1,
        question: '“${current.word}” kelimesinin Türkçe karşılığı hangisidir?',
        options: options,
        correctIndex: options.indexOf(current.translation),
        level: current.level,
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
      sessionId = null;
      placementLevel = null;
      reviewWords = [];
    });

    try {
      final levelQuery = selectedLevel == null ? '' : '&level=$selectedLevel';
      final path = widget.placement ? '/api/quiz/placement' : '/api/quiz/questions?count=5$levelQuery';
      final response = await _apiClient.get(path);
      final serverQuestions = response['questions'] as List<dynamic>;
      if (mounted && serverQuestions.isNotEmpty) {
        setState(() {
          sessionId = response['session_id'] as String;
          questions = serverQuestions
              .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList();
          isLoading = false;
        });
        _speakCurrentQuestion();
        return;
      }
    } catch (_) {
      // Hata durumunda dinamik çevrimdışı soruları üret
    }

    final offlineQuestions = await _generateOfflineQuestions();
    if (mounted) {
      setState(() {
        questions = offlineQuestions;
        isLoading = false;
      });
    }
  }

  void _speakCurrentQuestion() {
    final text = questions[currentIndex].speakText;
    if (text != null) {
      Speaker.speak(text);
    }
  }

  Future<void> selectAnswer(int index) async {
    if (selectedIndex != null || isCheckingAnswer) return;

    final question = questions[currentIndex];
    if (sessionId == null) {
      setState(() {
        selectedIndex = index;
        if (index == question.correctIndex) {
          correctCount++;
        }
      });
      return;
    }

    setState(() => isCheckingAnswer = true);
    try {
      final res = await _apiClient.post('/api/quiz/answer', {
        'session_id': sessionId,
        'question_id': question.id,
        'selected_index': index,
      });
      if (mounted) {
        setState(() {
          question.correctIndex = (res['correct_index'] as num).toInt();
          selectedIndex = index;
          if (res['correct'] == true) {
            correctCount++;
          }
          isCheckingAnswer = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isCheckingAnswer = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cevap kontrol edilemedi, lütfen tekrar deneyin.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
        _speakCurrentQuestion();
      }
    }
  }

  Future<void> submitResults() async {
    final auth = context.read<AuthProvider>();
    if (sessionId == null) {
      if (mounted) {
        setState(() {
          submitMessage = 'Çevrimdışı quizlerde XP kazanılmaz.';
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
        'session_id': sessionId,
      });

      if (mounted) {
        setState(() {
          earnedXp = (res['earned_xp'] as num?)?.toInt() ?? 0;
          placementLevel = res['placement_level'] as String?;
          reviewWords = (res['review'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          submitMessage = widget.placement
              ? 'Seviyen kaydedildi, kelimeler buna göre seçilecek.'
              : 'Tebrikler! Puanların hesabına kaydedildi.';
        });
      }

      // Profil bilgilerini sunucudan güncelle
      await auth.fetchUserProfile();
    } catch (e) {
      if (mounted) {
        setState(() {
          submitMessage = 'Sonucun kaydedilemedi, bağlantını kontrol et.';
        });
      }
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
              if (!widget.placement) ...[
                const SizedBox(height: 16),
                _levelSelector(),
              ],
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: questions.isEmpty ? 0 : (currentIndex + 1) / questions.length,
                backgroundColor: AppColors.navy,
                color: AppColors.yellow,
                minHeight: 8,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 12),
              Text(
                'Soru ${currentIndex + 1} / ${questions.length} • ${question.level}',
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
                    if (question.speakText != null) ...[
                      const SizedBox(height: 14),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppColors.yellow),
                        tooltip: 'Tekrar dinle',
                        onPressed: _speakCurrentQuestion,
                        icon: const Icon(Icons.volume_up_rounded, color: AppColors.darkNavy, size: 32),
                      ),
                    ],
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

  Widget _levelSelector() {
    final options = <String?>[null, ...cefrLevels];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final level = options[index];
          final isSelected = selectedLevel == level;
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              setState(() => selectedLevel = level);
              loadQuestions();
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.yellow : AppColors.cardNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.yellow : AppColors.cardBorder),
              ),
              child: Text(
                level ?? 'Seviyem',
                style: TextStyle(
                  color: isSelected ? AppColors.darkNavy : AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
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
        Expanded(
          child: Center(
            child: Text(
              widget.placement ? 'Seviye Testi' : 'Quiz',
              style: const TextStyle(
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
                    Text(
                      widget.placement ? 'Test Tamamlandı!' : 'Quiz Tamamlandı!',
                      style: const TextStyle(
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
                            widget.placement
                                ? 'Seviyen: ${placementLevel ?? '-'}'
                                : '+$earnedXp XP',
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
                    if (reviewWords.isNotEmpty && !widget.placement) ...[
                      const SizedBox(height: 22),
                      _reviewList(),
                    ],
                    const SizedBox(height: 24),
                    if (!widget.placement) ...[
                      _resultButton(
                        text: 'Tekrar Çöz',
                        color: AppColors.yellow,
                        textColor: AppColors.darkNavy,
                        onTap: restartQuiz,
                      ),
                      const SizedBox(height: 14),
                    ],
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

  Widget _reviewList() {
    return Container(
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
          const Text(
            'Tekrar Etmen Gereken Kelimeler',
            style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ...reviewWords.map((word) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${word['word']}: ${word['translation']}',
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                ),
              )),
        ],
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
