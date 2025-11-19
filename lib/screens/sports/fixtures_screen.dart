import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beritabola/providers/football_provider.dart';
import 'package:beritabola/models/fixture_model.dart';
import 'package:beritabola/widgets/match_card.dart';
import 'package:beritabola/screens/sports/match_detail_screen.dart';

/// Fixtures Screen - Shows matches for specific date/range
class FixturesScreen extends StatefulWidget {
  final String title;
  final int dateOffset; // 0=today, 1=tomorrow, -1=all (7 days)

  const FixturesScreen({
    Key? key,
    required this.title,
    required this.dateOffset,
  }) : super(key: key);

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  bool _isLoading = false;
  List<FixtureModel> _fixtures = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFixtures();
    });
  }

  Future<void> _loadFixtures() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<FootballProvider>(context, listen: false);

      if (widget.dateOffset == -1) {
        // Load all upcoming fixtures (7 days)
        await provider.fetchUpcomingFixtures();
        _fixtures = provider.upcomingFixtures;
      } else if (widget.dateOffset == 0) {
        // Load today's fixtures
        await provider.fetchTodayFixtures();
        _fixtures = provider.todayFixtures;
      } else {
        // Load specific day
        final targetDate = DateTime.now().add(Duration(days: widget.dateOffset));
        final dateStr = _formatDate(targetDate);
        final response = await provider.fetchFixturesByDate(dateStr);
        _fixtures = response;
      }
    } catch (e) {
      _error = 'Gagal memuat data: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshData() async {
    await _loadFixtures();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_fixtures.isEmpty) {
      return Center(
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
              'Tidak ada pertandingan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _fixtures.length,
        itemBuilder: (context, index) {
          final fixture = _fixtures[index];
          return MatchCard(
            fixture: fixture,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailScreen(fixture: fixture),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
