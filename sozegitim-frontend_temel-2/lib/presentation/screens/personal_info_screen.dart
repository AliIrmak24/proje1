import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PersonalInfoScreen extends StatelessWidget {
  final VoidCallback onGoBack;

  const PersonalInfoScreen({
    super.key,
    required this.onGoBack,
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
              _profilePhotoCard(),
              const SizedBox(height: 28),
              _sectionTitle('Hesap Bilgileri'),
              _infoGroup([
                _infoItem(Icons.person_outline, 'Ad Soyad', 'Ali Irmak'),
                _infoItem(Icons.account_circle_outlined, 'Kullanıcı Adı', 'aliirmak'),
                _infoItem(Icons.email_outlined, 'E-posta', 'aliirmak2019@gmail.com'),
                _infoItem(Icons.phone, 'Telefon Numarası', '+90 555 123 45 67'),
                _infoItem(Icons.calendar_month, 'Doğum Tarihi', '15 Mayıs 2002'),
                _infoItem(Icons.language, 'Ülke / Bölge', 'Türkiye'),
              ]),
              const SizedBox(height: 28),
              _sectionTitle('Hesap Güvenliği'),
              _infoGroup([
                _infoItem(Icons.lock_outline, 'Şifre Değiştir', 'Hesap şifreni güncelle'),
                _infoItem(
                  Icons.verified_user_outlined,
                  'İki Adımlı Doğrulama',
                  'Hesabını daha güvenli hale getir',
                  value: 'Kapalı',
                ),
                _infoItem(Icons.key, 'Oturumlar', 'Aktif oturumlarını yönet'),
              ]),
              const SizedBox(height: 30),
              _logoutButton(),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Hesapından çıkış yaparak güvenliğini artırabilirsin.',
                  style: TextStyle(color: AppColors.grey),
                  textAlign: TextAlign.center,
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
      children: [
        _squareButton(Icons.arrow_back, onGoBack),
        const Expanded(
          child: Column(
            children: [
              Text(
                'Kişisel Bilgiler',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hesap bilgilerini görüntüle ve güncelle',
                style: TextStyle(color: AppColors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
        _squareButton(Icons.verified_user_outlined, () {}),
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

  Widget _profilePhotoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil Fotoğrafı',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.yellow, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 58,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.darkNavy,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 28),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ali Irmak',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.workspace_premium, color: AppColors.yellow),
                        SizedBox(width: 8),
                        Text(
                          'Premium Üye',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey, size: 34),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoGroup(List<Widget> children) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(children: children),
    );
  }

  Widget _infoItem(
    IconData icon,
    String title,
    String subtitle, {
    String? value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF12395F), width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.yellow.withOpacity(0.35)),
            ),
            child: Icon(icon, color: AppColors.yellow, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (value != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                value,
                style: const TextStyle(color: AppColors.grey),
              ),
            ),
          const Icon(Icons.chevron_right, color: AppColors.grey, size: 30),
        ],
      ),
    );
  }

  Widget _logoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, color: Colors.redAccent),
          SizedBox(width: 12),
          Text(
            'Hesaptan Çıkış Yap',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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