import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Proje yapına uygun güvenli importlar
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import 'quiz_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback onGoHome;
  final VoidCallback onGoSettings;
  final VoidCallback onGoFriends;

  const ProfileScreen({
    super.key,
    this.isActive = true,
    required this.onGoHome,
    required this.onGoSettings,
    required this.onGoFriends,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _stats;

  VoidCallback get onGoHome => widget.onGoHome;
  VoidCallback get onGoSettings => widget.onGoSettings;
  VoidCallback get onGoFriends => widget.onGoFriends;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    try {
      final res = await _apiClient.get('/api/learn/stats');
      if (mounted && res is Map<String, dynamic>) {
        setState(() => _stats = res);
      }
    } catch (_) {}
  }

  void _showLevelPicker(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İngilizce Seviyem', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold)),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in cefrLevels)
              ChoiceChip(
                label: Text(level),
                selected: auth.currentUser?.cefrLevel == level,
                onSelected: (_) {
                  Navigator.pop(ctx);
                  auth.updateProfile(cefrLevel: level);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openPlacementTest(context);
            },
            child: const Text('Seviye Testine Gir', style: TextStyle(color: AppColors.yellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(child: _buildAuthenticatedProfile(context, authProvider)),
    );
  }

  // --- 2. GİRİŞ YAPMIŞ KULLANICI EKRANI ---
  Widget _buildAuthenticatedProfile(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(
        children: [
          _header(),
          const SizedBox(height: 22),
          _profileTop(user),
          const SizedBox(height: 24),
          _levelCard(user),
          const SizedBox(height: 18),
          _learningProfileCard(auth),
          const SizedBox(height: 18),
          _statsCard(),
          const SizedBox(height: 18),
          _achievementsCard(),
          const SizedBox(height: 18),
          _activityCard(),
          const SizedBox(height: 18),
          _bottomMenu(auth),
        ],
      ),
    );
  }

  // --- TASARIM BİLEŞENLERİ ---

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _squareButton(Icons.arrow_back, onGoHome),
        const Text(
          'Profil',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        // SAĞ ÜSTTEKİ AYARLAR BUTONU
        _squareButton(Icons.settings, onGoSettings), 
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

  Widget _profileTop(UserModel? user) {
    final initial = (user != null && user.username.isNotEmpty)
        ? user.username[0].toUpperCase()
        : 'U';
    final displayName = user?.username ?? 'Kullanıcı';

    return Column(
      children: [
        Container(
          width: 138,
          height: 138,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.yellow, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withAlpha((0.25 * 255).round()),
                blurRadius: 22,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          displayName,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.yellow, size: 20),
              const SizedBox(width: 6),
              Text(
                user != null ? '${user.level}. Seviye Öğrenci' : 'Misafir',
                style: const TextStyle(
                  color: AppColors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _levelCard(UserModel? user) {
    final level = user?.level ?? 1;
    final currentLevelXp = user?.xpInCurrentLevel ?? 0;
    final progress = user?.levelProgress ?? 0.0;
    final totalXp = user?.xp ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.yellow, width: 3),
            ),
            child: Text(
              '$level',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$level. Seviye',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppColors.navy,
                    color: AppColors.yellow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$currentLevelXp / 100 XP',
                  style: const TextStyle(color: AppColors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(width: 1, height: 80, color: AppColors.cardBorder),
          const SizedBox(width: 18),
          Column(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.yellow, size: 42),
              const SizedBox(height: 6),
              Text(
                '$totalXp',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Toplam XP', style: TextStyle(color: AppColors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _learningProfileCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, color: AppColors.blue, size: 30),
              SizedBox(width: 12),
              Text(
                'Öğrenme Profili',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _profileInfo(Icons.translate, AppColors.blue, 'Ana Dil', 'Türkçe'),
              _divider(),
              _profileInfo(
                Icons.language,
                AppColors.green,
                'Seviyem',
                auth.currentUser?.cefrLevel ?? 'Belirle',
                onTap: () => _showLevelPicker(auth),
              ),
              _divider(),
              _profileInfo(Icons.track_changes, AppColors.purple, 'Bugün', '${_stats?['words_today'] ?? 0} / ${_stats?['daily_goal'] ?? 10}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.yellow, size: 30),
              SizedBox(width: 12),
              Text(
                'İstatistiklerim',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statBox(Icons.menu_book, AppColors.blue, '${_stats?['learned_words'] ?? 0}', 'Öğrenilen Kelime'),
              const SizedBox(width: 10),
              _statBox(Icons.local_fire_department, AppColors.green, '${_stats?['streak_days'] ?? 0}', 'Günlük Seri'),
              const SizedBox(width: 10),
              _statBox(Icons.workspace_premium, AppColors.purple, '${_stats?['strongest_level'] ?? '-'}', 'En Güçlü Seviye'),
              const SizedBox(width: 10),
              _statBox(Icons.emoji_events, AppColors.yellow, '${_stats?['total_quizzes'] ?? 0}', 'Toplam Quiz'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _achievementsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech, color: AppColors.yellow, size: 30),
              SizedBox(width: 12),
              Text(
                'Başarılarım',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final item in (_stats?['achievements'] as List<dynamic>? ?? []))
                _achievement(
                  item['unlocked'] == true ? Icons.emoji_events : Icons.lock,
                  item['unlocked'] == true ? AppColors.yellow : AppColors.grey,
                  item['title'].toString(),
                  item['unlocked'] == true ? 'Tamamlandı' : 'Kilitli',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityCard() {
    final activity = (_stats?['activity'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final values = activity.map((day) => (day['xp'] as num).toInt()).toList();
    final maxValue = values.fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.blue, size: 30),
              SizedBox(width: 12),
              Text(
                'Son 7 Gün (XP)',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final height = 110.0 * values[index] / maxValue;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${values[index]}',
                        style: const TextStyle(color: AppColors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 28,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days[DateTime.parse(activity[index]['date'] as String).weekday - 1],
                        style: const TextStyle(color: AppColors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomMenu(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _menuItem(
            Icons.people_alt_rounded,
            AppColors.blue,
            'Arkadaşlarım',
            onGoFriends,
          ),
          const Divider(color: AppColors.cardBorder),
          _menuItem(
            Icons.settings,
            AppColors.grey,
            'Ayarlar',
            onGoSettings, // Callback'e bağladık
          ),
          const Divider(color: AppColors.cardBorder),
          _menuItem(
            Icons.logout,
            Colors.redAccent,
            'Çıkış Yap',
            auth.logout,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, Color iconColor, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _profileInfo(IconData icon, Color color, String label, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 80, color: AppColors.cardBorder);
  }

  Widget _statBox(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievement(IconData icon, Color color, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 42),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 5),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11)),
        ],
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