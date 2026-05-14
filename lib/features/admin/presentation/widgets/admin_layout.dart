import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/guards/admin_guard.dart';
import 'admin_sidebar.dart';
import 'admin_search_dialog.dart';

class AdminLayout extends StatefulWidget {
  final String activeRoute;
  final bool allowModerator;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;

  const AdminLayout({
    super.key,
    required this.activeRoute,
    required this.child,
    this.allowModerator = false,
    this.title,
    this.subtitle,
    this.actions,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  late Future<bool> _accessFuture;

  @override
  void initState() {
    super.initState();
    _accessFuture = _canAccess();
  }

  Future<bool> _canAccess() {
    if (widget.allowModerator) {
      return AdminGuard.isAdminOrModerator();
    }
    return AdminGuard.isAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E0E0E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            ),
          );
        }

        if (snapshot.data != true) {
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
                      elevation: 0,
                      title: const Text(
                        'Admin Panel',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    )
                  : null,
              drawer: compact
                  ? Drawer(
                      backgroundColor: const Color(0xFF111111),
                      child: AdminSidebar(
                        activeRoute: widget.activeRoute,
                        width: double.infinity,
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  if (!compact) AdminSidebar(activeRoute: widget.activeRoute),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AdminTopBar(compact: compact),
                        if (widget.title != null ||
                            widget.subtitle != null ||
                            widget.actions != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.title != null)
                                        Text(
                                          widget.title!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      if (widget.subtitle != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          widget.subtitle!,
                                          style: const TextStyle(
                                            color: Color(0xFFA7B3AA),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (widget.actions != null) ...[
                                  const SizedBox(width: 24),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: widget.actions!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        Expanded(child: ClipRect(child: widget.child)),
                      ],
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

class _AdminTopBar extends StatelessWidget {
  final bool compact;
  const _AdminTopBar({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: Colors.white, width: 0.05)),
      ),
      child: Row(
        children: [
          if (!compact) ...[
            Flexible(
              flex: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: TextField(
                  readOnly: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AdminSearchDialog(),
                    );
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Sistemde ara...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white24,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            tooltip: 'Duyurular',
            onPressed: () => context.go('/admin/notifications'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          _UserMenu(),
        ],
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFE53935),
            child: Icon(Icons.person_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Yönetici',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white24,
            size: 16,
          ),
        ],
      ),
    );
  }
}
