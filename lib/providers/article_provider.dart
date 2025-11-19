import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/wordpress_service.dart';
import '../services/firestore_service.dart';

class ArticleProvider with ChangeNotifier {
  final WordPressService _wordpressService = WordPressService();
  final FirestoreService _firestoreService = FirestoreService();

  // Category IDs from requirements: 31, 30, 24, 26, 23
  static const List<int> categoryIds = [31, 30, 24, 26, 23];

  // Featured articles (sticky posts for carousel)
  List<ArticleModel> _featuredArticles = [];
  bool _featuredLoading = false;
  String? _featuredError;

  // Category-based articles (Netflix-style lists)
  Map<int, List<ArticleModel>> _categoryArticles = {};
  Map<int, bool> _categoryLoading = {};
  Map<int, String?> _categoryErrors = {};

  // Latest articles for "View More" page
  List<ArticleModel> _latestArticles = [];
  bool _latestLoading = false;
  String? _latestError;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Article stats cache (views, likes, comments)
  Map<int, Map<String, int>> _articleStats = {};

  // Category names cache
  Map<int, String> _categoryNames = {};

  // Getters
  List<ArticleModel> get featuredArticles => _featuredArticles;
  bool get featuredLoading => _featuredLoading;
  String? get featuredError => _featuredError;

  Map<int, List<ArticleModel>> get categoryArticles => _categoryArticles;
  bool categoryLoading(int categoryId) => _categoryLoading[categoryId] ?? false;
  String? categoryError(int categoryId) => _categoryErrors[categoryId];

  List<ArticleModel> get latestArticles => _latestArticles;
  bool get latestLoading => _latestLoading;
  String? get latestError => _latestError;
  bool get hasMorePages => _hasMorePages;

  Map<int, Map<String, int>> get articleStats => _articleStats;
  Map<int, String> get categoryNames => _categoryNames;

  // ==================== FEATURED ARTICLES ====================

  /// Load featured/sticky articles for carousel
  Future<void> loadFeaturedArticles() async {
    _featuredLoading = true;
    _featuredError = null;
    notifyListeners();

    try {
      _featuredArticles = await _wordpressService.fetchFeaturedArticles();
      
      // Load stats for featured articles
      await _loadStatsForArticles(_featuredArticles);
      
      _featuredError = null;
    } catch (e) {      _featuredError = 'Gagal memuat artikel unggulan';
    } finally {
      _featuredLoading = false;
      notifyListeners();
    }
  }

  // ==================== CATEGORY ARTICLES ====================

  /// Load articles for a specific category (Netflix-style)
  Future<void> loadCategoryArticles(int categoryId) async {
    _categoryLoading[categoryId] = true;
    _categoryErrors[categoryId] = null;
    notifyListeners();

    try {
      final articles = await _wordpressService.fetchArticlesByCategory(
        categoryId,
        perPage: 5,
      );
      
      _categoryArticles[categoryId] = articles;
      
      // Load stats for category articles
      await _loadStatsForArticles(articles);
      
      _categoryErrors[categoryId] = null;
    } catch (e) {      _categoryErrors[categoryId] = 'Gagal memuat artikel';
    } finally {
      _categoryLoading[categoryId] = false;
      notifyListeners();
    }
  }

  /// Load all category articles at once
  Future<void> loadAllCategories() async {
    await Future.wait(
      categoryIds.map((id) => loadCategoryArticles(id)),
    );
  }

  // ==================== LATEST ARTICLES (VIEW MORE) ====================

  /// Load latest articles with pagination
  /// Set refresh=true to reset pagination
  Future<void> loadLatestArticles({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _latestArticles = [];
    }

    if (_latestLoading || !_hasMorePages) return;

    _latestLoading = true;
    _latestError = null;
    notifyListeners();

    try {
      final articles = await _wordpressService.fetchLatestArticles(
        page: _currentPage,
        perPage: 10,
      );

      if (articles.isEmpty) {
        _hasMorePages = false;
      } else {
        _latestArticles.addAll(articles);
        _currentPage++;
        
        // Load stats for new articles
        await _loadStatsForArticles(articles);
      }

      _latestError = null;
    } catch (e) {      _latestError = 'Gagal memuat artikel';
    } finally {
      _latestLoading = false;
      notifyListeners();
    }
  }

  // ==================== STATS MANAGEMENT ====================

  /// Load stats for a list of articles
  Future<void> _loadStatsForArticles(List<ArticleModel> articles) async {
    for (var article in articles) {
      try {
        final stats = await _firestoreService.getArticleStats(article.id);
        _articleStats[article.id] = stats;
      } catch (e) {        _articleStats[article.id] = {'views': 0, 'likes': 0, 'comments': 0};
      }
    }
  }

  /// Get stats for a specific article
  Map<String, int> getArticleStats(int articleId) {
    return _articleStats[articleId] ?? {'views': 0, 'likes': 0, 'comments': 0};
  }

  /// Refresh stats for an article (after like/comment)
  Future<void> refreshArticleStats(dynamic articleId) async {
    try {
      final id = articleId is String ? int.parse(articleId) : articleId as int;
      final stats = await _firestoreService.getArticleStats(id);
      _articleStats[id] = stats;
      notifyListeners();
    } catch (e) {    }
  }

  // ==================== CATEGORY NAMES ====================

  /// Load category names for chips
  Future<void> loadCategoryNames() async {
    try {
      _categoryNames = await _wordpressService.fetchCategoryNames(categoryIds);
      notifyListeners();
    } catch (e) {    }
  }

  /// Get category name by ID (fetches from API if not cached)
  Future<String> getCategoryName(int categoryId) async {
    // Return from cache if available
    if (_categoryNames.containsKey(categoryId)) {
      return _categoryNames[categoryId]!;
    }
    
    // Fetch from API if not in cache
    try {
      final name = await _wordpressService.getCategoryName(categoryId);
      _categoryNames[categoryId] = name;
      return name;
    } catch (e) {      return 'Kategori $categoryId';
    }
  }

  // ==================== INITIALIZATION ====================

  /// Initialize all data (call on app start)
  Future<void> initialize() async {
    await Future.wait([
      loadFeaturedArticles(),
      loadAllCategories(),
      loadCategoryNames(),
    ]);
  }

  /// Refresh all data (pull-to-refresh)
  Future<void> refreshAll() async {
    await Future.wait([
      loadFeaturedArticles(),
      loadAllCategories(),
      loadLatestArticles(refresh: true),
    ]);
  }

  // ==================== UTILITY ====================

  /// Clear all data
  void clear() {
    _featuredArticles = [];
    _categoryArticles = {};
    _latestArticles = [];
    _articleStats = {};
    _categoryNames = {};
    _currentPage = 1;
    _hasMorePages = true;
    notifyListeners();
  }
}
