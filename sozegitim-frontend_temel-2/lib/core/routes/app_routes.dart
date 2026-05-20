import 'package:flutter/material.dart';
import 'package:my_app/presentation/screens/dictionary_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String dictionary = '/';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dictionary:
      default:
        return MaterialPageRoute(
          builder: (_) => DictionaryScreen(onGoHome: () {}),
        );
    }
  }
}
