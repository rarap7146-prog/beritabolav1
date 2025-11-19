import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/article_model.dart';

class ArticleCardListItem extends StatelessWidget {
  final ArticleModel article;
  final Map<String, int> stats;
  final VoidCallback onTap;
  final String? categoryName;
  final String? authorName;

  const ArticleCardListItem({
    Key? key,
    required this.article,
    required this.stats,
    required this.onTap,
    this.categoryName,
    this.authorName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag
            if (categoryName != null && categoryName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  categoryName!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            
            // Thumbnail (full width)
            if (article.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: double.infinity,
                    height: 200,
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: 200,
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: isDark ? Colors.grey[700] : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Title
            Text(
              article.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 10),
            
            // Meta row (author, date, stats)
            Row(
              children: [
                // Author and date
                Expanded(
                  child: Row(
                    children: [
                      if (authorName != null && authorName!.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            authorName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                      Text(
                        article.formattedDateShort,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Stats
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatIcon(
                      context,
                      Icons.visibility_outlined,
                      _formatCount(stats['views'] ?? 0),
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildStatIcon(
                      context,
                      Icons.favorite_outline,
                      _formatCount(stats['likes'] ?? 0),
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildStatIcon(
                      context,
                      Icons.chat_bubble_outline,
                      _formatCount(stats['comments'] ?? 0),
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(BuildContext context, IconData icon, String count, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[600] : Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
