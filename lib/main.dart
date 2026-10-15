import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/env_config.dart';
import 'controllers/sight_controller.dart';
import 'core/constants/app_keys.dart';
import 'core/constants/app_strings.dart';
import 'core/localization/language_manager.dart';
import 'core/theme/accessible_theme.dart';
import 'screens/camera_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/camera_service.dart';
import 'services/currency_service.dart';
import 'services/firebase_service.dart';
import 'services/gemini_service.dart';
import 'services/hazard_service.dart';
import 'services/medicine_service.dart';
import 'services/ocr_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.initialize();

  runApp(const SightAssistApp());
}

class SightAssistApp extends StatelessWidget {
  const SightAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageManager()),
        ChangeNotifierProvider(create: (_) => TtsService()),
        ChangeNotifierProvider(create: (_) => SpeechService()),
        ChangeNotifierProvider(create: (_) => CameraService()),
        ChangeNotifierProvider(create: (_) => GeminiService()),
        ChangeNotifierProvider(create: (_) => OcrService()),
        ChangeNotifierProvider(create: (_) => FirebaseService()),
        ChangeNotifierProxyProvider<GeminiService, CurrencyService>(
          create: (ctx) => CurrencyService(
            geminiService: ctx.read<GeminiService>(),
          ),
          update: (ctx, gemini, prev) => prev ?? CurrencyService(geminiService: gemini),
        ),
        ChangeNotifierProxyProvider<GeminiService, MedicineService>(
          create: (ctx) => MedicineService(
            geminiService: ctx.read<GeminiService>(),
          ),
          update: (ctx, gemini, prev) => prev ?? MedicineService(geminiService: gemini),
        ),
        ChangeNotifierProxyProvider<GeminiService, HazardService>(
          create: (ctx) => HazardService(
            geminiService: ctx.read<GeminiService>(),
          ),
          update: (ctx, gemini, prev) => prev ?? HazardService(geminiService: gemini),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SightController(
            cameraService: ctx.read<CameraService>(),
            speechService: ctx.read<SpeechService>(),
            ttsService: ctx.read<TtsService>(),
            geminiService: ctx.read<GeminiService>(),
            ocrService: ctx.read<OcrService>(),
            currencyService: ctx.read<CurrencyService>(),
            medicineService: ctx.read<MedicineService>(),
            hazardService: ctx.read<HazardService>(),
            firebaseService: ctx.read<FirebaseService>(),
            languageManager: ctx.read<LanguageManager>(),
          ),
        ),
      ],
      child: Consumer<LanguageManager>(
        builder: (context, langManager, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AccessibleTheme.highContrastDarkTheme,
            locale: Locale(langManager.currentLanguage.code),
            supportedLocales: const [
              Locale('en', 'IN'),
              Locale('hi', 'IN'),
              Locale('kn', 'IN'),
              Locale('te', 'IN'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppKeys.routeSplash,
            routes: {
              AppKeys.routeSplash: (context) => const SplashScreen(),
              AppKeys.routeOnboarding: (context) => const OnboardingScreen(),
              AppKeys.routeHome: (context) => const HomeScreen(),
              AppKeys.routeResult: (context) => const ResultScreen(),
              AppKeys.routeSettings: (context) => const SettingsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppKeys.routeCamera) {
                final mode = settings.arguments as VisionMode? ?? VisionMode.sceneUnderstanding;
                return MaterialPageRoute(
                  builder: (context) => CameraScreen(mode: mode),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
