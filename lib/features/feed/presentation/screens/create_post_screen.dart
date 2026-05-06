import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  static const String routePath = '/create-post';

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  final postRepository = PostRepository();
  final uuid = const Uuid();

  String selectedCategory = 'Maç Yorumu';
  bool isPublishing = false;
  XFile? selectedImage;
  final picker = ImagePicker();

  final List<String> categories = const [
    'Maç Yorumu',
    'Kadro',
    'Transfer',
    'Tribün',
  ];

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlık ve içerik girin.')),
      );
      return;
    }

    final user = authService.currentUser;
    if (user == null) return;

    final postId = uuid.v4();
    String? imageUrl;

    setState(() => isPublishing = true);

    try {
      if (selectedImage != null) {
        imageUrl = await storageService.uploadPostImage(
          postId: postId,
          file: File(selectedImage!.path),
        );
      }

      final post = PostModel(
        id: postId,
        userId: user.uid,
        username: user.email ?? 'Taraftar',
        title: title,
        content: content,
        category: selectedCategory,
        likes: 0,
        commentsCount: 0,
        lineupId: '',
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await postRepository.createPost(post);
    } catch (e) {
      if (!mounted) return;
      setState(() => isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Hata: $e'),
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primaryGreen,
        content: Text('Post yayınlandı.'),
      ),
    );

    context.go('/feed');
  }

  Future<void> _pickImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => selectedImage = image);
    }
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
              _Header(onBack: () => context.go('/feed')),

              const SizedBox(height: 24),

              const Text(
                'Taraftar paylaşımı oluştur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Maç yorumu, kadro fikri veya tribün çağrısı paylaş.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),

              const SizedBox(height: 26),

              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((category) {
                        final active = selectedCategory == category;

                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedCategory = category);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primaryGreen
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: active
                                    ? AppColors.primaryGreen
                                    : Colors.white10,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : AppColors.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _InputField(
                controller: titleController,
                label: 'Başlık',
                icon: Icons.title_rounded,
              ),

              const SizedBox(height: 14),

              TextField(
                controller: contentController,
                minLines: 5,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                cursorColor: AppColors.primaryRed,
                decoration: InputDecoration(
                  labelText: 'İçerik',
                  alignLabelWithHint: true,
                  labelStyle: const TextStyle(color: AppColors.muted),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.edit_rounded, color: AppColors.primaryGreen),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.primaryRed),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Görsel Ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickImage,
                child: PremiumCard(
                  padding: EdgeInsets.zero,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.file(
                              File(selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate_rounded, color: AppColors.muted, size: 40),
                              SizedBox(height: 8),
                              Text('Fotoğraf Seç', style: TextStyle(color: AppColors.muted)),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              PremiumCard(
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryRed,
                      child: Icon(Icons.info_rounded, color: Colors.white),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Hakaret, küfür ve provokatif içerikler moderasyon tarafından kaldırılır.',
                        style: TextStyle(
                          color: AppColors.muted,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              AppButton(
                text: 'YAYINLA',
                isLoading: isPublishing,
                onTap: _publishPost,
              ),
            ],
          ),
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
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const SizedBox(width: 4),
        const Text(
          'Post Oluştur',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: AppColors.primaryRed,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primaryRed),
        ),
      ),
    );
  }
}
