import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/main.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/consent_repository.dart';
import 'package:ruralcare/features/doctor/screens/doctor_care_plan_screen.dart';
import 'package:ruralcare/features/doctor/screens/doctor_clinical_summary_screen.dart';
import 'package:ruralcare/features/doctor/screens/doctor_consultation_completed_screen.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_home_tab.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_patients_tab.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_profile_tab.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_queue_tab.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_referrals_tab.dart';

import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';

void main() {
  setUp(() {
    final aptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();
    final consentRepo = ConsentRepository();

    aptRepo.resetToDefaults();
    patientRepo.resetToDefaults();
    consentRepo.resetToDefaults();
    SessionCoordinator().switchLanguage('en');
    SessionCoordinator().completeOnboarding();

    patientRepo.addPatient(
      const PatientDto(
        id: 'pat-001',
        ruralCareId: 'RC-001',
        abhaId: 'ABHA-001',
        fullName: 'Ramesh Sharma',
        age: 45,
        gender: 'Male',
        phoneNumber: '9876543210',
        village: 'Rampur',
        subCentre: 'Rampur Health Sub-Centre',
        district: 'Bilaspur',
        assignedAsha: 'Sunita Bai',
        emergencyContact: EmergencyContactDto(
          name: 'Contact',
          relationship: 'Family',
          phoneNumber: '9876543210',
        ),
      ),
    );

    aptRepo.addAppointment(
      AppointmentDto(
        id: 'APT-101',
        patientId: 'pat-001',
        patientName: 'Ramesh Sharma',
        doctorName: 'Dr. Anita Roy',
        specialty: 'General Medicine',
        facilityName: 'PHC Rampur',
        scheduledTime: DateTime.now(),
        type: 'OPD',
        status: 'CONFIRMED',
        chiefComplaint: 'Follow-up',
      ),
    );
  });

  testWidgets('Test Doctor Dashboard tab navigation and profile interactions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final session = SessionCoordinator();
    session.switchRole(AppRole.doctor);

    await tester.pumpWidget(
      const RuralCareApp(),
    );
    await tester.pumpAndSettle();

    // 1. Verify Home Tab is active
    expect(find.byType(DoctorHomeTab), findsOneWidget);
    expect(find.textContaining('Dr. Anita Roy'), findsAtLeastNWidgets(1));

    // 2. Switch to Queue Tab
    final queueTab = find.byKey(const ValueKey('doctor_nav_2'));
    expect(queueTab, findsOneWidget);
    await tester.tap(queueTab);
    await tester.pumpAndSettle();
    expect(find.byType(DoctorQueueTab), findsOneWidget);
    expect(find.text('Patient Queue'), findsOneWidget);

    // 3. Switch to Patients Tab
    final patientsTab = find.byKey(const ValueKey('doctor_nav_1'));
    expect(patientsTab, findsOneWidget);
    await tester.tap(patientsTab);
    await tester.pumpAndSettle();
    expect(find.byType(DoctorPatientsTab), findsOneWidget);
    expect(find.text('Patient Clinical Charts'), findsOneWidget);

    // 4. Switch to Referrals Tab
    final referralsTab = find.byKey(const ValueKey('doctor_nav_3'));
    expect(referralsTab, findsOneWidget);
    await tester.tap(referralsTab);
    await tester.pumpAndSettle();
    expect(find.byType(DoctorReferralsTab), findsOneWidget);
    expect(find.text('Referral Coordination Desk'), findsOneWidget);

    // 5. Switch to Profile Tab
    final profileTab = find.byKey(const ValueKey('doctor_nav_4'));
    expect(profileTab, findsOneWidget);
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
    expect(find.byType(DoctorProfileTab), findsOneWidget);
    expect(find.text('Practice Facility & Timings'), findsOneWidget);

    // 6. Test Doctor Profile Language Switcher
    final hindiBtn = find.text('हिंदी');
    expect(hindiBtn, findsOneWidget);
    await tester.tap(hindiBtn);
    await tester.pumpAndSettle();
    expect(session.activeLanguage, 'hi');

    final marathiBtn = find.text('मराठी');
    expect(marathiBtn, findsOneWidget);
    await tester.tap(marathiBtn);
    await tester.pumpAndSettle();
    expect(session.activeLanguage, 'mr');

    final englishBtn = find.text('English');
    expect(englishBtn, findsOneWidget);
    await tester.tap(englishBtn);
    await tester.pumpAndSettle();
    expect(session.activeLanguage, 'en');

    // 7. Test Offline Switcher
    final offlineSwitch = find.text('Simulate Offline Mode');
    expect(offlineSwitch, findsOneWidget);
    await tester.tap(offlineSwitch);
    await tester.pumpAndSettle();
    expect(session.isOffline, true);

    await tester.tap(offlineSwitch);
    await tester.pumpAndSettle();
    expect(session.isOffline, false);

    // 8. Return to Home Tab
    final homeTab = find.byKey(const ValueKey('doctor_nav_0'));
    expect(homeTab, findsOneWidget);
    await tester.tap(homeTab);
    await tester.pumpAndSettle();
    expect(find.byType(DoctorHomeTab), findsOneWidget);
  });

  testWidgets('Test Doctor Clinical Chart Consent Request & OTP Authorization Flow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    ConsentRepository().resetToDefaults();
    final session = SessionCoordinator();
    session.switchRole(AppRole.doctor);

    await tester.pumpWidget(const RuralCareApp());
    await tester.pumpAndSettle();

    // 1. Go to Patients Tab
    final patientsTab = find.byKey(const ValueKey('doctor_nav_1'));
    await tester.tap(patientsTab);
    await tester.pumpAndSettle();

    // 2. Verify button is "Request for Clinical Chart"
    final requestBtn = find.text('Request for Clinical Chart');
    expect(requestBtn, findsAtLeastNWidgets(1));

    // 3. Tap "Request for Clinical Chart" on first patient
    await tester.tap(requestBtn.first);
    await tester.pumpAndSettle();

    // 4. Verify ABDM consent modal appears
    expect(find.text('ABDM Consent Gateway'), findsOneWidget);
    expect(find.text('Digital Health Record Access Request'), findsOneWidget);

    // 5. Tap Send Consent Request via SMS
    final sendSmsBtn = find.textContaining('Send Consent Request via SMS');
    expect(sendSmsBtn, findsOneWidget);
    await tester.tap(sendSmsBtn);
    await tester.pumpAndSettle();

    // 6. Verify OTP entry view and notification banner appear
    expect(find.textContaining('Incoming Patient Notification'), findsOneWidget);
    expect(find.text('Auto-Fill'), findsOneWidget);

    // 7. Auto-fill OTP and submit
    await tester.tap(find.text('Auto-Fill'));
    await tester.pumpAndSettle();

    final verifyBtn = find.text('Verify OTP & Decrypt →');
    expect(verifyBtn, findsOneWidget);
    await tester.tap(verifyBtn);
    await tester.pumpAndSettle();

    // 8. Verify DoctorClinicalSummaryScreen opens directly
    expect(find.byType(DoctorClinicalSummaryScreen), findsOneWidget);

    // 9. Pop back and verify button is now "Open Clinical Chart → (Consent Verified)"
    final backBtn = find.byIcon(Icons.arrow_back);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('Open Clinical Chart → (Consent Verified)'), findsOneWidget);
    expect(find.text('Consent Active'), findsOneWidget);
  });

  testWidgets('Test Full Consultation End-to-End Workflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final patientRepo = PatientRepository();
    final patient = patientRepo.patients.first;

    // 1. Mount DoctorClinicalSummaryScreen
    await tester.pumpWidget(
      MaterialApp(
        home: DoctorClinicalSummaryScreen(
          patient: patient,
          appointmentId: 'APT-101',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify patient information displayed
    expect(find.text(patient.fullName), findsAtLeastNWidgets(1));
    expect(find.text('Start Consultation & Care Plan →'), findsOneWidget);

    // 2. Mount DoctorCarePlanScreen directly
    await tester.pumpWidget(
      MaterialApp(
        home: DoctorCarePlanScreen(
          patient: patient,
          appointmentId: 'APT-101',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify clinical form fields
    expect(find.text('Clinical Care Plan'), findsOneWidget);
    expect(find.text('Complete Consultation →'), findsOneWidget);

    // 3. Tap Complete Consultation
    final completeBtn = find.text('Complete Consultation →');
    await tester.tap(completeBtn);
    await tester.pumpAndSettle();

    // Verify navigation to DoctorConsultationCompletedScreen
    expect(find.byType(DoctorConsultationCompletedScreen), findsOneWidget);
    expect(find.text('Consultation Completed'), findsOneWidget);
    expect(find.text('Digital Prescription Issued'), findsOneWidget);

    // Verify AppointmentRepository was updated
    final aptRepo = AppointmentRepository();
    final apt = aptRepo.getAppointmentById('APT-101');
    expect(apt?.status, 'COMPLETED');
  });

  testWidgets('Test Doctor Multilingual Dynamic Switching (EN, Hindi, Marathi)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final session = SessionCoordinator();
    session.switchRole(AppRole.doctor);
    session.switchLanguage('en');

    await tester.pumpWidget(const RuralCareApp());
    await tester.pumpAndSettle();

    // 1. Verify initial English state
    expect(session.isEnglish, true);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Patients'), findsOneWidget);
    expect(find.text('Queue'), findsWidgets);
    expect(find.text('Referrals'), findsWidgets);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text("Today's Appointments"), findsOneWidget);
    expect(find.text('In Queue'), findsOneWidget);

    // 2. Tap Hindi badge in App Bar ('हि')
    final hindiBadge = find.byKey(const ValueKey('doctor_lang_hi'));
    expect(hindiBadge, findsOneWidget);
    await tester.tap(hindiBadge);
    await tester.pumpAndSettle();

    // Verify session updated and UI re-rendered in Hindi
    expect(session.isHindi, true);
    expect(find.text('डैशबोर्ड'), findsOneWidget);
    expect(find.text('मरीज़'), findsOneWidget);
    expect(find.text('कतार'), findsWidgets);
    expect(find.text('रेफरल'), findsWidgets);
    expect(find.text('प्रोफ़ाइल'), findsOneWidget);
    expect(find.text('आज के अपॉइंटमेंट'), findsOneWidget);
    expect(find.text('चिकित्सा अधिकारी • प्राथमिक स्वास्थ्य केंद्र रामपुर'), findsOneWidget);

    // 3. Switch to Queue tab and verify Hindi translations
    final queueTab = find.byKey(const ValueKey('doctor_nav_2'));
    await tester.tap(queueTab);
    await tester.pumpAndSettle();
    expect(find.text('क्लिनिकल कतार'), findsOneWidget);
    expect(find.textContaining('आज की कतार'), findsOneWidget);
    expect(find.textContaining('प्रतीक्षारत'), findsWidgets);

    // 4. Switch to Referrals tab and verify Hindi translations
    final referralsTab = find.byKey(const ValueKey('doctor_nav_3'));
    await tester.tap(referralsTab);
    await tester.pumpAndSettle();
    expect(find.text('रेफरल समन्वय डेस्क'), findsOneWidget);
    expect(find.textContaining('आवक रेफरल'), findsOneWidget);
    expect(find.textContaining('जावक ट्रैकिंग'), findsOneWidget);

    // 5. Tap Marathi badge in App Bar ('म')
    final marathiBadge = find.byKey(const ValueKey('doctor_lang_mr'));
    expect(marathiBadge, findsOneWidget);
    await tester.tap(marathiBadge);
    await tester.pumpAndSettle();

    // Verify session updated and UI re-rendered in Marathi
    expect(session.isMarathi, true);
    expect(find.text('संदर्भ समन्वय डेस्क'), findsOneWidget);
    expect(find.textContaining('आवक संदर्भ'), findsOneWidget);
    expect(find.textContaining('जावक ट्रॅकिंग'), findsOneWidget);
    expect(find.text('डॅशबोर्ड'), findsOneWidget);
    expect(find.text('रुग्ण'), findsOneWidget);
    expect(find.text('प्रतीक्षा यादी'), findsWidgets);
    expect(find.text('संदर्भ'), findsWidgets);
    expect(find.text('प्रोफाइल'), findsOneWidget);

    // 6. Return to Home Tab and verify Marathi translations
    final homeTab = find.byKey(const ValueKey('doctor_nav_0'));
    await tester.tap(homeTab);
    await tester.pumpAndSettle();
    expect(find.text('आजच्या भेटी'), findsOneWidget);
    expect(find.text('वैद्यकीय अधिकारी • प्राथमिक आरोग्य केंद्र रामपूर'), findsOneWidget);

    // 7. Tap English badge ('EN') to return to English
    final englishBadge = find.byKey(const ValueKey('doctor_lang_en'));
    expect(englishBadge, findsOneWidget);
    await tester.tap(englishBadge);
    await tester.pumpAndSettle();

    // Verify back in English
    expect(session.isEnglish, true);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Patients'), findsOneWidget);
    expect(find.text("Today's Appointments"), findsOneWidget);
  });
}
