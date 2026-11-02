import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sozegitim/core/network/api_client.dart';
import 'package:sozegitim/data/models/user_model.dart';
import 'package:sozegitim/data/models/word_model.dart';
import 'package:sozegitim/presentation/providers/auth_provider.dart';
import 'package:sozegitim/presentation/screens/auth_screen.dart';
import 'package:sozegitim/presentation/screens/friends_screen.dart';
import 'package:sozegitim/presentation/screens/main_screen.dart';
import 'package:sozegitim/presentation/screens/reading_screen.dart';
import 'package:sozegitim/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('giriş ekranı açılır ve demo girişi içermez', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(apiClient: ApiClient()),
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    expect(find.text('Giriş Yap'), findsWidgets);
    expect(find.textContaining('Demo'), findsNothing);
  });

  testWidgets('ana sekmeler çizim hatası vermeden açılır', (WidgetTester tester) async {
    // Test yazı tipi harfleri kare çizdiği için dar ekranda sahte taşma üretir
    tester.view.physicalSize = const Size(700, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(apiClient: ApiClient()),
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    for (final tab in ['Sözlük', 'Quiz', 'Profil', 'Oyunlar', 'Ana Sayfa']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: tab);
    }
    expect(find.text('Öğrenme Profili', skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('okuma, arkadaşlar ve ayarlar ekranları açılır', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(700, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final screens = <Widget>[
      ReadingScreen(onGoBack: () {}),
      FriendsScreen(onGoBack: () {}),
      SettingsScreen(onGoHome: () {}, onGoBack: () {}, onGoPersonalInfo: () {}),
    ];
    for (final screen in screens) {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiClient: ApiClient()),
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  test('UserModel seviye bilgisini korur', () {
    final user = UserModel.fromJson({
      'id': 7,
      'username': 'deneme',
      'email': 'deneme@example.com',
      'xp': 250,
      'level': 3,
      'cefr_level': 'B1',
    });

    expect(user.xpInCurrentLevel, 50);
    expect(UserModel.fromJson(user.toJson()).cefrLevel, 'B1');
    expect(user.copyWith(xp: 300).cefrLevel, 'B1');
  });

  test('WordModel örnek cümle çevirisi ve kaynağını okur', () {
    final word = WordModel.fromJson({
      'id': 1,
      'word': 'apple',
      'translation': 'elma',
      'level': 'A1',
      'meanings': [
        {
          'part_of_speech': 'isim',
          'definition': 'a fruit',
          'example': 'I ate an apple.',
          'example_translation': 'Bir elma yedim.',
          'example_source': 'Tatoeba #1 (kullanıcı)',
        },
      ],
    });

    expect(word.id, 1);
    expect(word.meanings.first.exampleTranslation, 'Bir elma yedim.');
    expect(word.meanings.first.exampleSource, startsWith('Tatoeba'));
  });
}
