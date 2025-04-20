import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'controllers/auth_controller.dart';
import 'controllers/quote_controller.dart';
import 'services/openai_service.dart';
import 'services/quote_service.dart';
import 'views/screens/auth/login_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/saved_quotes_screen.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'services/logging_service.dart';
import 'services/performance_monitoring_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env file loaded successfully");
  } catch (e) {
    print("❌ Failed to load .env file: $e");
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Pass OpenAIService instance with API key
  final openAiService = OpenAIService(dotenv.env['OPENAI_API_KEY'] ?? '');

  runApp(
    MultiProvider(
      providers: [
        Provider<LoggingService>(create: (_) => LoggingService()),
        Provider<PerformanceMonitoringService>(
          create: (_) => PerformanceMonitoringService(),
        ),
        Provider<OpenAIService>(create: (_) => openAiService),
      ],
      child: MyApp(openAiService: openAiService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final OpenAIService openAiService;

  const MyApp({super.key, required this.openAiService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth controller
        ChangeNotifierProvider(create: (_) => AuthController()),

        // Services (pass openAiService correctly)
        Provider<OpenAIService>.value(value: openAiService),
        Provider(create: (_) => QuoteService()),

        // Quote controller (depends on services)
        ChangeNotifierProxyProvider2<
          OpenAIService,
          QuoteService,
          QuoteController
        >(
          create:
              (context) => QuoteController(
                openAIService: context.read<OpenAIService>(),
                quoteService: context.read<QuoteService>(),
              ),
          update:
              (context, openAIService, quoteService, previous) =>
                  QuoteController(
                    openAIService: openAIService,
                    quoteService: quoteService,
                  ),
        ),
      ],
      child: MaterialApp(
        title: 'InspireCloud',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        home: const LoginScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/saved_quotes': (context) => const SavedQuotesScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
