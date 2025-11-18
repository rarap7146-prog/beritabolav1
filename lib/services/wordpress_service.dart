import 'dart:convert';
import 'package:http/http.dart' as http;

class WordPressService {
  // Singleton pattern
  static final WordPressService _instance = WordPressService._internal();
  factory WordPressService() => _instance;
  WordPressService._internal();

  // Base URL from PROJECT_REFERENCE.md
  static const String baseUrl = 'https://beritabola.app/wp-json/wp/v2';

  /// Fetch articles from WordPress REST API
  /// 
  /// Example response JSON:
  /// ```json
  /// [
  ///   {
  ///     "id": 123,
  ///     "title": {"rendered": "Article Title"},
  ///     "content": {"rendered": "<p>Content</p>"},
  ///     "excerpt": {"rendered": "<p>Excerpt</p>"},
  ///     "date": "2025-11-17T10:00:00",
  ///     "author": 1,
  ///     "_embedded": {
  ///       "wp:featuredmedia": [...]
  ///     }
  ///   }
  /// ]
  /// ```
  Future<Map<String, dynamic>> fetchArticles({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?page=$page&per_page=$perPage&_embed'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'page': page,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load articles: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in WordPressService.fetchArticles: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Fetch single article by ID
  Future<Map<String, dynamic>> fetchArticleById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$id?_embed'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load article: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in WordPressService.fetchArticleById: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Fetch comments for a specific post
  Future<Map<String, dynamic>> fetchComments({
    required int postId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments?post=$postId&page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load comments: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in WordPressService.fetchComments: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Post a new comment
  Future<Map<String, dynamic>> postComment({
    required int postId,
    required String content,
    required String authorName,
    required String authorEmail,
    int? parentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'post': postId,
          'content': content,
          'author_name': authorName,
          'author_email': authorEmail,
          if (parentId != null) 'parent': parentId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to post comment: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in WordPressService.postComment: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
