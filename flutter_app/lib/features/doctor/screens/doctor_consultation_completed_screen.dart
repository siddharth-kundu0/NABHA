import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/patient/utils/patient_strings.dart';

/// Stitch Screen 6: Consultation Completed (Mobile 780x3924)
/// Screen ID: f90cdb39c57e43038d3feaa6bf33ca1a
class DoctorConsultationCompletedScreen extends StatefulWidget {
  final PatientDto patient;
  final PrescriptionDto? prescription;
  final String encounterRefId;
  final String visitMode;

  const DoctorConsultationCompletedScreen({
    super.key,
    required this.patient,
    this.prescription,
    this.encounterRefId = '#TC-2025-0841',
    this.visitMode = 'In-Person OPD',
  });

  @override
  State<DoctorConsultationCompletedScreen> createState() => _DoctorConsultationCompletedScreenState();
}

class _DoctorConsultationCompletedScreenState extends State<DoctorConsultationCompletedScreen> {
  bool _reminderSet = false;
  bool _notesExpanded = true;

  @override
  void initState() {
    super.initState();
    // Auto-commit prescribed medications to repository so patient's My Medications screen synchronizes
    if (widget.prescription != null) {
      AppointmentRepository().addPrescription(widget.prescription!);
    }
  }

  void _toggleReminder(PatientStrings strings, SessionCoordinator session) {
    if (!_reminderSet) {
      final aptRepo = AppointmentRepository();
      final followUpDate = DateTime.now().add(const Duration(days: 14));
      final doctor = DoctorRepository().getDoctorForSession(session);
      aptRepo.scheduleFollowUp(
        patientId: widget.patient.id,
        patientName: widget.patient.fullName,
        doctorName: doctor.name,
        facilityName: doctor.facilityName,
        specialty: doctor.specialty,
        scheduledTime: followUpDate,
      );

      setState(() => _reminderSet = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.addReminderSuccess),
          backgroundColor: RuralCareColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      setState(() => _reminderSet = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(session.isHindi
              ? 'रिमाइंडर रद्द किया गया।'
              : (session.isMarathi ? 'स्मरणपत्र रद्द केले.' : 'Reminder cancelled.')),
        ),
      );
    }
  }

  void _showSummaryPdfModal(PatientStrings strings, SessionCoordinator session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: RuralCareColors.critical, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.clinicalSummaryTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GOVERNMENT OF INDIA • ABDM HEALTH RECORD',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                    ),
                    const SizedBox(height: 4),
                    Text('Patient: ${widget.patient.fullName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('ABHA: ${widget.patient.abhaId} • RuralCare ID: ${widget.patient.ruralCareId}',
                        style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Encounter ID: ${widget.encounterRefId}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('Attending: ${DoctorRepository().getDoctorForSession(session).name}, ${DoctorRepository().getDoctorForSession(session).qualification} • ${DoctorRepository().getDoctorForSession(session).facilityName}',
                        style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.prescribedMedsReadOnly,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
              ),
              const SizedBox(height: 6),
              if (widget.prescription != null && widget.prescription!.medicines.isNotEmpty)
                ...widget.prescription!.medicines.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${m.medicineName} (${m.dosage}) - ${m.frequency}', style: const TextStyle(fontSize: 11)),
                    ))
              else
                Text(strings.noActiveMedications, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: RuralCareColors.border, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 110, color: Colors.blueGrey.shade800),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified, size: 20, color: RuralCareColors.teal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ABDM Digitally Signed & Verified',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(session.isHindi ? 'बंद करें' : (session.isMarathi ? 'बंद करा' : 'Close')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(session.isHindi
                      ? 'परामर्श सारांश पीडीएफ डाउनलोड हुआ!'
                      : (session.isMarathi ? 'सल्लामसलत सारांश पीडीएफ डाउनलोड झाली!' : 'Consultation Summary PDF saved to device!')),
                  backgroundColor: RuralCareColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.teal),
            icon: const Icon(Icons.download, size: 16, color: Colors.white),
            label: Text(
              session.isHindi ? 'डाउनलोड' : (session.isMarathi ? 'डाउनलोड' : 'Download'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final strings = PatientStrings.of(session);
        final rx = widget.prescription;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            title: Text(
              session.isHindi
                  ? 'परामर्श सारांश'
                  : (session.isMarathi ? 'सल्लामसलत सारांश' : 'Consultation Summary'),
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: RuralCareColors.textPrimary,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RuralCareColors.successSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi, size: 14, color: RuralCareColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.success),
                    ),
                  ],
                ),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: RuralCareColors.border),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                // 1. Success Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: RuralCareColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: RuralCareColors.success.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check, size: 34, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: RuralCareColors.successSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle, size: 8, color: RuralCareColors.success),
                            const SizedBox(width: 6),
                            Text(
                              session.isHindi
                                  ? 'परामर्श सफलतापूर्वक पूर्ण हुआ'
                                  : (session.isMarathi ? 'सल्लामसलत यशस्वीरित्या पूर्ण झाली' : 'Consultation Completed'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: RuralCareColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.isHindi
                            ? 'चिकित्सकीय देखभाल योजना मरीज के रिकॉर्ड में दर्ज कर दी गई है।'
                            : (session.isMarathi
                                ? 'वैद्यकीय काळजी योजना रुग्णाच्या नोंदीमध्ये नोंदवली गेली आहे.'
                                : 'Clinical care plan is recorded in the patient longitudinal chart.'),
                        style: const TextStyle(fontSize: 13, color: RuralCareColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Doctor Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: RuralCareColors.teal,
                            child: Text(
                              'AR',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rx?.doctorName ?? '${DoctorRepository().getDoctorForSession(session).name}, ${DoctorRepository().getDoctorForSession(session).qualification}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                                ),
                                Text(
                                  '${DoctorRepository().getDoctorForSession(session).specialty} • ${DoctorRepository().getDoctorForSession(session).facilityName}',
                                  style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.medical_services_outlined, size: 14, color: AppColors.skyBlue),
                                    const SizedBox(width: 4),
                                    Text(
                                      session.isHindi ? 'सामान्य चिकित्सा परामर्श' : (session.isMarathi ? 'सामान्य औषध सल्लामसलत' : 'General Medicine Consultation'),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.skyBlue),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: RuralCareColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Ref ID', style: TextStyle(fontSize: 9, color: RuralCareColors.textSecondary)),
                                Text(
                                  widget.encounterRefId,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: RuralCareColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Metrics Grid
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: RuralCareColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: RuralCareColors.textSecondary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.isHindi ? 'सत्र समय' : (session.isMarathi ? 'सत्र वेळ' : 'Session Time'),
                                      style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                                    ),
                                    Text(
                                      session.isHindi ? 'आज, 10:45 AM' : (session.isMarathi ? 'आज, 10:45 AM' : 'Today, 10:45 AM'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: RuralCareColors.textSecondary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.isHindi ? 'अवधि' : (session.isMarathi ? 'कालावधी' : 'Duration'),
                                      style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                                    ),
                                    Text(
                                      session.isHindi ? '15 मिनट' : (session.isMarathi ? '15 मिनिटे' : '15 mins'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.success),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Outcomes & Next Steps
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 18, color: RuralCareColors.teal),
                          const SizedBox(width: 6),
                          Text(
                            session.isHindi
                                ? 'परिणाम एवं आगामी कदम'
                                : (session.isMarathi ? 'निष्कर्ष आणि पुढील पावले' : 'Outcomes & Next Steps'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Prescription Available
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RuralCareColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RuralCareColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.medication_outlined, size: 16, color: AppColors.skyBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      session.isHindi
                                          ? 'डिजिटल नुस्खा जारी किया गया'
                                          : (session.isMarathi ? 'डिजिटल प्रिस्क्रिप्शन जारी केले' : 'Digital Prescription Issued'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${rx?.medicines.length ?? 0} ${strings.filterPrescriptions}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (rx != null && rx.medicines.isNotEmpty)
                              ...rx.medicines.map((m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(m.medicineName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        Text(m.frequency, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                                      ],
                                    ),
                                  ))
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  strings.noActiveMedications,
                                  style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Follow-up scheduled
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RuralCareColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RuralCareColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_available, size: 16, color: RuralCareColors.teal),
                                    const SizedBox(width: 6),
                                    Text(
                                      session.isHindi
                                          ? 'फॉलो-अप देखभाल निर्धारित'
                                          : (session.isMarathi ? 'फॉलो-अप काळजी निश्चित' : 'Follow-up Care Scheduled'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                                    ),
                                  ],
                                ),
                                Text(
                                  session.isHindi ? '2 सप्ताह में' : (session.isMarathi ? '2 आठवड्यांत' : 'In 2 Weeks'),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 14, color: RuralCareColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  session.isHindi ? '10:30 AM • पीएचसी रामपुर कक्ष 1' : (session.isMarathi ? '10:30 AM • पीएचसी रामपूर कक्ष 1' : '10:30 AM • PHC Rampur Room 1'),
                                  style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: () => _toggleReminder(strings, session),
                                icon: Icon(_reminderSet ? Icons.check_circle : Icons.notification_add_outlined, size: 18),
                                label: Text(
                                  _reminderSet
                                      ? (session.isHindi
                                          ? 'रिमाइंडर सक्रिय (एसएमएस और व्हाट्सएप)'
                                          : (session.isMarathi ? 'स्मरणपत्र सक्रिय (एसएमएस व व्हॉट्सअ‍ॅप)' : 'Reminder Set (SMS & WhatsApp)'))
                                      : (session.isHindi ? 'रिमाइंडर जोड़ें' : (session.isMarathi ? 'स्मरणपत्र जोडा' : 'Add Reminder')),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _reminderSet ? RuralCareColors.success : RuralCareColors.teal,
                                  side: BorderSide(color: _reminderSet ? RuralCareColors.success : RuralCareColors.teal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Diagnostics Recommendation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RuralCareColors.warningSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RuralCareColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.science, size: 20, color: RuralCareColors.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.isHindi
                                        ? 'गुर्दा कार्य जांच (केएफटी) आदेशित'
                                        : (session.isMarathi ? 'मूत्रपिंड कार्य चाचणी (KFT) आदेशित' : 'Renal Function Test (KFT) Ordered'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.warning),
                                  ),
                                  Text(
                                    session.isHindi
                                        ? 'सुविधा: पीएचसी रामपुर नैदानिक प्रयोगशाला'
                                        : (session.isMarathi ? 'सुविधा: पीएचसी रामपूर प्रयोगशाळा' : 'Facility: PHC Rampur Clinical Laboratory'),
                                    style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Clinician Notes (Collapsible)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _notesExpanded = !_notesExpanded),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assignment_outlined, size: 18, color: RuralCareColors.teal),
                                const SizedBox(width: 8),
                                Text(
                                  session.isHindi
                                      ? 'चिकित्सक नोट्स एवं सलाह'
                                      : (session.isMarathi ? 'वैद्यकीय नोंदी आणि सल्ला' : 'Clinician Notes & Advice'),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                                ),
                              ],
                            ),
                            Icon(_notesExpanded ? Icons.expand_less : Icons.expand_more, color: RuralCareColors.textSecondary),
                          ],
                        ),
                      ),
                      if (_notesExpanded) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: RuralCareColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            rx?.adviceNotes ??
                                (session.isHindi
                                    ? 'संतुलित आहार, पर्याप्त जलयोजन एवं समय पर दवा लें। आशा कार्यकर्ता द्वारा अनुवर्ती निगरानी।'
                                    : (session.isMarathi
                                        ? 'संतुलित आहार, योग्य पाणी पिणे आणि वेळेवर औषधे घ्या. आशा सेविकेद्वारे पाठपुरावा.'
                                        : 'Balanced diet, hydration, and regular medications. ASHA to perform follow-up monitoring.')),
                            style: const TextStyle(fontSize: 12, color: RuralCareColors.textPrimary, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: TextButton.icon(
                            onPressed: () => _showSummaryPdfModal(strings, session),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: Text(strings.downloadSummaryPdf),
                            style: TextButton.styleFrom(
                              foregroundColor: RuralCareColors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: RuralCareColors.border),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Bottom Return Action
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_outlined, size: 20),
                    label: Text(
                      session.isHindi ? 'डैशबोर्ड पर वापस जाएं' : (session.isMarathi ? 'डॅशबोर्डवर परत जा' : 'Back to Dashboard'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RuralCareColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
