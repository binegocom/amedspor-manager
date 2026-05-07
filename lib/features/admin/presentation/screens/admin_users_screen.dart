import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_layout.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  static const String routePath = '/admin/users';

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final userRepository = UserRepository();
  final List<AppUserModel> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMoreUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset)) return;

    setState(() => _isLoading = true);
    if (reset) {
      _users.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    try {
      final snapshot = await userRepository.getUsersSnapshotPaginated(
        limit: 20,
        lastDocument: _lastDocument,
        searchQuery: _searchQuery,
      );

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final newUsers = snapshot.docs
          .map((doc) => AppUserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      setState(() {
        _users.addAll(newUsers);
        _lastDocument = snapshot.docs.last;
        _isLoading = false;
        if (newUsers.length < 20) _hasMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRole({
    required AppUserModel user,
    required String role,
  }) async {
    try {
      await firestoreService.users.doc(user.id).update({
        'role': role,
      });

      // Update local state
      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = _users[index].copyWith(role: role);
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text('${user.username} rolü $role olarak güncellendi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Rol güncelleme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _toggleUserDisabled(AppUserModel user) async {
    final isDisabled = user.isDisabled;

    try {
      await firestoreService.users.doc(user.id).update({
        'disabled': !isDisabled,
      });

      // Update local state
      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = _users[index].copyWith(isDisabled: !isDisabled);
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text(
            !isDisabled
                ? '${user.username} pasifleştirildi.'
                : '${user.username} tekrar aktif edildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Kullanıcı güncelleme hatası: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminUsersScreen.routePath,
      title: 'Kullanıcı Yönetimi',
      subtitle: 'Kullanıcıları görüntüle, rol değiştir ve hesap durumunu yönet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: 520,
              child: TextField(
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFE53935),
                onSubmitted: (value) {
                  _searchQuery = value;
                  _loadMoreUsers(reset: true);
                },
                decoration: InputDecoration(
                  hintText: 'Kullanıcı adı ara (Enter ile)...',
                  hintStyle: const TextStyle(color: Color(0xFF777777)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F6A3D)),
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
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _users.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          'Kullanıcı bulunamadı.',
                          style: TextStyle(color: Color(0xFFB3B3B3), fontWeight: FontWeight.w600),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        itemCount: _users.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == _users.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: Color(0xFFE53935)),
                              ),
                            );
                          }

                          final user = _users[index];
                          return _UserCard(
                            user: user,
                            onRoleChanged: (role) => _updateRole(user: user, role: role),
                            onToggleDisabled: () => _toggleUserDisabled(user),
                            onOpenProfile: () => context.go('/profile/${user.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUserModel user;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onToggleDisabled;
  final VoidCallback onOpenProfile;

  const _UserCard({
    required this.user,
    required this.onRoleChanged,
    required this.onToggleDisabled,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final username =
        user.username.startsWith('@') ? user.username : '@${user.username}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: user.isDisabled
            ? const Color(0xFF241515)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: user.isDisabled ? const Color(0xFFE53935) : Colors.white10,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final userInfo = Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF0F6A3D),
                backgroundImage:
                    user.avatarUrl.isEmpty ? null : NetworkImage(user.avatarUrl),
                child: user.avatarUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Color(0xFFB3B3B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniBadge(
                          text: '${user.points} puan',
                          color: const Color(0xFF0F6A3D),
                        ),
                        const SizedBox(width: 8),
                        _MiniBadge(
                          text: user.isDisabled ? 'Pasif' : 'Aktif',
                          color: user.isDisabled
                              ? const Color(0xFFE53935)
                              : const Color(0xFF0F6A3D),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: compact ? double.infinity : 140,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: user.role,
                    dropdownColor: const Color(0xFF1A1A1A),
                    iconEnabledColor: Colors.white,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'moderator', child: Text('Moderator', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'admin', child: Text('Admin', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      onRoleChanged(value);
                    },
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF0F6A3D)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Profil'),
              ),
              OutlinedButton.icon(
                onPressed: onToggleDisabled,
                style: OutlinedButton.styleFrom(
                  foregroundColor: user.isDisabled
                      ? const Color(0xFF0F6A3D)
                      : const Color(0xFFE53935),
                  side: BorderSide(
                    color: user.isDisabled
                        ? const Color(0xFF0F6A3D)
                        : const Color(0xFFE53935),
                  ),
                ),
                icon: Icon(
                  user.isDisabled
                      ? Icons.check_circle_rounded
                      : Icons.block_rounded,
                  size: 18,
                ),
                label: Text(user.isDisabled ? 'Aktifleştir' : 'Pasifleştir'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userInfo,
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: userInfo),
              const SizedBox(width: 24),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({
    required this.text,
    required this.color,
  });

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
