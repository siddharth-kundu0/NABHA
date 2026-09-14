import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/services/firebase_auth_service.dart';
import 'package:ruralcare/core/services/hardware_vitals_telemetry_service.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/referral_dto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Auth Service & Canonical Identifiers', () {
    test('canonicalEmailForIdentifier formats mobile numbers correctly', () {
      final email = FirebaseAuthService.canonicalEmailForIdentifier('9823411204');
      expect(email, '9823411204@ruralcare.nabha.gov.in');
    });

    test('canonicalEmailForIdentifier formats ABHA IDs correctly', () {
      final email = FirebaseAuthService.canonicalEmailForIdentifier('91-4829-1029-8472');
      expect(email, '91-4829-1029-8472@ruralcare.nabha.gov.in');
    });

    test('canonicalEmailForIdentifier preserves standard email addresses', () {
      final email = FirebaseAuthService.canonicalEmailForIdentifier('doctor.anjali@nabha.gov.in');
      expect(email, 'doctor.anjali@nabha.gov.in');
    });
  });

  group('Role-Based Patient Record Isolation', () {
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();

    setUp(() {
      patientRepo.addPatient(const PatientDto(
        id: 'pat-001',
        ruralCareId: 'RC-MH-11021',
        abhaId: '91-4829-1029-8472',
        fullName: 'Kavita Rajesh Devi',
        age: 26,
        gender: 'FEMALE',
        phoneNumber: '+919823411204',
        village: 'Kashti',
        subCentre: 'Kashti Sub-Centre',
        district: 'Pune Rural',
        assignedAsha: 'Sunita Tai Gaikwad',
        emergencyContact: EmergencyContactDto(name: 'Contact', relationship: 'Family', phoneNumber: '+919823411200'),
      ));
      patientRepo.addPatient(const PatientDto(
        id: 'pat-002',
        ruralCareId: 'RC-MH-11022',
        abhaId: '91-5829-2019-1142',
        fullName: 'Ramesh Balu Jadhav',
        age: 54,
        gender: 'MALE',
        phoneNumber: '+919823411205',
        village: 'Kashti',
        subCentre: 'Kashti Sub-Centre',
        district: 'Pune Rural',
        assignedAsha: 'Sunita Tai Gaikwad',
        emergencyContact: EmergencyContactDto(name: 'Contact', relationship: 'Family', phoneNumber: '+919823411201'),
      ));
    });

    test('Patient role is strictly isolated to their own record', () {
      // Authenticate as Kavita Devi (pat-001)
      session.setAuthenticatedUser(
        uid: 'pat-001',
        email: '9823411204@ruralcare.nabha.gov.in',
        role: AppRole.patient,
        displayName: 'Kavita Rajesh Devi',
      );

      final isolatedPatients = patientRepo.patients;
      // Patient must only see their own profile
      expect(isolatedPatients.length, 1);
      expect(isolatedPatients.first.id, 'pat-001');
      expect(isolatedPatients.first.fullName, 'Kavita Rajesh Devi');
    });

    test('Health Worker (ASHA) role can access community patients in catchment', () {
      // Switch session to ASHA Worker
      session.setAuthenticatedUser(
        uid: 'asha-904',
        email: 'sunita.gaikwad@ruralcare.nabha.gov.in',
        role: AppRole.healthWorker,
        displayName: 'Sunita Tai Gaikwad',
        catchment: 'Kashti Sub-Centre',
      );

      final communityPatients = patientRepo.patients;
      // Health worker sees multiple community patients
      expect(communityPatients.length, greaterThan(1));
      expect(communityPatients.any((p) => p.id == 'pat-001'), isTrue);
    });

    test('Doctor role can access all patients for OPD consults', () {
      session.setAuthenticatedUser(
        uid: 'doc-001',
        email: 'dr.anjali@ruralcare.nabha.gov.in',
        role: AppRole.doctor,
        displayName: 'Dr. Anjali Patil',
      );

      final doctorPatients = patientRepo.patients;
      expect(doctorPatients.length, greaterThan(1));
    });
  });

  group('Appointment & Referral Data Scoping', () {
    final apptRepo = AppointmentRepository();
    final refRepo = ReferralRepository();
    final session = SessionCoordinator();

    setUp(() {
      apptRepo.addAppointment(AppointmentDto(
        id: 'APT-TEST-1',
        patientId: 'pat-001',
        patientName: 'Kavita Rajesh Devi',
        doctorName: 'Dr. Anjali Patil',
        specialty: 'Obstetrics',
        facilityName: 'SDH Baramati',
        scheduledTime: DateTime.now(),
        type: 'TELECONSULTATION',
        status: 'CONFIRMED',
        chiefComplaint: 'Routine checkup',
      ));
      refRepo.addReferral(ReferralDto(
        id: 'REF-TEST-1',
        patientId: 'pat-001',
        patientName: 'Kavita Rajesh Devi',
        patientAge: 26,
        patientGender: 'FEMALE',
        patientPhone: '+919823411204',
        patientVillage: 'Kashti',
        patientDistrict: 'Pune Rural',
        referringFacility: 'Kashti SC',
        targetFacilityId: 'FAC-SDH-301',
        targetFacilityName: 'Baramati SDH',
        reason: 'Gestational check',
        urgency: 'URGENT',
        requiredSpecialty: 'OB/GYN',
        status: 'HOSPITAL_NOTIFIED',
        createdAt: DateTime.now(),
        recommendationRationale: 'Specialty care needed',
      ));
    });

    test('Patient only views their own appointments and referrals', () {
      session.setAuthenticatedUser(
        uid: 'pat-001',
        role: AppRole.patient,
        displayName: 'Kavita Rajesh Devi',
      );

      final patientAppts = apptRepo.appointments;
      expect(patientAppts.isNotEmpty, isTrue);
      for (final apt in patientAppts) {
        expect(apt.patientId == 'pat-001' || apt.patientName == 'Kavita Rajesh Devi', isTrue);
      }

      final patientRefs = refRepo.referrals;
      expect(patientRefs.isNotEmpty, isTrue);
      for (final ref in patientRefs) {
        expect(ref.patientId == 'pat-001' || ref.patientName == 'Kavita Rajesh Devi', isTrue);
      }
    });
  });

  group('Hardware Heartbeat & Vitals Telemetry Ingestion', () {
    final telemetryService = HardwareVitalsTelemetryService();
    final patientRepo = PatientRepository();

    test('ingestHardwareReading updates patient latestVitals with sensor telemetry', () async {
      patientRepo.addPatient(const PatientDto(
        id: 'pat-001',
        ruralCareId: 'RC-MH-11021',
        abhaId: '91-4829-1029-8472',
        fullName: 'Kavita Rajesh Devi',
        age: 26,
        gender: 'FEMALE',
        phoneNumber: '+919823411204',
        village: 'Kashti',
        subCentre: 'Kashti Sub-Centre',
        district: 'Pune Rural',
        assignedAsha: 'Sunita Tai Gaikwad',
        emergencyContact: EmergencyContactDto(name: 'Contact', relationship: 'Family', phoneNumber: '+919823411200'),
      ));

      await telemetryService.ingestHardwareReading(
        patientId: 'pat-001',
        pulse: 86,
        spO2: 99,
        temperature: 98.4,
        systolicBp: 124,
        diastolicBp: 82,
        sensorDeviceId: 'BLE-HARDWARE-HEARTBEAT-V1',
      );

      final patient = patientRepo.getPatientById('pat-001');
      expect(patient, isNotNull);
      expect(patient!.latestVitals, isNotNull);
      expect(patient.latestVitals!.pulse, 86);
      expect(patient.latestVitals!.spO2, 99);
      expect(patient.latestVitals!.temperature, 98.4);
      expect(patient.latestVitals!.isFromBleDevice, isTrue);
      expect(patient.latestVitals!.recordedByRole, 'HARDWARE_BLE');
    });

    test('getOrCreatePatientForIdentifier auto-provisions patient on direct mobile sign in', () {
      final session = SessionCoordinator();
      final patient = patientRepo.getOrCreatePatientForIdentifier('8307165924');
      expect(patient, isNotNull);
      expect(patient.phoneNumber, contains('8307165924'));
      expect(patientRepo.activePatient?.id, patient.id);

      session.setAuthenticatedUser(
        uid: patient.id,
        email: '8307165924@ruralcare.nabha.gov.in',
        role: AppRole.patient,
        displayName: patient.fullName,
      );

      final scoped = patientRepo.patients;
      expect(scoped.length, 1);
      expect(scoped.first.phoneNumber, contains('8307165924'));
    });
  });
}

