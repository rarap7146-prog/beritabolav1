import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/main_page.dart';
import 'providers/theme_provider.dart';
import 'providers/article_provider.dart';
import 'providers/football_provider.dart';
import 'services/deep_link_service.dart';
import 'services/onesignal_service.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Analytics (Firebase Analytics, Facebook App Events, TikTok)
  await AnalyticsService().initialize();
  
  // Initialize OneSignal (after Firebase)
  await OneSignalService().initialize();
  
  // Initialize Deep Link Service
  DeepLinkService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
        ChangeNotifierProvider(create: (_) => FootballProvider()),
      ],
      child: const BeritaBolaApp(),
    ),
  );
}

class BeritaBolaApp extends StatelessWidget {
  const BeritaBolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Berita Bola',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // For deep link navigation
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Blue
          secondary: const Color(0xFFFF9800), // Orange
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF42A5F5), // Light Blue
          secondary: const Color(0xFFFFB74D), // Light Orange
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainPage(),
      },
    );
  }
}
