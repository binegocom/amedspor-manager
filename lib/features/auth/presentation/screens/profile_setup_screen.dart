import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_text_field.dart';
import '../../../../data/services/gamification_service.dart';

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

      // 🔥 Award Profile Completion XP
      await GamificationService().awardXp(
        userId: user.uid,
        amount: GamificationService.xpProfileCompleted,
        reason: 'Profil tamamlandığı için',
        eventType: 'profile_completed',
        sourceType: 'profile',
        sourceId: user.uid,
      );

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryRed.withValues(alpha: 0.05),
              AppColors.darkBackground,
              AppColors.primaryGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildDigitalFanCard(),
                const SizedBox(height: 40),
                _buildAvatarSection(),
                const SizedBox(height: 40),
                _buildFormSection(),
                const SizedBox(height: 40),
                _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Profilini Oluştur',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dijital tribündeki kimliğini tasarlıyoruz.',
          style: TextStyle(color: AppColors.muted, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDigitalFanCard() {
    return ValueListenableBuilder(
      valueListenable: usernameController,
      builder: (context, value, _) {
        return Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Amedspor Watermark
              Positioned(
                right: -40,
                bottom: -40,
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset('assets/images/app_icon.png', width: 240),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DİJİTAL TARAFTAR KARTI',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Image.asset(
                          'assets/images/app_icon.png',
                          width: 32,
                          height: 32,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildCardAvatar(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                usernameController.text.isEmpty
                                    ? 'KULLANICI ADI'
                                    : usernameController.text.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cityController.text.isEmpty
                                    ? 'ŞEHİR BELİRTİLMEDİ'
                                    : cityController.text.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCardInfo('ÜYELİK YILI', selectedSupportYear),
                        _buildCardInfo('SINIF', 'YENİ TARAFTAR'),
                        _buildCardInfo('DURUM', 'AKTİF'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardAvatar() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipOval(
        child: selectedAvatar != null
            ? Image.file(selectedAvatar!, fit: BoxFit.cover)
            : const Icon(Icons.person_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildCardInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryRed.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: selectedAvatar == null
                      ? const Icon(
                          Icons.add_a_photo_rounded,
                          color: Colors.white,
                          size: 32,
                        )
                      : ClipOval(
                          child: Image.file(selectedAvatar!, fit: BoxFit.cover),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Profil Fotoğrafı Ekle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        AppTextField(
          controller: usernameController,
          label: 'Kullanıcı Adı',
          hint: 'Tribündeki adın...',
          icon: Icons.alternate_email_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: cityController,
          label: 'Şehir',
          hint: 'Nereden destekliyorsun?',
          icon: Icons.location_on_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _buildYearSelector(),
      ],
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Destek Başlangıcı',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSupportYear,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              items: supportYears
                  .map(
                    (y) => DropdownMenuItem(
                      value: y,
                      child: Text(
                        y,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedSupportYear = v!),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      children: [
        AppButton(
          text: 'PROFİLİ TAMAMLA',
          isLoading: isCompleting,
          onTap: _completeSetup,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: isCompleting ? null : () => context.go('/home'),
          child: const Text(
            'Belki Daha Sonra',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
