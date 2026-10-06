import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/providers/dictionary_provider.dart';
import 'presentation/providers/auth_provider.dart'; // Kullanıcı yöneticisi
import 'domain/usecases/search_word_usecase.dart';
import 'data/repositories/word_repository_impl.dart';
import 'data/datasources/word_remote_datasource.dart';
import 'core/network/api_client.dart'; // İnternet arabası

Future<void> main() async {
  // Mobil motorunu başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Mobil dikey yönlendirmeyi kilitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Mobil bildirim çubuğu ve navigasyon rengini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.darkNavy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Varsa kayıtlı mobil sunucu adresini yükle
  await ApiClient.initCustomBaseUrl();

  // 0. İnternet arabamızı (ApiClient) oluşturuyoruz
  final apiClient = ApiClient(); 

  // 1. Python API'sine bağlanacak olan Veri Kaynağını oluşturuyoruz
  final remoteDataSource = WordRemoteDataSource(apiClient: apiClient);

  // 2. Veri Deposunu oluşturup, içine API Kaynağını takıyoruz
  final myRepository = WordRepositoryImpl(remoteDataSource: remoteDataSource); 

  // 3. Arama Motorunu oluşturup, içine Veri Deposunu takıyoruz
  final mySearchUseCase = SearchWordUseCase(repository: myRepository);

  // 4. Ana şalteri açıp her şeyi sisteme tanıtıyoruz
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DictionaryProvider(
            searchWordUseCase: mySearchUseCase, 
          ),
        ),
        // KULLANICI YÖNETİCİSİNİ BURAYA EKLEDİK
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = AuthProvider(apiClient: apiClient);
            authProvider.checkAuth(); // Uygulama açılırken oturumu kontrol et
            return authProvider;
          },
        ),
      ],
      child: const SozEgitimApp(),
    ),
  );
}

class SozEgitimApp extends StatelessWidget {
  const SozEgitimApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'SözEğitim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return Container(
          color: const Color(0xFF040A12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child ?? const SizedBox(),
            ),
          ),
        );
      },
      home: auth.isAuthenticated ? const MainScreen() : const AuthScreen(),
    );
  }
}