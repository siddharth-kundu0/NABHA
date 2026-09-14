import 'package:flutter/foundation.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/notification_item_dto.dart';

class NotificationRepository extends ChangeNotifier {
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal() {
    _initSampleNotifications();
  }

  final List<NotificationItemDto> _notifications = [];
  List<NotificationItemDto> get allNotifications => List.unmodifiable(_notifications);

  void _initSampleNotifications() {
    // Zero mock notifications - notifications are generated dynamically on real events
  }

  void resetToDefaults() {
    _notifications.clear();
    notifyListeners();
  }

  /// Get notifications for a specific active role
  List<NotificationItemDto> getNotificationsForRole(AppRole role) {
    return _notifications.where((n) => n.targetRole == role).toList();
  }

  /// Get unread count for badge
  int getUnreadCount(AppRole role) {
    return _notifications.where((n) => n.targetRole == role && !n.isRead).length;
  }

  /// Filter notifications for a role and category
  List<NotificationItemDto> getFilteredNotifications({
    required AppRole role,
    required String categoryFilter, // 'all', 'alerts', 'reminders', 'reports', 'referrals'
  }) {
    final roleItems = getNotificationsForRole(role);
    if (categoryFilter.toLowerCase() == 'all') {
      return roleItems;
    }
    return roleItems.where((n) {
      if (categoryFilter.toLowerCase() == 'alerts') {
        return n.category == NotificationCategory.alerts || n.isUrgent;
      }
      return n.category.name.toLowerCase() == categoryFilter.toLowerCase();
    }).toList();
  }

