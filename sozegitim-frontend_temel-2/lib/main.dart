import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/providers/auth_provider.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobil dikey yönlendirmeyi kilitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Android alt menü (geri, ana ekran, arka plan tuşları) ve durum çubuğunu gizle
  // Kullanıcı kenardan kaydırdığında geçici olarak belirip hemen kendiliğinden gizlenir.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Sistem çubuk renklerini şeffaf yap
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Varsa kayıtlı mobil sunucu adresini yükle
  await ApiClient.initCustomBaseUrl();

  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = AuthProvider(apiClient: apiClient);
            authProvider.checkAuth();
            return authProvider;
          },
        ),
      ],
      child: const SozEgitimApp(),
    ),
  );
}

class SozEgitimApp extends StatefulWidget {
  const SozEgitimApp({super.key});

  @override
  State<SozEgitimApp> createState() => _SozEgitimAppState();
}

class _SozEgitimAppState extends State<SozEgitimApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setImmersiveMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulamaya geri dönüldüğünde alt gezinme çubuğunu yeniden gizle
    if (state == AppLifecycleState.resumed) {
      _setImmersiveMode();
    }
  }

  void _setImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'SözEğitim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Çok büyük sistem yazı boyutlarının kartları taşırmasını önlerken
        // görme zorluğu olan kullanıcılar için büyütmeye izin verilir.
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: Container(
            color: const Color(0xFF040A12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: child ?? const SizedBox(),
              ),
            ),
          ),
        );
      },
      home: auth.isAuthenticated ? const MainScreen() : const AuthScreen(),
    );
  }
}
