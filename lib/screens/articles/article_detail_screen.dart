import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/article_model.dart';
import '../../providers/article_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/comment_section.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLiked = false;
  bool _isLoadingLike = false;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _initializeArticle();
  }

  Future<void> _initializeArticle() async {
    // Increment view count
    await _firestoreService.incrementArticleViews(widget.article.id.toString());

    // Refresh stats to show updated view count
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    await provider.refreshArticleStats(widget.article.id);

    // Check if user has liked this article
    final user = _authService.currentUser;
    if (user != null) {
      final hasLiked = await _firestoreService.hasUserLikedArticle(
        widget.article.id.toString(),
        user.uid,
      );
      if (mounted) {
        setState(() => _isLiked = hasLiked);
      }
    }

    // Get category name
    if (widget.article.categoryIds.isNotEmpty) {
      final name = await provider.getCategoryName(widget.article.categoryIds.first);
      if (mounted) {
        setState(() => _categoryName = name);
      }
    }
  }

  Future<void> _toggleLike() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Silakan login untuk menyukai artikel'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Optimistic update
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _isLoadingLike = true;
    });

    try {
      if (wasLiked) {
        await _firestoreService.unlikeArticle(widget.article.id.toString(), user.uid);
      } else {
        await _firestoreService.likeArticle(widget.article.id.toString(), user.uid);
      }

      if (mounted) {
        setState(() => _isLoadingLike = false);

        // Refresh article stats in provider
        final provider = Provider.of<ArticleProvider>(context, listen: false);
        await provider.refreshArticleStats(widget.article.id);

        // Success feedback
        if (!wasLiked) {
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _isLoadingLike = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Gagal ${wasLiked ? "membatalkan suka" : "menyukai"} artikel'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _toggleLike,
            ),
          ),
        );
      }
    }
  }

  void _shareArticle() {
    final url = 'https://beritabola.app/?p=${widget.article.id}';
    Share.share(
      '${widget.article.title}\n\n$url',
      subject: widget.article.title,
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

  // YouTube Player Widget
  Widget _buildYouTubePlayer(String videoId, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: true,
            ),
          ),
          showVideoProgressIndicator: true,
          progressIndicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // Gallery Carousel Widget
  Widget _buildGalleryCarousel(List<String> imageUrls, bool isDark) {
    int _currentIndex = 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 250,
                  viewportFraction: 0.9,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: imageUrls.length > 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                items: imageUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              if (imageUrls.length > 1)
                const SizedBox(height: 12),
              if (imageUrls.length > 1)
                // Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: _currentIndex == entry.key ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentIndex == entry.key
                            ? Theme.of(context).colorScheme.primary
                            : (isDark ? Colors.grey[700] : Colors.grey[300]),
                      ),
                    );
                  }).toList(),
                ),
              if (imageUrls.length > 1)
                const SizedBox(height: 8),
              if (imageUrls.length > 1)
                // Counter and swipe hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe,
                      size: 14,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentIndex + 1} / ${imageUrls.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  // Pull Quote Widget
  Widget _buildPullQuote(String text, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            size: 32,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            text.trim(),
            style: TextStyle(
              fontSize: 20,
              height: 1.6,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[200] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with back button
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.article.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.article.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        child: Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                        ),
                      ),
                    )
                  : Container(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Date
                  Row(
                    children: [
                      if (_categoryName != null)
                        Text(
                          _categoryName!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      if (_categoryName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ),
                      Text(
                        widget.article.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Author and Publisher
                  Row(
                    children: [
                      if (widget.article.authorName != null) ...[
                        Text(
                          widget.article.authorName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                      Text(
                        'beritabola.app',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.article.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tags (if any)
                  // TODO: Add tags support when available in API

                  // Stats and Share Button
                  Consumer<ArticleProvider>(
                    builder: (context, provider, child) {
                      final stats = provider.getArticleStats(widget.article.id);
                      
                      return Row(
                        children: [
                          // Stats on left
                          Expanded(
                            child: Row(
                              children: [
                                // Views
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatCount(stats['views'] ?? 0),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Likes (tappable with animation)
                                InkWell(
                                  onTap: _isLoadingLike ? null : _toggleLike,
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isLiked 
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isLoadingLike)
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(
                                                Colors.red,
                                              ),
                                            ),
                                          )
                                        else
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 1.0, end: _isLiked ? 1.2 : 1.0),
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeOutBack,
                                            builder: (context, scale, child) {
                                              return Transform.scale(
                                                scale: scale,
                                                child: Icon(
                                                  _isLiked
                                                      ? Icons.favorite
                                                      : Icons.favorite_outline,
                                                  size: 18,
                                                  color: _isLiked
                                                      ? Colors.red
                                                      : (isDark ? Colors.grey[500] : Colors.grey[600]),
                                                ),
                                              );
                                            },
                                          ),
                                        const SizedBox(width: 4),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 200),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _isLiked
                                                ? Colors.red
                                                : (isDark ? Colors.grey[500] : Colors.grey[600]),
                                            fontWeight: _isLiked ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          child: Text(_formatCount(stats['likes'] ?? 0)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Comments
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 18,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatCount(stats['comments'] ?? 0),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Share button on right
                          IconButton(
                            onPressed: _shareArticle,
                            icon: Icon(
                              Icons.share_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: 'Bagikan',
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Article Content
                  HtmlWidget(
                    widget.article.content,
                    customStylesBuilder: (element) {
                      // Make images full width
                      if (element.localName == 'img') {
                        return {
                          'width': '100%',
                          'height': 'auto',
                          'border-radius': '8px',
                          'margin': '16px 0',
                        };
                      }
                      if (element.localName == 'figure' && !element.classes.contains('wp-block-gallery')) {
                        return {
                          'width': '100%',
                          'margin': '16px 0',
                        };
                      }
                      return {
                        'font-size': '17px',
                        'line-height': '1.7',
                        'color': isDark ? '#e0e0e0' : '#212121',
                      };
                    },
                    customWidgetBuilder: (element) {
                      // YouTube Embed
                      if (element.localName == 'figure' && 
                          element.classes.contains('wp-block-embed-youtube')) {
                        final iframe = element.querySelector('iframe');
                        if (iframe != null) {
                          final src = iframe.attributes['src'] ?? '';
                          final videoId = YoutubePlayer.convertUrlToId(src);
                          if (videoId != null) {
                            return _buildYouTubePlayer(videoId, isDark);
                          }
                        }
                      }
                      
                      // Gallery with Carousel
                      if (element.localName == 'figure' && 
                          element.classes.contains('wp-block-gallery')) {
                        final images = element.querySelectorAll('img');
                        if (images.isNotEmpty) {
                          final imageUrls = images
                              .map((img) => img.attributes['src'] ?? '')
                              .where((url) => url.isNotEmpty)
                              .toList();
                          return _buildGalleryCarousel(imageUrls, isDark);
                        }
                      }
                      
                      // Pull Quote
                      if (element.localName == 'figure' && 
                          element.classes.contains('wp-block-pullquote')) {
                        final quote = element.querySelector('blockquote');
                        if (quote != null) {
                          return _buildPullQuote(quote.text, isDark);
                        }
                      }
                      
                      // Table
                      if (element.localName == 'figure' && 
                          element.classes.contains('wp-block-table')) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: HtmlWidget(
                                element.outerHtml,
                                customStylesBuilder: (el) {
                                  if (el.localName == 'table') {
                                    return {
                                      'border-collapse': 'collapse',
                                      'width': '100%',
                                    };
                                  }
                                  if (el.localName == 'td' || el.localName == 'th') {
                                    return {
                                      'border': '1px solid ${isDark ? '#616161' : '#e0e0e0'}',
                                      'padding': '12px',
                                      'text-align': 'left',
                                    };
                                  }
                                  if (el.localName == 'th') {
                                    return {
                                      'background-color': isDark ? '#424242' : '#f5f5f5',
                                      'font-weight': 'bold',
                                      'border': '1px solid ${isDark ? '#616161' : '#e0e0e0'}',
                                      'padding': '12px',
                                    };
                                  }
                                  return {};
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return null; // Use default rendering
                    },
                    textStyle: TextStyle(
                      fontSize: 17,
                      height: 1.7,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Comments Section
                  const Divider(),
                  CommentSection(articleId: widget.article.id),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
