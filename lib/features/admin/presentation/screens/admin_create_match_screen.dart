import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/match_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_sidebar.dart';

class AdminCreateMatchScreen extends StatefulWidget {
  final String? matchId;

  const AdminCreateMatchScreen({super.key, this.matchId});

  static const String routePath = '/admin/matches/create';
  static const String editRoutePath = '/admin/matches/edit/:matchId';

  @override
  State<AdminCreateMatchScreen> createState() => _AdminCreateMatchScreenState();
}

class _AdminCreateMatchScreenState extends State<AdminCreateMatchScreen> {
  final homeTeamController = TextEditingController();
  final awayTeamController = TextEditingController();
  final scoreController = TextEditingController();

  final matchRepository = MatchRepository();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 0);
  String status = 'upcoming';
  bool isLoaded = false;
  bool isSaving = false;
  bool isDeleting = false;

  bool get isEditing => widget.matchId != null;

  Future<bool> _isAdmin() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final doc = await firestoreService.users.doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Future<void> _loadMatch() async {
    if (isLoaded || !isEditing) return;

    final match = await matchRepository.getMatch(widget.matchId!);
    if (match == null) {
      isLoaded = true;
      return;
    }

    homeTeamController.text = match.homeTeam;
    awayTeamController.text = match.awayTeam;
    scoreController.text = match.score;
    selectedDate = match.matchDate;
    selectedTime = TimeOfDay(
      hour: match.matchDate.hour,
      minute: match.matchDate.minute,
    );
    status = match.status;

    isLoaded = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;
    setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked == null) return;
    setState(() => selectedTime = picked);
  }

  Future<void> _saveMatch() async {
    final homeTeam = homeTeamController.text.trim();
    final awayTeam = awayTeamController.text.trim();
    final score = scoreController.text.trim();

    if (homeTeam.isEmpty || awayTeam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Ev sahibi ve rakip takım boş olamaz.'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final matchDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final data = {
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'matchDate': matchDate.toIso8601String(),
        'status': status,
        'score': score,
      };

      if (isEditing) {
        await firestoreService.matches.doc(widget.matchId!).update(data);
      } else {
        await firestoreService.matches.add(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text(isEditing ? 'Maç güncellendi.' : 'Maç eklendi.'),
        ),
      );

      context.go('/admin/matches');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text(
            isEditing ? 'Maç güncelleme hatası: $e' : 'Maç ekleme hatası: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _deleteMatch() async {
    if (!isEditing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Maç silinsin mi?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Bu işlem geri alınamaz.',
            style: TextStyle(color: Color(0xFFB3B3B3)),
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

    setState(() => isDeleting = true);

    try {
      await firestoreService.matches.doc(widget.matchId!).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Maç silindi.'),
        ),
      );

      context.go('/admin/matches');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Maç silme hatası: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => isDeleting = false);
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

        return FutureBuilder<void>(
          future: _loadMatch(),
          builder: (context, matchSnapshot) {
            if (matchSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0E0E0E),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE53935)),
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
                          title: Text(
                            isEditing ? 'Maçı Düzenle' : 'Yeni Maç Ekle',
                          ),
                        )
                      : null,
                  drawer: compact
                      ? const Drawer(
                          backgroundColor: Color(0xFF111111),
                          child: AdminSidebar(
                            activeRoute: '/admin/matches',
                            width: double.infinity,
                          ),
                        )
                      : null,
                  body: Row(
                    children: [
                      if (!compact) const _AdminSidebar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            context.go('/admin/matches'),
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEditing
                                            ? 'Maçı Düzenle'
                                            : 'Yeni Maç Ekle',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isEditing)
                                        Flexible(
                                          child: OutlinedButton.icon(
                                            onPressed: isDeleting
                                                ? null
                                                : _deleteMatch,
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFFE53935,
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFFE53935),
                                              ),
                                            ),
                                            icon: isDeleting
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(
                                                            0xFFE53935,
                                                          ),
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.delete_rounded,
                                                  ),
                                            label: Text(
                                              isDeleting
                                                  ? 'Siliniyor...'
                                                  : 'Sil',
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Maç bilgilerini, skorunu ve durumunu buradan yönet.',
                                    style: TextStyle(
                                      color: Color(0xFFB3B3B3),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  _AdminCard(
                                    child: Column(
                                      children: [
                                        _AdminTextField(
                                          controller: homeTeamController,
                                          label: 'Ev sahibi takım',
                                          icon: Icons.home_rounded,
                                        ),
                                        const SizedBox(height: 16),
                                        _AdminTextField(
                                          controller: awayTeamController,
                                          label: 'Rakip takım',
                                          icon: Icons.shield_rounded,
                                        ),
                                        const SizedBox(height: 16),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final compact =
                                                constraints.maxWidth < 520;
                                            final datePicker = _PickerTile(
                                              icon:
                                                  Icons.calendar_month_rounded,
                                              title: 'Tarih',
                                              value:
                                                  '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                                              onTap: _pickDate,
                                            );
                                            final timePicker = _PickerTile(
                                              icon: Icons.schedule_rounded,
                                              title: 'Saat',
                                              value:
                                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                              onTap: _pickTime,
                                            );

                                            if (compact) {
                                              return Column(
                                                children: [
                                                  datePicker,
                                                  const SizedBox(height: 16),
                                                  timePicker,
                                                ],
                                              );
                                            }

                                            return Row(
                                              children: [
                                                Expanded(child: datePicker),
                                                const SizedBox(width: 16),
                                                Expanded(child: timePicker),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF111111),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: Colors.white10,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: status,
                                              dropdownColor: const Color(
                                                0xFF1A1A1A,
                                              ),
                                              iconEnabledColor: Colors.white,
                                              isExpanded: true,
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'upcoming',
                                                  child: Text(
                                                    'Yaklaşan Maç',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'live',
                                                  child: Text(
                                                    'Canlı',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'finished',
                                                  child: Text(
                                                    'Tamamlandı',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                if (value == null) return;
                                                setState(() => status = value);
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _AdminTextField(
                                          controller: scoreController,
                                          label: 'Skor (örn: 2-1)',
                                          icon: Icons.scoreboard_rounded,
                                        ),
                                        const SizedBox(height: 26),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton.icon(
                                            onPressed: isSaving
                                                ? null
                                                : _saveMatch,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFE53935,
                                              ),
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  Colors.white12,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            icon: isSaving
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.save_rounded,
                                                  ),
                                            label: Text(
                                              isSaving
                                                  ? 'Kaydediliyor...'
                                                  : isEditing
                                                  ? 'DEĞİŞİKLİKLERİ KAYDET'
                                                  : 'MAÇI KAYDET',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Widget child;

  const _AdminCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFE53935),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB3B3B3)),
        prefixIcon: Icon(icon, color: const Color(0xFF0F6A3D)),
        filled: true,
        fillColor: const Color(0xFF111111),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0F6A3D)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
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
            active: true,
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
