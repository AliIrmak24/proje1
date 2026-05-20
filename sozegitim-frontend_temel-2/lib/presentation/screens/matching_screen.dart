import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MatchingScreen extends StatefulWidget {
  final VoidCallback onGoHome;

  const MatchingScreen({
    super.key,
    required this.onGoHome,
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController rotateController;
  late AnimationController arrowController;
  late AnimationController pulseController;

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
  }

  @override
  void dispose() {
    rotateController.dispose();
    arrowController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 34),
              const Text(
                'SözEğitim',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 42),
              const Icon(
                Icons.sports_kabaddi,
                color: AppColors.yellow,
                size: 46,
              ),
              const SizedBox(height: 16),
              const Text(
                'Yarışma Eşleşmesi',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sana uygun bir rakip aranıyor...',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 42),
              _matchingArea(),
              const SizedBox(height: 42),
              _infoCard(),
              const SizedBox(height: 24),
              _tipCard(),
              const SizedBox(height: 34),
              _cancelButton(),
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
        _squareButton(Icons.home_outlined, widget.onGoHome),
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

  Widget _matchingArea() {
    return SizedBox(
      height: 270,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _playerSide(
            icon: Icons.person_outline,
            title: 'Sen',
            subtitle: 'Seviye 12',
            xp: '2450 XP',
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
                        size: const Size(210, 210),
                        painter: MatchingCirclePainter(),
                      ),
                    );
                  },
                ),

                ScaleTransition(
                  scale: pulseController,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardNavy,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(0.45),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.yellow,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: AppColors.yellow,
                      size: 44,
                    ),
                  ),
                ),

                const Positioned(
                  bottom: 42,
                  child: Text(
                    'Eşleşme aranıyor',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                Positioned(
                  left: 16,
                  child: AnimatedBuilder(
                    animation: arrowController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(arrowController.value * 16, 0),
                        child: const Row(
                          children: [
                            Icon(Icons.chevron_right,
                                color: AppColors.blue, size: 28),
                            Icon(Icons.chevron_right,
                                color: AppColors.blue, size: 28),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  right: 16,
                  child: AnimatedBuilder(
                    animation: arrowController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(-arrowController.value * 16, 0),
                        child: const Row(
                          children: [
                            Icon(Icons.chevron_left,
                                color: AppColors.yellow, size: 28),
                            Icon(Icons.chevron_left,
                                color: AppColors.yellow, size: 28),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          _opponentSide(),
        ],
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
      width: 96,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleIcon(icon, AppColors.blue),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              '🏆 $xp',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opponentSide() {
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleIcon(Icons.question_mark, AppColors.blue),
          const SizedBox(height: 16),
          const Text(
            'Rakip',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Bulunuyor...',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navy,
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(icon, color: color, size: 48),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.access_time, color: AppColors.blue, size: 42),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tahmini Bekleme Süresi',
                  style: TextStyle(color: AppColors.grey),
                ),
                SizedBox(height: 6),
                Text(
                  '10 - 20 saniye',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.groups_outlined, color: AppColors.blue, size: 42),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şu anda çevrimiçi',
                  style: TextStyle(color: AppColors.grey),
                ),
                SizedBox(height: 6),
                Text(
                  '1287 kullanıcı',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.yellow, size: 34),
              SizedBox(width: 12),
              Text(
                'Biliyor musun?',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Düzenli yarışmalara katılarak daha fazla XP kazanabilir, '
            'sıralamada yükselerek ödüller kazanabilirsin!',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _tipItem(
                  Icons.track_changes,
                  AppColors.blue,
                  'Doğru cevapla',
                  'XP kazan',
                ),
              ),
              Expanded(
                child: _tipItem(
                  Icons.flash_on,
                  AppColors.purple,
                  'Hızlı ol',
                  'Avantaj sağla',
                ),
              ),
              Expanded(
                child: _tipItem(
                  Icons.emoji_events,
                  AppColors.yellow,
                  'Kazan',
                  'Liderliğe yüksel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 42),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _cancelButton() {
    return GestureDetector(
      onTap: widget.onGoHome,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.redAccent, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, color: Colors.redAccent),
            SizedBox(width: 12),
            Text(
              'Eşleşmeyi İptal Et',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
      ..color = AppColors.cardBorder.withOpacity(0.45);

    final bluePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = AppColors.blue;

    final yellowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = AppColors.yellow;

    canvas.drawCircle(center, 105, basePaint);
    canvas.drawCircle(center, 78, basePaint);
    canvas.drawCircle(center, 52, basePaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 86),
      -pi / 2,
      pi * 1.15,
      false,
      bluePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 86),
      pi / 6,
      pi * 0.55,
      false,
      yellowPaint,
    );

    final dotPaint = Paint()..color = AppColors.blue.withOpacity(0.55);

    for (int i = 0; i < 18; i++) {
      final angle = (2 * pi / 18) * i;
      final dx = center.dx + cos(angle) * 64;
      final dy = center.dy + sin(angle) * 64;
      canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
