import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/core/services/zegocloud_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ZegoCloud Configuration & Credential Validation', () {
    test('AppID and AppSign are properly configured', () {
      expect(ZegoCloudConfig.appId, 1559974965);
      expect(
        ZegoCloudConfig.appSign,
        '7b54d06dc7b66e100be3f75f0e2f9ed3e5936afd436b78eb47af9bc90392ee14',
      );
      expect(ZegoCloudConfig.scene, 1); // 1-on-1 Video Consultation
      expect(ZegoCloudConfig.platform, 4); // Flutter
    });

    test('formatRoomId standardizes appointment IDs for Zego rooms', () {
      expect(ZegoCloudConfig.formatRoomId('APT-101'), 'room_APT_101');
      expect(ZegoCloudConfig.formatRoomId('APT-202-URGENT'), 'room_APT_202_URGENT');
      expect(ZegoCloudConfig.formatRoomId('teleconsult#9842'), 'room_teleconsult_9842');
    });

    test('formatUserId sanitizes user identifiers for Zego alphanumeric requirements', () {
      expect(ZegoCloudConfig.formatUserId('9823411204'), '9823411204');
      expect(ZegoCloudConfig.formatUserId('91-4829-1029-8472'), '91_4829_1029_8472');
      expect(ZegoCloudConfig.formatUserId('doc_anjali'), 'doc_anjali');
    });
  });

  group('ZegoCloud Service Teleconsultation Session Lifecycle', () {
    final zegoService = ZegoCloudService();

    test('initializeCallSession and endCallSession manage call state cleanly', () {
      expect(zegoService.isCallActive, isFalse);

      zegoService.initializeCallSession(
        appointmentId: 'APT-101',
        userId: 'pat-001',
        userName: 'Kavita Rajesh Devi',
      );

      expect(zegoService.isCallActive, isTrue);
      expect(zegoService.activeRoomId, 'room_APT_101');

      zegoService.endCallSession();

      expect(zegoService.isCallActive, isFalse);
      expect(zegoService.activeRoomId, isNull);
    });

    test('Doctor and Patient joining same appointment connect to identical room ID', () {
      final doctorRoom = ZegoCloudConfig.formatRoomId('APT-101');
      final patientRoom = ZegoCloudConfig.formatRoomId('APT-101');

      expect(doctorRoom, patientRoom);
      expect(doctorRoom, 'room_APT_101');
    });
  });
}
