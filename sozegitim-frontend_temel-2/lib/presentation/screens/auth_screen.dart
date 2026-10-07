import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Giriş Yap Kontrolleri
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Kayıt Ol Kontrolleri
  final _regUsernameController = TextEditingController();
  final _regFullNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regFullNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı adı ve şifrenizi girin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.login(username, password);
    setState(() => _isSubmitting = false);

    if (!success && mounted) {
      if (auth.error != null && (auth.error!.contains('Connection error') || auth.error!.contains('Sunucuya bağlanılamadı'))) {
        _showConnectionErrorDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Giriş yapılamadı. Bilgilerinizi kontrol edin.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    final username = _regUsernameController.text.trim();
    final fullName = _regFullNameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı adı, e-posta ve şifrenizi girin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre en az 4 karakter olmalıdır.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.register(email, username, password);

    if (success && fullName.isNotEmpty) {
      // Ad soyad girilmişse güncelle
      await auth.updateProfile(fullName: fullName);
    }

    setState(() => _isSubmitting = false);

    if (!success && mounted) {
      if (auth.error != null && (auth.error!.contains('Connection error') || auth.error!.contains('Sunucuya bağlanılamadı'))) {
        _showConnectionErrorDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Kayıt oluşturulamadı.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showConnectionErrorDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Sunucu Bağlantısı', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bilgisayarınızdaki SözEğitim sunucusuna erişilemedi.',
              style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Text(
              '• Telefon ve bilgisayarınız aynı Wi-Fi ağına bağlı olmalıdır.\n• Veya "Demo Modu" ile tüm 5.000+ kelimeyi hemen kullanabilirsiniz.',
              style: TextStyle(color: AppColors.grey, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showServerConfigDialog();
            },
            child: const Text('Sunucu IP Değiştir', style: TextStyle(color: AppColors.yellow)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _loginUsernameController.text = 'admin';
              _loginPasswordController.text = '1234';
              _handleLogin();
            },
            child: const Text('Demo Giriş Yap', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiClient.customBaseUrl ?? 'http://192.168.1.104:8000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_outlined, color: AppColors.yellow, size: 26),
            SizedBox(width: 10),
            Text('Sunucu IP Ayarı', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bilgisayarınızın IP adresini girin:',
              style: TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'http://192.168.1.104:8000',
                hintStyle: const TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: AppColors.darkNavy,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ApiClient.saveCustomBaseUrl(newUrl);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Sunucu adresi kaydedildi: $newUrl'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Üst Bar: Sunucu Durumu ve Ayarı
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.cardNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      onPressed: _showServerConfigDialog,
                      icon: const Icon(Icons.wifi_rounded, color: AppColors.yellow, size: 16),
                      label: const Text(
                        'Sunucu IP',
                        style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Logo & Başlık
                const Icon(Icons.school_rounded, color: AppColors.yellow, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'SözEğitim',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Learn. Play. Compete.',
                  style: TextStyle(color: AppColors.grey, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // Sekme Butonları (Giriş Yap / Kayıt Ol)
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: AppColors.yellow,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.darkNavy,
                    unselectedLabelColor: AppColors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: 'Giriş Yap'),
                      Tab(text: 'Kayıt Ol'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sekme İçerikleri
                SizedBox(
                  height: 410,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginTab(),
                      _buildRegisterTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Column(
      children: [
        _inputField(
          controller: _loginUsernameController,
          hint: 'Kullanıcı Adı veya E-posta',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _inputField(
          controller: _loginPasswordController,
          hint: 'Şifre',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 22),
        _primaryButton(
          title: 'Giriş Yap',
          isLoading: _isSubmitting,
          onTap: _handleLogin,
        ),
        const SizedBox(height: 14),
        // Hızlı Deneme Girişi Butonu
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.cardBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          onPressed: () {
            _loginUsernameController.text = 'admin';
            _loginPasswordController.text = '1234';
            _handleLogin();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, color: AppColors.yellow, size: 20),
              SizedBox(width: 8),
              Text(
                'Demo Hesapla Hemen Başla (Admin)',
                style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _inputField(
            controller: _regFullNameController,
            hint: 'Adınız Soyadınız',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _inputField(
            controller: _regUsernameController,
            hint: 'Kullanıcı Adı',
            icon: Icons.account_circle_outlined,
          ),
          const SizedBox(height: 12),
          _inputField(
            controller: _regEmailController,
            hint: 'E-posta Adresi',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _inputField(
            controller: _regPasswordController,
            hint: 'Şifre (en az 4 karakter)',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 20),
          _primaryButton(
            title: 'Kayıt Ol ve Başla',
            isLoading: _isSubmitting,
            onTap: _handleRegister,
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.white, fontSize: 16),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.yellow, size: 22),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 15),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String title,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.yellow, Color(0xFFFFA726)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withAlpha((0.3 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: AppColors.darkNavy, strokeWidth: 2.5),
                )
              : Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
