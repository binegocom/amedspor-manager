import 'package:flutter/material.dart';
import '../../../../core/router/navigation_helpers.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  static const String routePath = '/policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.popOrGo('/settings')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: const [
                  _PolicyHero(),
                  SizedBox(height: 18),
                  _PolicySection(
                    title: 'Topluluk Kuralları',
                    text:
                        'Küfür, hakaret, tehdit, hedef gösterme, nefret söylemi ve provokatif içerikler platformda yasaktır. Taraftarlar arasında saygılı iletişim esastır.',
                  ),
                  _PolicySection(
                    title: 'KVKK ve Veri Gizliliği',
                    text:
                        '6698 sayılı KVKK kapsamında, kişisel verileriniz (e-posta, kullanıcı adı) sadece uygulama deneyimini geliştirmek ve güvenliği sağlamak amacıyla işlenir. Verileriniz izniniz olmadan üçüncü taraflarla paylaşılmaz.',
                  ),
                  _PolicySection(
                    title: 'Hesap Silme ve Veri Hakkı',
                    text:
                        'Kullanıcılarımız istedikleri zaman Ayarlar > Hesabımı Sil menüsünden hesaplarını ve tüm ilişkili verilerini kalıcı olarak silebilirler. Veri taşınabilirliği hakkınız için destek ekibimizle iletişime geçebilirsiniz.',
                  ),
                  _PolicySection(
                    title: 'İçerik Sorumluluğu',
                    text:
                        'Kullanıcıların paylaştığı yorum, kadro, tahmin ve postlardan kullanıcıların kendisi sorumludur. Kurallara aykırı içerikler moderasyon tarafından kaldırılabilir.',
                  ),
                  _PolicySection(
                    title: 'İletişim',
                    text:
                        'Politikalarımız hakkındaki sorularınız için uygulama içindeki Geri Bildirim sistemini kullanabilir veya amedspor.app@gmail.com adresinden bize ulaşabilirsiniz.',
                  ),
                ],
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
          const Icon(Icons.privacy_tip_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gizlilik ve Kullanım Şartları',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyHero extends StatelessWidget {
  const _PolicyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6A3D), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE53935),
            child: Icon(Icons.shield_rounded, color: Colors.white, size: 30),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Güvenli, saygılı ve güçlü bir dijital tribün için bu kurallar geçerlidir.',
              style: TextStyle(
                color: Colors.white,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String text;

  const _PolicySection({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
