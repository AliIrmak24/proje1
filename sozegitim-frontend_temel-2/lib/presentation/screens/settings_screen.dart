import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';

class SettingsScreen extends StatefulWidget {
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
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _apiClient = ApiClient();

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: _apiClient.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.wifi_tethering, color: AppColors.yellow),
            SizedBox(width: 10),
            Text(
              'Sunucu / API Ayarı',
              style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mobil cihaz veya emülatörün bağlanacağı backend adresini girin:',
              style: TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkNavy,
                hintText: 'http://10.0.2.2:8000',
                hintStyle: const TextStyle(color: AppColors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.blue),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _quickUrlChip('Emülatör (10.0.2.2)', 'http://10.0.2.2:8000', controller),
                _quickUrlChip('Localhost (127.0.0.1)', 'http://127.0.0.1:8000', controller),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow),
            onPressed: () async {
              final newUrl = controller.text;
              await ApiClient.saveCustomBaseUrl(newUrl);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.cardNavy,
                    content: Text('Sunucu güncellendi: ${ApiClient().baseUrl}',
                        style: const TextStyle(color: AppColors.yellow)),
                  ),
                );
              }
            },
            child: const Text('Kaydet', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _quickUrlChip(String label, String url, TextEditingController controller) {
    return InkWell(
      onTap: () {
        controller.text = url;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.blue.withAlpha(120)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

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
                  onTap: widget.onGoPersonalInfo,
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
              _sectionTitle('TERCİHLER & MOBİL'),
              _settingsGroup([
                _settingsItem(
                  Icons.wifi_tethering,
                  AppColors.yellow,
                  'Mobil API Sunucusu',
                  'Cihazın bağlanacağı backend IP/port',
                  value: _apiClient.baseUrl,
                  onTap: _showServerConfigDialog,
                ),
                _settingsItem(
                  Icons.notifications,
                  AppColors.green,
                  'Bildirim Ayarları',
                  'Bildirim tercihlerini yönet',
                ),
                _settingsItem(
                  Icons.language,
                  Colors.pinkAccent,
                  'Dil',
                  'Uygulama dili',
                  value: 'Türkçe',
                ),
                _settingsItem(
                  Icons.dark_mode,
                  AppColors.yellow,
                  'Görünüm',
                  'Koyu tema',
                  showSwitch: true,
                ),
                _settingsItem(
                  Icons.text_fields,
                  AppColors.blue,
                  'Yazı Boyutu',
                  'Metin boyutunu ayarla',
                  value: 'Orta',
                ),
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
                  'Uygulama Sürümü 1.0.0 (Mobil Uyumlu)',
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
        _squareButton(Icons.arrow_back, widget.onGoBack),
        const Text(
          'Ayarlar',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
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
      child: Column(children: children),
    );
  }

  Widget _settingsItem(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle, {
    String? badge,
    String? value,
    bool showSwitch = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.cardBorder,
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
                            fontSize: 17,
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
                            color: AppColors.yellow.withAlpha((0.12 * 255).round()),
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
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (showSwitch)
              Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.blue,
              )
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.grey,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}