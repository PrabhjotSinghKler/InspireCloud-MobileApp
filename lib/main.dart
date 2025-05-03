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
import 'navigation_service.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  runApp(
    MultiProvider(
      providers: [
        Provider<LoggingService>(create: (_) => LoggingService()),
        Provider<PerformanceMonitoringService>(
          create: (_) => PerformanceMonitoringService(),
        ),
        Provider<OpenAIService>(
          create:
              (context) => OpenAIService(
                dotenv.env['OPENAI_API_KEY'] ?? '',
                context.read<LoggingService>(),
              ),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),
        Provider(create: (_) => QuoteService()),
        ChangeNotifierProxyProvider3<
          OpenAIService,
          QuoteService,
          LoggingService,
          QuoteController
        >(
          create:
              (context) => QuoteController(
                openAIService: context.read<OpenAIService>(),
                quoteService: context.read<QuoteService>(),
                loggingService: context.read<LoggingService>(),
              ),
          update:
              (
                context,
                openAIService,
                quoteService,
                loggingService,
                previous,
              ) => QuoteController(
                openAIService: openAIService,
                quoteService: quoteService,
                loggingService: loggingService,
              ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProxyProvider3<
          OpenAIService,
          QuoteService,
          LoggingService,
          QuoteController
        >(
          create:
              (context) => QuoteController(
                openAIService: context.read<OpenAIService>(),
                quoteService: context.read<QuoteService>(),
                loggingService: context.read<LoggingService>(),
              ),
          update:
              (
                context,
                openAIService,
                quoteService,
                loggingService,
                previous,
              ) => QuoteController(
                openAIService: openAIService,
                quoteService: quoteService,
                loggingService: loggingService,
              ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'InspireCloud',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
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
          '/login': (context) => const LoginScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
