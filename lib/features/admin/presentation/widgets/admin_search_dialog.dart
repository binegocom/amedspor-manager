import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/match_model.dart';

class AdminSearchDialog extends StatefulWidget {
  const AdminSearchDialog({super.key});

  @override
  State<AdminSearchDialog> createState() => _AdminSearchDialogState();
}

class _AdminSearchDialogState extends State<AdminSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<AppUserModel> _userResults = [];
  List<MatchModel> _matchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _userResults = [];
        _matchResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;
      
      // Search Users (prefix match on username)
      final userSnap = await db.collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(5)
          .get();

      // Search Matches (simple fetch for now, matching by name is harder in Firestore without full-text)
      // We'll just fetch recent matches and filter locally for this "Quick Search"
      final matchSnap = await db.collection('matches')
          .orderBy('matchDate', descending: true)
          .limit(20)
          .get();

      final users = userSnap.docs.map((doc) => AppUserModel.fromMap(doc.id, doc.data())).toList();
      final matches = matchSnap.docs
          .map((doc) => MatchModel.fromFirestore(doc))
          .where((m) => 
            m.homeTeam.toLowerCase().contains(query.toLowerCase()) || 
            m.awayTeam.toLowerCase().contains(query.toLowerCase())
          )
          .toList();

      setState(() {
        _userResults = users;
        _matchResults = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Kullanıcı veya maç ara...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE53935)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator(color: Color(0xFFE53935))
            else if (_userResults.isEmpty && _matchResults.isEmpty && _controller.text.isNotEmpty)
              const Text('Sonuç bulunamadı', style: TextStyle(color: Colors.white38))
            else ...[
              if (_userResults.isNotEmpty) ...[
                const _SearchHeader(title: 'Kullanıcılar'),
                ..._userResults.map((user) => _SearchResultTile(
                  title: user.username,
                  subtitle: user.email,
                  icon: Icons.person_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/profile/${user.id}');
                  },
                )),
              ],
              if (_matchResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SearchHeader(title: 'Maçlar'),
                ..._matchResults.map((match) => _SearchResultTile(
                  title: '${match.homeTeam} vs ${match.awayTeam}',
                  subtitle: '${match.matchDate.day}.${match.matchDate.month}.${match.matchDate.year}',
                  icon: Icons.sports_soccer_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin/matches'); // Or specific match edit if route exists
                  },
                )),
              ],
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final String title;
  const _SearchHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Colors.white10)),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SearchResultTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
