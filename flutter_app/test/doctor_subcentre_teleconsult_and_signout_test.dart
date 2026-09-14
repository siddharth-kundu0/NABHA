import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/features/teleconsult/screens/teleconsultation_landing_screen.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_profile_tab.dart';

void main() {
  setUp(() {
    DoctorRepository().resetToDefaults();
    PatientRepository().resetToDefaults();
    SessionCoordinator().switchLanguage('en');
    SessionCoordinator().resetToOnboarding();
  });

  test('DoctorRepository has zero mock data by default and autoSelectDoctor returns null', () {
    final docRepo = DoctorRepository();
    docRepo.resetToDefaults();

    expect(docRepo.registeredDoctors.isEmpty, true);
    expect(docRepo.autoSelectDoctor(), isNull);
    expect(docRepo.autoSelectDoctor(subCentre: 'Kashti Sub-Centre'), isNull);
  });

  test('Doctor and Patient Sub-Centre matching connects clinician', () {
    final docRepo = DoctorRepository();
    docRepo.resetToDefaults();

    // Register a doctor affiliated with Kashti Sub-Centre
    final registered = docRepo.registerDoctorDirectly(
      name: 'Dr. Siddharth Kundu',
      mobile: '9876543210',
      specialty: 'General Medicine',
      qualification: 'MBBS, MD',
      registrationNumber: 'MMC-2026-9999',
      facilityId: 'FAC-SC-102',
      facilityName: 'Kashti Sub-Centre (उप-केंद्र)',
    );

    expect(docRepo.registeredDoctors.length, 1);
    expect(docRepo.registeredDoctors.first.name, 'Dr. Siddharth Kundu');

    // Query for Kashti Sub-Centre
    final matches = docRepo.getDoctorsForSubCentre(subCentre: 'Kashti Sub-Centre');
    expect(matches.length, 1);
    expect(matches.first.doctorId, registered.doctorId);

    // Query for different sub-centre
    final noMatches = docRepo.getDoctorsForSubCentre(subCentre: 'Rampur Sub-Centre');
    expect(noMatches.isEmpty, true);

    // Auto-select for Kashti
    final autoKashti = docRepo.autoSelectDoctor(subCentre: 'Kashti Sub-Centre');
    expect(autoKashti?.name, 'Dr. Siddharth Kundu');
  });

  testWidgets('Teleconsultation shows No Doctors Available empty state when zero doctors registered', (tester) async {
    DoctorRepository().resetToDefaults();
    PatientRepository().resetToDefaults();

    PatientRepository().addPatient(
      const PatientDto(
        id: 'pat-kashti-01',
        ruralCareId: 'RC-101',
        abhaId: 'ABHA-101',
        fullName: 'Aarav Patil',
        age: 30,
        gender: 'Male',
        phoneNumber: '9123456780',
        village: 'Kashti',
        subCentre: 'Kashti Sub-Centre',
        district: 'Pune Rural',
        assignedAsha: 'Sunita Tai',
        emergencyContact: EmergencyContactDto(
          name: 'Contact',
          relationship: 'Parent',
          phoneNumber: '9123456780',
        ),
      ),
    );

    final session = SessionCoordinator();
    session.setAuthenticatedUser(
      uid: 'pat-kashti-01',
      role: AppRole.patient,
      displayName: 'Aarav Patil',
      catchment: 'Kashti Sub-Centre',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeleconsultationLandingScreen(initialStep: 1),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Verify empty state is displayed
    expect(find.text('No doctors available'), findsOneWidget);
    expect(find.textContaining('No verified doctor is currently registered for your sub-centre'), findsOneWidget);
    expect(find.text('No Doctors Available'), findsOneWidget); // Button disabled state label
  });

  testWidgets('Doctor Profile tab includes Sign Out button and handles sign out flow', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = SessionCoordinator();
    session.setAuthenticatedUser(
      uid: 'DOC-MH-TEST',
      role: AppRole.doctor,
      displayName: 'Dr. Test Clinician',
      catchment: 'Kashti Sub-Centre',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DoctorProfileTab(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Sign Out button is present
    final signOutBtn = find.byKey(const ValueKey('doctor_sign_out_button'));
    expect(signOutBtn, findsOneWidget);
    expect(find.text('Sign Out'), findsWidgets);

    // 2. Scroll into view and tap Sign Out to trigger confirmation dialog
    await tester.ensureVisible(signOutBtn);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(signOutBtn);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Confirm Sign Out'), findsOneWidget);
    expect(find.textContaining('Are you sure you want to sign out from the NABHA Clinician Portal?'), findsOneWidget);

    // 3. Confirm Sign Out inside AlertDialog
    final confirmBtn = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(ElevatedButton, 'Sign Out'),
    );
    await tester.tap(confirmBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // Session should be cleared and onboarding reset
    expect(session.currentUserId, isNull);
    expect(session.hasCompletedOnboarding, false);
  });

  test('PatientRepository getOrCreatePatientForIdentifier dynamically resolves without mock data', () {
    final patientRepo = PatientRepository();
    patientRepo.resetToDefaults();

    expect(patientRepo.patients.isEmpty, true);

    // Auto-provisioning mock patients is disabled
    final dynamicPatient = patientRepo.getOrCreatePatientForIdentifier('Sunita Sharma', subCentre: 'Kashti Sub-Centre');
    expect(dynamicPatient, isNull);
  });

  testWidgets('LiveTeleconsultRoomScreen displays remote participant based on user role', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = SessionCoordinator();

    // 1. Patient perspective: Main video frame displays Doctor Name and Specialty + Facility
    session.setAuthenticatedUser(
      uid: 'pat-001',
      role: AppRole.patient,
      displayName: 'Ramesh Patil',
      catchment: 'Kashti Sub-Centre',
      facilityId: 'FAC-SC-102',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LiveTeleconsultRoomScreen(
          patientName: 'Ramesh Patil',
          doctorName: 'Dr. Siddharth Kundu',
          specialty: 'General Medicine',
          facilityName: 'Kashti Sub-Centre (उप-केंद्र)',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Remote frame has Doctor name and speaking indicator
    expect(find.text('Dr. Siddharth Kundu'), findsWidgets);
    expect(find.text('Dr. Siddharth Kundu speaking'), findsOneWidget);
    expect(find.text('General Medicine • Kashti Sub-Centre (उप-केंद्र)'), findsOneWidget);
    expect(find.text('• Kashti Sub-Centre (उप-केंद्र)'), findsOneWidget);

    // 2. Doctor perspective: Main video frame displays Patient Name
    session.setAuthenticatedUser(
      uid: 'doc-001',
      role: AppRole.doctor,
      displayName: 'Dr. Siddharth Kundu',
      catchment: 'Kashti Sub-Centre (उप-केंद्र)',
      facilityId: 'FAC-SC-102',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LiveTeleconsultRoomScreen(
          patientName: 'Ramesh Patil',
          doctorName: 'Dr. Siddharth Kundu',
          specialty: 'General Medicine',
          facilityName: 'Kashti Sub-Centre (उप-केंद्र)',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ramesh Patil'), findsWidgets);
    expect(find.text('Ramesh Patil speaking'), findsOneWidget);
    expect(find.text('Patient • Kashti Sub-Centre (उप-केंद्र)'), findsOneWidget);
  });
}
