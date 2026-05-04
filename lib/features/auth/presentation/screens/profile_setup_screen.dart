import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const String routePath = '/profile-setup';

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final usernameController = TextEditingController();
  final cityController = TextEditingController();

  final userRepository = UserRepository();

  File? selectedAvatar;
  final imagePicker = ImagePicker();

  String selectedSupportYear = '2024';

  final List<String> supportYears = const [
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    'Daha eski',
  ];

  Future<void> _pickAvatar() async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    setState(() {
      selectedAvatar = File(pickedFile.path);
    });
  }

  Future<void> _completeSetup() async {
    final username = usernameController.text.trim();
    final city = cityController.text.trim();
    final user = authService.currentUser;

    if (user == null) {
      context.go('/login');
      return;
    }

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Kullanıcı adı boş olamaz.'),
        ),
      );
      return;
    }

    String avatarUrl = '';

    if (selectedAvatar != null) {
      avatarUrl = await storageService.uploadProfileAvatar(
        userId: user.uid,
        file: selectedAvatar!,
      );
    }

    final fcmToken = await fcmService.getToken();

    await firestoreService.users.doc(user.uid).set({
      'fcmToken': fcmToken,
    }, SetOptions(merge: true));

    final appUser = AppUserModel(
      id: user.uid,
      username: username,
      email: user.email ?? '',
      avatarUrl: avatarUrl,
      points: 0,
      badges: const ['Yeni Taraftar'],
      createdAt: DateTime.now(),
      city: city,
      supportYear: selectedSupportYear,
      role: 'user',
    );

    await userRepository.createOrUpdateUser(appUser);

    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    usernameController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),

              const SizedBox(height: 24),

              const Text(
                'Profilini Oluştur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Dijital tribünde seni nasıl tanıyalım?',
                style: TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
              ),

              const SizedBox(height: 34),

              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A1A1A),
                        border: Border.all(
                          color: const Color(0xFFE53935),
                          width: 3,
                        ),
                      ),
                      child: selectedAvatar == null
                          ? const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 62,
                            )
                          : ClipOval(
                              child: Image.file(
                                selectedAvatar!,
                                width: 112,
                                height: 112,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 4,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F6A3D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              _InputField(
                controller: usernameController,
                label: 'Kullanıcı adı',
                icon: Icons.alternate_email_rounded,
              ),

              const SizedBox(height: 14),

              _InputField(
                controller: cityController,
                label: 'Şehir',
                icon: Icons.location_city_rounded,
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSupportYear,
                    dropdownColor: const Color(0xFF1A1A1A),
                    iconEnabledColor: Colors.white,
                    isExpanded: true,
                    items: supportYears
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text(
                              'Destek yılı: $year',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedSupportYear = value);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 28),

              _DarkCard(
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Color(0xFF0F6A3D),
                      child: Icon(Icons.shield_rounded, color: Colors.white),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'İlk rozetin hazır: Yeni Taraftar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'PROFİLİ TAMAMLA',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text(
                    'Sonra tamamla',
                    style: TextStyle(color: Color(0xFFB3B3B3)),
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
