import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import '../config/deep_link_config.dart';
import '../models/article_model.dart';
import '../screens/articles/article_detail_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/main_page.dart';
import '../services/wordpress_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Deep Link Service
/// Handles parsing and routing of deep links
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  StreamSubscription? _sub;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppLinks _appLinks = AppLinks();
  final WordPressService _wordPressService = WordPressService();

  /// Initialize deep link listeners
  Future<void> initialize() async {
    try {
      // Handle initial link when app is opened from terminated state
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('📎 Initial deep link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('❌ Error getting initial URI: $e');
    }

    // Listen for deep links when app is in background/foreground
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      print('📎 Deep link received: $uri');
      _handleDeepLink(uri);
    }, onError: (err) {
      print('❌ Deep link stream error: $err');
    });
  }

  /// Dispose listeners
  void dispose() {
    _sub?.cancel();
  }

  /// Parse deep link URI and extract data
  DeepLinkData? parseDeepLink(Uri uri) {
    print('🔍 Parsing deep link: $uri');

    // Check if it's our link
    if (!DeepLinkConfig.isBeritaBolaLink(uri)) {
      print('⚠️ Not a Berita Bola link');
      return null;
    }

    final path = uri.path;
    print('📍 Path: $path');

    // Check for article
    if (path.contains(DeepLinkConfig.articlePattern) ||
        path.contains(DeepLinkConfig.postPattern) ||
        RegExp(r'/\d+').hasMatch(path)) {
      final articleId = DeepLinkConfig.extractArticleId(path);
      if (articleId != null) {
        print('📰 Article deep link detected: ID=$articleId');
        return DeepLinkData(
          type: DeepLinkType.article,
          id: articleId,
          originalUri: uri,
          requiresAuth: false,
        );
      }
    }

    // Check for category
    if (path.contains(DeepLinkConfig.categoryPattern)) {
      final categorySlug = DeepLinkConfig.extractCategorySlug(path);
      if (categorySlug != null) {
        print('📂 Category deep link detected: slug=$categorySlug');
        return DeepLinkData(
          type: DeepLinkType.category,
          slug: categorySlug,
          originalUri: uri,
          requiresAuth: false,
        );
      }
    }

    // Check for sports content (future use)
    if (path.contains(DeepLinkConfig.matchPattern)) {
      print('⚽ Match deep link (not implemented yet)');
      return DeepLinkData(
        type: DeepLinkType.match,
        originalUri: uri,
        requiresAuth: false,
      );
    }

    // Unknown type - open in browser if it's beritabola.app
    if (uri.host.endsWith(DeepLinkConfig.domain)) {
      print('🌐 Unknown path, will open in browser');
      return DeepLinkData(
        type: DeepLinkType.externalBrowser,
        originalUri: uri,
        openInBrowser: true,
      );
    }

    print('❓ Unknown deep link type');
    return DeepLinkData(
      type: DeepLinkType.unknown,
      originalUri: uri,
    );
  }

  /// Handle deep link and navigate
  Future<void> _handleDeepLink(Uri uri) async {
    final deepLinkData = parseDeepLink(uri);
    if (deepLinkData == null) {
      print('⚠️ Could not parse deep link');
      return;
    }

    print('✅ Parsed deep link: $deepLinkData');

    // Wait a bit for Flutter to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user is authenticated (not anonymous)
    final user = _auth.currentUser;
    final isLoggedIn = user != null && !user.isAnonymous;

    // CRITICAL: If user is not logged in or is anonymous, redirect to login
    // This prevents anonymous users who logged out from accessing content via deep links
    if (!isLoggedIn) {
      print('🔒 User not authenticated (anonymous or null), redirecting to login');
      navigateToLogin(deepLinkData);
      return;
    }

    // Route based on deep link type
    _routeDeepLink(deepLinkData);
  }

  /// Route deep link to appropriate screen
  void _routeDeepLink(DeepLinkData deepLinkData) {
    final context = _getNavigatorContext();
    if (context == null) {
      print('⚠️ Navigator context not available');
      return;
    }

    switch (deepLinkData.type) {
      case DeepLinkType.article:
        if (deepLinkData.id != null) {
          _navigateToArticle(context, deepLinkData.id!);
        } else {
          _showErrorAndGoHome(context, 'Article not found');
        }
        break;

      case DeepLinkType.category:
        // For now, go to home (category view not implemented)
        _navigateToHome(context);
        break;

      case DeepLinkType.externalBrowser:
        _openInBrowser(deepLinkData.originalUri);
        break;

      case DeepLinkType.unknown:
        _showErrorAndGoHome(context, 'Content not found');
        break;

      default:
        // Future sports content
        _showErrorAndGoHome(context, 'Feature coming soon');
        break;
    }
  }

  /// Navigate to article detail screen
  Future<void> _navigateToArticle(BuildContext context, String articleId) async {
    print('📰 Navigating to article: $articleId');
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Fetch article from WordPress
      final article = await _wordPressService.fetchArticleById(int.parse(articleId));
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Navigate to home first, then to article
      // This ensures back button always goes to home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false, // Clear all previous routes
      );
      
      // Then navigate to article detail
      // Now back button will return to home
      await Future.delayed(const Duration(milliseconds: 100));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleDetailScreen(article: article),
        ),
      );
    } catch (e) {
      print('❌ Error loading article: $e');
      // Close loading dialog
      Navigator.pop(context);
      _showErrorAndGoHome(context, 'Failed to load article');
    }
  }

  /// Navigate to home screen
  void _navigateToHome(BuildContext context) {
    print('🏠 Navigating to home');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
      (route) => false,
    );
  }

  /// Navigate to login screen
  void navigateToLogin(DeepLinkData? deepLinkData) {
    final context = _getNavigatorContext();
    if (context == null) return;

    print('🔑 Navigating to login');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  /// Show error chip and navigate to home
  void _showErrorAndGoHome(BuildContext context, String message) {
    print('❌ Error: $message');
    
    // Navigate to home first
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
      (route) => false,
    );

    // Show error chip
    Future.delayed(const Duration(milliseconds: 500), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  /// Open URL in external browser
  Future<void> _openInBrowser(Uri uri) async {
    print('🌐 Opening in browser: $uri');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('❌ Cannot launch URL');
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
    }
  }

  /// Get navigator context from global key
  BuildContext? _getNavigatorContext() {
    return navigatorKey.currentContext;
  }

  /// Handle deep link manually (for testing or OneSignal notifications)
  Future<void> handleDeepLinkManually(String url) async {
    try {
      final uri = Uri.parse(url);
      await _handleDeepLink(uri);
    } catch (e) {
      print('❌ Error handling manual deep link: $e');
    }
  }
}

/// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
