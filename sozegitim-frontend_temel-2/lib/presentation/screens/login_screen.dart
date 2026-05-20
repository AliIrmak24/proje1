import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'settings_screen.dart'; // Ayarlar ekranı importu

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    
    // AuthProvider içinde admin/1234 mantığı yüklü olduğu için doğrudan çağırıyoruz
    final success = await provider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context); // Giriş başarılı, ana ekrana dön
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Giriş başarısız!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // SOL ÜST: Ana ekrana dönme (Kapatma simgesi)
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        // SAĞ ÜST: Ayarlar butonu (Kırmızı çizgiyi kaldıran kısım)
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    onGoBack: () => Navigator.pop(context),
                    onGoHome: () => Navigator.popUntil(context, (route) => route.isFirst),
                    onGoPersonalInfo: () {
                       // Henüz bu ekranı bağlamadık, şimdilik boş kalabilir
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mavi Temalı Modern İkon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navy,
                  border: Border.all(color: AppColors.blue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_person_outlined, size: 60, color: AppColors.blue),
              ),
              const SizedBox(height: 30),
              
              const Text(
                'Giriş Yap',
                style: TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hesabına erişmek için bilgilerini gir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                controller: _usernameController,
                hint: 'Kullanıcı Adı (admin)',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hint: 'Şifre (1234)',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 32),

              isLoading
                  ? const CircularProgressIndicator(color: AppColors.blue)
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _login,
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: 'Hesabın yok mu? ',
                    style: TextStyle(color: AppColors.grey, fontSize: 15),
                    children: [
                      TextSpan(
                        text: 'Kayıt Ol',
                        style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.blue),
        filled: true,
        fillColor: AppColors.cardNavy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
    );
  }
}