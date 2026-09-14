import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/doctor/utils/doctor_strings.dart';
import 'package:ruralcare/features/doctor/screens/doctor_clinical_summary_screen.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';

/// Stitch Screen 2: Patient Queue / Appointments (Mobile 780x3556)
/// Screen ID: 46ec37bec60b4b1e939a8b2f5b07a6e5
class DoctorQueueTab extends StatefulWidget {
  const DoctorQueueTab({super.key});

  @override
  State<DoctorQueueTab> createState() => _DoctorQueueTabState();
}

class _DoctorQueueTabState extends State<DoctorQueueTab> {
  int _queueDayIndex = 0; // 0 = Today's Queue, 1 = Tomorrow
  int _filterChipIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([aptRepo, patientRepo, session]),
      builder: (context, _) {
        final strings = DoctorStrings.of(session);
        final appointments = aptRepo.appointments;
        final patients = patientRepo.patients;

        final now = DateTime.now();
        final todayAppointments = appointments.where((a) {
          return a.scheduledTime.year == now.year &&
              a.scheduledTime.month == now.month &&
              a.scheduledTime.day == now.day;
        }).toList();

        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowAppointments = appointments.where((a) {
          return a.scheduledTime.year == tomorrow.year &&
              a.scheduledTime.month == tomorrow.month &&
              a.scheduledTime.day == tomorrow.day;
        }).toList();

        // Default to active day appointments (or all non-tomorrow if today has items)
        final activeDayList = _queueDayIndex == 0
            ? (todayAppointments.isNotEmpty ? todayAppointments : appointments)
            : tomorrowAppointments;

        final waitingCount = activeDayList.where((a) => a.status == 'WAITING_ROOM').length;
        final inConsultationCount = activeDayList.where((a) => a.status == 'IN_PROGRESS').length;
        final teleconsultCount = activeDayList.where((a) => a.type == 'TELECONSULTATION').length;
        final inPersonCount = activeDayList.where((a) => a.type == 'IN_PERSON').length;
        final completedCount = activeDayList.where((a) => a.status == 'COMPLETED').length;

        // Apply filters
        List<AppointmentDto> filteredList = activeDayList;
        if (_filterChipIndex == 1) {
          filteredList = activeDayList.where((a) => a.status == 'WAITING_ROOM').toList();
        } else if (_filterChipIndex == 2) {
          filteredList = activeDayList.where((a) => a.type == 'TELECONSULTATION').toList();
        } else if (_filterChipIndex == 3) {
          filteredList = activeDayList.where((a) => a.type == 'IN_PERSON').toList();
        } else if (_filterChipIndex == 4) {
          filteredList = activeDayList.where((a) => a.status == 'COMPLETED').toList();
        }

        final query = _searchCtrl.text.toLowerCase().trim();
        if (query.isNotEmpty) {
          filteredList = filteredList.where((a) {
            return a.patientName.toLowerCase().contains(query) ||
                a.chiefComplaint.toLowerCase().contains(query) ||
                a.facilityName.toLowerCase().contains(query);
          }).toList();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sub-Nav & Breadcrumb
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(strings.doctorWorkspace, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.teal)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 14, color: RuralCareColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(strings.opdQueue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RuralCareColors.tealSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined, size: 14, color: RuralCareColors.teal),
                        const SizedBox(width: 4),
                        Text(strings.roomActive, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Page Title & Live Counter Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.clinicalQueue,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: RuralCareColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync_rounded, color: RuralCareColors.teal),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Queue synchronized with sub-centres')),
                      );
                    },
                    tooltip: 'Sync Queue',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Doctor Specialty Prominent Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF147D78)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                strings.isHi ? 'चिकित्सक विशेषज्ञता' : (strings.isMr ? 'वैद्यकीय विशेषज्ञता' : 'DOCTOR SPECIALTY'),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE OPD',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.isHi ? 'सामान्य चिकित्सा एवं ग्रामीण टेली-ट्राइएज (एमबीबीएस, एमडी)' : (strings.isMr ? 'सामान्य वैद्यक व ग्रामीण टेली-ट्रायेज (MBBS, MD)' : 'General Medicine & Rural Tele-Triage (MBBS, MD)'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: RuralCareColors.warning, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('$waitingCount ${strings.waiting}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.warning)),
                    ],
                  ),
                  const Text('  •  ', style: TextStyle(color: RuralCareColors.border)),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: RuralCareColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('$inConsultationCount ${strings.inConsultation}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.success)),
                    ],
                  ),
                  const Text('  •  ', style: TextStyle(color: RuralCareColors.border)),
                  Text('$completedCount ${strings.completedStatus}', style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Segmented Control Tabs (Today vs Tomorrow)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _queueDayIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _queueDayIndex == 0 ? RuralCareColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 16, color: _queueDayIndex == 0 ? Colors.white : RuralCareColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                "${strings.todaysQueue} (${todayAppointments.isNotEmpty ? todayAppointments.length : appointments.length})",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _queueDayIndex == 0 ? Colors.white : RuralCareColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _queueDayIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _queueDayIndex == 1 ? RuralCareColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 16, color: _queueDayIndex == 1 ? Colors.white : RuralCareColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                "${strings.tomorrow} (${tomorrowAppointments.length})",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _queueDayIndex == 1 ? Colors.white : RuralCareColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Search & Filter Bar with Voice Input
              Container(
                decoration: BoxDecoration(
                  color: RuralCareColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: strings.searchQueueHint,
                    hintStyle: const TextStyle(fontSize: 13, color: RuralCareColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: RuralCareColors.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic, color: RuralCareColors.teal, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Voice search listening...')),
                        );
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 5. Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    '${strings.filterAll} (${activeDayList.length})',
                    '${strings.filterWaiting} ($waitingCount)',
                    '${strings.filterTeleconsult} ($teleconsultCount)',
                    '${strings.filterInPerson} ($inPersonCount)',
                    '${strings.filterCompleted} ($completedCount)',
                  ].asMap().entries.map((entry) {
                    final isSelected = entry.key == _filterChipIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _filterChipIndex = entry.key),
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
              ),
              const SizedBox(height: 14),

              // 6. Queue Stack Section
              if (filteredList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 36, color: RuralCareColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        strings.isHi ? 'इस कतार में कोई मरीज़ नहीं है' : (strings.isMr ? 'या रांगेत कोणतेही रुग्ण नाहीत' : 'No Patients In This Queue'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.isHi ? 'डिजिटल ट्राइएज व टेलीकंसल्टेशन से मरीज़ यहां लाइव दिखाई देंगे।' : (strings.isMr ? 'डिजिटल ट्रायेज व टेलीकन्सल्टेशन नोंदीद्वारे रुग्ण येथे दिसतील.' : 'Patients with digital triage or teleconsult bookings appear here in live priority queue.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                      ),
                    ],
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
                  return _buildQueueCard(context, apt, patient, strings);
                }),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQueueCard(BuildContext context, AppointmentDto apt, PatientDto patient, DoctorStrings strings) {
    final isInConsultation = apt.status == 'IN_PROGRESS';
    final isTeleconsult = apt.type == 'TELECONSULTATION';
    final isWaiting = apt.status == 'WAITING_ROOM';

    Color stripColor = RuralCareColors.border;
    if (apt.triagePriority == 'P0') {
      stripColor = const Color(0xFFDC2626);
    } else if (isInConsultation) {
      stripColor = RuralCareColors.success;
    } else if (apt.triagePriority == 'P1') {
      stripColor = const Color(0xFFD97706);
    } else if (isTeleconsult) {
      stripColor = AppColors.skyBlue;
    } else if (isWaiting) {
      stripColor = RuralCareColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: apt.triagePriority == 'P0' ? const Color(0xFFFECACA) : RuralCareColors.border,
          width: apt.triagePriority == 'P0' ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status color strip
              Container(width: 6, color: stripColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Queue Number Badge + Triage Priority Badge + Encounter Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2457C5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2457C5).withOpacity(0.3)),
                                ),
                                child: Text(
                                  apt.queueNumber.isNotEmpty ? 'Queue ${apt.queueNumber}' : 'Queue #Q-01',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2457C5)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: apt.triagePriority == 'P0'
                                      ? const Color(0xFFFEF2F2)
                                      : (apt.triagePriority == 'P1' ? const Color(0xFFFEFCE8) : const Color(0xFFF0FDF4)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: apt.triagePriority == 'P0'
                                        ? const Color(0xFFEF4444)
                                        : (apt.triagePriority == 'P1' ? const Color(0xFFEAB308) : const Color(0xFF22C55E)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      apt.triagePriority == 'P0'
                                          ? Icons.warning_amber_rounded
                                          : (apt.triagePriority == 'P1' ? Icons.priority_high_rounded : Icons.check_circle_outline),
                                      size: 12,
                                      color: apt.triagePriority == 'P0'
                                          ? const Color(0xFFDC2626)
                                          : (apt.triagePriority == 'P1' ? const Color(0xFFCA8A04) : const Color(0xFF16A34A)),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Triage ${apt.triagePriority}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: apt.triagePriority == 'P0'
                                            ? const Color(0xFFDC2626)
                                            : (apt.triagePriority == 'P1' ? const Color(0xFFCA8A04) : const Color(0xFF16A34A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isInConsultation)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: RuralCareColors.successSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 6, color: RuralCareColors.success),
                                  const SizedBox(width: 4),
                                  Text(strings.inConsultation, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success)),
                                ],
                              ),
                            )
                          else if (isTeleconsult)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.skyBlueSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.videocam, size: 12, color: AppColors.skyBlue),
                                  SizedBox(width: 4),
                                  Text('Teleconsult', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.skyBlue)),
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
                              child: Text(strings.waiting, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.warning)),
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

                      // Patient Identity & Demographics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    apt.patientName,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${patient.age}y • ${patient.gender.toUpperCase()}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: RuralCareColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${patient.village} • ABHA: ${patient.abhaId.isNotEmpty ? patient.abhaId : patient.ruralCareId}',
                                style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Symptoms & Primary Issue Box (Displayed BEFORE starting consultation)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.medical_information_outlined, size: 14, color: RuralCareColors.teal),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ISSUE: ${apt.primaryIssue.isNotEmpty ? apt.primaryIssue : apt.chiefComplaint}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (apt.symptoms.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                children: apt.symptoms.map((s) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                )).toList(),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                'Symptoms: ${apt.chiefComplaint}',
                                style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isTeleconsult ? Icons.videocam_outlined : Icons.meeting_room_outlined,
                                      size: 13,
                                      color: isTeleconsult ? AppColors.skyBlue : RuralCareColors.teal,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isTeleconsult ? 'Teleconsultation Room' : 'In-Person OPD Room 1',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isTeleconsult ? AppColors.skyBlue : RuralCareColors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  apt.appointmentTime,
                                  style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Action Button: Start Video Call or Open Record
                      if (isTeleconsult)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AppointmentRepository().updateAppointmentStatus(apt.id, 'IN_PROGRESS');
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => LiveTeleconsultRoomScreen(
                                    patientName: apt.patientName,
                                    doctorName: DoctorRepository().getDoctorForSession(SessionCoordinator()).name,
                                    specialty: apt.specialty,
                                    appointmentId: apt.id,
                                    facilityName: apt.facilityName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.videocam, size: 18),
                            label: Text(
                              strings.isHi ? 'वीडियो कॉल शुरू करें' : (strings.isMr ? 'व्हिडिओ कॉल सुरू करा' : 'Start Video Call'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.skyBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
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
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: Text(strings.openRecord, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RuralCareColors.teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
