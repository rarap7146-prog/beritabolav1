import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/article_provider.dart';
import '../../providers/football_provider.dart';
import '../../services/onesignal_service.dart';
import '../../widgets/featured_articles_carousel.dart';
import '../../widgets/netflix_style_category_list.dart';
import '../../widgets/match_card.dart';
import '../../widgets/league_card.dart';
import '../profile/about_app_page.dart';
import '../articles/view_more_articles_screen.dart';
import '../articles/article_detail_screen.dart';
import '../sports/league_detail_screen.dart';
import '../sports/match_detail_screen.dart';
import '../sports/fixtures_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const NewsPage(),
    const SportsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Berita',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Pertandingan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// News Page
class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize articles on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ArticleProvider>(context, listen: false);
      provider.initialize();
    });
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    await provider.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/launcher/play_store_512.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Berita Bola'),
          ],
        ),
        centerTitle: false,
      ),
      body: Consumer<ArticleProvider>(
        builder: (context, provider, child) {
          // Show loading on first load
          if (provider.featuredLoading && 
              provider.featuredArticles.isEmpty &&
              provider.categoryArticles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              children: [
                const SizedBox(height: 16),
                
                // Featured Articles Carousel
                if (provider.featuredArticles.isNotEmpty)
                  FeaturedArticlesCarousel(
                    articles: provider.featuredArticles,
                    onArticleTap: (article) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(article: article),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 24),
                
                // Category Lists (Netflix-style)
                ...ArticleProvider.categoryIds.map((categoryId) {
                  final articles = provider.categoryArticles[categoryId] ?? [];
                  
                  if (articles.isEmpty && !provider.categoryLoading(categoryId)) {
                    return const SizedBox.shrink();
                  }
                  
                  if (provider.categoryLoading(categoryId) && articles.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FutureBuilder<String>(
                      future: provider.getCategoryName(categoryId),
                      builder: (context, snapshot) {
                        final categoryName = snapshot.data ?? 'Kategori $categoryId';
                        
                        return NetflixStyleCategoryList(
                          categoryName: categoryName,
                          articles: articles,
                          articleStats: provider.articleStats,
                          onArticleTap: (article) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArticleDetailScreen(article: article),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 16),
                
                // View More Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ViewMoreArticlesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Lihat Semua Berita'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Sports Page
class SportsPage extends StatefulWidget {
  const SportsPage({super.key});

  @override
  State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage> {
  @override
  void initState() {
    super.initState();
    // Only load live matches on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<FootballProvider>(context, listen: false);
      provider.fetchLiveFixtures();
    });
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<FootballProvider>(context, listen: false);
    await provider.fetchLiveFixtures();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/launcher/play_store_512.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Pertandingan'),
          ],
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Consumer<FootballProvider>(
          builder: (context, provider, child) {
            final hasLive = provider.liveFixtures.isNotEmpty;
            final isLoading = provider.isLoadingLive;

            return Column(
              children: [
                // Match Feed (scrollable)
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Live Matches Section
                      if (hasLive) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LIVE',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final fixture = provider.liveFixtures[index];
                              return MatchCard(
                                fixture: fixture,
                                isRefreshing: provider.isRefreshingLive,
                                showTrackButton: true, // Enable track button for live matches
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MatchDetailScreen(
                                        fixture: fixture,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: provider.liveFixtures.length,
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 16),
                        ),
                      ],

                      // Quick Access Buttons
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Jadwal Pertandingan',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildFixtureButton(
                                context,
                                'Hari Ini',
                                'Lihat semua pertandingan hari ini',
                                Icons.today,
                                Colors.blue,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FixturesScreen(
                                        title: 'Pertandingan Hari Ini',
                                        dateOffset: 0,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildFixtureButton(
                                context,
                                'Besok',
                                'Lihat pertandingan besok',
                                Icons.event,
                                Colors.orange,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FixturesScreen(
                                        title: 'Pertandingan Besok',
                                        dateOffset: 1,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildFixtureButton(
                                context,
                                'Semua Jadwal',
                                'Lihat jadwal lengkap (7 hari ke depan)',
                                Icons.calendar_month,
                                Colors.green,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FixturesScreen(
                                        title: 'Jadwal 7 Hari',
                                        dateOffset: -1, // -1 means load all
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Loading indicator
                      if (isLoading && !hasLive)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        ),

                      // Empty state
                      if (!isLoading && !hasLive)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_soccer,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada pertandingan live',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cek jadwal di bawah atau pilih liga favorit',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Bottom padding for league section
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
                ),

                // League Quick Access (compact chip style at bottom)
                Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Liga',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: LeagueConfig.allLeagues.length,
                          itemBuilder: (context, index) {
                            final league = LeagueConfig.allLeagues[index];
                            return LeagueCard(
                              leagueId: league.id,
                              name: league.name,
                              logo: league.logo,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LeagueDetailScreen(
                                      leagueId: league.id,
                                      leagueName: league.name,
                                      season: league.season,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFixtureButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  final oneSignalService = OneSignalService();
  bool _isLoading = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    // Only load for authenticated users (not anonymous)
    final user = authService.currentUser;
    if (user != null && !user.isAnonymous) {
      setState(() {
        _notificationsEnabled = oneSignalService.areNotificationsEnabled;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    // Only allow for authenticated users
    final user = authService.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap login terlebih dahulu untuk mengaktifkan notifikasi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (value) {
        await oneSignalService.enableNotifications();
      } else {
        await oneSignalService.disableNotifications();
      }

      setState(() {
        _notificationsEnabled = value;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Notifikasi diaktifkan'
                  : 'Notifikasi dinonaktifkan',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah pengaturan notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _linkWithGoogle() async {
    setState(() => _isLoading = true);
    
    final result = await authService.linkWithGoogle();
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menghubungkan akun Google!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh UI
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Gagal menghubungkan akun Google'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSetPasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Atur Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Atur password untuk mengaktifkan login dengan email/password.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    hintText: 'Masukkan ulang password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    if (value != passwordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _setPassword(passwordController.text);
                }
              },
              child: const Text('Atur Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setPassword(String password) async {
    setState(() => _isLoading = true);
    
    final result = await authService.setPassword(password: password);
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diatur!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh UI
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Gagal mengatur password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showUpgradeAccountDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih metode untuk mengupgrade akun Anda dan menyimpan data secara permanen.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Google Sign Up Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _linkWithGoogle();
                },
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 20,
                  width: 20,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.g_mobiledata, size: 20),
                ),
                label: const Text('Lanjutkan dengan Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Email Sign Up Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showEmailSignUpForm();
                },
                icon: const Icon(Icons.email, size: 20),
                label: const Text('Daftar dengan Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEmailSignUpForm() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Daftar dengan Email'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Lengkapi data di bawah untuk mengupgrade akun Anda.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Masukkan email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      hintText: 'Masukkan ulang password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() => obscureConfirm = !obscureConfirm);
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (value != passwordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _linkWithEmailPassword(
                    emailController.text.trim(),
                    passwordController.text,
                    nameController.text.trim(),
                  );
                }
              },
              child: const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _linkWithEmailPassword(String email, String password, String displayName) async {
    setState(() => _isLoading = true);
    
    final result = await authService.linkWithEmailPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun berhasil diupgrade!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh UI
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Gagal mengupgrade akun'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;
    final hasPassword = authService.hasPasswordProvider();
    final hasGoogle = authService.hasGoogleProvider();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/launcher/play_store_512.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Profil'),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Theme Selector Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tema',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return Row(
                                children: [
                                  _CompactThemeButton(
                                    icon: Icons.light_mode,
                                    isSelected: themeProvider.themeOption == ThemeOption.light,
                                    onTap: () => themeProvider.setThemeOption(ThemeOption.light),
                                  ),
                                  const SizedBox(width: 8),
                                  _CompactThemeButton(
                                    icon: Icons.dark_mode,
                                    isSelected: themeProvider.themeOption == ThemeOption.dark,
                                    onTap: () => themeProvider.setThemeOption(ThemeOption.dark),
                                  ),
                                  const SizedBox(width: 8),
                                  _CompactThemeButton(
                                    icon: Icons.brightness_auto,
                                    isSelected: themeProvider.themeOption == ThemeOption.system,
                                    onTap: () => themeProvider.setThemeOption(ThemeOption.system),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notification Settings Card (only show for authenticated users)
                  if (!isAnonymous) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifikasi Push',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Terima update berita terbaru',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // About App Button
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Tentang Aplikasi'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutAppPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Anonymous User - Show Upgrade Account Card
                  if (isAnonymous) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.upgrade,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Masuk ke Aplikasi',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Masuk untuk mengakses dari perangkat manapun',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showUpgradeAccountDialog,
                              icon: const Icon(Icons.arrow_upward),
                              label: const Text('Daftar Sekarang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Registered User - Show Account Info
                  if (!isAnonymous) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: const Text('Tipe Akun'),
                        subtitle: const Text('Terdaftar'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(user?.email ?? 'Tidak tersedia'),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Linked Accounts Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Akun Terhubung',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Provider Status
                    Card(
                      child: ListTile(
                        leading: Icon(
                          hasPassword ? Icons.check_circle : Icons.cancel,
                          color: hasPassword ? Colors.green : Colors.grey,
                        ),
                        title: const Text('Email/Password'),
                        subtitle: Text(
                          hasPassword 
                            ? 'Terhubung - Anda bisa login dengan email/password' 
                            : 'Belum diatur - Atur password untuk login dengan email',
                        ),
                        trailing: !hasPassword
                            ? ElevatedButton.icon(
                                onPressed: _showSetPasswordDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Atur Password'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    
                    // Google Provider Status
                    Card(
                      child: ListTile(
                        leading: Icon(
                          hasGoogle ? Icons.check_circle : Icons.cancel,
                          color: hasGoogle ? Colors.green : Colors.grey,
                        ),
                        title: const Text('Akun Google'),
                        subtitle: Text(
                          hasGoogle 
                            ? 'Terhubung - Anda bisa login dengan Google' 
                            : 'Belum terhubung - Hubungkan Google untuk login mudah',
                        ),
                        trailing: !hasGoogle
                            ? ElevatedButton.icon(
                                onPressed: _linkWithGoogle,
                                icon: Image.asset(
                                  'assets/google_logo.png',
                                  height: 18,
                                  width: 18,
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.link, size: 18),
                                ),
                                label: const Text('Hubungkan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// Compact Theme Button Widget
class _CompactThemeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactThemeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? Colors.white
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade700),
        ),
      ),
    );
  }
}
