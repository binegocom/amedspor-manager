import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/services/firebase/firebase_providers.dart';
import '../../features/system/presentation/screens/account_disabled_screen.dart';
import '../../features/system/presentation/screens/force_update_screen.dart';
import '../../features/system/presentation/screens/maintenance_screen.dart';
import '../../features/system/presentation/widgets/update_available_banner.dart';
import '../widgets/offline_screen.dart';

class GlobalAppGuard extends StatefulWidget {
  final Widget child;

  const GlobalAppGuard({super.key, required this.child});

  @override
  State<GlobalAppGuard> createState() => _GlobalAppGuardState();
}

class _GlobalAppGuardState extends State<GlobalAppGuard> {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool _isMaintenanceMode = false;
  bool _isForceUpdate = false;
  bool _isUpdateAvailable = false;
  bool _updateDismissed = false;
  bool _isBanned = false;
  bool _isAdmin = false;

  StreamSubscription<DocumentSnapshot>? _appSettingsSub;
  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<User?>? _authSub;

  String _currentAppVersion = '1.0.0';
  String _updateTitle = 'Yeni sürüm hazır';
  String _updateMessage =
      'Uygulamanın yeni sürümü yayında. Güncelleyerek en güncel deneyimi kullanabilirsiniz.';
  String? _webUpdateUrl;
  String? _androidUpdateUrl;
  String? _iosUpdateUrl;
  Map<String, dynamic>? _latestAppSettings;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initPackageInfo();
    _listenToAuth();
    _listenToAppSettings();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    _checkOfflineStatus(results);

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      _checkOfflineStatus(results);
    });
  }

  void _checkOfflineStatus(List<ConnectivityResult> results) {
    setState(() {
      _isOffline = results.contains(ConnectivityResult.none);
    });
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    _currentAppVersion = info.version;
    _applyAppSettings(_latestAppSettings);
  }

  void _listenToAuth() {
    _authSub = authService.authStateChanges().listen((user) {
      _userSub?.cancel();
      if (user != null) {
        _userSub = firestoreService.users
            .doc(user.uid)
            .snapshots()
            .listen(
              (doc) {
                if (!doc.exists) return;
                final data = doc.data();
                if (data == null) return;

                if (mounted) {
                  setState(() {
                    _isBanned = data['disabled'] == true;
                    _isAdmin =
                        data['role'] == 'admin' || data['role'] == 'moderator';
                  });
                }
              },
              onError: (error) {
                debugPrint('GlobalAppGuard: User sub error: $error');
              },
            );
      } else {
        if (mounted) {
          setState(() {
            _isBanned = false;
            _isAdmin = false;
          });
        }
      }
    });
  }

  void _listenToAppSettings() {
    _appSettingsSub = firestoreService.appSettings
        .doc('main')
        .snapshots()
        .listen(
          (doc) {
            if (!doc.exists) return;
            final data = doc.data();
            if (data == null) return;

            _latestAppSettings = data;
            _applyAppSettings(data);
          },
          onError: (error) {
            debugPrint('GlobalAppGuard: AppSettings sub error: $error');
          },
        );
  }

  void _applyAppSettings(Map<String, dynamic>? data) {
    if (!mounted || data == null) return;

    setState(() {
      _isMaintenanceMode = data['maintenanceMode'] == true;
      _updateTitle = data['updateTitle'] ?? _updateTitle;
      _updateMessage = data['updateMessage'] ?? _updateMessage;
      _webUpdateUrl = data['webUpdateUrl'];
      _androidUpdateUrl = data['androidUpdateUrl'];
      _iosUpdateUrl = data['iosUpdateUrl'];

      var minVersion = '0.0.0';
      var latestVersion = '0.0.0';
      if (kIsWeb) {
        minVersion = data['minimumWebVersion'] ?? '0.0.0';
        latestVersion = data['latestWebVersion'] ?? minVersion;
      } else if (Theme.of(context).platform == TargetPlatform.android) {
        minVersion = data['minimumAndroidVersion'] ?? '0.0.0';
        latestVersion = data['latestAndroidVersion'] ?? minVersion;
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        minVersion = data['minimumIosVersion'] ?? '0.0.0';
        latestVersion = data['latestIosVersion'] ?? minVersion;
      }

      _isForceUpdate = _shouldForceUpdate(_currentAppVersion, minVersion);
      _isUpdateAvailable =
          !_isForceUpdate &&
          !_updateDismissed &&
          _shouldForceUpdate(_currentAppVersion, latestVersion);
    });
  }

  bool _shouldForceUpdate(String current, String required) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final requiredParts = required.split('.').map(int.parse).toList();

      for (var i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final r = i < requiredParts.length ? requiredParts[i] : 0;

        if (c < r) return true;
        if (c > r) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _appSettingsSub?.cancel();
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base App Router (always active beneath)
        widget.child,

        // Layering priority: Offline > Banned > Force Update > Maintenance
        if (_isOffline)
          const Positioned.fill(child: OfflineScreen())
        else if (_isBanned)
          const Positioned.fill(child: AccountDisabledScreen())
        else if (_isForceUpdate)
          Positioned.fill(
            child: ForceUpdateScreen(
              title: _updateTitle,
              message: _updateMessage,
              webUrl: _webUpdateUrl,
              androidUrl: _androidUpdateUrl,
              iosUrl: _iosUpdateUrl,
            ),
          )
        else if (_isMaintenanceMode && !_isAdmin)
          const Positioned.fill(child: MaintenanceScreen()),
        if (_isUpdateAvailable && !_isOffline && !_isBanned)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: UpdateAvailableBanner(
                title: _updateTitle,
                message: _updateMessage,
                webUrl: _webUpdateUrl,
                androidUrl: _androidUpdateUrl,
                iosUrl: _iosUpdateUrl,
                onDismiss: () {
                  setState(() {
                    _updateDismissed = true;
                    _isUpdateAvailable = false;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
