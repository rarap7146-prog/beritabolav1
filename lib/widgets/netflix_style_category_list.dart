import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/article_model.dart';

class NetflixStyleCategoryList extends StatelessWidget {
  final String categoryName;
  final List<ArticleModel> articles;
  final Map<int, Map<String, int>> articleStats;
  final Function(ArticleModel) onArticleTap;

  const NetflixStyleCategoryList({
    Key? key,
    required this.categoryName,
    required this.articles,
    required this.articleStats,
    required this.onArticleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                categoryName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Horizontal scrollable list with floating arrow
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      final stats = articleStats[article.id] ?? {'views': 0, 'likes': 0, 'comments': 0};
                      
                      return _buildThumbnailCard(context, article, stats);
                    },
                  ),
                ),
                
                // Floating arrow indicator (right side, middle position)
                Positioned(
                  right: 20,
                  top: 85, // Middle of thumbnail (200px) + stats (50px) = 125px total center
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailCard(
    BuildContext context,
    ArticleModel article,
    Map<String, int> stats,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => onArticleTap(article),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Stack(
                children: [
                  // Image
                  article.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: article.thumbnailUrl!,
                          width: 160,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 160,
                            height: 200,
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 160,
                            height: 200,
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                        )
                      : Container(
                          width: 160,
                          height: 200,
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        ),
                  
                  // Date badge (top right corner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.formattedDateShort,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Title overlay (bottom with gradient)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).colorScheme.primary.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Stats row with rounded bottom corners
              Container(
                width: 160,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    left: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    right: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    bottom: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      Icons.visibility_outlined,
                      _formatCount(stats['views'] ?? 0),
                      isDark,
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                    ),
                    _buildStatItem(
                      context,
                      Icons.favorite_outline,
                      _formatCount(stats['likes'] ?? 0),
                      isDark,
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                    ),
                    _buildStatItem(
                      context,
                      Icons.comment_outlined,
                      _formatCount(stats['comments'] ?? 0),
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String count, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Format large numbers (e.g., 1000 -> 1K)
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
