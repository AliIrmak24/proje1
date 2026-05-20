import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onGoHome;
  final VoidCallback onGoBack;
  final VoidCallback onGoPersonalInfo;

  const SettingsScreen({
    super.key,
    required this.onGoHome,
    required this.onGoBack,
    required this.onGoPersonalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 30),

              _sectionTitle('HESAP'),
              _settingsGroup([
                _settingsItem(
                  Icons.person,
                  AppColors.blue,
                  'Kişisel Bilgiler',
                  'Ad, e-posta, dil ve diğer bilgiler',
                  onTap: onGoPersonalInfo,
                ),
              ]),

              const SizedBox(height: 24),
              _sectionTitle('ABONELİK'),
              _settingsGroup([
                _settingsItem(
                  Icons.workspace_premium,
                  AppColors.yellow,
                  'Abonelik Planım',
                  'Premium üyeliğin aktif',
                  badge: 'Premium',
                ),
                _settingsItem(
                  Icons.credit_card,
                  AppColors.blue,
                  'Aboneliği Yönet',
                  'Planı değiştir veya iptal et',
                ),
              ]),

              const SizedBox(height: 24),
              _sectionTitle('TERCİHLER'),
              _settingsGroup([
                _settingsItem(Icons.notifications, AppColors.green,
                    'Bildirim Ayarları', 'Bildirim tercihlerini yönet'),
                _settingsItem(Icons.language, Colors.pinkAccent, 'Dil',
                    'Uygulama dili',
                    value: 'Türkçe'),
                _settingsItem(Icons.dark_mode, AppColors.yellow, 'Görünüm',
                    'Koyu tema',
                    showSwitch: true),
                _settingsItem(Icons.text_fields, AppColors.blue, 'Yazı Boyutu',
                    'Metin boyutunu ayarla',
                    value: 'Orta'),
              ]),

              const SizedBox(height: 24),
              _sectionTitle('DİĞER'),
              _settingsGroup([
                _settingsItem(
                  Icons.info,
                  Colors.cyanAccent,
                  'Hakkımızda',
                  'SözEğitim hakkında bilgi',
                ),
                _settingsItem(
                  Icons.help,
                  AppColors.blue,
                  'Yardım ve Destek',
                  'Sık sorulan sorular ve destek',
                ),
                _settingsItem(
                  Icons.description,
                  AppColors.blue,
                  'Kullanım Koşulları',
                  'Kullanım koşulları ve gizlilik politikası',
                ),
                _settingsItem(
                  Icons.delete,
                  Colors.redAccent,
                  'Hesabı Sil',
                  'Hesabını kalıcı olarak sil',
                ),
              ]),

              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Uygulama Sürümü 1.0.0',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                  ),
                ),
              ),
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
        _squareButton(Icons.arrow_back, onGoBack),
        const Text(
          'Ayarlar',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        _squareButton(Icons.home_outlined, onGoHome),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _settingsItem(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle, {
    String? value,
    String? badge,
    bool showSwitch = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF12395F),
              width: 0.7,
            ),
          ),
        ),
        child: Row(
        children: [
          Icon(icon, color: iconColor, size: 34),
          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.yellow),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: AppColors.yellow,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          if (value != null)
            Text(
              value,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 16,
              ),
            ),

          if (showSwitch)
            Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.white,
              activeTrackColor: AppColors.blue,
            )
          else
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey,
              size: 30,
            ),
        ],
      ),
      ),
    );
  }
}