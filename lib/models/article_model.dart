class ArticleModel {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final DateTime date;
  final String? thumbnailUrl;
  final List<int> categoryIds;
  final bool isSticky;
  final int authorId;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.date,
    this.thumbnailUrl,
    required this.categoryIds,
    required this.isSticky,
    required this.authorId,
  });

  /// Parse from WordPress REST API JSON
  /// Expects _embed parameter for featured image
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    String? thumbnailUrl;
    
    // Extract featured image from _embedded data
    if (json['_embedded'] != null) {
      final embedded = json['_embedded'] as Map<String, dynamic>;
      if (embedded.containsKey('wp:featuredmedia')) {
        final media = embedded['wp:featuredmedia'] as List;
        if (media.isNotEmpty) {
          final mediaItem = media[0] as Map<String, dynamic>;
          thumbnailUrl = mediaItem['source_url'] as String?;
        }
      }
    }

    // Extract category IDs
    List<int> categoryIds = [];
    if (json['categories'] != null) {
      categoryIds = (json['categories'] as List)
          .map((e) => e as int)
          .toList();
    }

    return ArticleModel(
      id: json['id'] as int,
      title: _stripHtml(json['title']['rendered'] as String? ?? ''),
      content: json['content']['rendered'] as String? ?? '',
      excerpt: _stripHtml(json['excerpt']['rendered'] as String? ?? ''),
      date: DateTime.parse(json['date'] as String),
      thumbnailUrl: thumbnailUrl,
      categoryIds: categoryIds,
      isSticky: json['sticky'] as bool? ?? false,
      authorId: json['author'] as int,
    );
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'date': date.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'categoryIds': categoryIds,
      'isSticky': isSticky,
      'authorId': authorId,
    };
  }

  /// Helper to strip HTML tags from title/excerpt
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8211;', '-')
        .replaceAll('&#8212;', '—')
        .trim();
  }

  /// Get formatted date string (dd/mm format for thumbnails)
  String get formattedDateShort {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  /// Get formatted date string (full format for cards)
  String get formattedDateFull {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Copy with method for immutability
  ArticleModel copyWith({
    int? id,
    String? title,
    String? content,
    String? excerpt,
    DateTime? date,
    String? thumbnailUrl,
    List<int>? categoryIds,
    bool? isSticky,
    int? authorId,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      date: date ?? this.date,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      categoryIds: categoryIds ?? this.categoryIds,
      isSticky: isSticky ?? this.isSticky,
      authorId: authorId ?? this.authorId,
    );
  }

  @override
  String toString() {
    return 'ArticleModel(id: $id, title: $title, date: $formattedDateFull)';
  }
}
