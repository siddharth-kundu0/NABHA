import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/features/facility/widgets/facility_doctor_approvals_tab.dart';

/// Overview / Dashboard Tab (Stitch Screen 1 & Desktop Facility Management)
/// Features:
/// 1. Facility banner with 24x7 badge and interactive Staff Role Dropdown.
/// 2. Operational high-priority alerts (Amoxicillin & ORS low stock, Vaccine 4.2°C).
/// 3. 4-card Bento metrics grid (Appointments, Queue, Referrals, Lab).
/// 4. Quick operations 2x2 grid with live count badges.
/// 5. Live OPD room schedule (Room 1 MCH, Room 2 NCD).
/// 6. Inbound Urgent Emergency Case Card (Ramesh Sharma) with "Prepare Intake" action.
/// 7. Bed Capacity & live stepper ([-] Admit, [+] Discharge, 4/6 ICU, 2 Suites Free).
/// 8. Weekly Patient Encounters histogram (Mon-Sun, 682 total).
class FacilityOverviewTab extends StatelessWidget {
  final void Function(int index) onTabSelected;

  const FacilityOverviewTab({super.key, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final facRepo = FacilityRepository();
    final refRepo = ReferralRepository();
    final apptRepo = AppointmentRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([facRepo, refRepo, apptRepo, session]),
      builder: (context, _) {
        final strings = FacilityStrings.of(session);
        final facilities = facRepo.facilities;
        final facility = facRepo.currentFacility;
        final activeReferrals = refRepo.referrals;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Facility Header & Role Perspective Switcher Banner
              _buildShiftBanner(context, facility, facRepo, strings),

              const SizedBox(height: 14),

              // 2. High Priority Operational Alerts (Stitch Screen 1)
              _buildOperationalAlerts(context, strings),

              const SizedBox(height: 16),

              // 3. 4-Card Bento Metrics Grid
              _buildBentoMetrics(context, strings, activeReferrals.length),

              const SizedBox(height: 20),

              // 4. Quick Operations 2x2 Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(strings.quickOperations, style: AppTypography.sectionTitle),
                  Text(
                    facRepo.activeRoleTitle,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: RuralCareColors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildQuickOperationsGrid(context, strings, facRepo),

              const SizedBox(height: 20),

              // Doctor Affiliation Approvals Card
              ListenableBuilder(
                listenable: DoctorRepository(),
                builder: (context, _) {
                  final pending = DoctorRepository().getPendingRequestsForFacility(facRepo.currentFacility.id);
                  return Container(
                    decoration: BoxDecoration(
                      color: pending.isNotEmpty ? const Color(0xFFFEF3C7) : const Color(0xFFE8F5F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: pending.isNotEmpty ? const Color(0xFFB45309).withOpacity(0.4) : const Color(0xFF0A6B56).withOpacity(0.3),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: pending.isNotEmpty ? const Color(0xFFFFFBEB) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: pending.isNotEmpty ? const Color(0xFFB45309) : const Color(0xFF0A6B56),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pending.isNotEmpty
                                    ? '${pending.length} Doctor Request${pending.length > 1 ? 's' : ''} Pending'
                                    : 'Medical Officer Affiliations Active',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: pending.isNotEmpty ? const Color(0xFFB45309) : const Color(0xFF0A6B56),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pending.isNotEmpty
                                    ? 'Review practitioner credentials and issue Doctor IDs.'
                                    : 'All affiliated physicians are verified with State Medical Council.',
                                style: AppTypography.supporting.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FacilityDoctorApprovalsTab()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pending.isNotEmpty ? const Color(0xFFB45309) : const Color(0xFF0A6B56),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(pending.isNotEmpty ? 'Review' : 'View Desk', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              // 5. OPD Schedule & Inbound Emergency Intake
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(strings.opdSchedule, style: AppTypography.sectionTitle),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: AppDecorations.statusBadge(background: RuralCareColors.tealSoft),
                    child: const Text(
                      '3 Active',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: RuralCareColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildOpdScheduleList(context, strings, refRepo),

              const SizedBox(height: 22),

              // 6. Bed Capacity & Live Occupancy Stepper
              _buildBedManagementCard(context, facility, facRepo, strings),

              const SizedBox(height: 22),

              // 7. Capacity & Weekly Encounters Histogram (Desktop Console)
              _buildWeeklyEncountersCard(context, strings),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // 1. Facility Header & Role Perspective Switcher
  Widget _buildShiftBanner(
    BuildContext context,
    dynamic facility,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RuralCareColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            facility.name as String,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: RuralCareColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: RuralCareColors.tealSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '24x7 PHC',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: RuralCareColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: RuralCareColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${strings.shiftActive} • ${facRepo.currentShift}',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: RuralCareColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Role Perspective Popup Menu Button
              PopupMenuButton<String>(
                initialValue: facRepo.activeStaffRole,
                onSelected: (role) {
                  facRepo.setActiveStaffRole(role);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched view to: ${facRepo.activeRoleTitle}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 18, color: RuralCareColors.teal),
                        SizedBox(width: 8),
                        Text('Facility Admin', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Doctor',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 18, color: RuralCareColors.teal),
                        SizedBox(width: 8),
                        Text('Medical Officer', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Pharmacist',
                    child: Row(
                      children: [
                        Icon(Icons.medication_outlined, size: 18, color: RuralCareColors.teal),
                        SizedBox(width: 8),
                        Text('Chief Pharmacist', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Diagnostic',
                    child: Row(
                      children: [
                        Icon(Icons.biotech_outlined, size: 18, color: RuralCareColors.teal),
                        SizedBox(width: 8),
                        Text('Lab Staff', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RuralCareColors.border),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, size: 16, color: RuralCareColors.teal),
                      const SizedBox(width: 4),
                      Text(
                        facRepo.activeStaffRole,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: RuralCareColors.teal,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16, color: RuralCareColors.teal),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. High Priority Operational Alerts
  Widget _buildOperationalAlerts(BuildContext context, FacilityStrings strings) {
    return Column(
      children: [
        // Low Stock Alert
        Container(
          decoration: BoxDecoration(
            color: RuralCareColors.warningSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RuralCareColors.warning.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: RuralCareColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_outlined, color: RuralCareColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Amoxicillin & ORS (Low Stock)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: RuralCareColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: RuralCareColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '3d left',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_right, color: RuralCareColors.warning, size: 20),
                onPressed: () => onTabSelected(3), // Jump to Services tab
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Vaccine Cold-Chain Secure
        Container(
          decoration: BoxDecoration(
            color: RuralCareColors.successSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RuralCareColors.success.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: RuralCareColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.ac_unit, color: RuralCareColors.success, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Vaccine Storage 4.2°C (Secure)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RuralCareColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RuralCareColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ILR 1 Verified',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. 4-Card Bento Metrics Grid
  Widget _buildBentoMetrics(BuildContext context, FacilityStrings strings, int activeRefCount) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        // 1. Appointments
        _buildBentoTile(
          icon: Icons.calendar_today_outlined,
          iconColor: RuralCareColors.teal,
          title: strings.appointments,
          value: '28',
          subLabel: strings.total,
          footerLeading: '18 Done',
          footerLeadingColor: RuralCareColors.success,
          footerTrailing: '10 Left',
          footerTrailingColor: RuralCareColors.critical,
          onTap: () => onTabSelected(1),
        ),
        // 2. Queue Waiting
        _buildBentoTile(
          icon: Icons.schedule_outlined,
          iconColor: RuralCareColors.warning,
          title: strings.queueWaiting,
          value: '7',
          subLabel: 'in line',
          footerLeading: '2 In Consultation',
          footerLeadingColor: RuralCareColors.teal,
          isPulsing: true,
          onTap: () => onTabSelected(1),
        ),
        // 3. Active Referrals
        _buildBentoTile(
          icon: Icons.swap_horiz,
          iconColor: RuralCareColors.primary,
          title: strings.activeReferrals,
          value: activeRefCount > 0 ? '$activeRefCount' : '4',
          subLabel: 'Active',
          footerLeading: '2 Inbound',
          footerLeadingColor: RuralCareColors.primary,
          footerTrailing: '2 Outbound',
          footerTrailingColor: RuralCareColors.textSecondary,
          onTap: () => onTabSelected(2),
        ),
        // 4. Lab Diagnostics
        _buildBentoTile(
          icon: Icons.biotech_outlined,
          iconColor: RuralCareColors.teal,
          title: strings.labDiagnostics,
          value: '6',
          subLabel: strings.pending,
          footerLeading: '4 Collected',
          footerLeadingColor: RuralCareColors.textSecondary,
          footerTrailing: '2 Due',
          footerTrailingColor: RuralCareColors.warning,
          onTap: () => onTabSelected(3),
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subLabel,
    required String footerLeading,
    required Color footerLeadingColor,
    String? footerTrailing,
    Color? footerTrailingColor,
    bool isPulsing = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: RuralCareColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RuralCareColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RuralCareColors.textSecondary,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: iconColor, size: 14),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: RuralCareColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    subLabel,
                    style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: RuralCareColors.border, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPulsing)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(color: footerLeadingColor, shape: BoxShape.circle),
                          ),
                        Text(
                          footerLeading,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: footerLeadingColor,
                          ),
                        ),
                      ],
                    ),
                    if (footerTrailing != null)
                      Text(
                        footerTrailing,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: footerTrailingColor ?? RuralCareColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Quick Operations 2x2 Grid
  Widget _buildQuickOperationsGrid(BuildContext context, FacilityStrings strings, FacilityRepository facRepo) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [
        // 1. Queue Desk
        _buildOperationButton(
          title: strings.queueDesk,
          subtitle: strings.queueDeskSub,
          icon: Icons.format_list_numbered,
          badgeCount: 7,
          badgeColor: RuralCareColors.critical,
          onTap: () => onTabSelected(1),
        ),
        // 2. Patient Intake
        _buildOperationButton(
          title: strings.patientIntake,
          subtitle: strings.patientIntakeSub,
          icon: Icons.person_search,
          iconBgColor: RuralCareColors.primarySoft,
          iconColor: RuralCareColors.primary,
          onTap: () => _showFastTrackIntakeSheet(context),
        ),
        // 3. Referrals Desk
        _buildOperationButton(
          title: strings.referralNetwork,
          subtitle: strings.referralNetworkSub,
          icon: Icons.local_shipping_outlined,
          badgeCount: 4,
          badgeColor: RuralCareColors.primary,
          onTap: () => onTabSelected(2),
        ),
        // 4. Service Status
        _buildOperationButton(
          title: strings.serviceStatus,
          subtitle: strings.serviceStatusSub,
          icon: Icons.medical_services_outlined,
          onTap: () => onTabSelected(3),
        ),
      ],
    );
  }

  Widget _buildOperationButton({
    required String title,
    required String subtitle,
    required IconData icon,
    int? badgeCount,
    Color? badgeColor,
    Color? iconBgColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: RuralCareColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RuralCareColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBgColor ?? RuralCareColors.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
                  ),
                  if (badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: badgeColor ?? RuralCareColors.critical,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            '$badgeCount',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: RuralCareColors.textPrimary,
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: RuralCareColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. OPD Schedule & Inbound Emergency Intake (Stitch Screen 1)
  Widget _buildOpdScheduleList(BuildContext context, FacilityStrings strings, ReferralRepository refRepo) {
    return Column(
      children: [
        // Room 1: MCH & Immunization
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: RuralCareColors.tealSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pregnant_woman, color: RuralCareColors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MCH & Immunization',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                        ),
                        Text(
                          'Room 1 • ${DoctorRepository().registeredDoctors.isNotEmpty ? DoctorRepository().registeredDoctors.first.name : 'Attending MO'}, MBBS',
                          style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: RuralCareColors.warningSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '10:30 AM',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.warning),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hourglass_top, size: 14, color: RuralCareColors.warning),
                      SizedBox(width: 4),
                      Text(
                        '4 patients waiting',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.warning),
                      ),
                    ],
                  ),
                  Text('मातृ एवं शिशु स्वास्थ्य', style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Room 2: NCD & General OPD
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: RuralCareColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_outline, color: RuralCareColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NCD & General OPD',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                        ),
                        Text(
                          'Room 2 • Nurse Sunita, RN',
                          style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: RuralCareColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '11:00 AM',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups_outlined, size: 14, color: RuralCareColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        '3 patients queued',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                      ),
                    ],
                  ),
                  Text('गैर-संचारी रोग जांच', style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // INBOUND URGENT Emergency Alert Card (Stitch Screen 1)
        Container(
          decoration: BoxDecoration(
            color: RuralCareColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RuralCareColors.critical, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x1AB42318), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: RuralCareColors.criticalSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emergency, color: RuralCareColors.critical, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: RuralCareColors.critical,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                strings.inboundUrgent,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ETA 11:30 AM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: RuralCareColors.critical,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ramesh Sharma (Age 54)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: RuralCareColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Severe Asthma / Acute Dyspnea • SpO2 88%',
                          style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: RuralCareColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: RuralCareColors.critical),
                        SizedBox(width: 4),
                        Text(
                          'From SC Kalyanpur (Ambulance 108)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEmergencyIntakeModal(context, refRepo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RuralCareColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.assignment_turned_in, size: 16),
                      label: Text(strings.prepareIntake, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Bed Management Card with live occupancy stepper
  Widget _buildBedManagementCard(
    BuildContext context,
    dynamic fac,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    final available = fac.availableBeds as int;
    final total = fac.totalBeds as int;
    final occupied = total - available;
    final occupancyRatio = occupied / (total > 0 ? total : 1);

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.bedCapacity, style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.tealSoft),
                child: Text(
                  strings.liveTelemetry,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: RuralCareColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '$available ',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: RuralCareColors.teal,
                      ),
                      children: [
                        TextSpan(
                          text: '/ $total',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: RuralCareColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(strings.vacantBeds, style: AppTypography.supporting),
                ],
              ),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: available > 0
                        ? () {
                            facRepo.updateAvailableBeds(fac.id as String, available - 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Patient admitted. Bed capacity updated.'),
                                duration: Duration(milliseconds: 1200),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                    tooltip: strings.admitPatient,
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: available < total
                        ? () {
                            facRepo.updateAvailableBeds(fac.id as String, available + 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Patient discharged. Bed capacity restored.'),
                                duration: Duration(milliseconds: 1200),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add),
                    tooltip: strings.dischargePatient,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: occupancyRatio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: RuralCareColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                occupancyRatio > 0.85
                    ? RuralCareColors.critical
                    : (occupancyRatio > 0.70 ? RuralCareColors.warning : RuralCareColors.teal),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occupancy: ${(occupancyRatio * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
              ),
              const Text(
                '4 / 6 ICU Occupied • 2 Delivery Suites Free',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Weekly Encounters Histogram (Desktop Healthcare Facility Management)
  Widget _buildWeeklyEncountersCard(BuildContext context, FacilityStrings strings) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.weeklyEncounters, style: AppTypography.cardTitle),
              const Text(
                '682 Total',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: RuralCareColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day bars histogram
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDayBar('Mon', 92, 120),
              _buildDayBar('Tue', 114, 120),
              _buildDayBar('Wed', 120, 120, isPeak: true),
              _buildDayBar('Thu', 105, 120),
              _buildDayBar('Fri', 98, 120),
              _buildDayBar('Sat', 85, 120),
              _buildDayBar('Sun', 68, 120),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayBar(String day, int count, int max, {bool isPeak = false}) {
    final double barHeight = (count / max) * 64;
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 9,
            fontWeight: isPeak ? FontWeight.bold : FontWeight.w500,
            color: isPeak ? RuralCareColors.teal : RuralCareColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 18,
          height: barHeight,
          decoration: BoxDecoration(
            color: isPeak ? RuralCareColors.teal : RuralCareColors.tealSoft,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
            color: RuralCareColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Fast-track Arrival Sheet
  void _showFastTrackIntakeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: RuralCareColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fast-Track Arrival Token', style: AppTypography.pageTitle),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Register new walk-in or ambulance arrival directly into OPD queue:'),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: 'RC-9842-7105',
                decoration: const InputDecoration(
                  labelText: 'Patient ABHA ID / RuralCare ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: 'Ramesh Sharma',
                decoration: const InputDecoration(
                  labelText: 'Patient Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ReferralRepository().checkInReferralByToken('REF-9842-104');
                    Navigator.pop(ctx);
                    onTabSelected(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Token #TK-29 issued. Patient REF-9842-104 checked in and added to today\'s emergency queue.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Generate Token & Queue Patient', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Emergency Intake Modal for Ramesh Sharma
  void _showEmergencyIntakeModal(BuildContext context, ReferralRepository refRepo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: RuralCareColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emergency, color: RuralCareColors.critical),
                      SizedBox(width: 8),
                      Text('Emergency Intake Preparation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Patient: Ramesh Sharma (Age 54, Male)\nReferred From: SC Kalyanpur by CHO Sunita\nClinical Status: Severe Asthma Attack (SpO2 88%)',
                style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RuralCareColors.tealSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: RuralCareColors.teal),
                        SizedBox(width: 8),
                        Text('Oxygen Concentrator prepped in Room 1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: RuralCareColors.teal),
                        SizedBox(width: 8),
                        Text('Salbutamol nebulization kit reserved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    refRepo.acknowledgeArrival('REF-9842-104');
                    Navigator.pop(ctx);
                    onTabSelected(2); // Jump to Referrals
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Emergency Triage Bay assigned. Patient arrival prepped.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.critical,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Confirm Intake Readiness & Acknowledge Arrival', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
