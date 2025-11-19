/// Deep Link Configuration
/// Defines URL patterns and constants for deep linking
class DeepLinkConfig {
  // Domain for App Links
  static const String domain = 'beritabola.app';
  static const String scheme = 'https';
  
  // Custom Scheme
  static const String customScheme = 'beritabola';
  
  // URL Patterns
  static const String articlePattern = '/article/';
  static const String postPattern = '/post/';
  static const String categoryPattern = '/category/';
  
  // Match patterns for sports content (future use)
  static const String matchPattern = '/match/';
  static const String leaguePattern = '/league/';
  static const String playerPattern = '/player/';
  static const String teamPattern = '/team/';
  
  /// Check if URL is from our domain
  static bool isBeritaBolaLink(Uri uri) {
    return uri.host.endsWith(domain) || uri.scheme == customScheme;
  }
  
  /// Extract article ID from URL
  /// Supports: /article/123, /post/123, /123, /article-slug-123
  static String? extractArticleId(String path) {
    // Remove trailing slash
    path = path.replaceAll(RegExp(r'/$'), '');
    
    // Try to extract ID from various patterns
    final patterns = [
      RegExp(r'/article/(\d+)'),
      RegExp(r'/post/(\d+)'),
      RegExp(r'/(\d+)$'),
      RegExp(r'-(\d+)$'), // For slugs ending with ID
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(path);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    
    return null;
  }
  
  /// Extract category slug from URL
  static String? extractCategorySlug(String path) {
    final match = RegExp(r'/category/([^/]+)').firstMatch(path);
    return match?.group(1);
  }
  
  /// Check if deep link requires authentication
  static bool requiresAuth(Uri uri) {
    // Most content is public, only specific paths require auth
    // For now, all content is public
    return false;
  }
}

/// Deep Link Type enum
enum DeepLinkType {
  article,
  category,
  match,
  league,
  player,
  team,
  unknown,
  externalBrowser, // For ads and external links
}

/// Deep Link Data model
class DeepLinkData {
  final DeepLinkType type;
  final String? id;
  final String? slug;
  final Uri originalUri;
  final bool requiresAuth;
  final bool openInBrowser;
  
  DeepLinkData({
    required this.type,
    this.id,
    this.slug,
    required this.originalUri,
    this.requiresAuth = false,
    this.openInBrowser = false,
  });
  
  @override
  String toString() {
    return 'DeepLinkData(type: $type, id: $id, slug: $slug, requiresAuth: $requiresAuth, openInBrowser: $openInBrowser)';
  }
}
