import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dictionary_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'matching_screen.dart';
import 'settings_screen.dart';
import 'personal_info_screen.dart';

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
    ];

    return Scaffold(
      body: pages[selectedIndex],
    );
  }
}
