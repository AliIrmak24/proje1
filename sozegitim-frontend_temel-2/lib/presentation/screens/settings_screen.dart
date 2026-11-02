import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../providers/auth_provider.dart';

const String _aboutText = '''SözEğitim, Türkçe konuşanlar için İngilizce kelime öğrenme uygulamasıdır.

SÖZLÜK VERİ KAYNAKLARI

Kelime listesi ve seviyeler: The CEFR-J Wordlist Version 1.5. Compiled by Yukio Tono, Tokyo University of Foreign Studies. Octanove Vocabulary Profile C1/C2 (Octanove Labs), CC BY-SA 4.0.

Çeviriler, tanımlar ve telaffuz: Vikisözlük katılımcıları, CC BY-SA 4.0. Veriler Wiktextract/kaikki.org ile çıkarılmıştır (T. Ylonen). Üzerinde biçim ve eleme değişiklikleri yapılmıştır.

Örnek cümleler: Tatoeba katılımcıları, CC BY 2.0 FR. Her cümlenin numarası ve yazarı kelime kartında gösterilir.

Sözlük verisi CC BY-SA 4.0 koşullarıyla paylaşılır: creativecommons.org/licenses/by-sa/4.0''';

const String _helpText = '''Kelime kartları nasıl çalışır?
Bildiğin kelimeler giderek daha uzun aralıklarla karşına çıkar: 1, 3, 7, 14 ve 30 gün. Bilemediğin kelime kısa süre sonra yeniden gelir.

XP nasıl kazanılır?
Quiz, kelime kartları, eşleştirme, okuma ve mini quiz XP kazandırır. Her etkinliğin 24 saatlik bir XP sınırı vardır.

Seviyemi nasıl değiştiririm?
Profil ekranında Seviyem alanına dokun.

Sunucuya bağlanamıyorum
Telefon ve sunucunun aynı ağda olduğundan emin ol, adresi bu ekrandaki Mobil API Sunucusu alanından kontrol et.''';

const String _privacyText = '''Toplanan bilgiler
Kullanıcı adı, e-posta ve şifrenin geri çevrilemez özeti. İsteğe bağlı olarak ad soyad, telefon ve kısa tanıtım. Öğrenme ilerlemesi, XP, kişisel notlar ve arkadaş listesi.

Kullanım amacı
Bu bilgiler yalnızca hesabını yönetmek, öğrenme ilerlemeni göstermek ve skor tablosu ile arkadaş özelliklerini çalıştırmak için kullanılır. Üçüncü taraflarla paylaşılmaz, reklam amacıyla kullanılmaz.

Görünürlük
Kullanıcı adın, seviyen ve XP'n skor tablosunda ve kullanıcı aramalarında görünür.

Silme hakkı
Ayarlar > Hesabı Sil ile hesabını ve sana ait tüm verileri kalıcı olarak silebilirsin.''';

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

  void _showTextDialog(String title, String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(text, style: const TextStyle(color: AppColors.white, fontSize: 14, height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(color: AppColors.yellow)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hesabı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hesabın, ilerlemen, notların ve arkadaşlıkların kalıcı olarak silinir. Bu işlem geri alınamaz.',
              style: TextStyle(color: AppColors.white),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                labelText: 'Şifren',
                labelStyle: TextStyle(color: AppColors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              final success = await auth.deleteAccount(passwordController.text);
              navigator.pop();
              if (!success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(auth.error ?? 'Hesap silinemedi'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Kalıcı Olarak Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
                  'Ad, e-posta, şifre ve diğer bilgiler',
                  onTap: widget.onGoPersonalInfo,
                ),
              ]),

              const SizedBox(height: 24),
              _sectionTitle('BAĞLANTI'),
              _settingsGroup([
                _settingsItem(
                  Icons.wifi_tethering,
                  AppColors.yellow,
                  'Mobil API Sunucusu',
                  'Cihazın bağlanacağı backend IP/port',
                  value: _apiClient.baseUrl,
                  onTap: _showServerConfigDialog,
                ),
              ]),

              const SizedBox(height: 24),
              _sectionTitle('DİĞER'),
              _settingsGroup([
                _settingsItem(
                  Icons.info,
                  Colors.cyanAccent,
                  'Hakkımızda',
                  'Uygulama ve sözlük kaynakları',
                  onTap: () => _showTextDialog('Hakkımızda', _aboutText),
                ),
                _settingsItem(
                  Icons.help,
                  AppColors.blue,
                  'Yardım',
                  'Sık sorulan sorular',
                  onTap: () => _showTextDialog('Yardım', _helpText),
                ),
                _settingsItem(
                  Icons.description,
                  AppColors.blue,
                  'Gizlilik',
                  'Hangi verilerin tutulduğu',
                  onTap: () => _showTextDialog('Gizlilik', _privacyText),
                ),
                _settingsItem(
                  Icons.delete,
                  Colors.redAccent,
                  'Hesabı Sil',
                  'Hesabını kalıcı olarak sil',
                  onTap: _showDeleteAccountDialog,
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
    String? value,
    required VoidCallback onTap,
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
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
