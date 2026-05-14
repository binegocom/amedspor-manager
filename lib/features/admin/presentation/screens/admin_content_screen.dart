import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/app_content_model.dart';
import '../../../../data/repositories/app_content_repository.dart';
import '../widgets/admin_layout.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  static const String routePath = '/admin/content';

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final _repository = AppContentRepository();
  List<AppContentModel> _contents = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tümü';

  final List<String> _categories = ['Tümü', 'onboarding', 'page', 'banner'];

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getAllContents();
      setState(() {
        _contents = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(AppContentModel? existingContent) {
    final isNew = existingContent == null;
    final idController = TextEditingController(text: existingContent?.id ?? '');
    final titleController = TextEditingController(
      text: existingContent?.title ?? '',
    );
    String category = existingContent?.category ?? 'onboarding';
    bool isActive = existingContent?.isActive ?? true;

    // Deep copy items for local dialog editing
    List<ContentItemModel> items =
        existingContent?.items.map((i) => i.copyWith()).toList() ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF161616),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.white10),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880, maxHeight: 720),
              child: Column(
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_document,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          isNew
                              ? 'Yeni İçerik Bloğu'
                              : 'İçeriği Düzenle: ${existingContent.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: isActive,
                          activeThumbColor: AppColors.primaryGreen,
                          onChanged: (val) =>
                              setDialogState(() => isActive = val),
                        ),
                        const Text(
                          'Aktif',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dialog Body
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Form side
                        Expanded(
                          flex: 5,
                          child: ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              if (isNew) ...[
                                TextField(
                                  controller: idController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Kayıt ID (Örn: rules_2026)',
                                    labelStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: Colors.black26,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextField(
                                controller: titleController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Grup / Başlık Adı',
                                  labelStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: category,
                                dropdownColor: const Color(0xFF222222),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Kategori',
                                  labelStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'onboarding',
                                    child: Text('Karşılama Slaytı'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'page',
                                    child: Text('Statik Sayfa (SSS/Hakkında)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'banner',
                                    child: Text('Duyuru Banner'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => category = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Slaytlar / Blok Elemanları',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        items.add(
                                          const ContentItemModel(
                                            title: 'Yeni Başlık',
                                            body: 'Açıklama metni...',
                                            imageUrl:
                                                'https://images.unsplash.com/photo-placeholder',
                                          ),
                                        );
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryGreen,
                                    ),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('SLAYT EKLE'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'Henüz slayt eklenmedi.',
                                      style: TextStyle(color: Colors.white38),
                                    ),
                                  ),
                                )
                              else
                                ...items.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  return Card(
                                    color: Colors.black12,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                        color: Colors.white10,
                                      ),
                                    ),
                                    child: ExpansionTile(
                                      title: Text(
                                        '${idx + 1}. ${item.title}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        item.body,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.primaryRed,
                                        ),
                                        onPressed: () {
                                          setDialogState(
                                            () => items.removeAt(idx),
                                          );
                                        },
                                      ),
                                      childrenPadding: const EdgeInsets.all(16),
                                      children: [
                                        TextFormField(
                                          initialValue: item.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'Başlık',
                                            labelStyle: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          onChanged: (v) => items[idx] =
                                              items[idx].copyWith(title: v),
                                        ),
                                        TextFormField(
                                          initialValue: item.body,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'İçerik/Açıklama',
                                            labelStyle: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          onChanged: (v) => items[idx] =
                                              items[idx].copyWith(body: v),
                                        ),
                                        TextFormField(
                                          initialValue: item.imageUrl,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Görsel URL (asset/https)',
                                            labelStyle: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          onChanged: (v) => items[idx] =
                                              items[idx].copyWith(imageUrl: v),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: item.actionText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Buton Metni',
                                                      labelStyle: TextStyle(
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                onChanged: (v) => items[idx] =
                                                    items[idx].copyWith(
                                                      actionText: v,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: item.actionUrl,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Yönlendirme Linki',
                                                      labelStyle: TextStyle(
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                onChanged: (v) =>
                                                    items[idx] = items[idx]
                                                        .copyWith(actionUrl: v),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),

                        // Right Live Render Preview Side
                        Expanded(
                          flex: 4,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.phone_android,
                                      color: Colors.white38,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Canlı Mobil Önizleme',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Container(
                                    width: 280,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 4,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: items.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Boş Ekran',
                                              style: TextStyle(
                                                color: Colors.white38,
                                              ),
                                            ),
                                          )
                                        : DefaultTabController(
                                            length: items.length,
                                            child: Stack(
                                              children: [
                                                TabBarView(
                                                  children: items.map((slide) {
                                                    final isAsset = slide
                                                        .imageUrl
                                                        .startsWith('assets/');
                                                    return Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        if (slide
                                                            .imageUrl
                                                            .isNotEmpty)
                                                          isAsset
                                                              ? Image.asset(
                                                                  slide
                                                                      .imageUrl,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (
                                                                        _,
                                                                        _,
                                                                        _,
                                                                      ) =>
                                                                          const Placeholder(),
                                                                )
                                                              : Image.network(
                                                                  slide
                                                                      .imageUrl,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (
                                                                        _,
                                                                        _,
                                                                        _,
                                                                      ) =>
                                                                          const Placeholder(),
                                                                ),
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                Colors
                                                                    .transparent,
                                                                Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.8,
                                                                    ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          left: 16,
                                                          right: 16,
                                                          bottom: 40,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                slide.title,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 6,
                                                              ),
                                                              Text(
                                                                slide.body,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 3,
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                              if (slide
                                                                  .actionText
                                                                  .isNotEmpty) ...[
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () {},
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        AppColors
                                                                            .primaryGreen,
                                                                    minimumSize:
                                                                        const Size(
                                                                          120,
                                                                          32,
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    slide
                                                                        .actionText,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                                Positioned(
                                                  bottom: 12,
                                                  left: 0,
                                                  right: 0,
                                                  child: TabPageSelector(
                                                    color: Colors.white38,
                                                    selectedColor:
                                                        AppColors.primaryRed,
                                                    indicatorSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dialog Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İPTAL'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final targetId = isNew
                                ? idController.text.trim()
                                : existingContent.id;
                            if (targetId.isEmpty) return;

                            final newModel = AppContentModel(
                              id: targetId,
                              title: titleController.text.trim(),
                              category: category,
                              items: items,
                              isActive: isActive,
                              updatedAt: DateTime.now(),
                            );

                            Navigator.pop(context);
                            await _repository.saveContent(newModel);
                            _loadContents();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('KAYDET VE YAYINLA'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'Tümü'
        ? _contents
        : _contents.where((c) => c.category == _selectedCategory).toList();

    return AdminLayout(
      activeRoute: AdminContentScreen.routePath,
      title: 'Dinamik İçerik CMS',
      subtitle:
          'Karşılama slaytları, kural sayfaları ve duyuru bloklarını anında güncelle.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showEditDialog(null),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('YENİ BLOK OLUŞTUR'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: _categories.map((cat) {
                final active = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.toUpperCase()),
                    selected: active,
                    selectedColor: AppColors.primaryRed.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryRed,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppColors.muted,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Content grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  )
                : filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Bu kategoride içerik bulunmuyor.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisExtent: 210,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Card(
                        color: const Color(0xFF161616),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: item.isActive
                                ? Colors.white10
                                : AppColors.errorRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.category == 'onboarding'
                                          ? AppColors.gold.withValues(
                                              alpha: 0.15,
                                            )
                                          : const Color(
                                              0xFF2E7DFF,
                                            ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.category.toUpperCase(),
                                      style: TextStyle(
                                        color: item.category == 'onboarding'
                                            ? AppColors.gold
                                            : const Color(0xFF2E7DFF),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    item.isActive
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: item.isActive
                                        ? AppColors.primaryGreen
                                        : AppColors.muted,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.title.isEmpty ? item.id : item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.items.length} Slayt/Blok  •  ID: ${item.id}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (item.id != 'onboarding')
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.primaryRed,
                                        size: 18,
                                      ),
                                      onPressed: () async {
                                        final c = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: const Color(
                                              0xFF222222,
                                            ),
                                            title: const Text(
                                              'İçeriği Sil',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            content: const Text(
                                              'Bu CMS bloğu silinecektir. Onaylıyor musunuz?',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('İPTAL'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.primaryRed,
                                                ),
                                                child: const Text('SİL'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (c == true) {
                                          await _repository.deleteContent(
                                            item.id,
                                          );
                                          _loadContents();
                                        }
                                      },
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: () => _showEditDialog(item),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit, size: 14),
                                    label: const Text(
                                      'DÜZENLE',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
