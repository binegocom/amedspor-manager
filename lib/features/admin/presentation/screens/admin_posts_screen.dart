import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_sidebar.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  static const String routePath = '/admin/posts';

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final postRepository = PostRepository();

  String searchQuery = '';
  String selectedCategory = 'Tümü';

  final categories = const [
    'Tümü',
    'Maç Yorumu',
    'Kadro',
    'Transfer',
    'Tribün',
  ];

  Future<bool> _isAdmin() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final doc = await firestoreService.users.doc(user.uid).get();
    final role = doc.data()?['role'];

    return role == 'admin' || role == 'moderator';
  }

  List<PostModel> _filterPosts(List<PostModel> posts) {
    final q = searchQuery.trim().toLowerCase();

    return posts.where((post) {
      final matchesCategory =
          selectedCategory == 'Tümü' || post.category == selectedCategory;

      final matchesSearch =
          q.isEmpty ||
          post.title.toLowerCase().contains(q) ||
          post.content.toLowerCase().contains(q) ||
          post.username.toLowerCase().contains(q);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _deletePost(PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Post silinsin mi?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '"${post.title}" kalıcı olarak silinecek.',
            style: const TextStyle(color: Color(0xFFB3B3B3)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Sil',
                style: TextStyle(color: Color(0xFFE53935)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await firestoreService.posts.doc(post.id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Post silindi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Post silme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _toggleHidden(PostModel post) async {
    final doc = await firestoreService.posts.doc(post.id).get();
    final data = doc.data();
    final isHidden = data?['hidden'] == true;

    try {
      await firestoreService.posts.doc(post.id).update({'hidden': !isHidden});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text(
            !isHidden ? 'Post gizlendi.' : 'Post tekrar görünür yapıldı.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Post güncelleme hatası: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E0E0E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            ),
          );
        }

        if (adminSnapshot.data != true) {
          return Scaffold(
            backgroundColor: const Color(0xFF0E0E0E),
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Admin girişi yap'),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;

            return Scaffold(
              backgroundColor: const Color(0xFF0E0E0E),
              appBar: compact
                  ? AppBar(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      title: const Text('Post Yönetimi'),
                    )
                  : null,
              drawer: compact
                  ? const Drawer(
                      backgroundColor: Color(0xFF111111),
                      child: AdminSidebar(
                        activeRoute: AdminPostsScreen.routePath,
                        width: double.infinity,
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  if (!compact) const _AdminSidebar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Post Yönetimi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Taraftar paylaşımlarını incele, gizle veya sil.',
                            style: TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth < 900
                                    ? double.infinity
                                    : 520,
                                child: TextField(
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: const Color(0xFFE53935),
                                  onChanged: (value) {
                                    setState(() => searchQuery = value);
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'Başlık, içerik veya kullanıcı ara...',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF777777),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF0F6A3D),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1A1A1A),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Colors.white10,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE53935),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: constraints.maxWidth < 900
                                    ? double.infinity
                                    : 220,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCategory,
                                    dropdownColor: const Color(0xFF1A1A1A),
                                    iconEnabledColor: Colors.white,
                                    isExpanded: true,
                                    items: categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => selectedCategory = value);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Expanded(
                            child: StreamBuilder<List<PostModel>>(
                              stream: postRepository.watchPosts(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFE53935),
                                    ),
                                  );
                                }

                                final posts = _filterPosts(snapshot.data ?? []);

                                if (posts.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Post bulunamadı.',
                                      style: TextStyle(
                                        color: Color(0xFFB3B3B3),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  itemCount: posts.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final post = posts[index];

                                    return _AdminPostCard(
                                      post: post,
                                      onOpen: () =>
                                          context.go('/post/${post.id}'),
                                      onToggleHidden: () => _toggleHidden(post),
                                      onDelete: () => _deletePost(post),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onOpen;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;

  const _AdminPostCard({
    required this.post,
    required this.onOpen,
    required this.onToggleHidden,
    required this.onDelete,
  });

  Future<bool> _isHidden() async {
    final doc = await firestoreService.posts.doc(post.id).get();
    return doc.data()?['hidden'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final hour = post.createdAt.hour.toString().padLeft(2, '0');
    final minute = post.createdAt.minute.toString().padLeft(2, '0');

    return FutureBuilder<bool>(
      future: _isHidden(),
      builder: (context, snapshot) {
        final isHidden = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isHidden ? const Color(0xFF241515) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isHidden ? const Color(0xFFE53935) : Colors.white10,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;

              final leading = CircleAvatar(
                radius: 28,
                backgroundColor: isHidden
                    ? const Color(0xFFE53935)
                    : const Color(0xFF0F6A3D),
                child: Icon(
                  post.category == 'Kadro'
                      ? Icons.sports_soccer_rounded
                      : Icons.article_rounded,
                  color: Colors.white,
                ),
              );

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MiniBadge(
                        text: post.category,
                        color: const Color(0xFF0F6A3D),
                      ),
                      if (isHidden)
                        const _MiniBadge(
                          text: 'Gizli',
                          color: Color(0xFFE53935),
                        ),
                      Text(
                        '$hour:$minute',
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '👍 ${post.likes}',
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '💬 ${post.commentsCount}',
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF0F6A3D)),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Aç'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onToggleHidden,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isHidden
                          ? const Color(0xFF0F6A3D)
                          : const Color(0xFFFFB300),
                      side: BorderSide(
                        color: isHidden
                            ? const Color(0xFF0F6A3D)
                            : const Color(0xFFFFB300),
                      ),
                    ),
                    icon: Icon(
                      isHidden
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                    ),
                    label: Text(isHidden ? 'Göster' : 'Gizle'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                    ),
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Sil'),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leading,
                        const SizedBox(width: 16),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: 16),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: 16),
                  Expanded(child: details),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AMEDSPOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Admin Panel',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            onTap: () => context.go('/admin/dashboard'),
          ),
          _SidebarItem(
            icon: Icons.sports_soccer_rounded,
            title: 'Maçlar',
            onTap: () => context.go('/admin/matches'),
          ),
          _SidebarItem(
            icon: Icons.people_rounded,
            title: 'Kullanıcılar',
            onTap: () => context.go('/admin/users'),
          ),
          _SidebarItem(
            icon: Icons.article_rounded,
            title: 'Postlar',
            active: true,
            onTap: () => context.go('/admin/posts'),
          ),
          _SidebarItem(
            icon: Icons.report_rounded,
            title: 'Raporlar',
            onTap: () => context.go('/admin/reports'),
          ),
          _SidebarItem(
            icon: Icons.notifications_rounded,
            title: 'Bildirim',
            onTap: () => context.go('/admin/notifications'),
          ),
          _SidebarItem(
            icon: Icons.forum_rounded,
            title: 'Sohbet',
            onTap: () => context.go('/admin/chats'),
          ),
          _SidebarItem(
            icon: Icons.emoji_events_rounded,
            title: 'Tahminler',
            onTap: () => context.go('/admin/predictions'),
          ),
          _SidebarItem(
            icon: Icons.settings_rounded,
            title: 'Ayarlar',
            onTap: () => context.go('/admin/settings'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authService.signOut();
                if (!context.mounted) return;
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFE53935)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Çıkış'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool active;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: active ? const Color(0xFF0F6A3D) : Colors.transparent,
        leading: Icon(
          icon,
          color: active ? Colors.white : const Color(0xFFB3B3B3),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB3B3B3),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
