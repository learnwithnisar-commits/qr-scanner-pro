import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/ad_service.dart';
import 'services/history_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  final settings = SettingsService();
  final history = HistoryService();
  final ads = AdService();
  await settings.load();
  await history.load();
  ads.loadInterstitial(); // preload (never shown on launch)

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider.value(value: ads),
      ],
      child: const QrScannerApp(),
    ),
  );
}

class QrScannerApp extends StatelessWidget {
  const QrScannerApp({super.key});

  ThemeMode _mode(String v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return MaterialApp(
      title: 'QR Scanner Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode(settings.themeMode),
      home: settings.onboarded
          ? const HomeScreen()
          : OnboardingScreen(
              onDone: () => settings.setOnboarded(),
            ),
    );
  }
}