  /// Mark single notification as read
  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read for a role
  void markAllAsRead(AppRole role) {
    var modified = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].targetRole == role && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        modified = true;
      }
    }
    if (modified) notifyListeners();
  }

  /// Dispatch facility notification when a doctor registers
  void notifyFacilityOfDoctorRequest({
    required String facilityId,
    required String doctorName,
    required String specialty,
    required String requestId,
  }) {
    _notifications.insert(
      0,
      NotificationItemDto(
        id: 'NOTIF-FAC-${DateTime.now().millisecondsSinceEpoch % 10000}',
        targetRole: AppRole.facilityStaff,
        title: 'New Doctor Verification Request: $doctorName',
        bilingualTitle: 'नया चिकित्सक सत्यापन अनुरोध: $doctorName',
        message: '$doctorName ($specialty) has submitted verification credentials for administrative review.',
        category: NotificationCategory.verification,
        timestamp: DateTime.now(),
        isRead: false,
        isUrgent: true,
        actionLabel: 'Review Request',
        actionRoute: '/facility/approvals',
        actionPayload: {'requestId': requestId, 'facilityId': facilityId},
      ),
    );
    notifyListeners();
  }

  /// Dispatch doctor notification when facility approves affiliation
  void notifyDoctorOfApproval({
    required String doctorMobile,
    required String doctorName,
    required String generatedDoctorId,
    required String facilityName,
    required String tempOtp,
  }) {
    _notifications.insert(
      0,
      NotificationItemDto(
        id: 'NOTIF-DOC-${DateTime.now().millisecondsSinceEpoch % 10000}',
        targetRole: AppRole.doctor,
        title: 'Facility Affiliation Approved: $facilityName',
        bilingualTitle: 'रुग्णालय संबद्धता स्वीकृत: $facilityName',
        message: 'Your registration at $facilityName is approved. Unique Doctor ID: $generatedDoctorId. Activation OTP: $tempOtp.',
        category: NotificationCategory.alerts,
        timestamp: DateTime.now(),
        isRead: false,
        isUrgent: true,
        actionLabel: 'Activate Account',
        actionRoute: '/auth/doctor-activate',
        actionPayload: {'tempOtp': tempOtp, 'doctorId': generatedDoctorId},
      ),
    );
    notifyListeners();
  }

  /// Dispatch doctor notification when facility rejects
  void notifyDoctorOfRejection({
    required String doctorMobile,
    required String doctorName,
    required String facilityName,
    required String reason,
  }) {
    _notifications.insert(
      0,
      NotificationItemDto(
        id: 'NOTIF-DOC-${DateTime.now().millisecondsSinceEpoch % 10000}',
        targetRole: AppRole.doctor,
        title: 'Verification Request Rejected',
        bilingualTitle: 'सत्यापन अनुरोध अस्वीकृत',
        message: 'Your request for $facilityName was declined: $reason. Please verify your council credentials.',
        category: NotificationCategory.alerts,
        timestamp: DateTime.now(),
        isRead: false,
        isUrgent: true,
        actionLabel: 'Re-submit Details',
        actionRoute: '/auth/doctor-register',
      ),
    );
    notifyListeners();
  }

  /// Dispatch notification to Doctor when an appointment is booked
  void notifyDoctorOfAppointment({
    required String doctorName,
    required String patientName,
    required String time,
    required String type,
    required String specialty,
    required String appointmentId,
  }) {
    _notifications.insert(
      0,
      NotificationItemDto(
        id: 'NOTIF-APT-DOC-${DateTime.now().millisecondsSinceEpoch % 100000}',
        targetRole: AppRole.doctor,
        title: 'New Appointment: $patientName',
        bilingualTitle: 'नवीन अपॉइंटमेंट: $patientName',
        message: '$patientName has booked a $type ($specialty) appointment for $time.',
        category: NotificationCategory.reminders,
        timestamp: DateTime.now(),
        isRead: false,
        isUrgent: true,
        actionLabel: 'View Schedule',
        actionRoute: '/doctor/queue',
        actionPayload: {'appointmentId': appointmentId},
      ),
    );
    notifyListeners();
  }

  /// Dispatch notification to Patient when appointment is confirmed
  void notifyPatientOfAppointment({
    required String patientName,
    required String doctorName,
    required String time,
    required String type,
    required String specialty,
    required String appointmentId,
  }) {
    _notifications.insert(
      0,
      NotificationItemDto(
        id: 'NOTIF-APT-PAT-${DateTime.now().millisecondsSinceEpoch % 100000}',
        targetRole: AppRole.patient,
        title: 'Appointment Confirmed: $doctorName',
        bilingualTitle: 'अपॉइंटमेंट निश्चित: $doctorName',
        message: 'Your $type consultation with $doctorName ($specialty) is confirmed for $time.',
        category: NotificationCategory.reminders,
        timestamp: DateTime.now(),
        isRead: false,
        isUrgent: false,
        actionLabel: 'View Details',
        actionRoute: '/patient/appointments',
        actionPayload: {'appointmentId': appointmentId},
      ),
    );
    notifyListeners();
  }

  /// Dispatch urgent incoming call notification to Patient when Doctor starts calling
  void notifyPatientOfIncomingCall({
    required String patientName,
    required String doctorName,
    required String specialty,
    required String appointmentId,
    required String facilityName,
  }) {
    _notifications.insert(
      0,
      NotificationItemDto(
        id: 'NOTIF-CALL-${DateTime.now().millisecondsSinceEpoch % 100000}',
        targetRole: AppRole.patient,
        title: '📞 Incoming Teleconsultation: $doctorName',
        bilingualTitle: '📞 थेट व्हिडिओ कॉल: $doctorName',
        message: '$doctorName ($specialty) is calling you now. Tap to join the live video consultation room.',
        category: NotificationCategory.alerts,
        timestamp: DateTime.now(),
        isRead: false,
        isUrgent: true,
        actionLabel: 'Join Video Call',
        actionRoute: '/teleconsult/room',
        actionPayload: {
          'appointmentId': appointmentId,
          'doctorName': doctorName,
          'patientName': patientName,
          'specialty': specialty,
          'facilityName': facilityName,
        },
      ),
    );
    notifyListeners();
  }

  /// Dispatch notification to Doctor when Patient enters waiting room
  void notifyDoctorOfPatientWaiting({
    required String doctorName,
    required String patientName,
    required String appointmentId,
    required String specialty,
  }) {
    _notifications.insert(
      0,
      NotificationItemDto(
        id: 'NOTIF-WAIT-${DateTime.now().millisecondsSinceEpoch % 100000}',
        targetRole: AppRole.doctor,
        title: 'Patient Waiting: $patientName',
        bilingualTitle: 'रुग्ण प्रतीक्षालयात उपस्थित: $patientName',
        message: '$patientName is online in the virtual waiting room for $specialty teleconsultation.',
        category: NotificationCategory.alerts,
        timestamp: DateTime.now(),
        isRead: false,
        isUrgent: true,
        actionLabel: 'Connect Call',
        actionRoute: '/teleconsult/room',
        actionPayload: {
          'appointmentId': appointmentId,
          'patientName': patientName,
        },
      ),
    );
    notifyListeners();
  }

  /// Dispatch notification to Patient when consultation completes
  void notifyPatientOfConsultationCompleted({
    required String patientName,
    required String doctorName,
    required String appointmentId,
  }) {
    _notifications.insert(
      0,
      NotificationItemDto(
        id: 'NOTIF-END-${DateTime.now().millisecondsSinceEpoch % 100000}',
        targetRole: AppRole.patient,
        title: 'Consultation Completed: $doctorName',
        bilingualTitle: 'सल्लामसलत पूर्ण: $doctorName',
        message: 'Your teleconsultation with $doctorName has completed. Your digital prescription and clinical summary have been issued.',
        category: NotificationCategory.reports,
        timestamp: DateTime.now(),
        isRead: false,
        isUrgent: false,
        actionLabel: 'View Records',
        actionRoute: '/patient/records',
        actionPayload: {'appointmentId': appointmentId},
      ),
    );
    notifyListeners();
  }

  void dispatchNotification(NotificationItemDto notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void addNotification({
    required AppRole role,
    required String title,
    String? bilingualTitle,
    required String message,
    required NotificationCategory category,
    bool isUrgent = false,
  }) {
    dispatchNotification(
      NotificationItemDto(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}-${_notifications.length}',
        targetRole: role,
        title: title,
        bilingualTitle: bilingualTitle ?? title,
        message: message,
        category: category,
        timestamp: DateTime.now(),
        isUrgent: isUrgent,
      ),
    );
  }
}
