import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_guard.dart';
import 'admin_sidebar.dart';

class AdminLayout extends StatelessWidget {
  final String activeRoute;
  final bool allowModerator;
  final Widget child;

  const AdminLayout({
    super.key,
    required this.activeRoute,
    required this.child,
    this.allowModerator = false,
  });

  Future<bool> _canAccess() {
    if (allowModerator) {
      return AdminGuard.isAdminOrModerator();
    }

    return AdminGuard.isAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canAccess(),
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
                        activeRoute: activeRoute,
                        width: double.infinity,
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  if (!compact) AdminSidebar(activeRoute: activeRoute),
                  Expanded(child: child),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
