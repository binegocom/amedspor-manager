class ContentItemModel {
  final String title;
  final String body;
  final String imageUrl;
  final String actionText;
  final String actionUrl;

  const ContentItemModel({
    required this.title,
    required this.body,
    required this.imageUrl,
    this.actionText = '',
    this.actionUrl = '',
  });

  factory ContentItemModel.fromMap(Map<String, dynamic> map) {
    return ContentItemModel(
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      actionText: map['actionText'] ?? '',
      actionUrl: map['actionUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionText': actionText,
      'actionUrl': actionUrl,
    };
  }

  ContentItemModel copyWith({
    String? title,
    String? body,
    String? imageUrl,
    String? actionText,
    String? actionUrl,
  }) {
    return ContentItemModel(
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      actionText: actionText ?? this.actionText,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

class AppContentModel {
  final String id;
  final String title;
  final String category;
  final List<ContentItemModel> items;
  final bool isActive;
  final DateTime updatedAt;

  const AppContentModel({
    required this.id,
    required this.title,
    required this.category,
    required this.items,
    this.isActive = true,
    required this.updatedAt,
  });

  factory AppContentModel.fromMap(String id, Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?) ?? [];
    return AppContentModel(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'general',
      items: itemsList
          .map((item) => ContentItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      isActive: map['isActive'] ?? true,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'items': items.map((item) => item.toMap()).toList(),
      'isActive': isActive,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AppContentModel copyWith({
    String? title,
    String? category,
    List<ContentItemModel>? items,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return AppContentModel(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      items: items ?? this.items,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppContentModel.defaultOnboarding() {
    return AppContentModel(
      id: 'onboarding',
      title: 'Karşılama Ekranı Slaytları',
      category: 'onboarding',
      items: const [
        ContentItemModel(
          title: 'Amedspor Menajeri Ol!',
          body:
              'Kulübün tüm kontrolü artık senin ellerinde. Kadronu kur, taktiklerini belirle ve Amedspor\'u zirveye taşı.',
          imageUrl: 'assets/images/splash_bg.png',
        ),
        ContentItemModel(
          title: 'Kendi 11\'ini Sahaya Sür',
          body:
              'Rakibe göre taktiğini (4-3-3, 3-5-2 vb.) seç, en formda oyuncularını ilk 11\'e yerleştir ve maça hükmet.',
          imageUrl: 'assets/images/splash_bg.png',
        ),
        ContentItemModel(
          title: 'Canlı 2D Simülasyon',
          body:
              'Diğer menajerlerin kurduğu kadrolara karşı gerçek zamanlı simülasyonlarda yarış. Yorulan oyuncularını oyundan al, maça anında müdahale et!',
          imageUrl: 'assets/images/splash_bg.png',
        ),
        ContentItemModel(
          title: 'Revir ve Disiplin Yönetimi',
          body:
              'Sadece saha içi değil, saha dışı da önemli! Sakatlanan veya kırmızı kart gören oyuncularının yerini doğru transferler veya yedeklerle doldur.',
          imageUrl: 'assets/images/splash_bg.png',
        ),
        ContentItemModel(
          title: 'Liglere Hükmet!',
          body:
              'Kazandıkça Elo puanı topla, Süper Lig\'e kadar yüksel ve Amedspor dijital ekosisteminde efsaneleş.',
          imageUrl: 'assets/images/app_icon.png',
          actionText: 'BAŞLA',
          actionUrl: '/home',
        ),
      ],
      isActive: true,
      updatedAt: DateTime.now(),
    );
  }
}
