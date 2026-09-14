import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/admin/screens/district_analytics_screen.dart';
import 'package:ruralcare/features/admin/widgets/admin_facilities_tab.dart';
import 'package:ruralcare/features/admin/widgets/admin_system_audit_tab.dart';
import 'package:ruralcare/features/admin/widgets/admin_users_tab.dart';

void main() {
  group('District Admin Profile & Operational Modules Tests', () {
    late DoctorRepository doctorRepo;
    late FacilityRepository facilityRepo;
    late SessionCoordinator sessionCoordinator;

    setUp(() {
      doctorRepo = DoctorRepository();
      facilityRepo = FacilityRepository();
      sessionCoordinator = SessionCoordinator();
      sessionCoordinator.switchRole(AppRole.admin);
      sessionCoordinator.switchLanguage('en');
    });

    testWidgets('DistrictAnalyticsScreen loads shell with Dashboard Tab and Header', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ListenableBuilder(
            listenable: sessionCoordinator,
            builder: (context, _) => const DistrictAnalyticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar verification
      expect(find.text('NABHA RuralCare'), findsOneWidget);
      expect(find.text('v2.4 LTS'), findsOneWidget);
      expect(find.text('Operational • Sync Live'), findsOneWidget);

      // Verify KPI banner is present
      expect(find.text('Rampur District Cluster HQ'), findsOneWidget);
      expect(find.text('18 Nodes Online'), findsOneWidget);
      expect(find.text('Registered Users'), findsOneWidget);
      expect(find.text('Active Facilities'), findsOneWidget);
    });

    testWidgets('District Admin can switch tabs via sidebar to Users, Facilities, and Audit', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ListenableBuilder(
            listenable: sessionCoordinator,
            builder: (context, _) => const DistrictAnalyticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Users & Roles in Sidebar
      final usersNav = find.text('Users & Roles');
      expect(usersNav, findsOneWidget);
      await tester.tap(usersNav);
      await tester.pumpAndSettle();

      expect(find.byType(AdminUsersTab), findsOneWidget);
      expect(find.text('User & Role Management'), findsOneWidget);

      // Tap on Facilities in Sidebar
      final facilitiesNav = find.text('Facilities');
      expect(facilitiesNav, findsOneWidget);
      await tester.tap(facilitiesNav);
      await tester.pumpAndSettle();

      expect(find.byType(AdminFacilitiesTab), findsOneWidget);
      expect(find.text('Healthcare Facility Management'), findsOneWidget);

      // Tap on System & Audit in Sidebar
      final auditNav = find.text('System & Audit');
      expect(auditNav, findsOneWidget);
      await tester.tap(auditNav);
      await tester.pumpAndSettle();

      expect(find.byType(AdminSystemAuditTab), findsOneWidget);
      expect(find.text('Cluster Node Health Directory'), findsOneWidget);
    });

    testWidgets('Multilingual switching updates District Admin UI labels', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ListenableBuilder(
            listenable: sessionCoordinator,
            builder: (context, _) => const DistrictAnalyticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Hindi
      sessionCoordinator.switchLanguage('hi');
      await tester.pumpAndSettle();

      expect(find.text('उपयोगकर्ता एवं रोल'), findsOneWidget);
      expect(find.text('स्वास्थ्य केंद्र'), findsOneWidget);

      // Switch to Marathi
      sessionCoordinator.switchLanguage('mr');
      await tester.pumpAndSettle();

      expect(find.text('वापरकर्ते व अधिकार'), findsOneWidget);
      expect(find.text('आरोग्य संस्था'), findsOneWidget);
    });

    test('DoctorRepository.registerDoctorDirectly registers new staff without mock data', () {
      final initialCount = doctorRepo.registeredDoctors.length;

      final newDoc = doctorRepo.registerDoctorDirectly(
        name: 'Dr. Vikram Sarabhai',
        mobile: '9822114455',
        qualification: 'MBBS, MD (Pediatrics)',
        registrationNumber: 'MMC/2026/01/9921',
        specialty: 'Pediatrics',
        facilityId: 'FAC-DH-100',
        facilityName: 'Rampur District Civil Hospital',
      );

      expect(doctorRepo.registeredDoctors.length, equals(initialCount + 1));
      expect(newDoc.name, equals('Dr. Vikram Sarabhai'));
      expect(doctorRepo.registeredDoctors.any((d) => d.mobile == '9822114455'), isTrue);
    });

    test('FacilityRepository.addFacility registers new health sub-centre', () {
      final initialCount = facilityRepo.facilities.length;

      const newFac = FacilityDto(
        id: 'FAC-PHC-999',
        name: 'Wadgaon Primary Health Centre',
        type: 'PHC',
        distanceKm: 6.2,
        address: 'Wadgaon Village, Shirur Block, Rampur',
        contactPhone: '+91 2138 223344',
        totalBeds: 12,
        availableBeds: 8,
        onDutySpecialists: ['Dr. Ramesh Patil'],
        availableBloodUnits: {'A+': 4, 'B+': 5},
        availableDiagnostics: ['CBC', 'Malaria Rapid Test'],
        availableMedicines: ['Paracetamol', 'Amoxicillin'],
        hasEmergencyCapability: false,
        hasAmbulanceAvailable: true,
      );

      facilityRepo.addFacility(newFac);
      expect(facilityRepo.facilities.length, equals(initialCount + 1));

      final fetched = facilityRepo.getFacilityById('FAC-PHC-999');
      expect(fetched, isNotNull);
      expect(fetched?.name, equals('Wadgaon Primary Health Centre'));
    });
  });
}
