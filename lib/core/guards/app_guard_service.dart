import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppGuardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for settings
  Map<String, dynamic>? _settings;

  Future<void> init() async {
    try {
      final doc = await _firestore.collection('appSettings').doc('main').get();
      _settings = doc.data();
    } catch (e) {
      if (kDebugMode) print('Error initializing AppGuardService: $e');
    }
  }

  bool get isMaintenanceMode => _settings?['maintenanceMode'] ?? false;

  Future<bool> isUpdateRequired() async {
    if (_settings == null) return false;

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    
    String minVersion = '0.0.0';
    if (kIsWeb) {
      minVersion = _settings?['minimumWebVersion'] ?? '0.0.0';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      minVersion = _settings?['minimumAndroidVersion'] ?? '0.0.0';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      minVersion = _settings?['minimumIosVersion'] ?? '0.0.0';
    }

    return _isVersionLower(currentVersion, minVersion);
  }

  bool _isVersionLower(String current, String required) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> requiredParts = required.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      int c = currentParts.length > i ? currentParts[i] : 0;
      int r = requiredParts.length > i ? requiredParts[i] : 0;
      if (c < r) return true;
      if (c > r) return false;
    }
    return false;
  }

  bool isFeatureEnabled(String featureKey) {
    return _settings?['features']?[featureKey] ?? true;
  }
}
