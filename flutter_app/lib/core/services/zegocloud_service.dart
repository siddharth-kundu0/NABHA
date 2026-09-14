import 'package:flutter/foundation.dart';

class ZegoCloudConfig {
  static const int appId = 1559974965;
  static const String appSign =
      '7b54d06dc7b66e100be3f75f0e2f9ed3e5936afd436b78eb47af9bc90392ee14';
  static const int scene = 1; // 1-on-1 Teleconsultation Call
  static const int platform = 4; // Flutter

  /// Cleans an appointment ID or consultation token into a valid ZegoCloud room ID
  static String formatRoomId(String appointmentId) {
    final clean = appointmentId
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return 'room_$clean';
  }

  /// Cleans an identifier or phone number into a valid ZegoCloud user ID
  static String formatUserId(String identifier) {
    final clean = identifier
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return clean.isNotEmpty ? clean : 'user_${DateTime.now().millisecondsSinceEpoch % 10000}';
  }
}

class ZegoCloudService {
  static final ZegoCloudService _instance = ZegoCloudService._internal();
  factory ZegoCloudService() => _instance;
  ZegoCloudService._internal();

  int get appId => ZegoCloudConfig.appId;
  String get appSign => ZegoCloudConfig.appSign;

  bool _isCallActive = false;
  String? _activeRoomId;
  String? _activeUserId;
  String? _activeUserName;

  bool get isCallActive => _isCallActive;
  String? get activeRoomId => _activeRoomId;

  /// Initializes a 1-on-1 teleconsultation call session between doctor and patient
  void initializeCallSession({
    required String appointmentId,
    required String userId,
    required String userName,
  }) {
    _activeRoomId = ZegoCloudConfig.formatRoomId(appointmentId);
    _activeUserId = ZegoCloudConfig.formatUserId(userId);
    _activeUserName = userName.trim().isNotEmpty ? userName.trim() : 'Participant';
    _isCallActive = true;

    debugPrint('ZegoCloud Call Initialized -> Room: $_activeRoomId, User: $_activeUserId ($_activeUserName), AppID: $appId');
  }

  /// Ends the active call session
  void endCallSession() {
    debugPrint('ZegoCloud Call Terminated -> Room: $_activeRoomId');
    _isCallActive = false;
    _activeRoomId = null;
    _activeUserId = null;
    _activeUserName = null;
  }
}
