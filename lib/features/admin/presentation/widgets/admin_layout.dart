import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_guard.dart';
import 'admin_sidebar.dart';

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
                        if (widget.title != null || widget.subtitle != null || widget.actions != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (widget.title != null)
                                        Text(
                                          widget.title!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      if (widget.subtitle != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          widget.subtitle!,
                                          style: const TextStyle(
                                            color: Color(0xFFA7B3AA),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (widget.actions != null) ...[
                                  const SizedBox(width: 24),
                                  Row(children: widget.actions!),
                                ],
                              ],
                            ),
                          ),
                        if (widget.title != null || widget.subtitle != null || widget.actions != null)
                          const SizedBox(height: 32),
                        Expanded(child: widget.child),
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
