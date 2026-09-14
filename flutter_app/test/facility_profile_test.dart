import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/main.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/facility/screens/facility_dashboard_screen.dart';
import 'package:ruralcare/features/facility/widgets/facility_overview_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_queue_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_services_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_referrals_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_profile_tab.dart';

import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';

void main() {
  setUp(() {
    SessionCoordinator().switchRole(AppRole.facilityStaff);
    SessionCoordinator().switchLanguage('en');
    SessionCoordinator().completeOnboarding();

    final patientRepo = PatientRepository();
    final apptRepo = AppointmentRepository();
    final refRepo = ReferralRepository();
    final facRepo = FacilityRepository();
    patientRepo.resetToDefaults();
    apptRepo.resetToDefaults();
    refRepo.resetToDefaults();
    facRepo.resetToDefaults();
    facRepo.addApprovedDoctor(
      facilityId: 'FAC-SDH-301',
      doctorId: 'DOC-101',
      doctorName: 'Dr. Anita Roy',
      specialty: 'Obstetrician & Gynecologist',
      qualification: 'MBBS, MD',
    );

    refRepo.addReferral(
      ReferralDto(
        id: 'REF-101',
        patientId: 'pat-001',
        patientName: 'Kavita Rajesh Devi',
        referringFacility: 'Kashti Sub-Centre',
        targetFacilityId: 'FAC-SDH-301',
        targetFacilityName: 'Baramati Sub-District Hospital',
        reason: 'Pre-eclampsia evaluation',
        urgency: 'EMERGENCY',
        requiredSpecialty: 'OB/GYN',
        status: 'HOSPITAL_NOTIFIED',
        recommendationRationale: 'Pre-eclampsia evaluation and specialist management',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    );
    refRepo.addReferral(
      ReferralDto(
        id: 'REF-102',
        patientId: 'pat-002',
        patientName: 'Rajesh Verma',
        referringFacility: 'Baramati Sub-District Hospital',
        targetFacilityId: 'FAC-DH-401',
        targetFacilityName: 'Aundh District Hospital',
        reason: 'Complex fracture',
        urgency: 'PRIORITY',
        requiredSpecialty: 'Orthopedics',
        status: 'ACCEPTED',
        recommendationRationale: 'Surgical orthopedic intervention required',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );
    refRepo.addReferral(
      ReferralDto(
        id: 'REF-103',
        patientId: 'pat-003',
        patientName: 'Sanjay Deshmukh',
        referringFacility: 'Baramati Sub-District Hospital',
        targetFacilityId: 'FAC-DH-401',
        targetFacilityName: 'Aundh District Hospital',
        reason: 'Cardiac review',
        urgency: 'ROUTINE',
        requiredSpecialty: 'Cardiology',
        status: 'ACCEPTED',
        recommendationRationale: 'Cardiology specialist consultation',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    );

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
        subCentre: 'Sub-Centre',
        district: 'Bilaspur',
        assignedAsha: 'Sunita Bai',
        emergencyContact: EmergencyContactDto(
          name: 'Contact',
          relationship: 'Family',
          phoneNumber: '9876543210',
        ),
      ),
    );

    apptRepo.addAppointment(
      AppointmentDto(
        id: 'APT-001',
        patientId: 'pat-001',
        patientName: 'Ramesh Sharma',
        doctorName: 'Dr. Anita Roy',
        specialty: 'General Medicine',
        facilityName: 'Baramati Sub-District Hospital',
        scheduledTime: DateTime.now(),
        type: 'OPD',
        status: 'IN_PROGRESS',
        chiefComplaint: 'Follow-up',
      ),
    );
  });

  testWidgets('Test Facility Dashboard tab navigation and operational features', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final session = SessionCoordinator();
    session.switchRole(AppRole.facilityStaff);

    await tester.pumpWidget(const RuralCareApp());
    await tester.pumpAndSettle();

    // 1. Verify Facility Dashboard Shell and Overview Tab are rendered
    expect(find.byType(FacilityDashboardScreen), findsOneWidget);
    expect(find.byType(FacilityOverviewTab), findsOneWidget);
    expect(find.textContaining('Baramati Sub-District Hospital'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Bed Capacity & Occupancy'), findsOneWidget);
    expect(find.textContaining('Vacant beds available'), findsOneWidget);

    // Verify bed capacity stepper
    final facRepo = FacilityRepository();
    final fac = facRepo.facilities.firstWhere((f) => f.id == 'FAC-SDH-301');
    final initialBeds = fac.availableBeds;

    final minusBedBtn = find.byTooltip('Admit Patient (-1 bed)');
    expect(minusBedBtn, findsOneWidget);
    await tester.tap(minusBedBtn);
    await tester.pumpAndSettle();

    expect(
      facRepo.facilities.firstWhere((f) => f.id == 'FAC-SDH-301').availableBeds,
      equals(initialBeds - 1),
    );

    final plusBedBtn = find.byTooltip('Discharge Patient (+1 bed)');
    expect(plusBedBtn, findsOneWidget);
    await tester.tap(plusBedBtn);
    await tester.pumpAndSettle();

    expect(
      facRepo.facilities.firstWhere((f) => f.id == 'FAC-SDH-301').availableBeds,
      equals(initialBeds),
    );

    // Verify Bento Metrics
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('Queue Waiting'), findsOneWidget);
    expect(find.text('Active Referrals'), findsOneWidget);
    expect(find.text('Lab Diagnostics'), findsOneWidget);

    // 2. Switch to Queue Tab
    final queueTab = find.byKey(const ValueKey('facility_nav_1'));
    expect(queueTab, findsOneWidget);
    await tester.tap(queueTab);
    await tester.pumpAndSettle();

    expect(find.byType(FacilityQueueTab), findsOneWidget);
    expect(find.textContaining("Today's Patient Queue"), findsOneWidget);
    expect(find.text('Fast-track arrival token check-in'), findsOneWidget);

    // Verify search and patient cards
    expect(find.textContaining('Ramesh Sharma'), findsAtLeastNWidgets(1));

    // Test Open Patient sheet
    final openPatientBtn = find.widgetWithText(OutlinedButton, 'Open Patient').first;
    await tester.ensureVisible(openPatientBtn);
    await tester.tap(openPatientBtn);
    await tester.pumpAndSettle();
    expect(find.text('Clinical Encounter Summary'), findsOneWidget);

    // Close sheet
    final closeRecordBtn = find.widgetWithText(ElevatedButton, 'Close Record');
    await tester.tap(closeRecordBtn);
    await tester.pumpAndSettle();

    // 3. Switch to Services & Inventory Tab
    final servicesTab = find.byKey(const ValueKey('facility_nav_2'));
    expect(servicesTab, findsOneWidget);
    await tester.tap(servicesTab);
    await tester.pumpAndSettle();

    expect(find.byType(FacilityServicesTab), findsOneWidget);
    expect(find.text('Facility Services & Availability'), findsOneWidget);
    expect(find.text('Essential Medicines (दवाइयां)'), findsOneWidget);
    expect(find.text('Paracetamol 500mg'), findsOneWidget);

    // Switch sub-tab to Diagnostics
    final diagSubTab = find.text('जांच');
    expect(diagSubTab, findsOneWidget);
    await tester.tap(diagSubTab);
    await tester.pumpAndSettle();
    expect(find.text('Diagnostics & Rapid Kits (जांच)'), findsOneWidget);
    expect(find.text('Hemoglobin (CBC / Strip)'), findsOneWidget);

    // Switch sub-tab to Clinical Services
    final clinSubTab = find.text('सेवाएं');
    expect(clinSubTab, findsOneWidget);
    await tester.tap(clinSubTab);
    await tester.pumpAndSettle();
    expect(find.text('Clinical Facility Services (स्वास्थ्य सेवाएं)'), findsOneWidget);
    expect(find.text('Blood Bank Inventory'), findsOneWidget);

    // 4. Switch to Referrals Desk Tab
    final referralsTab = find.byKey(const ValueKey('facility_nav_3'));
    expect(referralsTab, findsOneWidget);
    await tester.tap(referralsTab);
    await tester.pumpAndSettle();

    expect(find.byType(FacilityReferralsTab), findsOneWidget);
    expect(find.text('Referral Coordination'), findsOneWidget);
    expect(find.textContaining('Inbound'), findsAtLeastNWidgets(1));
    expect(find.text('+ Create Outbound Referral'), findsOneWidget);

    // Switch to Outbound stream
    final outboundBtn = find.text('Outbound (2)');
    expect(outboundBtn, findsOneWidget);
    await tester.tap(outboundBtn);
    await tester.pumpAndSettle();
    expect(find.textContaining('Rajesh Verma'), findsOneWidget);

    // 5. Switch to Profile / Admin Tab
    final profileTab = find.byKey(const ValueKey('facility_nav_5'));
    expect(profileTab, findsOneWidget);
    await tester.tap(profileTab);
    await tester.pumpAndSettle();

    expect(find.byType(FacilityProfileTab), findsOneWidget);
    expect(find.text('Duty Shift Management'), findsOneWidget);
    expect(find.text('On-Duty Staff Roster'), findsOneWidget);
    expect(find.text('Dr. Anita Roy'), findsOneWidget);

    // Test Multilingual Language Switcher (Hindi)
    final hindiChip = find.text('हिन्दी (HI)');
    expect(hindiChip, findsOneWidget);
    await tester.ensureVisible(hindiChip);
    await tester.tap(hindiChip);
    await tester.pumpAndSettle();

    // Verify reactive translation
    expect(find.text('ड्यूटी शिफ्ट प्रबंधन'), findsOneWidget);
    expect(find.text('ऑन-ड्यूटी स्टाफ रोस्टर'), findsOneWidget);

    // Test Multilingual Language Switcher (Marathi)
    final marathiChip = find.text('मराठी (MR)');
    expect(marathiChip, findsOneWidget);
    await tester.ensureVisible(marathiChip);
    await tester.tap(marathiChip);
    await tester.pumpAndSettle();

    // Verify reactive translation
    expect(find.text('ड्युटी शिफ्ट व्यवस्थापन'), findsOneWidget);
    expect(find.text('ऑन-ड्युटी कर्मचारी यादी'), findsOneWidget);
  });
}
