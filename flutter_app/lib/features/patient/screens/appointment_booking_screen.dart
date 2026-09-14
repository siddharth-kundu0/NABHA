import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/features/patient/utils/patient_strings.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';

/// Appointments screen adhering strictly to DESIGN.md Section 6:
/// - Distinct Upcoming vs Past views.
/// - Single Appointment Per Doctor validation.
/// - 10 Clinical specialties & 11 granular time slots.
/// - Hospital selection & doctor search.
/// - Digital Triage symptom checker with priority evaluation.
/// - Interactive ABDM Digital Arrival Pass modal.
class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  int _selectedView = 0; // 0: Upcoming, 1: Past
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedFacility = 'Baramati Sub-District Hospital (SDH)';
  String _selectedSpecialty = 'General Medicine';
  String _selectedSlot = 'Today, 10:00 AM - 10:30 AM';
  String _selectedType = 'TELECONSULTATION';
  final Set<String> _selectedSymptoms = {};

  final List<String> _facilitiesList = [
    'Kashti Sub-Centre (Shirur)',
    'Shirur Rural PHC (Shirur)',
    'Daund Community Health Centre (CHC)',
    'Baramati Sub-District Hospital (SDH)',
    'Aundh District Hospital (Pune)',
  ];

  final List<String> _specialtiesList = [
    'General Medicine',
    'Obstetrics & Gynecology',
    'Pediatrics',
    'Cardiology',
    'Orthopedics',
    'Ophthalmology',
    'ENT',
    'Dermatology',
    'General Surgery',
    'AYUSH / Integrative Medicine',
  ];

  final List<String> _timeSlots = [
    'Today, 09:00 AM - 09:30 AM',
    'Today, 09:30 AM - 10:00 AM',
    'Today, 10:00 AM - 10:30 AM',
    'Today, 10:30 AM - 11:00 AM',
    'Today, 11:00 AM - 11:30 AM',
    'Today, 11:30 AM - 12:00 PM',
    'Today, 02:00 PM - 02:30 PM',
    'Today, 02:30 PM - 03:00 PM',
    'Today, 03:00 PM - 03:30 PM',
    'Today, 03:30 PM - 04:00 PM',
    'Today, 04:00 PM - 04:30 PM',
  ];

  @override
  void dispose() {
    _complaintController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _calculateTriageLevel(PatientStrings strings) {
    if (_selectedSymptoms.contains('chestPain')) {
      return strings.urgentSeverity;
    }
    if (_selectedSymptoms.contains('fever') ||
        _selectedSymptoms.contains('headacheBp') ||
        _selectedSymptoms.contains('abdominalPain')) {
      return strings.prioritySeverity;
    }
    return strings.routineSeverity;
  }

  Color _getTriageColor() {
    if (_selectedSymptoms.contains('chestPain')) {
      return RuralCareColors.critical;
    }
    if (_selectedSymptoms.contains('fever') ||
        _selectedSymptoms.contains('headacheBp') ||
        _selectedSymptoms.contains('abdominalPain')) {
      return RuralCareColors.warning;
    }
    return RuralCareColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final aptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([aptRepo, patientRepo, session]),
      builder: (context, _) {
        final strings = PatientStrings.of(session);
        final patient = patientRepo.activePatient;
        final patientId = patient?.id ?? '';

        final upcomingList = aptRepo.appointments
            .where((a) =>
                a.patientId == patientId &&
                a.status != 'COMPLETED' &&
                a.status != 'CANCELLED')
            .toList();

        final pastList = aptRepo.appointments
            .where((a) =>
                a.patientId == patientId &&
                (a.status == 'COMPLETED' || a.status == 'CANCELLED'))
            .toList();

        final appointments = _selectedView == 0 ? upcomingList : pastList;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            title: Text(
              strings.appointmentsTitle,
              style: AppTypography.pageTitle,
            ),
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: const BoxDecoration(
                  color: RuralCareColors.surface,
                  border: Border(bottom: BorderSide(color: RuralCareColors.border, width: 1.0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _viewTabButton(strings.tabUpcoming, 0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _viewTabButton(strings.tabPast, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: appointments.isEmpty
              ? _buildEmptyView(strings)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: appointments.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
                  itemBuilder: (ctx, idx) => _buildAppointmentRow(
                    ctx,
                    appointments[idx],
                    patient,
                    strings,
                  ),
                ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: RuralCareColors.surface,
              border: Border(top: BorderSide(color: RuralCareColors.border, width: 1.0)),
              boxShadow: AppDecorations.subtleShadow,
            ),
            child: SafeArea(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _openBookingSheet(context, aptRepo, patient, strings),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    strings.bookAppointment,
                    style: AppTypography.button,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _viewTabButton(String title, int index) {
    final isSelected = _selectedView == index;
    return InkWell(
      onTap: () => setState(() => _selectedView = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? RuralCareColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? RuralCareColors.primary : RuralCareColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentRow(
    BuildContext context,
    AppointmentDto apt,
    PatientDto? patient,
    PatientStrings strings,
  ) {
    final isTeleconsult = apt.type == 'TELECONSULTATION';
    final isCompleted = apt.status == 'COMPLETED';

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                apt.appointmentTime,
                style: AppTypography.supporting.copyWith(
                  fontWeight: FontWeight.w600,
                  color: RuralCareColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(
                  background: isCompleted
                      ? RuralCareColors.surfaceSubtle
                      : (apt.status == 'CONFIRMED' ? RuralCareColors.successSoft : RuralCareColors.warningSoft),
                ),
                child: Text(
                  isCompleted ? strings.localizeReferralStatus('COMPLETED') : strings.confirmed,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? RuralCareColors.textSecondary
                        : (apt.status == 'CONFIRMED' ? RuralCareColors.success : RuralCareColors.warning),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            apt.doctorName,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 2),
          Text(
            '${apt.specialty} • ${apt.facilityName}',
            style: AppTypography.supporting,
          ),
          if (apt.chiefComplaint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${strings.reasonLabel}: ${apt.chiefComplaint}',
              style: AppTypography.supporting.copyWith(color: RuralCareColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (_selectedView == 1 || isCompleted)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSummaryDialog(context, apt, strings),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: Text(strings.view, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RuralCareColors.teal,
                        side: const BorderSide(color: RuralCareColors.teal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                )
              else if (isTeleconsult)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => LiveTeleconsultRoomScreen(
                              patientName: patient?.fullName ?? 'Beneficiary',
                              doctorName: apt.doctorName,
                              specialty: apt.specialty,
                              appointmentId: apt.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.video_call_outlined, size: 18),
                      label: Text(strings.joinTeleconsult),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RuralCareColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _showArrivalPassDialog(context, apt, patient, strings),
                      icon: const Icon(Icons.qr_code_outlined, size: 18),
                      label: Text(strings.viewArrivalPass),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RuralCareColors.primary,
                        side: const BorderSide(color: RuralCareColors.inputBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showArrivalPassDialog(
    BuildContext context,
    AppointmentDto apt,
    PatientDto? patient,
    PatientStrings strings,
  ) {
    final token = '#TK-${apt.facilityName.split(' ').first.toUpperCase()}-${apt.id.replaceAll(RegExp(r'[^0-9]'), '')}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: RuralCareColors.successSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 14, color: RuralCareColors.success),
                  const SizedBox(width: 4),
                  Text(
                    strings.fastTrackArrivalPass,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.tokenNumber,
              style: AppTypography.supporting,
            ),
            const SizedBox(height: 2),
            Text(
              token,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: RuralCareColors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Simulated QR pass container
            Container(
              width: 140,
              height: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RuralCareColors.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 96, color: RuralCareColors.textPrimary),
                  Text('ABDM TOKEN PASS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RuralCareColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(patient?.fullName ?? 'Beneficiary', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(apt.appointmentTime, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${apt.doctorName} • ${apt.specialty}', style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('${strings.roomNumber}: OPD Room 01 • ${apt.facilityName}', style: const TextStyle(fontSize: 11, color: RuralCareColors.teal, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.arrivalPassSub,
              textAlign: TextAlign.center,
              style: AppTypography.supporting.copyWith(fontSize: 11),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(strings.scanAtReception, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSummaryDialog(BuildContext context, AppointmentDto apt, PatientStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.clinicalSummaryTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${apt.doctorName} (${apt.specialty})', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${apt.appointmentTime} • ${apt.facilityName}', style: AppTypography.supporting),
            const Divider(height: 20),
            Text('${strings.reasonLabel}: ${apt.chiefComplaint}', style: AppTypography.body),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RuralCareColors.successSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: RuralCareColors.success),
                  const SizedBox(width: 6),
                  Text(strings.localizeReferralStatus('COMPLETED'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.success)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(strings.back)),
        ],
      ),
    );
  }

  Widget _buildEmptyView(PatientStrings strings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: RuralCareColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined, color: RuralCareColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedView == 0 ? strings.noUpcomingApts : strings.noPastApts,
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: 6),
            Text(
              _selectedView == 0 ? strings.noUpcomingAptsSub : strings.noPastAptsSub,
              textAlign: TextAlign.center,
              style: AppTypography.supporting,
            ),
          ],
        ),
      ),
    );
  }

  void _openBookingSheet(
    BuildContext context,
    AppointmentRepository aptRepo,
    PatientDto? patient,
    PatientStrings strings,
  ) {
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.isHi ? 'कृपया पहले प्रोफ़ाइल पंजीकृत करें।' : 'Please register a patient profile first.')),
      );
      return;
    }

    final doctorRepo = DoctorRepository();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RuralCareColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.scheduleAppointment,
                      style: AppTypography.sectionTitle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: RuralCareColors.textSecondary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Consultation Type Selector
                Row(
                  children: [
                    Expanded(
                      child: _typeSelectorOption(
                        strings.teleconsultationMode,
                        'TELECONSULTATION',
                        _selectedType == 'TELECONSULTATION',
                        () => setSheetState(() => _selectedType = 'TELECONSULTATION'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _typeSelectorOption(
                        strings.inPersonMode,
                        'IN_PERSON',
                        _selectedType == 'IN_PERSON',
                        () => setSheetState(() => _selectedType = 'IN_PERSON'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Facility Selector
                Text(strings.selectFacility, style: AppTypography.supporting),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedFacility,
                  isExpanded: true,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: _facilitiesList
                      .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => _selectedFacility = val);
                  },
                ),
                const SizedBox(height: 14),

                // Specialty Selector (10 Specialties)
                Text(strings.specialtyLabel, style: AppTypography.supporting),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  isExpanded: true,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: _specialtiesList
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => _selectedSpecialty = val);
                  },
                ),
                const SizedBox(height: 14),

                // Time Slot Selector (11 Slots)
                Text(strings.timeSlotLabel, style: AppTypography.supporting),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedSlot,
                  isExpanded: true,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: _timeSlots
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => _selectedSlot = val);
                  },
                ),
                const SizedBox(height: 14),

                // Digital Triage: Symptoms Selector
                Text(strings.symptomsCheck, style: AppTypography.supporting),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _symptomChip('fever', strings.fever, setSheetState),
                    _symptomChip('cough', strings.cough, setSheetState),
                    _symptomChip('headacheBp', strings.headacheBp, setSheetState),
                    _symptomChip('pregnancy', strings.pregnancy, setSheetState),
                    _symptomChip('chestPain', strings.chestPain, setSheetState),
                    _symptomChip('abdominalPain', strings.abdominalPain, setSheetState),
                    _symptomChip('jointPain', strings.jointPain, setSheetState),
                    _symptomChip('skinRash', strings.skinRash, setSheetState),
                  ],
                ),
                const SizedBox(height: 8),

                // Triage Severity Assessment Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTriageColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getTriageColor().withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined, size: 16, color: _getTriageColor()),
                      const SizedBox(width: 6),
                      Text(
                        '${strings.triageSeverity}: ${_calculateTriageLevel(strings)}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getTriageColor()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Additional Reason / Clinical Notes
                Text(strings.reasonLabel, style: AppTypography.supporting),
                const SizedBox(height: 6),
                TextField(
                  controller: _complaintController,
                  decoration: InputDecoration(
                    hintText: strings.reasonHint,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Auto-Assigned Doctor Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: RuralCareColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'On-Duty Clinician: ${doctorRepo.autoSelectDoctor(specialty: _selectedSpecialty).name} ($_selectedSpecialty)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // Auto-select registered or on-duty doctor for this specialty
                      final autoDoctor = doctorRepo.autoSelectDoctor(
                        specialty: _selectedSpecialty,
                      );
                      final doctorName = autoDoctor.name;

                      // Validation: Single Appointment Per Doctor Conflict Check
                      final hasConflict = aptRepo.hasConflict(
                        patientId: patient.id,
                        doctorName: doctorName,
                        scheduledTimeStr: _selectedSlot,
                      );

                      if (hasConflict) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.singleAppointmentError),
                            backgroundColor: RuralCareColors.critical,
                          ),
                        );
                        return;
                      }

                      final fallbackReason = _selectedSymptoms.isNotEmpty
                          ? _selectedSymptoms.map((s) => s.toUpperCase()).join(', ')
                          : 'Clinical Examination';

                      final newApt = AppointmentDto(
                        id: 'APT-${DateTime.now().millisecondsSinceEpoch % 100000}',
                        patientId: patient.id,
                        patientName: patient.fullName,
                        doctorName: doctorName,
                        specialty: _selectedSpecialty,
                        facilityName: _selectedFacility,
                        scheduledTime: DateTime.now().add(const Duration(hours: 4)),
                        type: _selectedType,
                        status: 'CONFIRMED',
                        chiefComplaint: _complaintController.text.isNotEmpty
                            ? '${_complaintController.text} [Triage: ${_calculateTriageLevel(strings)}]'
                            : '$fallbackReason [Triage: ${_calculateTriageLevel(strings)}]',
                      );

                      aptRepo.addAppointment(newApt);
                      _complaintController.clear();
                      _selectedSymptoms.clear();
                      Navigator.of(ctx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.aptConfirmedToast),
                          backgroundColor: RuralCareColors.success,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RuralCareColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      strings.confirmAppointmentBtn,
                      style: AppTypography.button,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _symptomChip(String key, String label, StateSetter setSheetState) {
    final isSelected = _selectedSymptoms.contains(key);
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      onSelected: (val) {
        setSheetState(() {
          if (val) {
            _selectedSymptoms.add(key);
          } else {
            _selectedSymptoms.remove(key);
          }
        });
      },
      selectedColor: RuralCareColors.primarySoft,
      checkmarkColor: RuralCareColors.primary,
      backgroundColor: RuralCareColors.surfaceSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? RuralCareColors.primary : RuralCareColors.border),
      ),
    );
  }

  Widget _typeSelectorOption(String label, String value, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? RuralCareColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? RuralCareColors.primary : RuralCareColors.inputBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? RuralCareColors.primary : RuralCareColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
