import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'dictionary_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'matching_screen.dart';
import 'settings_screen.dart';
import 'personal_info_screen.dart';
import 'friends_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  // Sekmeler ilk açıldığında oluşturulur, sonra durumlarını korur
  final Set<int> _visitedPages = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerPlacementTest());
  }

  // Seviyesi belli olmayan kullanıcıya bir kez seviye testi önerilir
  Future<void> _offerPlacementTest() async {
    final user = context.read<AuthProvider>().currentUser;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || user == null || user.cefrLevel != null) return;
    if (prefs.getBool('placement_prompted') ?? false) return;
    await prefs.setBool('placement_prompted', true);
    if (!mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Seviyeni Belirleyelim', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold)),
        content: const Text(
          '18 soruluk kısa test sana uygun kelimeleri seçmemizi sağlar. Sonucu Profil ekranından değiştirebilirsin.',
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Şimdi Değil', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.darkNavy),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Teste Başla', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      openPlacementTest(context);
    }
  }

  void _goTo(int index) {
    setState(() {
      selectedIndex = index;
      _visitedPages.add(index);
    });
  }

  void goHome() => _goTo(0);
  void goDictionary() => _goTo(1);
  void goQuiz() => _goTo(2);
  void goProfile() => _goTo(3);
  void goMatching() => _goTo(4);
  void goSettings() => _goTo(5);
  void goPersonalInfo() => _goTo(6);
  void goFriends() => _goTo(7);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        isActive: selectedIndex == 0,
        onGoDictionary: goDictionary,
        onGoQuiz: goQuiz,
        onGoProfile: goProfile,
        onGoMatching: goMatching,
      ),

      DictionaryScreen(
        onGoHome: goHome,
      ),

      QuizScreen(
        onGoHome: goHome,
      ),

      ProfileScreen(
        isActive: selectedIndex == 3,
        onGoHome: goHome,
        onGoSettings: goSettings,
        onGoFriends: goFriends,
      ),

      MatchingScreen(
        onGoHome: goHome,
      ),

      SettingsScreen(
        onGoHome: goHome,
        onGoBack: goProfile,
        onGoPersonalInfo: goPersonalInfo,
      ),

      PersonalInfoScreen(
        onGoBack: goSettings,
      ),

      FriendsScreen(
        onGoBack: goProfile,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: IndexedStack(
        index: selectedIndex,
        children: [
          for (var i = 0; i < pages.length; i++)
            _visitedPages.contains(i) ? pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            border: Border(
              top: BorderSide(
                color: AppColors.cardBorder.withAlpha(120),
                width: 1.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex < 5 ? selectedIndex : 3,
            onTap: _goTo,
            backgroundColor: AppColors.cardNavy,
            selectedItemColor: AppColors.yellow,
            unselectedItemColor: AppColors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded),
                label: 'Sözlük',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.quiz_rounded),
                label: 'Quiz',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_esports_rounded),
                label: 'Oyunlar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
