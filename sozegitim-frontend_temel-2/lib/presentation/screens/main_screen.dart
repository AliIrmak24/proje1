import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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

  void goHome() {
    setState(() {
      selectedIndex = 0;
    });
  }

  void goDictionary() {
    setState(() {
      selectedIndex = 1;
    });
  }

  void goQuiz() {
    setState(() {
      selectedIndex = 2;
    });
  }

  void goProfile() {
    setState(() {
      selectedIndex = 3;
    });
  }

  void goMatching() {
    setState(() {
      selectedIndex = 4;
    });
  }

  void goSettings() {
    setState(() {
      selectedIndex = 5;
    });
  }

  void goPersonalInfo() {
    setState(() {
      selectedIndex = 6;
    });
  }

  void goFriends() {
    setState(() {
      selectedIndex = 7;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
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
      body: pages[selectedIndex],
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
            currentIndex: selectedIndex < 5 ? selectedIndex : 0,
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
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
                label: 'Eşleştirme',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
