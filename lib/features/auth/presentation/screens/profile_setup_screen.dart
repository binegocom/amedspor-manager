import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_text_field.dart';
import '../../../../shared/components/premium_card.dart';

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
  bool isCompleting = false;
  AppUserModel? existingUser;

  final List<String> supportYears = const [
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    'Daha eski',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = authService.currentUser;
    if (user == null) return;

    final profile = await userRepository.getUser(user.uid);
    if (!mounted || profile == null) return;

    setState(() {
      existingUser = profile;
      usernameController.text = profile.username;
      cityController.text = profile.city;
      if (supportYears.contains(profile.supportYear)) {
        selectedSupportYear = profile.supportYear;
      }
    });
  }

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
    if (isCompleting) return;

    FocusManager.instance.primaryFocus?.unfocus();

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
          backgroundColor: AppColors.errorRed,
          content: Text('Kullanıcı adı boş olamaz.'),
        ),
      );
      return;
    }

    setState(() => isCompleting = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      String avatarUrl = existingUser?.avatarUrl ?? '';

      if (selectedAvatar != null) {
        avatarUrl = await storageService.uploadProfileAvatar(
          userId: user.uid,
          file: selectedAvatar!,
        );
      }

      final fcmToken = await _safeFcmToken();

      final appUser = AppUserModel(
        id: user.uid,
        username: username,
        email: user.email ?? '',
        avatarUrl: avatarUrl,
        points: existingUser?.points ?? 0,
        badges: existingUser?.badges.isNotEmpty == true
            ? existingUser!.badges
            : const ['Yeni Taraftar'],
        createdAt: existingUser?.createdAt ?? DateTime.now(),
        city: city,
        supportYear: selectedSupportYear,
        role: existingUser?.role ?? 'user',
        fcmToken: fcmToken ?? existingUser?.fcmToken,
      );

      await userRepository.createOrUpdateUser(appUser);

      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;

      setState(() => isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Profil tamamlanamadi. Lutfen tekrar deneyin.'),
        ),
      );
    }
  }

  Future<String?> _safeFcmToken() async {
    try {
      final permissionAlreadyAsked = await appStateService
          .wasNotificationPermissionAsked();

      if (!permissionAlreadyAsked) {
        await fcmService.init();
        await appStateService.setNotificationPermissionAsked();
      }

      return await fcmService.getToken();
    } catch (_) {
      return null;
    }
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
      backgroundColor: AppColors.darkBackground,
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
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.primaryRed,
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
                        color: AppColors.primaryGreen,
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

              AppTextField(
                controller: usernameController,
                label: 'Kullanıcı adı',
                icon: Icons.alternate_email_rounded,
              ),

              const SizedBox(height: 14),

              AppTextField(
                controller: cityController,
                label: 'Şehir',
                icon: Icons.location_city_rounded,
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSupportYear,
                    dropdownColor: AppColors.surface,
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

              PremiumCard(
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryGreen,
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

              AppButton(
                text: 'PROFİLİ TAMAMLA',
                isLoading: isCompleting,
                onTap: _completeSetup,
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: isCompleting ? null : () => context.go('/home'),
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
