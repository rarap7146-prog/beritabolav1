import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class WordPressService {
  // Singleton pattern
  static final WordPressService _instance = WordPressService._internal();
  factory WordPressService() => _instance;
  WordPressService._internal();

  static const String baseUrl = 'https://beritabola.app/wp-json/wp/v2';

  /// Fetch sticky/featured articles for carousel (1.91:1 aspect ratio)
  /// Returns list of sticky posts for homepage carousel
  Future<List<ArticleModel>> fetchFeaturedArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?sticky=true&per_page=5&_embed'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ArticleModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load featured articles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching featured articles: $e');
      rethrow;
    }
  }

  /// Fetch articles by category for Netflix-style lists
  /// Categories: 31, 30, 24, 26, 23
  /// [categoryId] - WordPress category ID
  /// [perPage] - Number of articles (default: 5 for homepage)
  Future<List<ArticleModel>> fetchArticlesByCategory(
    int categoryId, {
    int perPage = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?categories=$categoryId&per_page=$perPage&_embed'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ArticleModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load articles for category $categoryId: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching articles for category $categoryId: $e');
      rethrow;
    }
  }

  /// Fetch latest articles with pagination for "View More" card list
  /// [page] - Page number (starts at 1)
  /// [perPage] - Articles per page (default: 10)
  Future<List<ArticleModel>> fetchLatestArticles({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?page=$page&per_page=$perPage&orderby=date&order=desc&_embed'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ArticleModel.fromJson(json)).toList();
      } else if (response.statusCode == 400) {
        // No more pages available
        return [];
      } else {
        throw Exception('Failed to load latest articles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching latest articles: $e');
      rethrow;
    }
  }

  /// Fetch single article by ID for detail page
  /// [articleId] - WordPress post ID
  Future<ArticleModel> fetchArticleById(int articleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$articleId?_embed'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ArticleModel.fromJson(data);
      } else {
        throw Exception('Failed to load article: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching article $articleId: $e');
      rethrow;
    }
  }

  /// Get category name by ID for displaying category chips
  /// Returns category name or fallback
  Future<String> getCategoryName(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['name'] ?? 'Unknown';
      } else {
        return 'Category $categoryId';
      }
    } catch (e) {
      print('Error fetching category name: $e');
      return 'Category $categoryId';
    }
  }

  /// Fetch multiple category names at once for efficiency
  /// Returns map of categoryId -> categoryName
  Future<Map<int, String>> fetchCategoryNames(List<int> categoryIds) async {
    final Map<int, String> categoryMap = {};
    
    try {
      final ids = categoryIds.join(',');
      final response = await http.get(
        Uri.parse('$baseUrl/categories?include=$ids'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var category in data) {
          categoryMap[category['id']] = category['name'];
        }
      }
    } catch (e) {
      print('Error fetching category names: $e');
    }

    // Fill missing with fallback
    for (int id in categoryIds) {
      categoryMap.putIfAbsent(id, () => 'Category $id');
    }

    return categoryMap;
  }

  // NOTE: Comments are NOT fetched from WordPress API
  // All comments are managed via Firestore to avoid spam
  // See FirestoreService for comment operations
}
