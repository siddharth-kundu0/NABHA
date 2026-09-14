import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/doctor/utils/doctor_strings.dart';
import 'package:ruralcare/features/doctor/screens/doctor_clinical_summary_screen.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';

/// Stitch Screen 1: Doctor Dashboard (Mobile 780x3934)
/// Screen ID: 70eda21ad5234c67ba2d2fa84a73cb39
class DoctorHomeTab extends StatefulWidget {
  final Function(int) onTabSelected;

  const DoctorHomeTab({
    super.key,
    required this.onTabSelected,
  });

  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  int _scheduleFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final aptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();
    final refRepo = ReferralRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([aptRepo, patientRepo, refRepo, session]),
      builder: (context, _) {
        final strings = DoctorStrings.of(session);
        final doctor = DoctorRepository().getDoctorForSession(session);
        final appointments = aptRepo.appointments;
        final patients = patientRepo.patients;
        final referrals = refRepo.referrals;

        final waitingCount = appointments.where((a) => a.status == 'WAITING_ROOM').length;
        final completedCount = appointments.where((a) => a.status == 'COMPLETED').length;
        final pendingReferralsCount = referrals.where((r) => r.status != 'COMPLETED' && r.status != 'CLOSED').length;

        // Filter appointments according to selected filter
        List<AppointmentDto> filteredList = appointments;
        if (_scheduleFilterIndex == 1) {
          filteredList = appointments.where((a) => a.status == 'WAITING_ROOM').toList();
        } else if (_scheduleFilterIndex == 2) {
          filteredList = appointments.where((a) => a.type == 'TELECONSULTATION').toList();
        } else if (_scheduleFilterIndex == 3) {
          filteredList = appointments.where((a) => a.chiefComplaint.toLowerCase().contains('anc') || a.chiefComplaint.toLowerCase().contains('follow')).toList();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Offline/Online Tactical Status Ribbon
              _buildTacticalStatusRibbon(session.isOffline, strings),
              const SizedBox(height: 12),

              // 2. Clinician Persona & Facility Card
              _buildClinicianPersonaCard(session, doctor, strings),
              const SizedBox(height: 14),

              // 3. Tactical Workload 2x2 Bento Metric Grid
              _buildBentoWorkloadGrid(
                strings: strings,
                totalAppointments: appointments.length,
                doneCount: completedCount,
                waitingCount: waitingCount,
                followupsCount: appointments.where((a) => a.chiefComplaint.toLowerCase().contains('follow') || a.type == 'FOLLOW_UP').length,
                pendingReferrals: pendingReferralsCount,
              ),
              const SizedBox(height: 16),

              // 4. Quick Clinical Actions (4 shortcuts)
              _buildQuickClinicalActions(waitingCount, strings),
              const SizedBox(height: 18),

              // 5. Today's Schedule Section
              _buildScheduleHeader(strings),
              const SizedBox(height: 10),

              // 6. Filter Pills
              _buildScheduleFilterPills(strings, appointments),
              const SizedBox(height: 12),

              // 7. Appointment Cards List
              if (filteredList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 40,
                          color: RuralCareColors.teal.withOpacity(0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.noAppointmentsScheduled,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: RuralCareColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.noAppointmentsScheduledSub,
                          style: const TextStyle(
                            fontSize: 12,
                            color: RuralCareColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredList.map((apt) {
                  final patient = patients.firstWhere(
                    (p) => p.id == apt.patientId || p.fullName == apt.patientName,
                    orElse: () => PatientDto(
                      id: apt.patientId,
                      ruralCareId: 'RC-${apt.patientId}',
                      abhaId: 'ABHA-${apt.patientId}',
                      fullName: apt.patientName,
                      age: 35,
                      gender: 'Other',
                      phoneNumber: '9876543210',
                      village: apt.facilityName,
                      subCentre: 'Sub-Centre',
                      district: 'District',
                      assignedAsha: 'ASHA Worker',
                      emergencyContact: const EmergencyContactDto(
                        name: 'Contact',
                        relationship: 'Family',
                        phoneNumber: '9876543210',
                      ),
                    ),
                  );
                  return _buildAppointmentCard(context, apt, patient, strings);
                }),

              const SizedBox(height: 14),

              // 8. Clinical Governance Notice
              _buildClinicalGovernanceNotice(strings),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTacticalStatusRibbon(bool isOffline, DoctorStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOffline ? RuralCareColors.warningSoft : RuralCareColors.tealSoft,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOffline ? RuralCareColors.warning : RuralCareColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOffline ? strings.statusOffline : strings.statusOnlineSync,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isOffline ? RuralCareColors.warning : RuralCareColors.teal,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: RuralCareColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '10:42 AM',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicianPersonaCard(SessionCoordinator session, RegisteredDoctorAccount doctor, DoctorStrings strings) {
    final rawClean = doctor.name.replaceAll('Dr. ', '').replaceAll('Dr.', '').trim();
    final nameParts = rawClean.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : (nameParts.isNotEmpty ? nameParts[0][0].toUpperCase() : 'DR');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RuralCareColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: RuralCareColors.teal,
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: RuralCareColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${doctor.name}, ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: RuralCareColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      doctor.qualification,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RuralCareColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${doctor.specialty} • ${strings.clinicianRole}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RuralCareColors.teal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.facilityName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: RuralCareColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoWorkloadGrid({
    required DoctorStrings strings,
    required int totalAppointments,
    required int doneCount,
    required int waitingCount,
    required int followupsCount,
    required int pendingReferrals,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Card 1: Today's Appts
        _buildBentoCard(
          title: strings.todaysAppointments,
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.skyBlue,
          iconBg: AppColors.skyBlueSoft,
          primaryValue: '$totalAppointments',
          secondaryLabel: '$doneCount ${strings.done}',
          secondaryColor: AppColors.skyBlue,
          progress: 0.57,
          progressColor: AppColors.skyBlue,
        ),
        // Card 2: In Queue
        _buildBentoCard(
          title: strings.inQueue,
          icon: Icons.hourglass_top_rounded,
          iconColor: RuralCareColors.warning,
          iconBg: RuralCareColors.warningSoft,
          primaryValue: '$waitingCount',
          secondaryLabel: strings.waiting,
          secondaryColor: RuralCareColors.warning,
          progress: 0.75,
          progressColor: RuralCareColors.warning,
        ),
        // Card 3: Follow-ups
        _buildBentoCard(
          title: strings.followups,
          icon: Icons.autorenew_rounded,
          iconColor: RuralCareColors.teal,
          iconBg: RuralCareColors.tealSoft,
          primaryValue: '$followupsCount',
          secondaryLabel: strings.ancNcd,
          secondaryColor: RuralCareColors.teal,
          progress: 0.40,
          progressColor: RuralCareColors.teal,
        ),
        // Card 4: Pending Referrals
        _buildBentoCard(
          title: strings.pendingReferrals,
          icon: Icons.forward_to_inbox_rounded,
          iconColor: const Color(0xFFC2410C),
          iconBg: const Color(0xFFFFEDD5),
          primaryValue: '$pendingReferrals',
          secondaryLabel: strings.pending,
          secondaryColor: const Color(0xFFC2410C),
          progress: 0.60,
          progressColor: const Color(0xFFC2410C),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String primaryValue,
    required String secondaryLabel,
    required Color secondaryColor,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RuralCareColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                primaryValue,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: RuralCareColors.textPrimary),
              ),
              const SizedBox(width: 6),
              Text(
                secondaryLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: secondaryColor),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: RuralCareColors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickClinicalActions(int queueBadge, DoctorStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.quickActions,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
            ),
            Text(
              strings.quickActionsSub,
              style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Shortcut 1: Queue (Tab 2)
            Expanded(
              child: _buildActionShortcut(
                icon: Icons.checklist_rounded,
                iconBg: RuralCareColors.teal,
                iconColor: Colors.white,
                badgeText: '$queueBadge',
                label: strings.actionQueue,
                subLabel: strings.actionQueue,
                onTap: () => widget.onTabSelected(2),
              ),
            ),
            const SizedBox(width: 8),
            // Shortcut 2: Search Patients (Tab 1)
            Expanded(
              child: _buildActionShortcut(
                icon: Icons.person_search_rounded,
                iconBg: RuralCareColors.tealSoft,
                iconColor: RuralCareColors.teal,
                label: strings.actionSearch,
                subLabel: strings.actionSearch,
                onTap: () => widget.onTabSelected(1),
              ),
            ),
            const SizedBox(width: 8),
            // Shortcut 3: Follow-ups
            Expanded(
              child: _buildActionShortcut(
                icon: Icons.event_available_rounded,
                iconBg: const Color(0xFFE8F5F2),
                iconColor: RuralCareColors.teal,
                label: strings.actionFollowups,
                subLabel: strings.actionFollowups,
                onTap: () {
                  setState(() => _scheduleFilterIndex = 3);
                },
              ),
            ),
            const SizedBox(width: 8),
            // Shortcut 4: Referrals (Tab 3)
            Expanded(
              child: _buildActionShortcut(
                icon: Icons.call_split_rounded,
                iconBg: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFC2410C),
                label: strings.actionReferrals,
                subLabel: strings.actionReferrals,
                onTap: () => widget.onTabSelected(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionShortcut({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    String? badgeText,
    required String label,
    required String subLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: RuralCareColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RuralCareColors.border),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconBg,
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                if (badgeText != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: RuralCareColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
            ),
            Text(
              subLabel,
              style: const TextStyle(fontSize: 9, color: RuralCareColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleHeader(DoctorStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              strings.todaysSchedule,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Text(
              strings.todaysScheduleSub,
              style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
            ),
          ],
        ),
        InkWell(
          onTap: () => widget.onTabSelected(2),
          child: Row(
            children: [
              Text(
                strings.viewQueue,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
              ),
              const Icon(Icons.chevron_right, size: 16, color: RuralCareColors.teal),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleFilterPills(DoctorStrings strings, List<AppointmentDto> appointments) {
    final allCount = appointments.length;
    final waitingCount = appointments.where((a) => a.status == 'WAITING_ROOM').length;
    final teleconsultCount = appointments.where((a) => a.type == 'TELECONSULTATION').length;
    final followupCount = appointments.where((a) => a.chiefComplaint.toLowerCase().contains('follow') || a.type == 'FOLLOW_UP').length;

    final filters = [
      '${strings.filterAll} ($allCount)',
      '${strings.filterWaiting} ($waitingCount)',
      '${strings.filterTeleconsult} ($teleconsultCount)',
      '${strings.filterFollowupDue} ($followupCount)',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final isSelected = entry.key == _scheduleFilterIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) => setState(() => _scheduleFilterIndex = entry.key),
              selectedColor: RuralCareColors.teal,
              backgroundColor: RuralCareColors.surface,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : RuralCareColors.textSecondary,
              ),
              side: BorderSide(color: isSelected ? RuralCareColors.teal : RuralCareColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentDto apt, PatientDto patient, DoctorStrings strings) {
    final doctor = DoctorRepository().getDoctorForSession(SessionCoordinator());
    final isInConsultation = apt.status == 'IN_PROGRESS';
    final isTeleconsult = apt.type == 'TELECONSULTATION';
    final isWaiting = apt.status == 'WAITING_ROOM';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInConsultation ? RuralCareColors.success : RuralCareColors.border,
          width: isInConsultation ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isInConsultation ? RuralCareColors.teal : RuralCareColors.surfaceSubtle,
                child: Text(
                  patient.fullName.isNotEmpty ? patient.fullName[0] : 'P',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isInConsultation ? Colors.white : RuralCareColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt.patientName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                    ),
                    Text(
                      '${patient.age}${patient.gender.isNotEmpty ? patient.gender[0] : "M"} • ${patient.village} | ${patient.ruralCareId}',
                      style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Status Badge
              if (isInConsultation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RuralCareColors.successSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 6, color: RuralCareColors.success),
                      const SizedBox(width: 4),
                      Text(strings.inConsultation, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success)),
                    ],
                  ),
                )
              else if (isWaiting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RuralCareColors.warningSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 10, color: RuralCareColors.warning),
                      const SizedBox(width: 4),
                      Text(strings.waiting, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.warning)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(strings.completedStatus, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Info Box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isTeleconsult ? Icons.videocam_outlined : Icons.medical_services_outlined,
                      size: 15,
                      color: isTeleconsult ? AppColors.skyBlue : RuralCareColors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      apt.chiefComplaint.length > 30 ? '${apt.chiefComplaint.substring(0, 30)}...' : apt.chiefComplaint,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: RuralCareColors.textPrimary),
                    ),
                  ],
                ),
                Text(
                  apt.appointmentTime.contains(' ') ? apt.appointmentTime.split(' ').last : '11:00 AM',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isTeleconsult ? Icons.wifi : Icons.room_outlined,
                    size: 14,
                    color: isTeleconsult ? RuralCareColors.success : RuralCareColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isTeleconsult ? strings.videoReady : strings.facilityRoom,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isTeleconsult ? FontWeight.w600 : FontWeight.normal,
                      color: isTeleconsult ? RuralCareColors.success : RuralCareColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (isInConsultation)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => DoctorClinicalSummaryScreen(
                          patient: patient,
                          appointmentId: apt.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: Text(strings.resume, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else if (isTeleconsult)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => LiveTeleconsultRoomScreen(
                          patientName: apt.patientName,
                          doctorName: doctor.name,
                          specialty: apt.specialty,
                          appointmentId: apt.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.videocam, size: 14),
                  label: Text(strings.callPatient, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => DoctorClinicalSummaryScreen(
                          patient: patient,
                          appointmentId: apt.id,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RuralCareColors.teal,
                    minimumSize: const Size(0, 36),
                    side: const BorderSide(color: RuralCareColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(strings.openRecord, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalGovernanceNotice(DoctorStrings strings) {
    final session = SessionCoordinator();
    final doctor = DoctorRepository().getDoctorForSession(session);
    final text = strings.isHi
        ? 'नैदानिक ​​दस्तावेज़ीकरण और प्रशासन • ${doctor.name}, ${doctor.facilityName}'
        : (strings.isMr
            ? 'क्लिनिकल दस्तऐवजीकरण आणि प्रशासन • ${doctor.name}, ${doctor.facilityName}'
            : 'Clinical documentation & governance • ${doctor.name}, ${doctor.facilityName}');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RuralCareColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 20, color: RuralCareColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
