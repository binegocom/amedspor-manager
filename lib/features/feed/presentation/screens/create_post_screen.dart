import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

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

  final List<String> categories = const [
    'Maç Yorumu',
    'Kadro',
    'Transfer',
    'Tribün',
  ];

  Future<void> _publishPost() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final user = authService.currentUser;

    if (user == null) {
      context.go('/login');
      return;
    }

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Başlık ve içerik boş olamaz.'),
        ),
      );
      return;
    }

    final post = PostModel(
      id: uuid.v4(),
      userId: user.uid,
      username: user.email ?? 'Taraftar',
      title: title,
      content: content,
      category: selectedCategory,
      likes: 0,
      commentsCount: 0,
      createdAt: DateTime.now(),
    );

    await postRepository.createPost(post);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0F6A3D),
        content: Text('Post yayınlandı.'),
      ),
    );

    context.go('/feed');
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
                onBack: () => context.go('/feed'),
              ),

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
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 26),

              _DarkCard(
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
                                  ? const Color(0xFF0F6A3D)
                                  : const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF0F6A3D)
                                    : Colors.white10,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : const Color(0xFFB3B3B3),
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
                minLines: 7,
                maxLines: 10,
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFE53935),
                decoration: InputDecoration(
                  labelText: 'İçerik',
                  alignLabelWithHint: true,
                  labelStyle: const TextStyle(color: Color(0xFFB3B3B3)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 126),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF0F6A3D),
                    ),
                  ),
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

              const SizedBox(height: 16),

              _DarkCard(
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Color(0xFFE53935),
                      child: Icon(Icons.info_rounded, color: Colors.white),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Hakaret, küfür ve provokatif içerikler moderasyon tarafından kaldırılır.',
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
                  onPressed: _publishPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'YAYINLA',
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
      cursorColor: const Color(0xFFE53935),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB3B3B3)),
        prefixIcon: Icon(icon, color: const Color(0xFF0F6A3D)),
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