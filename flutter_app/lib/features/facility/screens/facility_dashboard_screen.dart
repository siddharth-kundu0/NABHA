import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';
import 'package:ruralcare/features/notifications/screens/notification_center_screen.dart';
import 'package:ruralcare/features/facility/widgets/facility_overview_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_queue_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_services_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_referrals_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_profile_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_doctor_approvals_tab.dart';
import 'package:ruralcare/features/facility/widgets/facility_staff_approvals_tab.dart';
import 'package:ruralcare/features/facility/widgets/pharmacist_workstation_tab.dart';
import 'package:ruralcare/features/facility/widgets/lab_technician_workstation_tab.dart';
import 'package:ruralcare/features/facility/widgets/staff_nurse_workstation_tab.dart';
import 'package:ruralcare/features/facility/widgets/reception_intake_workstation_tab.dart';

/// Facility Operational Workstation Shell conforming to Stitch Designs & DESIGN.md Section 7.
/// Automatically renders the dedicated workspace corresponding strictly to the authenticated user's approved role:
/// - Pharmacist: Pharmacy & Dispensing Queue
/// - Lab Technician: Diagnostics & Pathology Worklist
/// - Staff Nurse: Inpatient Wards, Bed Stepper, Medication Rounds & Triage
/// - Reception Clerk: Fast Check-In, 108 Ambulance Intake & Referrals
/// - Facility Admin: Full Hospital Cockpit, Staff Approvals Desk, Doctor Verification, Services & Bed Ledger
class FacilityDashboardScreen extends StatefulWidget {
  final int initialTab;

  const FacilityDashboardScreen({super.key, this.initialTab = 0});

  @override
  State<FacilityDashboardScreen> createState() => _FacilityDashboardScreenState();
}

class _FacilityDashboardScreenState extends State<FacilityDashboardScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildCurrentTab(FacilityRepository facRepo) {
    final session = facRepo.currentStaffSession;
    final role = session?.role;
    final roleStr = facRepo.activeStaffRole;

    if (role == FacilityStaffRole.pharmacist || roleStr == 'Pharmacist') {
      return const PharmacistWorkstationTab();
    }

    if (role == FacilityStaffRole.labTechnician || roleStr == 'Lab Technician' || roleStr == 'Diagnostic') {
      return const LabTechnicianWorkstationTab();
    }

    if (role == FacilityStaffRole.staffNurse || roleStr == 'Staff Nurse' || roleStr == 'Nurse') {
      return const StaffNurseWorkstationTab();
    }

    if (role == FacilityStaffRole.receptionClerk || roleStr == 'Intake Clerk' || roleStr == 'Reception') {
      return const ReceptionIntakeWorkstationTab();
    }

