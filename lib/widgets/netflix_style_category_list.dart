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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            categoryName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        
        // Horizontal scrollable list
        SizedBox(
          height: 280, // Vertical thumbnail height
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
      ],
    );
  }

  Widget _buildThumbnailCard(
    BuildContext context,
    ArticleModel article,
    Map<String, int> stats,
  ) {
    return GestureDetector(
      onTap: () => onArticleTap(article),
      child: Container(
        width: 160, // Vertical thumbnail width
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with overlay
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: article.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: article.thumbnailUrl!,
                          width: 160,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 160,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 160,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                        )
                      : Container(
                          width: 160,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        ),
                ),
                
                // Date badge (top right corner with background)
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
                      article.formattedDateShort, // dd/mm format
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Title overlay (bottom with blue gradient background)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
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
            
            const SizedBox(height: 8),
            
            // Stats row (non-interactive)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.visibility_outlined,
                  _formatCount(stats['views'] ?? 0),
                ),
                _buildStatItem(
                  Icons.favorite_outline,
                  _formatCount(stats['likes'] ?? 0),
                ),
                _buildStatItem(
                  Icons.comment_outlined,
                  _formatCount(stats['comments'] ?? 0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
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
