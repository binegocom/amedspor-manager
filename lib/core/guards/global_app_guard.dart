import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/services/firebase/firebase_providers.dart';
import '../widgets/banned_screen.dart';
import '../widgets/force_update_screen.dart';
import '../widgets/maintenance_screen.dart';
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
  bool _isBanned = false;
  bool _isAdmin = false;
  
  StreamSubscription<DocumentSnapshot>? _appSettingsSub;
  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<User?>? _authSub;

  String _currentAppVersion = '1.0.0';

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

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((results) {
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
  }

  void _listenToAuth() {
    _authSub = authService.authStateChanges().listen((user) {
      _userSub?.cancel();
      if (user != null) {
        _userSub = firestoreService.users.doc(user.uid).snapshots().listen((doc) {
          if (!doc.exists) return;
          final data = doc.data();
          if (data == null) return;

          setState(() {
            _isBanned = data['disabled'] == true;
            _isAdmin = data['role'] == 'admin' || data['role'] == 'moderator';
          });
        });
      } else {
        setState(() {
          _isBanned = false;
          _isAdmin = false;
        });
      }
    });
  }

  void _listenToAppSettings() {
    _appSettingsSub = firestoreService.appSettings.doc('main').snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      setState(() {
        _isMaintenanceMode = data['maintenanceMode'] == true;
        final minVersion = data['minAppVersion'] as String?;
        if (minVersion != null) {
          _isForceUpdate = _shouldForceUpdate(_currentAppVersion, minVersion);
        } else {
          _isForceUpdate = false;
        }
      });
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
          const Positioned.fill(child: BannedScreen())
        else if (_isForceUpdate)
          const Positioned.fill(child: ForceUpdateScreen())
        else if (_isMaintenanceMode && !_isAdmin)
          Positioned.fill(
            child: MaintenanceScreen(
              onAdminBypass: () => setState(() => _isAdmin = true), // Fallback locally if they manage to authenticate as admin
            ),
          ),
      ],
    );
  }
}
