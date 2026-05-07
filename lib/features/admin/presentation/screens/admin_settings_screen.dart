import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../data/services/reset_service.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_layout.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  static const String routePath = '/admin/settings';

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final appNameController = TextEditingController();
  final announcementController = TextEditingController();
  final supportEmailController = TextEditingController();

  bool maintenanceMode = false;
  bool predictionsEnabled = true;
  bool chatEnabled = true;
  bool feedEnabled = true;
  bool isLoaded = false;
  bool isSaving = false;

  late Future<void> _settingsLoadFuture;

  @override
  void initState() {
    super.initState();
    _settingsLoadFuture = _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('appSettings')
          .doc('main')
          .get();

      if (doc.exists) {
        final data = doc.data();
        appNameController.text = data?['appName'] ?? 'Amedspor Dijital Tribün';
        announcementController.text = data?['announcement'] ?? '';
        supportEmailController.text = data?['supportEmail'] ?? '';

        setState(() {
          maintenanceMode = data?['maintenanceMode'] ?? false;
          predictionsEnabled = data?['predictionsEnabled'] ?? true;
          chatEnabled = data?['chatEnabled'] ?? true;
          feedEnabled = data?['feedEnabled'] ?? true;
          isLoaded = true;
        });
      } else {
        setState(() => isLoaded = true);
      }
    } catch (e) {
      debugPrint('Ayarlar yüklenirken hata: $e');
      rethrow;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('appSettings')
          .doc('main')
          .set({
            'appName': appNameController.text.trim(),
            'announcement': announcementController.text.trim(),
            'supportEmail': supportEmailController.text.trim(),
            'maintenanceMode': maintenanceMode,
            'predictionsEnabled': predictionsEnabled,
            'chatEnabled': chatEnabled,
            'feedEnabled': feedEnabled,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Ayarlar kaydedildi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Ayar kaydetme hatası: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminSettingsScreen.routePath,
      title: 'Platform Ayarları',
      subtitle: 'Uygulama adı, bakım modu, duyuru ve modül erişimlerini yönet.',
      child: FutureBuilder<void>(
        future: _settingsLoadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !isLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 48),
                  const SizedBox(height: 16),
                  Text('Hata oluştu: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _settingsLoadFuture = _loadSettings()),
                    child: const Text('TEKRAR DENE'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Genel Bilgiler',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AdminTextField(
                            controller: appNameController,
                            label: 'Platform adı',
                            icon: Icons.apps_rounded,
                          ),
                          const SizedBox(height: 16),
                          _AdminTextField(
                            controller: supportEmailController,
                            label: 'Destek email',
                            icon: Icons.email_rounded,
                          ),
                          const SizedBox(height: 16),
                          _AdminTextField(
                            controller: announcementController,
                            label: 'Duyuru mesajı',
                            icon: Icons.campaign_rounded,
                            minLines: 4,
                            maxLines: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sistem Durumu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SwitchTile(
                            title: 'Bakım modu',
                            subtitle:
                                'Açılırsa kullanıcılar uygulamaya erişemeden bakım mesajı görür.',
                            value: maintenanceMode,
                            color: const Color(0xFFE53935),
                            onChanged: (value) {
                              setState(() => maintenanceMode = value);
                            },
                          ),
                          _SwitchTile(
                            title: 'Tahmin sistemi aktif',
                            subtitle:
                                'Kullanıcıların maç tahmini yapmasına izin ver.',
                            value: predictionsEnabled,
                            color: const Color(0xFF0F6A3D),
                            onChanged: (value) {
                              setState(() => predictionsEnabled = value);
                            },
                          ),
                          _SwitchTile(
                            title: 'Sohbet sistemi aktif',
                            subtitle:
                                'Sohbet odalarını kullanıcılar için aç/kapat.',
                            value: chatEnabled,
                            color: const Color(0xFF0F6A3D),
                            onChanged: (value) {
                              setState(() => chatEnabled = value);
                            },
                          ),
                          _SwitchTile(
                            title: 'Feed aktif',
                            subtitle:
                                'Sosyal akış ve post sistemini aç/kapat.',
                            value: feedEnabled,
                            color: const Color(0xFF0F6A3D),
                            onChanged: (value) {
                              setState(() => feedEnabled = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          isSaving ? 'Kaydediliyor...' : 'AYARLARI KAYDET',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tehlikeli İşlemler',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActionTile(
                            title: 'Kadro Sürümünü Güncelle (2025-26)',
                            subtitle: 'Eski oyuncuları siler ve 2025-26 rüya kadrosunu yükler.',
                            icon: Icons.group_add_rounded,
                            onTap: () => _confirmSquadUpdate(context),
                            color: const Color(0xFF0F6A3D),
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          _buildActionTile(
                            title: 'Tüm Verileri Sıfırla',
                            subtitle: 'Tüm koleksiyonları (Oyuncular, Tahminler vb.) temizler.',
                            icon: Icons.delete_forever_rounded,
                            onTap: () => _confirmReset(context),
                            color: const Color(0xFFE53935),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSquadUpdate(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Kadroyu Güncelle?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Eski oyuncular silinecek ve yeni Amedspor 2025-2026 kadrosu yüklenecek. Tahminler ve diğer veriler korunacaktır.',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('VAZGEÇ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F6A3D)),
            child: const Text('GÜNCELLE'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!context.mounted) return;
      
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF0F6A3D))),
      );

      try {
        await ResetService().wipePlayersOnly();
        await seedService.seedAmedspor2026Squad();
        
        if (!context.mounted) return;
        navigator.pop(); // Close loading
        scaffoldMessenger.showSnackBar(const SnackBar(backgroundColor: Color(0xFF0F6A3D), content: Text('Kadro başarıyla güncellendi!')));
      } catch (e) {
        if (!context.mounted) return;
        navigator.pop(); // Close loading
        scaffoldMessenger.showSnackBar(SnackBar(backgroundColor: const Color(0xFFE53935), content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sistemi Sıfırla?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Tüm veritabanı silinecek. Bu işlem geri alınamaz! Canlıya geçmeden hemen önce yapılması önerilir.',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('VAZGEÇ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('EVET, HER ŞEYİ SİL'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!context.mounted) return;
      
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
      );

      try {
        await ResetService().wipeAllData();
        if (!context.mounted) return;
        navigator.pop(); // Close loading
        scaffoldMessenger.showSnackBar(const SnackBar(backgroundColor: Color(0xFF0F6A3D), content: Text('Sistem başarıyla sıfırlandı!')));
      } catch (e) {
        if (!context.mounted) return;
        navigator.pop(); // Close loading
        scaffoldMessenger.showSnackBar(SnackBar(backgroundColor: const Color(0xFFE53935), content: Text('Hata: $e')));
      }
    }
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
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
  final int? minLines;
  final int? maxLines;

  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.minLines,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines ?? 1,
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

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final icon = CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(
              value ? Icons.check_rounded : Icons.close_rounded,
              color: color,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
            ],
          );

          final toggle = Switch(
            value: value,
            activeThumbColor: color,
            onChanged: onChanged,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [icon, const SizedBox(width: 14), toggle]),
                const SizedBox(height: 12),
                content,
              ],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(child: content),
              toggle,
            ],
          );
        },
      ),
    );
  }
}
