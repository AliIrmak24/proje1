import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  final VoidCallback onGoBack;

  const PersonalInfoScreen({
    super.key,
    required this.onGoBack,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  // Sifre degistirme
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPasswordSection = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profil başarıyla güncellendi!' : (auth.error ?? 'Bir hata oluştu')),
          backgroundColor: success ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm şifre alanlarını doldurun'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifreler eşleşmiyor'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifre en az 8 karakter olmalı'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _showPasswordSection = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Şifre başarıyla değiştirildi!' : (auth.error ?? 'Şifre değiştirilemedi')),
          backgroundColor: success ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 30),
                _profilePhotoCard(user),
                const SizedBox(height: 28),
                _sectionTitle('Kişisel Bilgiler'),
                _editableCard([
                  _editableField(Icons.person_outline, 'Ad Soyad', _fullNameController, 'Adınızı girin'),
                  _editableField(Icons.account_circle_outlined, 'Kullanıcı Adı', _usernameController, 'Kullanıcı adınızı girin'),
                  _editableField(Icons.email_outlined, 'E-posta', _emailController, 'E-posta adresinizi girin', keyboardType: TextInputType.emailAddress),
                  _editableField(Icons.phone_outlined, 'Telefon', _phoneController, 'Telefon numaranızı girin', keyboardType: TextInputType.phone),
                  _editableField(Icons.info_outline, 'Hakkımda', _bioController, 'Kendinizi tanıtın', maxLines: 3),
                ]),
                const SizedBox(height: 20),
                _saveButton(),
                const SizedBox(height: 28),
                _sectionTitle('Hesap Bilgileri'),
                _infoGroup([
                  _infoItem(Icons.workspace_premium, 'Seviye ve Puan', user != null ? '${user.level}. Seviye (${user.xp} XP)' : '-'),
                  _infoItem(Icons.calendar_month, 'Kayıt Tarihi', user?.createdAt != null ? '${user!.createdAt!.day}.${user.createdAt!.month}.${user.createdAt!.year}' : 'Yeni Üye'),
                  _infoItem(Icons.language, 'Uygulama Dili', 'Türkçe'),
                ]),
                const SizedBox(height: 28),
                _sectionTitle('Şifre Yönetimi'),
                _passwordSection(),
                const SizedBox(height: 30),
                _logoutButton(context, auth),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Hesabından çıkış yaparak güvenliğini artırabilirsin.',
                    style: TextStyle(color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        _squareButton(Icons.arrow_back, widget.onGoBack),
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
        const SizedBox(width: 58),
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

  Widget _profilePhotoCard(UserModel? user) {
    final initial = (user != null && user.username.isNotEmpty)
        ? user.username[0].toUpperCase()
        : 'U';
    final displayName = user?.fullName ?? user?.username ?? 'Kullanıcı';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
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
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 58,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: AppColors.yellow),
                        const SizedBox(width: 8),
                        Text(
                          '${user?.level ?? 1}. Seviye',
                          style: const TextStyle(
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _editableCard(List<Widget> children) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(children: children),
    );
  }

  Widget _editableField(
    IconData icon,
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF12395F), width: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            margin: EdgeInsets.only(top: maxLines > 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.yellow.withAlpha((0.35 * 255).round())),
            ),
            child: Icon(icon, color: AppColors.yellow, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: const TextStyle(color: AppColors.white, fontSize: 17),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: AppColors.grey.withAlpha((0.5 * 255).round())),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.yellow, Color(0xFFFFA726)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withAlpha((0.3 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSaving)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkNavy),
              )
            else
              const Icon(Icons.save_outlined, color: AppColors.darkNavy),
            const SizedBox(width: 12),
            Text(
              _isSaving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet',
              style: const TextStyle(
                color: AppColors.darkNavy,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordSection() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.yellow.withAlpha((0.35 * 255).round())),
                    ),
                    child: const Icon(Icons.lock_outline, color: AppColors.yellow, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Şifre Değiştir',
                      style: TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    _showPasswordSection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.grey,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
          if (_showPasswordSection) ...[
            _passwordField('Mevcut Şifre', _oldPasswordController),
            _passwordField('Yeni Şifre', _newPasswordController),
            _passwordField('Yeni Şifre (Tekrar)', _confirmPasswordController),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _isSaving ? null : _changePassword,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.yellow.withAlpha((0.5 * 255).round())),
                  ),
                  child: const Center(
                    child: Text(
                      'Şifreyi Güncelle',
                      style: TextStyle(color: AppColors.yellow, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF12395F), width: 0.7)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(color: AppColors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
        ),
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

  Widget _infoItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF12395F), width: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.yellow.withAlpha((0.35 * 255).round())),
            ),
            child: Icon(icon, color: AppColors.yellow, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context, AuthProvider auth) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Hesaptan Çıkış Yap', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            content: const Text(
              'Oturumunuz kapatılacak ve giriş ekranına yönlendirileceksiniz. Onaylıyor musunuz?',
              style: TextStyle(color: AppColors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Vazgeç', style: TextStyle(color: AppColors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await auth.logout();
                },
                child: const Text('Evet, Çıkış Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha((0.08 * 255).round()),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.redAccent.withAlpha((0.6 * 255).round())),
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