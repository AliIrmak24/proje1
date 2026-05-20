import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _topBar(),
              const SizedBox(height: 28),
              _logoArea(),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: _wordOfDayCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _miniQuizCard()),
                ],
              ),
              const SizedBox(height: 22),
              _leaderboardCard(),
              const SizedBox(height: 34),
              _bottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '9:41',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Icon(Icons.notifications_none, color: AppColors.white, size: 30),
      ],
    );
  }

  Widget _logoArea() {
    return Column(
      children: const [
        Text(
          'SözEğitim',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Learn. ', style: TextStyle(color: AppColors.blue)),
              TextSpan(text: 'Play. ', style: TextStyle(color: AppColors.purple)),
              TextSpan(text: 'Compete.', style: TextStyle(color: AppColors.yellow)),
            ],
          ),
          style: TextStyle(fontSize: 20),
        ),
      ],
    );
  }

  Widget _wordOfDayCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(AppColors.blue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.blue, size: 34),
          const SizedBox(height: 20),
          const Text(
            'Günün Kelimesi',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ambition',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('/æmˈbɪʃən/', style: TextStyle(color: AppColors.white)),
          const SizedBox(height: 18),
          const Text(
            'Anlamı',
            style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Büyük başarı elde etme arzusu; hırs, istek, azim.',
            style: TextStyle(color: AppColors.white, height: 1.4),
          ),
          const SizedBox(height: 18),
          _smallButton('Sözlüğe Git', Icons.arrow_forward_ios, onGoDictionary),
        ],
      ),
    );
  }

  Widget _miniQuizCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(AppColors.purple),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sports_esports, color: AppColors.purple, size: 34),
          const SizedBox(height: 20),
          const Text(
            'Mini Quiz',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 22),
          const Text(
            '“Ambition” kelimesinin Türkçe anlamı hangisidir?',
            style: TextStyle(color: AppColors.white, height: 1.4),
          ),
          const SizedBox(height: 14),
          _option('A', 'Başarısızlık', false),
          _option('B', 'İlgi', false),
          _option('C', 'Arzu, hırs', true),
          _option('D', 'Korku', false),
          const SizedBox(height: 14),
          _smallButton('Quiz’e Git', Icons.arrow_forward_ios, onGoQuiz),
        ],
      ),
    );
  }

  Widget _leaderboardCard() {
    final users = [
      ['1', 'Ali Irmak', '2450 XP'],
      ['2', 'Levent Koçtaş', '1920 XP'],
      ['3', 'Zeynep', '1750 XP'],
      ['4', 'Mert', '1380 XP'],
      ['5', 'Elif', '1120 XP'],
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(AppColors.cardBorder),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.yellow, size: 34),
              SizedBox(width: 12),
              Text(
                'Skor Tablosu',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text('Haftalık', style: TextStyle(color: AppColors.white)),
              Icon(Icons.keyboard_arrow_down, color: AppColors.white),
            ],
          ),
          const SizedBox(height: 18),
          ...users.map(
            (user) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: user[0] == '2' ? AppColors.yellow : AppColors.navy,
                    child: Text(
                      user[0],
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      user[1],
                      style: TextStyle(
                        color: user[0] == '2' ? AppColors.yellow : AppColors.white,
                        fontWeight: user[0] == '2' ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(user[2], style: const TextStyle(color: AppColors.yellow)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _circleAction(Icons.person_outline, 'Profil', AppColors.blue, onGoProfile),
        _bigStartButton(),
        _circleAction(Icons.menu_book_outlined, 'Sözlük', AppColors.blue, onGoDictionary),
      ],
    );
  }

  Widget _bigStartButton() {
    return GestureDetector(
      onTap: onGoMatching,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.yellow, width: 3),
          color: AppColors.navy,
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withOpacity(0.35),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_kabaddi, color: AppColors.yellow, size: 36),
            SizedBox(height: 8),
            Text(
              'BAŞLA',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleAction(
    IconData icon,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          color: AppColors.navy,
        ),
        child: Icon(icon, color: color, size: 36),
      ),
    );
  }

  Widget _option(String letter, String text, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.green.withOpacity(0.75) : AppColors.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(letter, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.white))),
          if (selected) const Icon(Icons.check_circle_outline, color: AppColors.white),
        ],
      ),
    );
  }

  Widget _smallButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.blue, size: 18),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(Color borderColor) {
    return BoxDecoration(
      color: AppColors.cardNavy,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor.withOpacity(0.6)),
    );
  }
}