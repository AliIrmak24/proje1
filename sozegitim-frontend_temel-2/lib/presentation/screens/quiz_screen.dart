import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int? selectedIndex;
  int correctCount = 0;
  bool quizFinished = false;

  final List<QuizQuestion> questions = [
    QuizQuestion(
      question: '“Ambition” kelimesinin Türkçe anlamı hangisidir?',
      options: ['Başarısızlık', 'İlgi', 'Arzu, hırs', 'Korku'],
      correctIndex: 2,
    ),
    QuizQuestion(
      question: '“Goal” kelimesinin Türkçe anlamı hangisidir?',
      options: ['Hedef', 'Ses', 'Kural', 'Yolculuk'],
      correctIndex: 0,
    ),
    QuizQuestion(
      question: '“Drive” kelimesi bu bağlamda ne anlama gelir?',
      options: ['Sürmek', 'Motivasyon', 'Kapı', 'Sessizlik'],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: '“Desire” kelimesinin Türkçe karşılığı nedir?',
      options: ['Arzu', 'Kayıp', 'Zaman', 'Cevap'],
      correctIndex: 0,
    ),
    QuizQuestion(
      question: '“Aspiration” kelimesine en yakın anlam hangisidir?',
      options: ['Endişe', 'Amaç / istek', 'Yorgunluk', 'Gürültü'],
      correctIndex: 1,
    ),
  ];

  void selectAnswer(int index) {
    if (selectedIndex != null) return;

    setState(() {
      selectedIndex = index;

      if (index == questions[currentIndex].correctIndex) {
        correctCount++;
      }
    });
  }

  void nextQuestion() {
    if (selectedIndex == null) return;

    if (currentIndex == questions.length - 1) {
      setState(() {
        quizFinished = true;
      });
    } else {
      setState(() {
        currentIndex++;
        selectedIndex = null;
      });
    }
  }

  void restartQuiz() {
    setState(() {
      currentIndex = 0;
      selectedIndex = null;
      correctCount = 0;
      quizFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (quizFinished) {
      return _resultScreen();
    }

    final question = questions[currentIndex];

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 30),
              LinearProgressIndicator(
                value: (currentIndex + 1) / questions.length,
                backgroundColor: AppColors.navy,
                color: AppColors.yellow,
                minHeight: 8,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 14),
              Text(
                'Soru ${currentIndex + 1} / ${questions.length}',
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 35),
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
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ...List.generate(
                      question.options.length,
                      (index) => _option(index, question.options[index]),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
        bgColor = Colors.green.withOpacity(0.75);
        borderColor = Colors.greenAccent;
        icon = Icons.check_circle;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.withOpacity(0.75);
        borderColor = Colors.redAccent;
        icon = Icons.cancel;
      } else if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.35);
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
                  fontSize: 18,
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 30,
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Mini Quiz',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 58),
      ],
    );
  }

  Widget _resultScreen() {
    final int wrongCount = questions.length - correctCount;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _header(),
              const Spacer(),
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
                    const SizedBox(height: 24),
                    Text(
                      '$correctCount / ${questions.length} doğru',
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Yanlış sayısı: $wrongCount',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 30),
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
              const Spacer(),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
