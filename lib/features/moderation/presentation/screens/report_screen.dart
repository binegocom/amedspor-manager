import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/navigation_helpers.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/report_model.dart';
import '../../../../data/repositories/report_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class ReportScreen extends StatefulWidget {
  final String type;
  final String id;

  const ReportScreen({super.key, required this.type, required this.id});

  static const String routePath = '/report/:type/:id';

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final detailController = TextEditingController();

  final reportRepository = ReportRepository();
  final uuid = const Uuid();
  bool isSubmitting = false;

  String selectedReason = 'Hakaret / Küfür';

  final List<String> reasons = const [
    'Hakaret / Küfür',
    'Spam',
    'Yanıltıcı bilgi',
    'Provokatif içerik',
    'Diğer',
  ];

  Future<void> _submitReport() async {
    if (isSubmitting) return;

    final detail = detailController.text.trim();
    final user = authService.currentUser;

    if (user == null) {
      context.go('/login');
      return;
    }

    if (selectedReason == 'Diğer' && detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Lütfen rapor detayını yaz.'),
        ),
      );
      return;
    }

    final report = ReportModel(
      id: uuid.v4(),
      reporterId: user.uid,
      targetType: widget.type,
      targetId: widget.id,
      reason: selectedReason,
      detail: detail,
      status: 'reviewing',
      createdAt: DateTime.now(),
    );

    setState(() => isSubmitting = true);

    try {
      await reportRepository.createReport(report);
    } catch (_) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Rapor gonderilemedi. Lutfen tekrar deneyin.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0F6A3D),
        content: Text('Rapor gönderildi. Teşekkürler.'),
      ),
    );

    context.go('/reports');
  }

  String get targetTitle {
    if (widget.type == 'post') return 'Post Raporla';
    if (widget.type == 'comment') return 'Yorum Raporla';
    if (widget.type == 'user') return 'Kullanıcı Raporla';
    return 'İçerik Raporla';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: targetTitle,
                onBack: () => context.popOrGo('/feed'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Neden raporluyorsun?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Topluluğu güvenli tutmak için raporlar moderasyon tarafından incelenir.',
                style: TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
              ),
              const SizedBox(height: 24),
              _DarkCard(
                child: RadioGroup<String>(
                  groupValue: selectedReason,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedReason = value);
                  },
                  child: Column(
                    children: reasons.map((reason) {
                      return RadioListTile<String>(
                        value: reason,
                        activeColor: const Color(0xFFE53935),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          reason,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailController,
                minLines: 5,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFE53935),
                decoration: InputDecoration(
                  labelText: 'Ek açıklama',
                  alignLabelWithHint: true,
                  labelStyle: const TextStyle(color: Color(0xFFB3B3B3)),
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
              const SizedBox(height: 18),
              _DarkCard(
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Color(0xFFE53935),
                      child: Icon(Icons.shield_rounded, color: Colors.white),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Raporun gizli tutulur. Kötüye kullanım durumunda hesap işlemleri uygulanabilir.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'RAPORU GÖNDER',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;

  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}