    // Default: Facility Administrator Workspace
    switch (_currentIndex) {
      case 0:
        return FacilityOverviewTab(onTabSelected: _onTabSelected);
      case 1:
        return const FacilityQueueTab();
      case 2:
        return const FacilityServicesTab();
      case 3:
        return const FacilityReferralsTab();
      case 4:
        return const FacilityStaffApprovalsTab();
      case 5:
        return const FacilityProfileTab();
      default:
        return FacilityOverviewTab(onTabSelected: _onTabSelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final facRepo = FacilityRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([session, facRepo]),
      builder: (context, _) {
        final strings = FacilityStrings.of(session);
        final staffSession = facRepo.currentStaffSession;
        final role = staffSession?.role;
        final roleStr = facRepo.activeStaffRole;
        final isSpecificStaff = role == FacilityStaffRole.pharmacist ||
            roleStr == 'Pharmacist' ||
            role == FacilityStaffRole.labTechnician ||
            roleStr == 'Lab Technician' ||
            roleStr == 'Diagnostic' ||
            role == FacilityStaffRole.staffNurse ||
            roleStr == 'Staff Nurse' ||
            roleStr == 'Nurse' ||
            role == FacilityStaffRole.receptionClerk ||
            roleStr == 'Intake Clerk' ||
            roleStr == 'Reception';

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: RuralCareColors.teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RuralCare',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: RuralCareColors.teal,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: session.isOffline ? RuralCareColors.warning : RuralCareColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.isOffline ? strings.offline : strings.online,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: session.isOffline ? RuralCareColors.warning : RuralCareColors.success,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Language quick selector
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _langBadge('EN', 'en', session),
                    _langBadge('हि', 'hi', session),
                    _langBadge('म', 'mr', session),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Authenticated Staff Designation Badge (No ad-hoc switcher)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RuralCareColors.tealSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getBadgeIcon(role, roleStr), size: 14, color: RuralCareColors.teal),
                    const SizedBox(width: 4),
                    Text(
                      staffSession?.role.shortName ?? facRepo.activeRoleTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: RuralCareColors.teal,
                      ),
                    ),
                  ],
                ),
              ),

              // If Facility Admin, show Staff Approvals & Doctor Approvals quick actions
              if (!isSpecificStaff) ...[
                ListenableBuilder(
                  listenable: facRepo,
                  builder: (context, _) {
                    final pendingStaff = facRepo.getPendingStaffRequestsForFacility(facRepo.currentFacility.id).length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.people_outline, color: RuralCareColors.teal, size: 22),
                          tooltip: 'Staff Approvals Desk',
                          onPressed: () {
                            setState(() => _currentIndex = 4);
                          },
                        ),
                        if (pendingStaff > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFFB45309), shape: BoxShape.circle),
                              child: Text(
                                '$pendingStaff',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                ListenableBuilder(
                  listenable: DoctorRepository(),
                  builder: (context, _) {
                    final pending = DoctorRepository().getPendingRequestsForFacility('FAC-SC-102').length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.verified_user_outlined, color: RuralCareColors.teal, size: 22),
                          tooltip: 'Doctor Approvals Desk',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FacilityDoctorApprovalsTab()),
                            );
                          },
                        ),
                        if (pending > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFFB45309), shape: BoxShape.circle),
                              child: Text(
                                '$pending',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],

              // Notification Center Bell
              ListenableBuilder(
                listenable: NotificationRepository(),
                builder: (context, _) {
                  final notifRepo = NotificationRepository();
                  final unreadCount = notifRepo.getUnreadCount(AppRole.facilityStaff);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: RuralCareColors.textSecondary, size: 22),
                        tooltip: 'Notifications',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: RuralCareColors.critical, shape: BoxShape.circle),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(width: 8),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(color: RuralCareColors.border, height: 1),
            ),
          ),
          body: _buildCurrentTab(facRepo),
          bottomNavigationBar: isSpecificStaff
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: RuralCareColors.border, width: 1)),
                  ),
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onTabSelected,
                    backgroundColor: RuralCareColors.surface,
                    indicatorColor: RuralCareColors.tealSoft,
                    height: 64,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      NavigationDestination(
                        key: const ValueKey('facility_nav_0'),
                        icon: const Icon(Icons.dashboard_outlined),
                        selectedIcon: const Icon(Icons.dashboard_rounded, color: RuralCareColors.teal),
                        label: strings.tabDashboard,
                      ),
                      NavigationDestination(
                        key: const ValueKey('facility_nav_1'),
                        icon: const Icon(Icons.format_list_numbered_outlined),
                        selectedIcon: const Icon(Icons.format_list_numbered_rounded, color: RuralCareColors.teal),
                        label: strings.tabQueue,
                      ),
                      NavigationDestination(
                        key: const ValueKey('facility_nav_2'),
                        icon: const Icon(Icons.medical_services_outlined),
                        selectedIcon: const Icon(Icons.medical_services_rounded, color: RuralCareColors.teal),
                        label: strings.tabServices,
                      ),
                      NavigationDestination(
                        key: const ValueKey('facility_nav_3'),
                        icon: const Icon(Icons.swap_horiz_outlined),
                        selectedIcon: const Icon(Icons.swap_horiz_rounded, color: RuralCareColors.teal),
                        label: strings.tabReferrals,
                      ),
                      const NavigationDestination(
                        key: ValueKey('facility_nav_4'),
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people_rounded, color: RuralCareColors.teal),
                        label: 'Staff Desk',
                      ),
                      NavigationDestination(
                        key: const ValueKey('facility_nav_5'),
                        icon: const Icon(Icons.account_circle_outlined),
                        selectedIcon: const Icon(Icons.account_circle_rounded, color: RuralCareColors.teal),
                        label: strings.tabProfile,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  IconData _getBadgeIcon(FacilityStaffRole? role, String roleStr) {
    if (role == FacilityStaffRole.pharmacist || roleStr == 'Pharmacist') {
      return Icons.medication_outlined;
    }
    if (role == FacilityStaffRole.labTechnician || roleStr == 'Lab Technician' || roleStr == 'Diagnostic') {
      return Icons.biotech_outlined;
    }
    if (role == FacilityStaffRole.staffNurse || roleStr == 'Staff Nurse' || roleStr == 'Nurse') {
      return Icons.local_hospital_outlined;
    }
    if (role == FacilityStaffRole.receptionClerk || roleStr == 'Intake Clerk' || roleStr == 'Reception') {
      return Icons.how_to_reg_outlined;
    }
    return Icons.admin_panel_settings_outlined;
  }

  Widget _langBadge(String label, String code, SessionCoordinator session) {
    final current = session.activeLanguage;
    final isSelected = current == code ||
        (code == 'en' && (current == 'English' || current == 'en')) ||
        (code == 'hi' && (current == 'Hindi' || current == 'हिन्दी')) ||
        (code == 'mr' && (current == 'Marathi' || current == 'मराठी'));

    return InkWell(
      onTap: () => session.setLanguage(code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? RuralCareColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : RuralCareColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
