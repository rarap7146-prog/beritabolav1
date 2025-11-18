import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../home/main_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup rotation animation for the ball
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Infinite rotation

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159, // Full rotation (2π)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    // Initialize app and navigate
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait minimum 3 seconds for splash display
      await Future.wait([
        Future.delayed(const Duration(seconds: 3)),
        _performInitialization(),
      ]);

      if (!mounted) return;

      // Check authentication state
      final User? user = FirebaseAuth.instance.currentUser;
      
      // Navigate based on auth state
      if (user != null) {
        // User is logged in, go to main page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      } else {
        // No user, go to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error during splash initialization: $e');
      // On error, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _performInitialization() async {
    // TODO: Add initialization tasks here:
    // - Initialize OneSignal
    // - Check for deep links
    // - Load initial data/cache
    // - Initialize analytics SDKs
    
    // Placeholder for now
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Logo
              Image.asset(
                'assets/images/LOGOKT.png',
                width: MediaQuery.of(context).size.width * 0.6,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sports_soccer,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
              
              const SizedBox(height: 60),
              
              // Rotating soccer ball emoji
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: child,
                  );
                },
                child: const Text(
                  '⚽',
                  style: TextStyle(fontSize: 48),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Loading text
              Text(
                'Memuat...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              
              const Spacer(flex: 3),
              
              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  'Berita Bola v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
