import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/article_model.dart';

class FeaturedArticlesCarousel extends StatefulWidget {
  final List<ArticleModel> articles;
  final Function(ArticleModel) onArticleTap;

  const FeaturedArticlesCarousel({
    Key? key,
    required this.articles,
    required this.onArticleTap,
  }) : super(key: key);

  @override
  State<FeaturedArticlesCarousel> createState() => _FeaturedArticlesCarouselState();
}

class _FeaturedArticlesCarouselState extends State<FeaturedArticlesCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.articles.length,
          itemBuilder: (context, index, realIndex) {
            final article = widget.articles[index];
            return _buildCarouselItem(article);
          },
          options: CarouselOptions(
            aspectRatio: 1.91, // 1.91:1 as specified
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.articles.asMap().entries.map((entry) {
            return Container(
              width: _currentIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentIndex == entry.key
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(ArticleModel article) {
    return GestureDetector(
      onTap: () => widget.onArticleTap(article),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Featured image
              article.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: article.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 50),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50),
                    ),
              
              // Gradient overlay for text readability (blue to transparent)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.95),
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
