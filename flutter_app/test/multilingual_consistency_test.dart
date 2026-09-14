import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/doctor/utils/doctor_strings.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';
import 'package:ruralcare/features/health_worker/utils/health_worker_strings.dart';
import 'package:ruralcare/features/patient/screens/patient_home_screen.dart';
import 'package:ruralcare/features/patient/screens/appointment_booking_screen.dart';
import 'package:ruralcare/features/patient/screens/longitudinal_records_screen.dart';
import 'package:ruralcare/features/health_worker/screens/health_worker_dashboard_screen.dart';

import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

void main() {
  group('Multilingual Localization System Tests', () {
    late SessionCoordinator session;

    setUp(() {
      session = SessionCoordinator();
      session.switchLanguage('en');

      final patientRepo = PatientRepository();
      patientRepo.resetToDefaults();
      patientRepo.addPatient(
        const PatientDto(
          id: 'pat-001',
          ruralCareId: 'RC-001',
          abhaId: 'ABHA-001',
          fullName: 'Ramesh Sharma',
          age: 45,
          gender: 'Male',
          phoneNumber: '9823411204',
          village: 'Rampur',
          subCentre: 'Rampur Health Sub-Centre',
          district: 'Bilaspur',
          assignedAsha: 'Sunita Bai',
          emergencyContact: EmergencyContactDto(
            name: 'Contact',
            relationship: 'Family',
            phoneNumber: '9823411204',
          ),
        ),
      );
    });

    test('SessionCoordinator canonical language normalization and boolean getters', () {
      // English variants
      session.switchLanguage('English');
      expect(session.isEnglish, isTrue);
      expect(session.isHindi, isFalse);
      expect(session.isMarathi, isFalse);
      expect(session.canonicalLanguageCode, equals('en'));

      session.switchLanguage('en');
      expect(session.isEnglish, isTrue);

      // Hindi variants
      session.switchLanguage('Hindi');
      expect(session.isHindi, isTrue);
      expect(session.isEnglish, isFalse);
      expect(session.isMarathi, isFalse);
      expect(session.canonicalLanguageCode, equals('hi'));

      session.switchLanguage('हिन्दी');
      expect(session.isHindi, isTrue);

      session.switchLanguage('हिंदी');
      expect(session.isHindi, isTrue);

      session.switchLanguage('hi');
      expect(session.isHindi, isTrue);

      // Marathi variants
      session.switchLanguage('Marathi');
      expect(session.isMarathi, isTrue);
      expect(session.isEnglish, isFalse);
      expect(session.isHindi, isFalse);
      expect(session.canonicalLanguageCode, equals('mr'));

      session.switchLanguage('मराठी');
      expect(session.isMarathi, isTrue);

      session.switchLanguage('mr');
      expect(session.isMarathi, isTrue);
    });

    test('DoctorStrings returns accurate translations for English, Hindi, and Marathi', () {
      session.switchLanguage('en');
      var docStrings = DoctorStrings.of(session);
      expect(docStrings.tabDashboard, equals('Dashboard'));
      expect(docStrings.tabPatients, equals('Patients'));
      expect(docStrings.online, equals('Online'));

      session.switchLanguage('hi');
      docStrings = DoctorStrings.of(session);
      expect(docStrings.tabDashboard, equals('डैशबोर्ड'));
      expect(docStrings.tabPatients, equals('मरीज़'));
      expect(docStrings.online, equals('ऑनलाइन'));

      session.switchLanguage('mr');
      docStrings = DoctorStrings.of(session);
      expect(docStrings.tabDashboard, equals('डॅशबोर्ड'));
      expect(docStrings.tabPatients, equals('रुग्ण'));
      expect(docStrings.online, equals('ऑनलाइन'));
    });

    test('FacilityStrings returns accurate translations for English, Hindi, and Marathi', () {
      session.switchLanguage('en');
      var facStrings = FacilityStrings.of(session);
      expect(facStrings.tabDashboard, equals('Dashboard'));
      expect(facStrings.tabServices, equals('Services'));

      session.switchLanguage('hi');
      facStrings = FacilityStrings.of(session);
      expect(facStrings.tabDashboard, equals('डैशबोर्ड'));
      expect(facStrings.tabServices, equals('सेवाएं'));

      session.switchLanguage('mr');
      facStrings = FacilityStrings.of(session);
      expect(facStrings.tabDashboard, equals('डॅशबोर्ड'));
      expect(facStrings.tabServices, equals('सेवा'));
    });

    test('HealthWorkerStrings provides complete consistent strings for all 3 languages', () {
      // English
      session.switchLanguage('en');
      var hwStrings = HealthWorkerStrings.of(session);
      expect(hwStrings.tabDashboard, equals('Dashboard'));
      expect(hwStrings.tabPatients, equals('Patients'));
      expect(hwStrings.dueToday, equals('DUE TODAY'));
      expect(hwStrings.priorityCases, equals('PRIORITY CASES'));
      expect(hwStrings.activeReferrals, equals('ACTIVE REFERRALS'));
      expect(hwStrings.completedThisWeek, equals('COMPLETED THIS WEEK'));
      expect(hwStrings.findPatient, equals('Find Patient'));
      expect(hwStrings.todaysTasks, equals("Today's Tasks"));

      // Hindi
      session.switchLanguage('hi');
      hwStrings = HealthWorkerStrings.of(session);
      expect(hwStrings.tabDashboard, equals('डैशबोर्ड'));
      expect(hwStrings.tabPatients, equals('मरीज़'));
      expect(hwStrings.tabTasks, equals('कार्य'));
      expect(hwStrings.tabReferrals, equals('रेफरल'));
      expect(hwStrings.dueToday, equals('आज देय'));
      expect(hwStrings.priorityCases, equals('प्राथमिकता मामले'));
      expect(hwStrings.activeReferrals, equals('सक्रिय रेफरल'));
      expect(hwStrings.completedThisWeek, equals('इस सप्ताह पूर्ण'));
      expect(hwStrings.findPatient, equals('मरीज़ खोजें'));
      expect(hwStrings.todaysTasks, equals('आज के कार्य'));

      // Marathi
      session.switchLanguage('mr');
      hwStrings = HealthWorkerStrings.of(session);
      expect(hwStrings.tabDashboard, equals('डॅशबोर्ड'));
      expect(hwStrings.tabPatients, equals('रुग्ण'));
      expect(hwStrings.tabTasks, equals('कार्ये'));
      expect(hwStrings.tabReferrals, equals('संदर्भ'));
      expect(hwStrings.dueToday, equals('आज देय'));
      expect(hwStrings.priorityCases, equals('प्राधान्य प्रकरणे'));
      expect(hwStrings.activeReferrals, equals('सक्रिय संदर्भ'));
      expect(hwStrings.completedThisWeek, equals('या आठवड्यात पूर्ण'));
      expect(hwStrings.findPatient, equals('रुग्ण शोधा'));
      expect(hwStrings.todaysTasks, equals('आजची कार्ये'));
    });

    testWidgets('PatientHomeScreen middle body content dynamically localizes when language changes', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      session.switchLanguage('en');

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // In English
      expect(find.text('How can we help?'), findsOneWidget);
      expect(find.text('Your health'), findsOneWidget);

      // Switch to Hindi
      session.switchLanguage('hi');
      await tester.pumpAndSettle();

      // Middle body must be translated to Hindi
      expect(find.text('हम आपकी कैसे मदद कर सकते हैं?'), findsOneWidget);
      expect(find.text('आपकी स्वास्थ्य स्थिति'), findsOneWidget);
      expect(find.text('How can we help?'), findsNothing);

      // Switch to Marathi
      session.switchLanguage('mr');
      await tester.pumpAndSettle();

      // Middle body must be translated to Marathi
      expect(find.text('आम्ही कशी मदत करू शकतो?'), findsOneWidget);
      expect(find.text('तुमचे आरोग्य'), findsOneWidget);
      expect(find.text('How can we help?'), findsNothing);
    });

    testWidgets('AppointmentBookingScreen tabs and headers update on language switch', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      session.switchLanguage('hi');

      await tester.pumpWidget(
        const MaterialApp(
          home: AppointmentBookingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('अपॉइंटमेंट्स'), findsOneWidget);
      expect(find.text('आगामी'), findsOneWidget);
      expect(find.text('विगत'), findsOneWidget);
      expect(find.text('अपॉइंटमेंट बुक करें'), findsOneWidget);

      // Switch to Marathi
      session.switchLanguage('mr');
      await tester.pumpAndSettle();

      expect(find.text('भेटी'), findsOneWidget);
      expect(find.text('मागील'), findsOneWidget);
      expect(find.text('भेट बुक करा'), findsOneWidget);
    });

    testWidgets('LongitudinalRecordsScreen filter chips update on language switch', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      session.switchLanguage('hi');

      await tester.pumpWidget(
        const MaterialApp(
          home: LongitudinalRecordsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('स्वास्थ्य रिकॉर्ड'), findsOneWidget);
      expect(find.text('सभी'), findsOneWidget);
      expect(find.text('दवाएं'), findsOneWidget);
      expect(find.text('जांच रिपोर्ट'), findsOneWidget);

      // Switch to Marathi
      session.switchLanguage('mr');
      await tester.pumpAndSettle();

      expect(find.text('आरोग्य नोंदी'), findsOneWidget);
      expect(find.text('सर्व'), findsOneWidget);
      expect(find.text('औषधे'), findsOneWidget);
      expect(find.text('तपासणी अहवाल'), findsOneWidget);
    });

    testWidgets('HealthWorkerDashboardScreen bento metrics and navigation tabs update on language switch', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      session.switchLanguage('hi');

      await tester.pumpWidget(
        const MaterialApp(
          home: HealthWorkerDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Bento metrics in Hindi
      expect(find.text('आज देय'), findsOneWidget);
      expect(find.text('प्राथमिकता मामले'), findsOneWidget);
      expect(find.text('सक्रिय रेफरल'), findsOneWidget);
      expect(find.text('इस सप्ताह पूर्ण'), findsOneWidget);
      expect(find.text('आज के कार्य'), findsOneWidget);

      // Bottom nav in Hindi
      expect(find.text('डैशबोर्ड'), findsOneWidget);
      expect(find.text('मरीज़'), findsWidgets);
      expect(find.text('कार्य'), findsOneWidget);
      expect(find.text('रेफरल'), findsOneWidget);

      // Switch to Marathi
      session.switchLanguage('mr');
      await tester.pumpAndSettle();

      // Bento metrics in Marathi
      expect(find.text('प्राधान्य प्रकरणे'), findsOneWidget);
      expect(find.text('सक्रिय संदर्भ'), findsOneWidget);
      expect(find.text('या आठवड्यात पूर्ण'), findsOneWidget);
      expect(find.text('आजची कार्ये'), findsOneWidget);

      // Bottom nav in Marathi
      expect(find.text('डॅशबोर्ड'), findsOneWidget);
      expect(find.text('रुग्ण'), findsWidgets);
      expect(find.text('कार्ये'), findsOneWidget);
      expect(find.text('संदर्भ'), findsOneWidget);
    });
  });
}
