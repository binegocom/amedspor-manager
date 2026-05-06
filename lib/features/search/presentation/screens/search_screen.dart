import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/search_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const String routePath = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchController = TextEditingController();

  final searchRepository = SearchRepository();
  List<SearchResultModel> results = [];
  bool isLoading = false;

  String query = '';

  Future<void> _search(String value) async {
    setState(() {
      query = value;
      isLoading = true;
    });

    try {
      final data = await searchRepository.search(value);

      if (!mounted) return;

      setState(() {
        results = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        results = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Arama yapilamadi. Lutfen tekrar deneyin.'),
        ),
      );
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'user':
        return Icons.person_rounded;
      case 'post':
        return Icons.article_rounded;
      case 'match':
        return Icons.sports_soccer_rounded;
      case 'chat':
        return Icons.forum_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'user':
        return const Color(0xFFE53935);
      case 'post':
        return const Color(0xFF0F6A3D);
      case 'match':
        return const Color(0xFFFFB300);
      case 'chat':
        return const Color(0xFF2E7DFF);
      default:
        return const Color(0xFFB3B3B3);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.go('/feed')),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFE53935),
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Kullanıcı, post, maç veya sohbet ara...',
                  hintStyle: const TextStyle(color: Color(0xFF777777)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF0F6A3D),
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              query = '';
                              results = [];
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFB3B3B3),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE53935)),
                  ),
                ),
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    )
                  : results.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = results[index];

                        return _ResultCard(
                          item: item,
                          icon: _iconForType(item.type),
                          color: _colorForType(item.type),
                          onTap: () => context.go(item.route),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Icon(Icons.search_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          const Text(
            'Arama',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SearchResultModel item;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ResultCard({
    required this.item,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sonuç bulunamadı.',
        style: TextStyle(color: Color(0xFFB3B3B3), fontWeight: FontWeight.w600),
      ),
    );
  }
}
