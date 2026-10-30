import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/leaderboard_service.dart';
import 'services/question_repository.dart';
import 'services/stats_service.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Future.wait([
    QuestionRepository.instance.load(),
    StatsService.instance.load(),
  ]);
  runApp(const ChopChopApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService.instance.init();
    LeaderboardService.signIn();
    AudioService.instance.init().then((_) {
      AudioService.instance.playMusic(MusicTrack.menu);
    });
  });
}

class ChopChopApp extends StatelessWidget {
  const ChopChopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chớp Chớp Quiz',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: C.pink),
        textTheme: GoogleFonts.baloo2TextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}
