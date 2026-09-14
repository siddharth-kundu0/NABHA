import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/notification_item_dto.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';

void main() {
  group('Cross-Profile Notification System Tests', () {
    late NotificationRepository notifRepo;

    setUp(() {
      notifRepo = NotificationRepository();
      notifRepo.resetToDefaults();
      notifRepo.addNotification(
        role: AppRole.patient,
        title: 'Teleconsultation Reminder',
        message: 'Your teleconsultation with Dr. Anita Roy is scheduled.',
        category: NotificationCategory.reminders,
      );
      notifRepo.addNotification(
        role: AppRole.doctor,
        title: 'Patient in Waiting Room',
        message: 'Patient waiting for teleconsultation.',
        category: NotificationCategory.alerts,
        isUrgent: true,
      );
      notifRepo.addNotification(
        role: AppRole.healthWorker,
        title: 'High Risk Alert',
        message: 'Patient with elevated BP flagged.',
        category: NotificationCategory.alerts,
      );
      notifRepo.addNotification(
        role: AppRole.facilityStaff,
        title: 'Emergency Inbound Referral',
        message: 'Ambulance dispatched.',
        category: NotificationCategory.alerts,
      );
    });

    test('Each profile receives dedicated typed notifications', () {
      final patientNotifs = notifRepo.getNotificationsForRole(AppRole.patient);
      final doctorNotifs = notifRepo.getNotificationsForRole(AppRole.doctor);
      final hwNotifs = notifRepo.getNotificationsForRole(AppRole.healthWorker);
      final facNotifs = notifRepo.getNotificationsForRole(AppRole.facilityStaff);

      expect(patientNotifs, isNotEmpty);
      expect(doctorNotifs, isNotEmpty);
      expect(hwNotifs, isNotEmpty);
      expect(facNotifs, isNotEmpty);

      // Verify patient has teleconsultation reminder
      expect(patientNotifs.any((n) => n.category == NotificationCategory.reminders), isTrue);

      // Verify doctor has waiting room alert
      expect(doctorNotifs.any((n) => n.isUrgent), isTrue);

      // Verify health worker has high risk alert
      expect(hwNotifs.any((n) => n.category == NotificationCategory.alerts), isTrue);

      // Verify facility has emergency pre-alert or verification alert
      expect(facNotifs.any((n) => n.category == NotificationCategory.verification || n.category == NotificationCategory.alerts), isTrue);
    });

    test('Unread count tracking and mark all as read', () {
      final initialUnread = notifRepo.getUnreadCount(AppRole.patient);
      expect(initialUnread, greaterThanOrEqualTo(1));

      notifRepo.markAllAsRead(AppRole.patient);

      final finalUnread = notifRepo.getUnreadCount(AppRole.patient);
      expect(finalUnread, equals(0));
    });

    test('Category filtering works accurately', () {
      final allPatient = notifRepo.getFilteredNotifications(
        role: AppRole.patient,
        categoryFilter: 'all',
      );
      final alertsOnly = notifRepo.getFilteredNotifications(
        role: AppRole.patient,
        categoryFilter: 'alerts',
      );

      expect(allPatient.length, greaterThanOrEqualTo(alertsOnly.length));
      for (final a in alertsOnly) {
        expect(a.category == NotificationCategory.alerts || a.isUrgent, isTrue);
      }
    });
  });
}
