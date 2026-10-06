import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _register() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final success = await provider.register(
      _emailController.text.trim(),
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      // Kayıt başarılı olunca tüm giriş pencerelerini kapatıp ana profile dönmek için
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Kayıt başarısız!'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            Navigator.pop(context); // Bir önceki sayfa olan Giriş Yap ekranına döner
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.white),
            onPressed: () {
              // Giriş/Kayıt akışından tamamen çıkıp doğrudan ana ekrana fırlatır
              Navigator.popUntil(context, (route) => route.isFirst);
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
              // Mavi Temalı İkon Çerçevesi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navy,
                  border: Border.all(color: AppColors.blue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withAlpha((0.3 * 255).round()),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.person_add_alt_1, size: 60, color: AppColors.blue),
              ),
              const SizedBox(height: 30),
              
              const Text(
                'Aramıza Katıl',
                style: TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kelime öğrenme serüvenine başlamak için\nücretsiz hesabını oluştur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                controller: _emailController,
                hint: 'E-posta',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _usernameController,
                hint: 'Kullanıcı Adı',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hint: 'Şifre',
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
                          elevation: 5,
                        ),
                        onPressed: _register,
                        child: const Text(
                          'Kayıt Ol',
                          style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Giriş ekranına pürüzsüz geri dönüş sağlar
                },
                child: RichText(
                  text: const TextSpan(
                    text: 'Zaten hesabın var mı? ',
                    style: TextStyle(color: AppColors.grey, fontSize: 15),
                    children: [
                      TextSpan(
                        text: 'Giriş Yap',
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
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey),
        prefixIcon: Icon(icon, color: AppColors.blue),
        filled: true,
        fillColor: AppColors.cardNavy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue, width: 2), // Odaklanınca mavi parlar
        ),
      ),
    );
  }
}