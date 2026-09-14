import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';
import 'package:ruralcare/app/routes.dart';

/// Queue & Patient Intake Tab (Stitch Screen 2 & Flow 21)
/// High-density triage queue matching Stitch Screen 2:
/// 1. Triage Header with sync status & average wait indicator (Avg. 12m wait).
/// 2. 3-metric triage summary (Registered, Waiting, In Cabin).
/// 3. Search bar with voice dictation action.
/// 4. Horizontal filter chips (All Patients, Waiting, In Consultation, Completed).
/// 5. Fast-Track Arrival Token Check-In Card.
/// 6. Interactive Patient Queue Cards with context-specific actions:
///    - In Consultation: Open Patient + Update Status
///    - Priority ANC: Call Patient + Update Status
///    - Routine Waiting: Call Patient / Open Patient + Assign Room
///    - Completed: View Summary
/// 7. Modals: Call Patient chime alert, Room Assignment sheet, Status Update sheet, Encounter Details.
class FacilityQueueTab extends StatefulWidget {
  const FacilityQueueTab({super.key});

  @override
  State<FacilityQueueTab> createState() => _FacilityQueueTabState();
}

class _FacilityQueueTabState extends State<FacilityQueueTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _tokenCtrl = TextEditingController(text: 'REF-11021');
  String _selectedFilter = 'all'; // 'all', 'waiting', 'consultation', 'completed'

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final apptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([apptRepo, patientRepo, session]),
      builder: (context, _) {
        final strings = FacilityStrings.of(session);
        final appointments = apptRepo.appointments;
        final patients = patientRepo.patients;

        // Count metrics
        final totalCount = appointments.length;
        final waitingCount = appointments.where((a) => a.status == 'WAITING_ROOM' || a.status == 'CONFIRMED').length;
        final inConsultCount = appointments.where((a) => a.status == 'IN_PROGRESS').length;
        final completedCount = appointments.where((a) => a.status == 'COMPLETED').length;

        // Filter appointments
        final query = _searchCtrl.text.toLowerCase().trim();
        final filteredAppointments = appointments.where((a) {
          final matchesQuery = query.isEmpty ||
              a.patientName.toLowerCase().contains(query) ||
              a.id.toLowerCase().contains(query) ||
              a.patientId.toLowerCase().contains(query) ||
              a.specialty.toLowerCase().contains(query);

          if (!matchesQuery) return false;

          switch (_selectedFilter) {
            case 'waiting':
              return a.status == 'WAITING_ROOM' || a.status == 'CONFIRMED';
            case 'consultation':
              return a.status == 'IN_PROGRESS';
            case 'completed':
              return a.status == 'COMPLETED';
            default:
              return true;
          }
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Operational Context Header Block
              _buildContextBlock(context, strings),

              const SizedBox(height: 14),

              // 2. Real-time Triage Metric Row
              _buildTriageMetricRow(context, strings, totalCount, waitingCount, inConsultCount),

              const SizedBox(height: 16),

              // 3. Search Field & Mic Dictation
              _buildSearchBar(context, strings),

              const SizedBox(height: 14),

              // 4. Status Filter Pills
              _buildFilterPills(context, strings, totalCount, waitingCount, inConsultCount, completedCount),

              const SizedBox(height: 18),

              // 5. Fast-Track Arrival Token Check-In Card
              _buildFastTrackCard(context, strings, apptRepo),

              const SizedBox(height: 20),

              // 6. Patient Cards Stack
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${strings.allPatients} (${filteredAppointments.length})',
                    style: AppTypography.sectionTitle,
                  ),
                  Text(
                    'Sorted by Arrival / Priority',
                    style: AppTypography.caption.copyWith(color: RuralCareColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (filteredAppointments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: AppDecorations.card(),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 40, color: RuralCareColors.textSecondary),
                      const SizedBox(height: 8),
                      Text('No patients matching criteria.', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Try adjusting your search query or filter chip.', style: AppTypography.supporting),
                    ],
                  ),
                )
              else
                ...List.generate(filteredAppointments.length, (index) {
                  final appt = filteredAppointments[index];
                  final patient = patients.firstWhere(
                    (p) => p.id == appt.patientId,
                    orElse: () => patients.first,
                  );
                  final tokenNumber = (index + 8).toString().padLeft(2, '0');
                  return _buildPatientQueueCard(context, appt, patient, apptRepo, strings, tokenNumber);
                }),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContextBlock(BuildContext context, FacilityStrings strings) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  Text(
                    strings.onlineSynced,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RuralCareColors.success,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: RuralCareColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: const Text(
                  'OPD 1 Desk',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: RuralCareColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.todaysQueue, style: AppTypography.sectionTitle),
                  const SizedBox(height: 2),
                  const Text('Rampur Sub-District Catchment', style: AppTypography.supporting),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: RuralCareColors.tealSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RuralCareColors.teal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: RuralCareColors.teal),
                    const SizedBox(width: 4),
                    Text(
                      strings.avgWait,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: RuralCareColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriageMetricRow(
    BuildContext context,
    FacilityStrings strings,
    int registered,
    int waiting,
    int inCabin,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: strings.registered,
            subtitle: strings.isHi ? 'कुल मरीज' : (strings.isMr ? 'एकूण रुग्ण' : 'Total Reg.'),
            value: '$registered',
            color: RuralCareColors.textPrimary,
            bg: RuralCareColors.surface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: strings.waitingCount,
            subtitle: strings.isHi ? 'प्रतीक्षारत' : (strings.isMr ? 'प्रतीक्षेत' : 'In Waiting'),
            value: '$waiting',
            color: RuralCareColors.warning,
            bg: RuralCareColors.warningSoft,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: strings.inCabin,
            subtitle: strings.isHi ? 'परामर्श जारी' : (strings.isMr ? 'सुरू आहे' : 'In Cabin'),
            value: '$inCabin',
            color: RuralCareColors.teal,
            bg: RuralCareColors.tealSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RuralCareColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: RuralCareColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              color: RuralCareColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, FacilityStrings strings) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: strings.searchPatient,
              prefixIcon: const Icon(Icons.search, color: RuralCareColors.textSecondary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.isHi
                    ? 'ध्वनि खोज सक्रिय... मरीज का नाम या RuralCare ID बोलें।'
                    : (strings.isMr
                        ? 'व्हॉईस शोध सक्रिय... रुग्णाचे नाव किंवा RuralCare ID बोला.'
                        : 'Voice search listening... Speak patient name or RuralCare ID.')),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.mic, color: RuralCareColors.teal),
          style: IconButton.styleFrom(
            backgroundColor: RuralCareColors.tealSoft,
            minimumSize: const Size(48, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPills(
    BuildContext context,
    FacilityStrings strings,
    int total,
    int waiting,
    int inConsult,
    int completed,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', strings.allPatients, total),
          const SizedBox(width: 8),
          _buildFilterChip('waiting', strings.waitingCount, waiting),
          const SizedBox(width: 8),
          _buildFilterChip('consultation', strings.inCabin, inConsult),
          const SizedBox(width: 8),
          _buildFilterChip('completed', strings.isHi ? 'पूर्ण' : (strings.isMr ? 'पूर्ण झाले' : 'Completed'), completed),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? RuralCareColors.teal : RuralCareColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? RuralCareColors.teal : RuralCareColors.border),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : RuralCareColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : RuralCareColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : RuralCareColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFastTrackCard(BuildContext context, FacilityStrings strings, AppointmentRepository apptRepo) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: RuralCareColors.tealSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: RuralCareColors.teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.fastTrackCheckin, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      strings.isHi
                          ? 'QR कोड स्कैन करें या 12-अक्षरों का टोकन दर्ज करें'
                          : (strings.isMr
                              ? 'QR कोड स्कॅन करा किंवा 12-अक्षरी टोकन टाका'
                              : 'Scan QR pass or verify 12-character arrival token.'),
                      style: AppTypography.supporting,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. REF-BAR-2026-0891'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final token = _tokenCtrl.text.trim();
                  final checked = ReferralRepository().checkInReferralByToken(token);
                  if (checked != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.isHi
                            ? 'रेफरल ${checked.id} (${checked.patientName}) चेक-इन सफल! टोकन #${checked.checkInToken}'
                            : (strings.isMr
                                ? 'संदर्भ ${checked.id} (${checked.patientName}) चेक-इन यशस्वी! टोकन #${checked.checkInToken}'
                                : 'Referral ${checked.id} (${checked.patientName}) checked in! Token #${checked.checkInToken}')),
                        backgroundColor: RuralCareColors.teal,
                        action: SnackBarAction(
                          label: 'Clinical Handoff',
                          textColor: Colors.white,
                          onPressed: () => _showReferralHandoffSheet(context, checked, strings),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.isHi
                            ? 'टोकन $token सत्यापित। मरीज का पंजीकरण प्राथमिकता सूची में दर्ज।'
                            : (strings.isMr
                                ? 'टोकन $token सत्यापित. रुग्णाची नोंदणी प्राधान्य यादीत केली.'
                                : 'Token $token verified. Fast-track intake confirmed.')),
                        backgroundColor: RuralCareColors.teal,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuralCareColors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(90, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(strings.checkIn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientQueueCard(
    BuildContext context,
    dynamic appt,
    dynamic patient,
    AppointmentRepository apptRepo,
    FacilityStrings strings,
    String tokenNumber,
  ) {
    final isConsult = appt.status == 'IN_PROGRESS';
    final isWaiting = appt.status == 'WAITING_ROOM' || appt.status == 'CONFIRMED';
    final isCompleted = appt.status == 'COMPLETED';

    final isAncPriority = (appt.specialty as String).toLowerCase().contains('obstetric') ||
        (appt.specialty as String).toLowerCase().contains('maternal') ||
        (appt.chiefComplaint as String).toLowerCase().contains('anc');

    Color statusColor;
    String statusLabel;
    if (isConsult) {
      statusColor = RuralCareColors.teal;
      statusLabel = strings.inCabin;
    } else if (isAncPriority) {
      statusColor = const Color(0xFFC026D3); // Magenta / Priority ANC
      statusLabel = 'Priority ANC';
    } else if (isWaiting) {
      statusColor = RuralCareColors.warning;
      statusLabel = '${strings.waitingCount} (12m)';
    } else {
      statusColor = RuralCareColors.success;
      statusLabel = strings.isHi ? 'पूर्ण' : (strings.isMr ? 'पूर्ण' : 'Completed');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Name & Token & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isConsult
                                ? RuralCareColors.tealSoft
                                : (isAncPriority ? const Color(0xFFFAE8FF) : RuralCareColors.surfaceSubtle),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isConsult
                                  ? RuralCareColors.teal.withOpacity(0.3)
                                  : (isAncPriority ? const Color(0xFFC026D3).withOpacity(0.3) : RuralCareColors.border),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#$tokenNumber',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isConsult
                                  ? RuralCareColors.teal
                                  : (isAncPriority ? const Color(0xFFC026D3) : RuralCareColors.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt.patientName as String,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: RuralCareColors.textPrimary,
                              ),
                            ),
                            Text(
                              'ID: ${patient.id} • ${patient.gender}, ${patient.age}y',
                              style: AppTypography.supporting,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: AppDecorations.statusBadge(background: statusColor.withOpacity(0.12)),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Assigned Doctor & Room / Service bar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: RuralCareColors.teal),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${appt.doctorName} • ${appt.facilityName}',
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: RuralCareColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${appt.scheduledTime.hour}:${appt.scheduledTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: RuralCareColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),

                if ((appt.chiefComplaint as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 14, color: RuralCareColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appt.chiefComplaint as String,
                          style: AppTypography.supporting.copyWith(color: RuralCareColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: RuralCareColors.border),

          // Context-specific actions per Stitch Screen 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: _buildCardActions(context, appt, patient, apptRepo, strings, isConsult, isAncPriority, isWaiting, isCompleted),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions(
    BuildContext context,
    dynamic appt,
    dynamic patient,
    AppointmentRepository apptRepo,
    FacilityStrings strings,
    bool isConsult,
    bool isAncPriority,
    bool isWaiting,
    bool isCompleted,
  ) {
    if (isConsult) {
      // In Consultation: Open Patient + Update Status
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showPatientDetailsModal(context, appt, patient),
              icon: const Icon(Icons.folder_shared_rounded, size: 16),
              label: Text(strings.openPatient),
              style: OutlinedButton.styleFrom(
                foregroundColor: RuralCareColors.textPrimary,
                side: const BorderSide(color: RuralCareColors.border),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showUpdateStatusModal(context, appt, apptRepo, strings),
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(strings.updateStatus),
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    }

    if (isAncPriority) {
      // Priority ANC: Call Patient + Update Status
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCallPatientDialog(context, appt, strings),
              icon: const Icon(Icons.volume_up_rounded, size: 16),
              label: Text(strings.callPatient),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC026D3),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showUpdateStatusModal(context, appt, apptRepo, strings),
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(strings.updateStatus),
              style: OutlinedButton.styleFrom(
                foregroundColor: RuralCareColors.textPrimary,
                side: const BorderSide(color: RuralCareColors.border),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    }

    if (isCompleted) {
      // Completed: View Summary
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showPatientDetailsModal(context, appt, patient),
          icon: const Icon(Icons.receipt_long_rounded, size: 16),
          label: Text(strings.viewSummary),
          style: OutlinedButton.styleFrom(
            foregroundColor: RuralCareColors.textPrimary,
            side: const BorderSide(color: RuralCareColors.border),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    // Default Waiting: Call Patient / Open Patient + Assign Room
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showCallPatientDialog(context, appt, strings),
            icon: const Icon(Icons.volume_up_rounded, size: 16),
            label: Text(strings.callPatient),
            style: OutlinedButton.styleFrom(
              foregroundColor: RuralCareColors.textPrimary,
              side: const BorderSide(color: RuralCareColors.border),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAssignRoomModal(context, appt, apptRepo, strings),
            icon: const Icon(Icons.meeting_room_outlined, size: 16),
            label: Text(strings.assignRoom),
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  void _showCallPatientDialog(BuildContext context, dynamic appt, FacilityStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RuralCareColors.tealSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.volume_up_rounded, color: RuralCareColors.teal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${strings.callPatient}: ${appt.patientName}',
                style: AppTypography.cardTitle,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.isHi
                  ? 'मरीज को लाउडस्पीकर और प्रतीक्षालय डिस्प्ले पर बुलाया जाएगा:'
                  : (strings.isMr
                      ? 'रुग्णाला लाऊडस्पीकर आणि प्रतीक्षा कक्ष डिस्प्लेवर बोलावले जाईल:'
                      : 'Calling announcement will be broadcast on waiting area speakers and digital board:'),
              style: AppTypography.body,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RuralCareColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RuralCareColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient: ${appt.patientName} (${appt.patientId})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Assigned Room: ${appt.facilityName}'),
                  const SizedBox(height: 4),
                  Text('Clinician: ${appt.doctorName}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.isHi ? 'रद्द करें' : (strings.isMr ? 'रद्द करा' : 'Cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.campaign, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${strings.toastCallingPatient} "${appt.patientName}" -> ${appt.facilityName}',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: RuralCareColors.teal,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.campaign, size: 18),
            label: Text(strings.isHi ? 'उद्घोषणा करें' : (strings.isMr ? 'घोषणा करा' : 'Broadcast Chime')),
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignRoomModal(
    BuildContext context,
    dynamic appt,
    AppointmentRepository apptRepo,
    FacilityStrings strings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: RuralCareColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${strings.assignRoom} (${appt.patientName})', style: AppTypography.sectionTitle),
                    const SizedBox(height: 2),
                    Text('Current: ${appt.facilityName}', style: AppTypography.supporting),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRoomOption(
              ctx,
              title: 'Room 1 - MCH Clinic (मातृ एवं शिशु स्वास्थ्य)',
              subtitle: '${DoctorRepository().registeredDoctors.isNotEmpty ? DoctorRepository().registeredDoctors.first.name : 'Attending MO'} • General Medicine & ANC • 3 In Queue',
              icon: Icons.pregnant_woman_rounded,
              color: const Color(0xFFC026D3),
              onTap: () {
                apptRepo.assignRoom(appt.id as String, 'PHC Rampur • Room 1 - MCH');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assigned ${appt.patientName} to Room 1 (MCH).')),
                );
              },
            ),
            _buildRoomOption(
              ctx,
              title: 'Room 2 - NCD & Geriatric Clinic',
              subtitle: 'Dr. Alok Verma • Hypertension & Diabetes • 2 In Queue',
              icon: Icons.health_and_safety_rounded,
              color: RuralCareColors.teal,
              onTap: () {
                apptRepo.assignRoom(appt.id as String, 'PHC Rampur • Room 2 - NCD');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assigned ${appt.patientName} to Room 2 (NCD).')),
                );
              },
            ),
            _buildRoomOption(
              ctx,
              title: 'Room 3 - Minor OT & Triage',
              subtitle: 'Staff Nurse Sunita • Dressing, Sutures & Trauma',
              icon: Icons.healing_rounded,
              color: RuralCareColors.warning,
              onTap: () {
                apptRepo.assignRoom(appt.id as String, 'PHC Rampur • Room 3 - Minor OT');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assigned ${appt.patientName} to Room 3 (Minor OT).')),
                );
              },
            ),
            _buildRoomOption(
              ctx,
              title: 'Diagnostics & Phlebotomy Lab',
              subtitle: 'Lab Tech Anand • Blood, Urine, Rapid Malaria & AFB',
              icon: Icons.biotech_rounded,
              color: RuralCareColors.primary,
              onTap: () {
                apptRepo.assignRoom(appt.id as String, 'PHC Rampur • Diagnostics Lab');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assigned ${appt.patientName} to Diagnostics Lab.')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomOption(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: RuralCareColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RuralCareColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text(subtitle, style: AppTypography.supporting),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }

  void _showPatientDetailsModal(BuildContext context, dynamic appt, dynamic patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: RuralCareColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.fullName as String, style: AppTypography.sectionTitle),
                    Text('RuralCare ID: ${patient.id} • ${patient.phoneNumber}', style: AppTypography.supporting),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Clinical Encounter Summary', style: AppTypography.cardTitle),
            const SizedBox(height: 8),
            Text('Scheduled Doctor: ${appt.doctorName}', style: AppTypography.body),
            Text('Room / Service: ${appt.facilityName}', style: AppTypography.body),
            Text('Consultation Specialty: ${appt.specialty}', style: AppTypography.body),
            Text('Encounter Reason: ${appt.chiefComplaint}', style: AppTypography.body),
            const SizedBox(height: 16),
            const Text('Recorded Baseline Vitals', style: AppTypography.cardTitle),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildVitalChip('Blood Pressure', '128/84 mmHg'),
                _buildVitalChip('Pulse', '76 bpm'),
                _buildVitalChip('SpO2', '98%'),
                _buildVitalChip('Temp', '98.4 °F'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuralCareColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: RuralCareColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RuralCareColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary)),
        ],
      ),
    );
  }

  void _showUpdateStatusModal(
    BuildContext context,
    dynamic appt,
    AppointmentRepository apptRepo,
    FacilityStrings strings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: RuralCareColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.updateStatus} (${appt.patientName})', style: AppTypography.sectionTitle),
            const SizedBox(height: 6),
            const Text('Select next workflow stage for triage ledger:', style: AppTypography.supporting),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule, color: RuralCareColors.warning),
              title: const Text('Waiting Room (प्रतीक्षारत)'),
              onTap: () {
                apptRepo.updateStatus(appt.id as String, 'WAITING_ROOM');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status updated to Waiting Room.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: RuralCareColors.teal),
              title: const Text('In Doctor Cabin (परामर्श जारी)'),
              onTap: () {
                apptRepo.updateStatus(appt.id as String, 'IN_PROGRESS');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient routed to Doctor Cabin.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.biotech, color: RuralCareColors.primary),
              title: const Text('Routed to Diagnostics Lab (जांच हेतु भेजा गया)'),
              onTap: () {
                apptRepo.updateStatus(appt.id as String, 'IN_PROGRESS');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient routed to Diagnostics Lab.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: RuralCareColors.success),
              title: const Text('Encounter Completed (परामर्श पूर्ण)'),
              onTap: () {
                apptRepo.updateStatus(appt.id as String, 'COMPLETED');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Encounter marked as completed.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReferralHandoffSheet(BuildContext context, ReferralDto r, FacilityStrings strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_ind, color: RuralCareColors.teal),
                      const SizedBox(width: 8),
                      Text('Clinical Handoff: ${r.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Text('Beneficiary: ${r.patientName} (Age ${r.patientAge}, ${r.patientGender})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Referring Center: ${r.referringFacility} • Provider: ${r.referringProviderName}', style: AppTypography.supporting),
              if (r.checkInToken != null)
                Text('Fast-Track Arrival Token: #${r.checkInToken}', style: const TextStyle(fontWeight: FontWeight.bold, color: RuralCareColors.teal)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: RuralCareColors.surfaceSubtle, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pre-Transfer Clinical Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('• Reason for Referral: ${r.reason}', style: AppTypography.supporting),
                    if (r.vitals != null)
                      Text('• Frontline Vitals: BP ${r.vitals!.systolicBp}/${r.vitals!.diastolicBp}, SpO2 ${r.vitals!.spO2}%, Pulse ${r.vitals!.pulse}, Hb ${r.vitals!.haemoglobin} g/dL', style: AppTypography.supporting),
                    if (r.priorMedications.isNotEmpty)
                      Text('• Pre-transfer Medicines: ${r.priorMedications.join(", ")}', style: AppTypography.supporting),
                    if (r.chronicConditions.isNotEmpty)
                      Text('• Chronic History: ${r.chronicConditions.join(", ")}', style: AppTypography.supporting),
                    if (r.bedReservation != null)
                      Text('• Reserved Resource: ${r.bedReservation!.wardUnit} (${r.bedReservation!.bedType})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text('Attending Care Destination:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ReferralRepository().recordDisposition(r.id, disposition: 'ADMITTED', notes: 'Admitted from queue to reserved bed.');
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Patient ${r.patientName} admitted to inpatient unit.'), backgroundColor: RuralCareColors.teal),
                        );
                      },
                      icon: const Icon(Icons.hotel, size: 16),
                      label: const Text('Admit Inpatient', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.teal, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ReferralRepository().completeClinicalHandoff(r.id, receivingDoctor: 'Medical Officer On-Duty', handoffNotes: 'Assessed in emergency triage.');
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Patient ${r.patientName} routed to doctor consultation cabin.'), backgroundColor: const Color(0xFF0284C7)),
                        );
                      },
                      icon: const Icon(Icons.meeting_room, size: 16),
                      label: const Text('Route to Cabin', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
