import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/facility/screens/facility_dashboard_screen.dart';
import 'package:ruralcare/features/facility/widgets/pharmacist_workstation_tab.dart';
import 'package:ruralcare/features/facility/widgets/lab_technician_workstation_tab.dart';
import 'package:ruralcare/features/facility/widgets/staff_nurse_workstation_tab.dart';
import 'package:ruralcare/features/facility/widgets/reception_intake_workstation_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_overview_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_staff_approvals_tab.dart';

void main() {
  late FacilityRepository facRepo;

  setUp(() {
    facRepo = FacilityRepository();
    facRepo.resetToDefaults();
    SessionCoordinator().switchRole(AppRole.facilityStaff);
    SessionCoordinator().switchLanguage('en');
    SessionCoordinator().completeOnboarding();
  });

  group('Multi-tier Facility Staff & Admin Approval Hierarchy Tests', () {
    test('Staff registration creates request with pendingFacilityAdmin status', () {
      final staffReq = FacilityStaffRequestDto(
        id: 'REQ-PHARM-101',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Ramesh Pawar',
        mobile: '9822012345',
        role: FacilityStaffRole.pharmacist,
        licenseOrEmployeeId: 'PHARM-REG-4421',
        department: 'Central Drug Store',
        status: FacilityApprovalStatus.pendingFacilityAdmin,
        submittedAt: DateTime.now(),
      );

      facRepo.submitStaffRequest(staffReq);

      final pendingStaff = facRepo.getPendingStaffRequestsForFacility('FAC-SDH-301');
      expect(pendingStaff.length, 1);
      expect(pendingStaff.first.staffName, 'Ramesh Pawar');
      expect(pendingStaff.first.role, FacilityStaffRole.pharmacist);
      expect(pendingStaff.first.status, FacilityApprovalStatus.pendingFacilityAdmin);
    });

    test('Facility Admin registration creates request with pendingDistrictAdmin status', () {
      final adminReq = FacilityStaffRequestDto(
        id: 'REQ-ADM-201',
        facilityId: 'FAC-CHC-201',
        facilityName: 'Daund Community Health Centre',
        staffName: 'Dr. Suresh Patil',
        mobile: '9822099887',
        role: FacilityStaffRole.facilityAdmin,
        licenseOrEmployeeId: 'HFR-MH-PUN-002',
        department: 'Administration',
        status: FacilityApprovalStatus.pendingDistrictAdmin,
        submittedAt: DateTime.now(),
      );

      facRepo.submitFacilityAdminRequest(adminReq);

      final pendingAdmins = facRepo.getPendingFacilityAdminRequests();
      expect(pendingAdmins.length, 1);
      expect(pendingAdmins.first.staffName, 'Dr. Suresh Patil');
      expect(pendingAdmins.first.status, FacilityApprovalStatus.pendingDistrictAdmin);
    });

    test('Facility Admin approves staff request and assigns room, populating active staff roster', () {
      final staffReq = FacilityStaffRequestDto(
        id: 'REQ-NURSE-102',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Sunita Gaikwad',
        mobile: '9822045678',
        role: FacilityStaffRole.staffNurse,
        licenseOrEmployeeId: 'NURSE-REG-8891',
        department: 'Maternity Ward',
        status: FacilityApprovalStatus.pendingFacilityAdmin,
        submittedAt: DateTime.now(),
      );

      facRepo.submitStaffRequest(staffReq);
      expect(facRepo.getPendingStaffRequestsForFacility('FAC-SDH-301').length, 1);

      // Facility Admin Approves
      facRepo.approveStaffRequest('REQ-NURSE-102', assignedRoom: 'Maternity Ward - Station B');

      // Check request status updated
      final updatedReq = facRepo.getRequestById('REQ-NURSE-102');
      expect(updatedReq, isNotNull);
      expect(updatedReq!.status, FacilityApprovalStatus.approved);
      expect(updatedReq.assignedRoom, 'Maternity Ward - Station B');

      // Check added to active staff roster
      final staffMember = facRepo.staffRoster.firstWhere((s) => s.id == 'REQ-NURSE-102');
      expect(staffMember.name, 'Sunita Gaikwad');
      expect(staffMember.role, 'Staff Nurse');
      expect(staffMember.assignedRoom, 'Maternity Ward - Station B');
      expect(staffMember.onDutyStatus, 'On Duty');
    });

    test('Facility Admin rejects staff request with reason', () {
      final staffReq = FacilityStaffRequestDto(
        id: 'REQ-LAB-103',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Vinod Kumar',
        mobile: '9822033445',
        role: FacilityStaffRole.labTechnician,
        licenseOrEmployeeId: 'LAB-TECH-7711',
        department: 'Biochemistry',
        status: FacilityApprovalStatus.pendingFacilityAdmin,
        submittedAt: DateTime.now(),
      );

      facRepo.submitStaffRequest(staffReq);
      facRepo.rejectStaffRequest('REQ-LAB-103', 'Invalid council registration diploma certificate');

      final rejectedReq = facRepo.getRequestById('REQ-LAB-103');
      expect(rejectedReq, isNotNull);
      expect(rejectedReq!.status, FacilityApprovalStatus.rejected);
      expect(rejectedReq.rejectionReason, 'Invalid council registration diploma certificate');
    });

    test('District Admin approves and rejects Facility Admin requests', () {
      final adminReq1 = FacilityStaffRequestDto(
        id: 'REQ-ADM-301',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Dr. Neha Deshmukh',
        mobile: '9822088776',
        role: FacilityStaffRole.facilityAdmin,
        licenseOrEmployeeId: 'HFR-MH-PUN-001',
        department: 'Medical Superintendent',
        status: FacilityApprovalStatus.pendingDistrictAdmin,
        submittedAt: DateTime.now(),
      );
      final adminReq2 = FacilityStaffRequestDto(
        id: 'REQ-ADM-302',
        facilityId: 'FAC-CHC-201',
        facilityName: 'Daund Community Health Centre',
        staffName: 'Anil Jadhav',
        mobile: '9822011223',
        role: FacilityStaffRole.facilityAdmin,
        licenseOrEmployeeId: 'HFR-MH-PUN-999',
        department: 'Administration',
        status: FacilityApprovalStatus.pendingDistrictAdmin,
        submittedAt: DateTime.now(),
      );

      facRepo.submitFacilityAdminRequest(adminReq1);
      facRepo.submitFacilityAdminRequest(adminReq2);
      expect(facRepo.getPendingFacilityAdminRequests().length, 2);

      // District Admin approves Req 1
      facRepo.approveFacilityAdminRequest('REQ-ADM-301');
      final approvedAdmin = facRepo.getRequestById('REQ-ADM-301');
      expect(approvedAdmin!.status, FacilityApprovalStatus.approved);

      // District Admin rejects Req 2
      facRepo.rejectFacilityAdminRequest('REQ-ADM-302', 'HFR Facility Code does not match district records');
      final rejectedAdmin = facRepo.getRequestById('REQ-ADM-302');
      expect(rejectedAdmin!.status, FacilityApprovalStatus.rejected);
      expect(rejectedAdmin.rejectionReason, 'HFR Facility Code does not match district records');

      // Remaining pending should be 0
      expect(facRepo.getPendingFacilityAdminRequests().length, 0);
    });
  });

  group('Workstation Role Isolation & Dashboard Shell Tests', () {
    testWidgets('Pharmacist sees only PharmacistWorkstationTab with prescriptions queue & dispensing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final pharmSession = FacilityStaffRequestDto(
        id: 'STAFF-PHARM-1',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Ramesh Pawar (RPh)',
        mobile: '9822012345',
        role: FacilityStaffRole.pharmacist,
        licenseOrEmployeeId: 'PHARM-8890',
        department: 'OPD Pharmacy Desk 1',
        status: FacilityApprovalStatus.approved,
        submittedAt: DateTime.now(),
      );

      facRepo.setCurrentStaffSession(pharmSession);

      await tester.pumpWidget(
        const MaterialApp(
          home: FacilityDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Pharmacist Workstation is active
      expect(find.byType(PharmacistWorkstationTab), findsOneWidget);
      expect(find.byType(FacilityOverviewTab), findsNothing);

      // Verify role badge in AppBar
      expect(find.textContaining('Ramesh Pawar (RPh)'), findsOneWidget);
      expect(find.text('Pharmacist'), findsOneWidget);

      // Verify ad-hoc switcher popup menu is NOT present
      expect(find.byType(PopupMenuButton<String>), findsNothing);

      // Sub-tab 0: E-Prescriptions
      expect(find.text('Prescription Queue Clear'), findsOneWidget);

      // Sub-tab 1: Drug Inventory
      final inventoryTab = find.text('Drug Inventory');
      expect(inventoryTab, findsOneWidget);
      await tester.tap(inventoryTab);
      await tester.pumpAndSettle();
      expect(find.textContaining('Amoxicillin'), findsAtLeastNWidgets(1));

      // Sub-tab 2: Cold Chain & Safety
      final coldChainTab = find.text('Cold Chain & Safety');
      expect(coldChainTab, findsOneWidget);
      await tester.tap(coldChainTab);
      await tester.pumpAndSettle();
      expect(find.text('Ice-Lined Refrigerator (ILR) Telemetry'), findsOneWidget);
    });

    testWidgets('Lab Technician sees only LabTechnicianWorkstationTab with diagnostic worklist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final labSession = FacilityStaffRequestDto(
        id: 'STAFF-LAB-1',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Mahesh Kadam (MLT)',
        mobile: '9822023456',
        role: FacilityStaffRole.labTechnician,
        licenseOrEmployeeId: 'LAB-5544',
        department: 'Pathology & Diagnostic Wing',
        status: FacilityApprovalStatus.approved,
        submittedAt: DateTime.now(),
      );

      facRepo.setCurrentStaffSession(labSession);

      await tester.pumpWidget(
        const MaterialApp(
          home: FacilityDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Lab Technician Workstation is active
      expect(find.byType(LabTechnicianWorkstationTab), findsOneWidget);
      expect(find.byType(PharmacistWorkstationTab), findsNothing);
      expect(find.byType(FacilityOverviewTab), findsNothing);

      // Verify Lab role badge in AppBar
      expect(find.textContaining('Mahesh Kadam (MLT)'), findsOneWidget);
      expect(find.text('Lab Technician'), findsOneWidget);

      // Sub-tab 0: Investigation Worklist
      expect(find.text('Investigation Worklist'), findsOneWidget);
      expect(find.text('Lab Worklist Queue Clear'), findsOneWidget);

      // Sub-tab 1: Reagents & Test Kits
      final reagentsTab = find.text('Reagents & Test Kits');
      expect(reagentsTab, findsOneWidget);
      await tester.tap(reagentsTab);
      await tester.pumpAndSettle();
      expect(find.text('Reagents & Test Kits'), findsOneWidget);
    });

    testWidgets('Staff Nurse sees only StaffNurseWorkstationTab with inpatient beds & vitals', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final nurseSession = FacilityStaffRequestDto(
        id: 'STAFF-NURSE-1',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Sister Anjali Shinde',
        mobile: '9822034567',
        role: FacilityStaffRole.staffNurse,
        licenseOrEmployeeId: 'NURSE-2211',
        department: 'Inpatient & Triage Ward',
        status: FacilityApprovalStatus.approved,
        submittedAt: DateTime.now(),
      );

      facRepo.setCurrentStaffSession(nurseSession);

      await tester.pumpWidget(
        const MaterialApp(
          home: FacilityDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Nurse Workstation is active
      expect(find.byType(StaffNurseWorkstationTab), findsOneWidget);
      expect(find.byType(PharmacistWorkstationTab), findsNothing);
      expect(find.byType(FacilityOverviewTab), findsNothing);

      // Verify Nurse role badge in AppBar
      expect(find.textContaining('Sister Anjali Shinde'), findsOneWidget);
      expect(find.text('Staff Nurse'), findsOneWidget);

      // Sub-tab 0: Wards & Beds
      expect(find.text('Inpatient Wards Breakdown'), findsOneWidget);
      expect(find.text('Live Bed Stepper Control'), findsOneWidget);

      // Sub-tab 1: Medication Rounds
      final medRoundsTab = find.text('Medication Rounds');
      expect(medRoundsTab, findsOneWidget);
      await tester.tap(medRoundsTab);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sunita Bai Gaikwad'), findsOneWidget);
    });

    testWidgets('Reception Clerk sees only ReceptionIntakeWorkstationTab with fast token issue & 108 relay', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final clerkSession = FacilityStaffRequestDto(
        id: 'STAFF-RECEP-1',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Deepak More',
        mobile: '9822045678',
        role: FacilityStaffRole.receptionClerk,
        licenseOrEmployeeId: 'CLERK-9900',
        department: 'Main Registration & Helpdesk',
        status: FacilityApprovalStatus.approved,
        submittedAt: DateTime.now(),
      );

      facRepo.setCurrentStaffSession(clerkSession);

      await tester.pumpWidget(
        const MaterialApp(
          home: FacilityDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Reception Workstation is active
      expect(find.byType(ReceptionIntakeWorkstationTab), findsOneWidget);
      expect(find.byType(StaffNurseWorkstationTab), findsNothing);
      expect(find.byType(FacilityOverviewTab), findsNothing);

      // Verify Reception role badge in AppBar
      expect(find.textContaining('Deepak More'), findsOneWidget);
      expect(find.text('Intake Clerk'), findsOneWidget);

      // Sub-tab 0: Check-In Desk
      expect(find.text('Fast-Track Arrival Token Issuance'), findsOneWidget);

      // Sub-tab 1: 108 Ambulances
      final ambulancesTab = find.text('108 Ambulances');
      expect(ambulancesTab, findsOneWidget);
      await tester.tap(ambulancesTab);
      await tester.pumpAndSettle();
      expect(find.text('Call Driver'), findsAtLeastNWidgets(1));
    });

    testWidgets('Facility Admin sees complete Hospital Cockpit with Staff Desk tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final adminSession = FacilityStaffRequestDto(
        id: 'STAFF-ADM-1',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
        staffName: 'Dr. Vivek Ranade',
        mobile: '9822099999',
        role: FacilityStaffRole.facilityAdmin,
        licenseOrEmployeeId: 'HFR-MH-PUN-001',
        department: 'Medical Superintendent Office',
        status: FacilityApprovalStatus.approved,
        submittedAt: DateTime.now(),
      );

      facRepo.setCurrentStaffSession(adminSession);

      await tester.pumpWidget(
        const MaterialApp(
          home: FacilityDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Admin Overview Tab is active by default
      expect(find.byType(FacilityOverviewTab), findsOneWidget);
      expect(find.textContaining('Bed Capacity & Occupancy'), findsOneWidget);

      // Verify Staff Desk navigation tab is present
      final staffDeskTab = find.byKey(const ValueKey('facility_nav_4'));
      expect(staffDeskTab, findsOneWidget);

      // Tap Staff Desk
      await tester.tap(staffDeskTab);
      await tester.pumpAndSettle();

      // Verify FacilityStaffApprovalsTab is displayed
      expect(find.byType(FacilityStaffApprovalsTab), findsOneWidget);
      expect(find.text('Staff Approvals Desk'), findsOneWidget);
      expect(find.text('Pending Staff Authorization Requests'), findsOneWidget);
    });
  });
}
