import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/doctor_verification_request_dto.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';

void main() {
  group('Doctor Verification & Facility Handshake Workflow Tests', () {
    late DoctorRepository docRepo;
    late FacilityRepository facRepo;
    late NotificationRepository notifRepo;

    setUp(() {
      docRepo = DoctorRepository();
      facRepo = FacilityRepository();
      notifRepo = NotificationRepository();
    });

    test('Doctor submits verification request and facility receives notification', () {
      final req = docRepo.submitVerificationRequest(
        doctorName: 'Dr. Ramesh Tendulkar',
        doctorMobile: '9822998877',
        email: 'ramesh.t@health.gov.in',
        qualification: 'MBBS, MD',
        registrationNumber: 'MMC/2015/04/8192',
        medicalCouncil: 'Maharashtra Medical Council',
        specialty: 'Cardiology',
        targetFacilityId: 'FAC-SC-102',
        targetFacilityName: 'Kashti Sub-Centre',
      );

      expect(req.status, equals(DoctorVerificationStatus.pending));
      expect(req.doctorName, equals('Dr. Ramesh Tendulkar'));

      // Check that facility pending list includes this request
      final pending = docRepo.getPendingRequestsForFacility('FAC-SC-102');
      expect(pending.any((r) => r.id == req.id), isTrue);

      // Check that facility staff received an alert notification
      final facNotifs = notifRepo.getNotificationsForRole(AppRole.facilityStaff);
      expect(facNotifs.any((n) => n.message.contains('Dr. Ramesh Tendulkar')), isTrue);
    });

    test('Facility staff accepts doctor request, generating Doctor ID and OTP', () {
      final req = docRepo.submitVerificationRequest(
        doctorName: 'Dr. Anand Joshi',
        doctorMobile: '9822441188',
        email: 'anand.j@health.gov.in',
        qualification: 'MBBS, MS (Orthopedics)',
        registrationNumber: 'MMC/2016/09/4412',
        medicalCouncil: 'Maharashtra Medical Council',
        specialty: 'Orthopedics',
        targetFacilityId: 'FAC-SC-102',
        targetFacilityName: 'Kashti Sub-Centre',
      );

      final accepted = docRepo.acceptVerificationRequest(
        req.id,
        reviewedBy: 'Sister Sarita Patil, RN (Facility Admin)',
      );

      expect(accepted, isNotNull);
      expect(accepted!.status, equals(DoctorVerificationStatus.accepted));
      expect(accepted.generatedDoctorId, startsWith('DOC-MH-8421-'));
      expect(accepted.tempOtp, isNotNull);
      expect(accepted.tempOtp!.length, equals(6));

      // Verify doctor OTP check succeeds
      final isOtpValid = docRepo.verifyOtp(accepted.id, accepted.tempOtp!);
      expect(isOtpValid, isTrue);

      // Finalize registration with password
      final doctorAccount = docRepo.finalizeRegistration(
        requestId: accepted.id,
        password: 'securePass@123',
      );

      expect(doctorAccount.doctorId, equals(accepted.generatedDoctorId));
      expect(doctorAccount.specialty, equals('Orthopedics'));

      // Verify doctor can log in directly
      final loggedIn = docRepo.directLogin(
        identifier: accepted.generatedDoctorId!,
        password: 'securePass@123',
      );
      expect(loggedIn, isNotNull);
      expect(loggedIn!.name, equals('Dr. Anand Joshi'));

      // Verify facility roster updated
      final roster = facRepo.staffRoster;
      expect(roster.any((s) => s.name == 'Dr. Anand Joshi'), isTrue);
    });

    test('Facility staff rejects doctor request with reason', () {
      final req = docRepo.submitVerificationRequest(
        doctorName: 'Dr. Invalid Reg',
        doctorMobile: '9822110022',
        email: 'invalid@health.gov.in',
        qualification: 'MBBS',
        registrationNumber: 'FAKE/0000/00',
        medicalCouncil: 'Maharashtra Medical Council',
        specialty: 'General Medicine',
        targetFacilityId: 'FAC-SC-102',
        targetFacilityName: 'Kashti Sub-Centre',
      );

      final rejected = docRepo.rejectVerificationRequest(
        req.id,
        reason: 'Council registration could not be verified in state registry',
        reviewedBy: 'Admin In-Charge',
      );

      expect(rejected, isNotNull);
      expect(rejected!.status, equals(DoctorVerificationStatus.rejected));
      expect(rejected.rejectionReason, contains('Council registration'));
    });
  });
}
