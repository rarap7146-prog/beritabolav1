import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/article_provider.dart';
import '../../widgets/article_card_list_item.dart';
import '../../models/article_model.dart';
import 'article_detail_screen.dart';

class ViewMoreArticlesScreen extends StatefulWidget {
  const ViewMoreArticlesScreen({Key? key}) : super(key: key);

  @override
  State<ViewMoreArticlesScreen> createState() => _ViewMoreArticlesScreenState();
}

class _ViewMoreArticlesScreenState extends State<ViewMoreArticlesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load initial articles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ArticleProvider>(context, listen: false);
      if (provider.latestArticles.isEmpty) {
        provider.loadLatestArticles();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ArticleProvider>(context, listen: false);
      if (!provider.latestLoading && provider.hasMorePages) {
        provider.loadLatestArticles();
      }
    }
  }

  Future<void> _onRefresh() async {
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    await provider.loadLatestArticles(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita Terbaru'),
        elevation: 0,
      ),
      body: Consumer<ArticleProvider>(
        builder: (context, provider, child) {
          if (provider.latestArticles.isEmpty && provider.latestLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.latestArticles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada artikel',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: provider.latestArticles.length + (provider.latestLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.latestArticles.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final article = provider.latestArticles[index];
                final stats = provider.getArticleStats(article.id);

                return _CategoryArticleCard(
                  article: article,
                  stats: stats,
                  provider: provider,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Helper widget to handle async category name loading
class _CategoryArticleCard extends StatefulWidget {
  final ArticleModel article;
  final Map<String, int> stats;
  final ArticleProvider provider;

  const _CategoryArticleCard({
    required this.article,
    required this.stats,
    required this.provider,
  });

  @override
  State<_CategoryArticleCard> createState() => _CategoryArticleCardState();
}

class _CategoryArticleCardState extends State<_CategoryArticleCard> {
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _loadCategoryName();
  }

  Future<void> _loadCategoryName() async {
    if (widget.article.categoryIds.isNotEmpty) {
      final name = await widget.provider.getCategoryName(widget.article.categoryIds.first);
      if (mounted) {
        setState(() {
          _categoryName = name;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArticleCardListItem(
      article: widget.article,
      stats: widget.stats,
      categoryName: _categoryName,
      authorName: widget.article.authorName,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: widget.article),
          ),
        );
      },
    );
  }
}
