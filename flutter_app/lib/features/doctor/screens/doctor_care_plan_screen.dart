import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/core/services/fhir_r4_prescription_service.dart';
import 'package:ruralcare/features/patient/utils/patient_strings.dart';
import 'package:ruralcare/features/doctor/screens/doctor_consultation_completed_screen.dart';

/// Stitch Screen 4: Consultation & Care Plan (Mobile 780x4742)
/// Screen ID: d66b6f7bbf7f49c4a0eaa5321bace718
class DoctorCarePlanScreen extends StatefulWidget {
  final PatientDto patient;
  final String appointmentId;
  final bool isPatientView;

  const DoctorCarePlanScreen({
    super.key,
    required this.patient,
    required this.appointmentId,
    this.isPatientView = false,
  });

  @override
  State<DoctorCarePlanScreen> createState() => _DoctorCarePlanScreenState();
}

class _DoctorCarePlanScreenState extends State<DoctorCarePlanScreen> {
  String _visitMode = 'In-Person';
  late TextEditingController _diagnosisCtrl;
  late TextEditingController _clinicalNotesCtrl;
  late TextEditingController _ashaNotesCtrl;

  final List<PrescriptionItemDto> _prescriptions = [];

  bool _kftOrdered = true;
  bool _cardioReferralMaintained = true;
  bool _patientConsentGranted = true;
  String _selectedReferralFacilityId = 'FAC-SDH-301';
  bool _isSaving = false;
  final String _doctorSpecialty = 'General Medicine & Rural Emergency Triage (MD, MBBS)';

  @override
  void initState() {
    super.initState();
    // Retrieve existing clinical records for active patient if available
    final existingRx = AppointmentRepository().getPrescriptionsForPatient(widget.patient.id);
    if (existingRx.isNotEmpty) {
      final latest = existingRx.last;
      _prescriptions.addAll(latest.medicines);
      _diagnosisCtrl = TextEditingController(text: latest.diagnosis);
      _clinicalNotesCtrl = TextEditingController(text: latest.adviceNotes);
    } else {
      _diagnosisCtrl = TextEditingController();
      _clinicalNotesCtrl = TextEditingController();
    }
    _ashaNotesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _clinicalNotesCtrl.dispose();
    _ashaNotesCtrl.dispose();
    super.dispose();
  }

  void _addMedicineDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Medication (Rx)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Medicine Name & Strength',
                hintText: 'e.g. Tab Paracetamol 500mg',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g. 500 mg',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: freqCtrl,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                hintText: 'e.g. 1 tablet twice daily after meals',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (Days)',
                hintText: '30',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _prescriptions.add(
                    PrescriptionItemDto(
                      medicineName: nameCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim().isEmpty ? '1 dose' : dosageCtrl.text.trim(),
                      frequency: freqCtrl.text.trim().isEmpty ? 'As directed' : freqCtrl.text.trim(),
                      durationDays: int.tryParse(durationCtrl.text.trim()) ?? 30,
                    ),
                  );
                });
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.teal),
            child: const Text('Add Rx', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFhirBundlePreviewModal() {
    final activeDoc = DoctorRepository().getDoctorForSession(SessionCoordinator());
    final rx = PrescriptionDto(
      id: 'RX-${DateTime.now().millisecondsSinceEpoch % 100000}',
      patientId: widget.patient.id,
      doctorName: activeDoc.name,
      diagnosis: _diagnosisCtrl.text.trim().isEmpty ? 'General Clinical Evaluation' : _diagnosisCtrl.text.trim(),
      medicines: List.from(_prescriptions),
      adviceNotes: _clinicalNotesCtrl.text.trim().isEmpty ? 'Follow routine healthcare measures.' : _clinicalNotesCtrl.text.trim(),
      issuedAt: DateTime.now(),
    );

    final fhirBundle = FhirR4PrescriptionService().buildAbdmFhirR4Bundle(
      rx: rx,
      patient: widget.patient,
      doctorSpecialty: activeDoc.specialty,
      doctorRegistrationNumber: activeDoc.registrationNumber,
      facilityName: activeDoc.facilityName,
    );

    final fhirJson = FhirR4PrescriptionService().buildFhirJsonString(fhirBundle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.code_rounded, color: RuralCareColors.teal),
                      SizedBox(width: 8),
                      Text(
                        'ABDM FHIR R4 Prescription Bundle',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Conforms to ABDM FHIR R4 Bundle Specification (Composition, Practitioner, Patient, Encounter, Condition, MedicationRequest)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    child: SelectableText(
                      fhirJson,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF38BDF8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConsentRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gpp_maybe_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Patient Consent Required', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Under ABDM Health Data Management Policy, saving and publishing digital health records requires explicit patient permission consent. Please check the consent box before saving or completing consultation.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: RuralCareColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _patientConsentGranted = true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.teal),
            child: const Text('Grant Consent & Proceed', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveReport() {
    if (!_patientConsentGranted) {
      _showConsentRequiredDialog();
      return;
    }

    final aptRepo = AppointmentRepository();
    final activeDoc = DoctorRepository().getDoctorForSession(SessionCoordinator());
    final rx = PrescriptionDto(
      id: 'RX-${DateTime.now().millisecondsSinceEpoch % 100000}',
      patientId: widget.patient.id,
      doctorName: activeDoc.name,
      diagnosis: _diagnosisCtrl.text.trim().isEmpty ? 'General OPD Consultation' : _diagnosisCtrl.text.trim(),
      medicines: List.from(_prescriptions),
      adviceNotes: _clinicalNotesCtrl.text.trim().isEmpty ? 'Follow routine healthcare measures.' : _clinicalNotesCtrl.text.trim(),
      issuedAt: DateTime.now(),
    );
    aptRepo.addPrescription(rx);

    final session = SessionCoordinator();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(session.isHindi
            ? 'पर्चे को ABDM रिकॉर्ड एवं माय मेडिकेशन्स में सफलतापूर्वक सहेजा गया!'
            : (session.isMarathi ? 'प्रिस्क्रिप्शन ABDM नोंदीत आणि माय मेडिकेशन्समध्ये सेव्ह केले!' : 'Report & Prescription saved to ABDM history & My Medications!')),
        backgroundColor: RuralCareColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _completeConsultation() {
    if (!_patientConsentGranted) {
      _showConsentRequiredDialog();
      return;
    }

    setState(() => _isSaving = true);

    final aptRepo = AppointmentRepository();
    final refRepo = ReferralRepository();
    final activeDoc = DoctorRepository().getDoctorForSession(SessionCoordinator());

    final rx = PrescriptionDto(
      id: 'RX-${DateTime.now().millisecondsSinceEpoch % 100000}',
      patientId: widget.patient.id,
      doctorName: activeDoc.name,
      diagnosis: _diagnosisCtrl.text.trim().isEmpty ? 'Routine Clinical Evaluation' : _diagnosisCtrl.text.trim(),
      medicines: List.from(_prescriptions),
      adviceNotes: _clinicalNotesCtrl.text.trim().isEmpty ? 'Dietary balance and periodic follow-up advised.' : _clinicalNotesCtrl.text.trim(),
      issuedAt: DateTime.now(),
    );

    // 1. Commit to AppointmentRepository (updates medical history and My Medications)
    aptRepo.markConsultationCompleted(
      appointmentId: widget.appointmentId,
      rx: rx,
    );

    // 2. Dispatch counter-referral instructions to ReferralRepository with selected facility & vacant bed status
    if (_cardioReferralMaintained) {
      final fac = FacilityRepository().getFacilityById(_selectedReferralFacilityId) ?? FacilityRepository().facilities.first;
      final refNotes = _ashaNotesCtrl.text.trim().isNotEmpty
          ? 'Referred to ${fac.name} (Vacant Beds: ${fac.availableBeds}/${fac.totalBeds}). ${_ashaNotesCtrl.text.trim()}'
          : 'Referred to ${fac.name} (Vacant Beds: ${fac.availableBeds}/${fac.totalBeds}). Frontline follow-up requested.';

      refRepo.dispatchCounterReferral(
        referralId: 'REF-${DateTime.now().millisecondsSinceEpoch % 10000}',
        instructions: refNotes,
      );
    }

    final session = SessionCoordinator();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(session.isHindi
            ? 'परामर्श पूर्ण हुआ! दवाएं माय मेडिकेशन्स में अपडेट कर दी गईं।'
            : (session.isMarathi ? 'सल्लामसलत पूर्ण झाली! औषधे माय मेडिकेशन्समध्ये अपडेट झाली.' : 'Consultation completed! Prescribed medicines synced to My Medications.')),
        backgroundColor: RuralCareColors.success,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => DoctorConsultationCompletedScreen(
          patient: widget.patient,
          prescription: rx,
          visitMode: _visitMode,
        ),
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
        final isPatient = widget.isPatientView || session.activeRole == AppRole.patient;
        final vitals = widget.patient.latestVitals;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              isPatient
                  ? (session.isHindi ? 'देखभाल योजना' : (session.isMarathi ? 'काळजी योजना' : 'Clinical Care Plan'))
                  : 'Clinical Care Plan',
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: RuralCareColors.success),
                    const SizedBox(width: 4),
                    Text(
                      isPatient ? strings.patientViewBadge : 'Active Encounter',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.success),
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
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Patient Encounter Bar
                    _buildEncounterHeader(widget.patient, vitals, isPatient, session),
                    const SizedBox(height: 14),

                    // 2. Section 1: Visit Mode & Confirmation
                    _buildVisitConfirmationSection(isPatient, session),
                    const SizedBox(height: 14),

                    // 3. Section 2: Clinical Assessment & Diagnosis
                    _buildAssessmentSection(isPatient, strings, session),
                    const SizedBox(height: 14),

                    // 4. Section 3: Digital Prescription (Rx)
                    _buildPrescriptionSection(isPatient, strings, session),
                    const SizedBox(height: 14),

                    // 5. Section 4: Diagnostics / Lab Tests
                    _buildDiagnosticsSection(isPatient, strings, session),
                    const SizedBox(height: 14),

                    // 6. Section 5: Referral Coordination
                    _buildReferralCoordinationSection(isPatient, strings, session),
                    const SizedBox(height: 14),

                    // 7. Section 6: Follow-up Care Order
                    _buildFollowUpSection(isPatient, session),
                    const SizedBox(height: 14),

                    // 8. Section 7: Attending Doctor Attribution
                    _buildDoctorAttribution(session),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Sticky Bottom Action Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildStickyBottomBar(isPatient, strings, session),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEncounterHeader(PatientDto patient, dynamic vitals, bool isPatient, SessionCoordinator session) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        patient.fullName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: RuralCareColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${patient.age} • ${patient.gender} • ${patient.ruralCareId}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.isHindi
                        ? 'परामर्श: सामान्य ओपीडी • चिकित्सकीय सत्र'
                        : (session.isMarathi ? 'सल्लामसलत: सामान्य ओपीडी • वैद्यकीय सत्र' : 'Encounter: General OPD • Clinical Session'),
                    style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                  ),
                ],
              ),
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
                    Text(
                      session.isHindi ? 'सक्रिय' : (session.isMarathi ? 'सक्रिय' : 'Active'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services_rounded, size: 16, color: Color(0xFF0F766E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DOCTOR SPECIALTY: $_doctorSpecialty',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F766E), letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Vitals pill bar
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: RuralCareColors.tealSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        session.isHindi ? 'रक्तचाप (बीपी)' : (session.isMarathi ? 'रक्तदाब (बीपी)' : 'BP (Current)'),
                        style: const TextStyle(fontSize: 10, color: RuralCareColors.teal),
                      ),
                      Text(
                        '${vitals?.systolicBp ?? 126}/${vitals?.diastolicBp ?? 82}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                      ),
                      const Text('mmHg', style: TextStyle(fontSize: 9, color: RuralCareColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        session.isHindi ? 'हृदय गति' : (session.isMarathi ? 'हृदय गती' : 'Heart Rate'),
                        style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                      ),
                      Text(
                        '${vitals?.pulse ?? 74}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                      ),
                      const Text('bpm', style: TextStyle(fontSize: 9, color: RuralCareColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('SpO2 / Temp', style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                      Text(
                        '${vitals?.spO2 ?? 98}% / ${vitals?.temperature ?? 98.6}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                      ),
                      Text(
                        session.isHindi ? 'सामान्य' : (session.isMarathi ? 'सामान्य' : 'Normal'),
                        style: const TextStyle(fontSize: 9, color: RuralCareColors.success),
                      ),
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

  Widget _buildVisitConfirmationSection(bool isPatient, SessionCoordinator session) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
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
                  const Icon(Icons.assignment_ind_outlined, size: 18, color: RuralCareColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    session.isHindi
                        ? '1. परामर्श मोड एवं पुष्टि'
                        : (session.isMarathi ? '1. सल्लामसलत पद्धत आणि पुष्टी' : '1. Patient / Visit Confirmation'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              if (isPatient)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RuralCareColors.tealSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RuralCareColors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _visitMode == 'Teleconsult' ? Icons.videocam_outlined : Icons.local_hospital_outlined,
                        size: 14,
                        color: RuralCareColors.teal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _visitMode,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _visitMode = 'In-Person'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _visitMode == 'In-Person' ? RuralCareColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'In-Person',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _visitMode == 'In-Person' ? Colors.white : RuralCareColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _visitMode = 'Teleconsult'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _visitMode == 'Teleconsult' ? RuralCareColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Teleconsult',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _visitMode == 'Teleconsult' ? Colors.white : RuralCareColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RuralCareColors.border.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.isHindi ? 'मुख्य शिकायत' : (session.isMarathi ? 'मुख्य तक्रार' : 'CHIEF COMPLAINT'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                ),
                const SizedBox(height: 2),
                Text(
                  session.isHindi
                      ? 'सामान्य स्वास्थ्य जांच एवं फॉलो-अप समीक्षा'
                      : (session.isMarathi ? 'सामान्य आरोग्य तपासणी आणि फॉलो-अप पुनरावलोकन' : 'Clinical evaluation & health follow-up.'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentSection(bool isPatient, PatientStrings strings, SessionCoordinator session) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
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
                  const Icon(Icons.assignment_outlined, size: 18, color: RuralCareColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    session.isHindi
                        ? '2. नैदानिक मूल्यांकन एवं निदान'
                        : (session.isMarathi ? '2. वैद्यकीय मूल्यांकन आणि निदान' : '2. Clinical Assessment & Diagnosis'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              if (isPatient)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RuralCareColors.successSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: RuralCareColors.success),
                      const SizedBox(width: 4),
                      Text(
                        strings.doctorVerified,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPatient)
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
                  Text(
                    _diagnosisCtrl.text.trim().isEmpty ? 'General Health Assessment' : _diagnosisCtrl.text,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _clinicalNotesCtrl.text.trim().isEmpty ? 'Clinical examination normal. Advised periodic review.' : _clinicalNotesCtrl.text,
                    style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              session.isHindi ? 'प्राथमिक निदान' : (session.isMarathi ? 'प्राथमिक निदान' : 'Diagnosis / Clinical Impression'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _diagnosisCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                hintText: session.isHindi ? 'निदान दर्ज करें...' : (session.isMarathi ? 'निदान प्रविष्ट करा...' : 'Enter clinical diagnosis...'),
                fillColor: RuralCareColors.surfaceSubtle,
                suffixIcon: const Icon(Icons.check_circle, color: RuralCareColors.success, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              session.isHindi ? 'चिकित्सकीय टिप्पणी' : (session.isMarathi ? 'वैद्यकीय नोंदी' : 'Clinical Notes & Examination'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _clinicalNotesCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                hintText: session.isHindi ? 'चिकित्सकीय परीक्षण एवं नोट्स...' : (session.isMarathi ? 'वैद्यकीय तपासणी आणि नोंदी...' : 'Examination observations and clinical notes...'),
                fillColor: RuralCareColors.surfaceSubtle,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionSection(bool isPatient, PatientStrings strings, SessionCoordinator session) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
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
                  const Icon(Icons.medication_outlined, size: 18, color: RuralCareColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    isPatient ? strings.prescribedMedsReadOnly : '3. Prescription (Rx)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              if (!isPatient)
                InkWell(
                  onTap: _addMedicineDialog,
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 16, color: RuralCareColors.teal),
                      SizedBox(width: 4),
                      Text('+ Add Medicine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.teal)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_prescriptions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: RuralCareColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  strings.noActiveMedications,
                  style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                ),
              ),
            )
          else
            ..._prescriptions.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: RuralCareColors.border.withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.medicineName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: RuralCareColors.tealSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${m.durationDays} ${strings.daysRemaining}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${m.dosage} • ${m.frequency}', style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 12, color: RuralCareColors.teal),
                          const SizedBox(width: 4),
                          Text(strings.takeAfterFood, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 10),

          // ABDM Patient Permission Consent Checkbox & FHIR R4 Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _patientConsentGranted ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _patientConsentGranted ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _patientConsentGranted ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                          color: _patientConsentGranted ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          session.isHindi ? 'ABDM सहमति एवं रोगी अनुमति' : (session.isMarathi ? 'ABDM संमती व रुग्ण परवानगी' : 'ABDM Consent & Patient Permission'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _patientConsentGranted ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _patientConsentGranted ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        _patientConsentGranted ? 'CONSENT GRANTED' : 'CONSENT REQUIRED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _patientConsentGranted ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _patientConsentGranted,
                    onChanged: isPatient ? null : (val) => setState(() => _patientConsentGranted = val ?? true),
                    title: Text(
                      session.isHindi
                          ? 'मरीज़ ने इस डिजिटल पर्चे (FHIR R4 E-Prescription) को अपनी मेडिकल हिस्ट्री में सहेजने और "My Medications" में स्वतः अपडेट करने की सहमति दी है।'
                          : (session.isMarathi
                              ? 'रुग्णाने हे डिजिटल प्रिस्क्रिप्शन (FHIR R4) आपल्या वैद्यकीय इतिहासात सेव्ह करण्यास व "My Medications" मध्ये अपडेट करण्यास संमती दिली आहे.'
                              : 'Patient has granted explicit consent to save this ABDM FHIR R4 E-Prescription into medical history and auto-update "My Medications".'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showFhirBundlePreviewModal,
                        icon: const Icon(Icons.code_rounded, size: 14),
                        label: Text(
                          session.isHindi ? 'ABDM FHIR R4 बंडल देखें' : (session.isMarathi ? 'ABDM FHIR R4 बंडल पहा' : 'View ABDM FHIR R4 Bundle'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF147D78)),
                          foregroundColor: const Color(0xFF147D78),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsSection(bool isPatient, PatientStrings strings, SessionCoordinator session) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
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
                  const Icon(Icons.science_outlined, size: 18, color: RuralCareColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    isPatient ? strings.orderedLabTests : '4. Diagnostics / Tests',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              Text(
                session.isHindi ? 'जांच अनुरोध' : (session.isMarathi ? 'तपासणी विनंती' : 'Diagnostics'),
                style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RuralCareColors.border.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPatient) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.science, size: 16, color: RuralCareColors.teal),
                          SizedBox(width: 6),
                          Text(
                            'Renal & Metabolic Profile (KFT)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: RuralCareColors.tealSoft, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          session.isHindi ? 'निर्धारित' : (session.isMarathi ? 'नियोजित' : 'Ordered'),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('PHC Laboratory • Follow-up check', style: TextStyle(fontSize: 11, color: RuralCareColors.teal)),
                ] else ...[
                  Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _kftOrdered,
                      onChanged: (val) => setState(() => _kftOrdered = val ?? true),
                      title: const Text(
                        'Routine Renal Function Test (KFT)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('PHC Lab • Follow-up check', style: TextStyle(fontSize: 10, color: RuralCareColors.teal)),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: RuralCareColors.teal,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    session.isHindi
                        ? 'नैदानिक कारण: नियमित स्वास्थ्य निगरानी प्रोटोकॉल।'
                        : (session.isMarathi ? 'वैद्यकीय कारण: नियमित आरोग्य देखरेख प्रोटोकॉल.' : 'Clinical Reason: Routine monitoring and preventive protocol.'),
                    style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCoordinationSection(bool isPatient, PatientStrings strings, SessionCoordinator session) {
    final facilities = FacilityRepository().facilities.where((f) => f.type != 'SUB_CENTRE').toList();

    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
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
                  const Icon(Icons.share_location_outlined, size: 18, color: RuralCareColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    session.isHindi
                        ? '5. रेफरल एवं अस्पताल बेड स्थिति'
                        : (session.isMarathi ? '5. संदर्भ व रुग्णालय बेड स्थिती' : '5. Referral Coordination & Vacant Bed Status'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'LIVE VACANCY',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Referral maintenance checkbox for doctor
          if (!isPatient) ...[
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _cardioReferralMaintained,
                onChanged: (val) => setState(() => _cardioReferralMaintained = val ?? true),
                title: Text(
                  session.isHindi ? 'मरीज़ को उच्च चिकित्सा केंद्र पर रेफर करें' : (session.isMarathi ? 'रुग्णाला उच्च आरोग्य केंद्रात संदर्भित करा' : 'Refer Patient to Higher Medical Facility'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Live vacancy tracking from District Health Network', style: TextStyle(fontSize: 10, color: RuralCareColors.teal)),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: RuralCareColors.teal,
              ),
            ),
          ],

          if (_cardioReferralMaintained || isPatient) ...[
            Text(
              session.isHindi ? 'रेफरल अस्पताल चुनें (उपलब्ध बेड स्थिति जांचें):' : (session.isMarathi ? 'संदर्भ रुग्णालय निवडा (उपलब्ध खाटांची स्थिती तपासा):' : 'Hospital Destination (Inspect Vacant Beds Before Referring):'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // Bed Vacancy Cards
            ...facilities.map((fac) {
              final isSelected = _selectedReferralFacilityId == fac.id;
              final icuVacancies = (fac.availableBeds * 0.25).clamp(1, 15).toInt();
              final isCriticalVacant = fac.availableBeds < 5;

              return InkWell(
                onTap: isPatient ? null : () => setState(() => _selectedReferralFacilityId = fac.id),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF16A34A) : RuralCareColors.border.withOpacity(0.7),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 16,
                                color: isSelected ? const Color(0xFF16A34A) : RuralCareColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                fac.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCriticalVacant ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${fac.distanceKm} km',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCriticalVacant ? const Color(0xFFB91C1C) : const Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Bed status badges (Total Vacant & ICU Vacant)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hotel_rounded, size: 12, color: Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  'Total: ${fac.availableBeds}/${fac.totalBeds} Vacant',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.emergency_rounded, size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  'ICU: $icuVacancies Vacant',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                          if (fac.hasEmergencyCapability) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '24x7 ER',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF7E22CE)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            Text(
              strings.ashaInstructions,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
            ),
            const SizedBox(height: 4),
            if (isPatient)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RuralCareColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _ashaNotesCtrl.text.trim().isEmpty
                      ? (session.isHindi
                          ? 'आशा कार्यकर्ता द्वारा नियमित गृह निरीक्षण एवं अनुवर्ती जांच।'
                          : (session.isMarathi ? 'आशा सेविकेमार्फत नियमित गृहभेट व पाठपुरावा.' : 'Frontline ASHA home follow-up and monitoring.'))
                      : _ashaNotesCtrl.text,
                  style: const TextStyle(fontSize: 12, color: RuralCareColors.textPrimary),
                ),
              )
            else
              TextField(
                controller: _ashaNotesCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  hintText: session.isHindi ? 'आशा कार्यकर्ता के लिए निर्देश दर्ज करें...' : (session.isMarathi ? 'आशा सेविकेसाठी सूचना प्रविष्ट करा...' : 'Enter instructions for frontline ASHA...'),
                  fillColor: RuralCareColors.surface,
                  contentPadding: const EdgeInsets.all(8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowUpSection(bool isPatient, SessionCoordinator session) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
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
                  const Icon(Icons.event_repeat_outlined, size: 18, color: RuralCareColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    session.isHindi
                        ? '6. अनुवर्ती देखभाल (फॉलो-अप)'
                        : (session.isMarathi ? '6. अनुवर्ती काळजी (फॉलो-अप)' : '6. Follow-up Care Order'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              Text(
                session.isHindi ? 'फॉलो-अप' : (session.isMarathi ? 'फॉलो-अप' : 'Follow-up'),
                style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RuralCareColors.border.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.isHindi ? 'सामुदायिक स्वास्थ्य कार्यकर्ता जांच' : (session.isMarathi ? 'आरोग्य सेविका तपासणी' : 'Health Worker Check'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      session.isHindi ? 'आशा गृह निरीक्षण प्रोटोकॉल' : (session.isMarathi ? 'आशा गृहभेट प्रोटोकॉल' : 'ASHA / ANM visit protocol'),
                      style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Text(
                    session.isHindi ? '2 सप्ताह में' : (session.isMarathi ? '2 आठवड्यांत' : 'In 2 Weeks'),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RuralCareColors.border.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.isHindi ? 'चिकित्सक ओपीडी समीक्षा' : (session.isMarathi ? 'वैद्यकीय ओपीडी पुनरावलोकन' : 'Clinician OPD Review'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      session.isHindi ? 'पीएचसी परामर्श कक्ष' : (session.isMarathi ? 'पीएचसी सल्ला कक्ष' : 'PHC Consultation Room'),
                      style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Text(
                    session.isHindi ? '1 माह में' : (session.isMarathi ? '1 महिन्यात' : 'In 1 Month'),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAttribution(SessionCoordinator session) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RuralCareColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: RuralCareColors.teal,
            child: Text('AR', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attending Clinician: ${DoctorRepository().getDoctorForSession(SessionCoordinator()).name}, ${DoctorRepository().getDoctorForSession(SessionCoordinator()).qualification}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Specialty: ${DoctorRepository().getDoctorForSession(SessionCoordinator()).specialty}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                ),
                const SizedBox(height: 1),
                Text(
                  '${DoctorRepository().getDoctorForSession(SessionCoordinator()).facilityName} • Reg: ${DoctorRepository().getDoctorForSession(SessionCoordinator()).registrationNumber} • ABDM FHIR R4 Author',
                  style: const TextStyle(fontSize: 9, color: RuralCareColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(bool isPatient, PatientStrings strings, SessionCoordinator session) {
    return Container(
      decoration: const BoxDecoration(
        color: RuralCareColors.surface,
        border: Border(top: BorderSide(color: RuralCareColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _completeConsultation,
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Completing...'),
                      ],
                    )
                  : Text(
                      isPatient
                          ? (session.isHindi ? 'परामर्श समाप्त करें एवं सारांश देखें →' : (session.isMarathi ? 'सल्लामसलत पूर्ण करा आणि सारांश पहा →' : 'Complete & View Summary →'))
                          : (session.isHindi ? 'परामर्श पूर्ण करें →' : (session.isMarathi ? 'सल्लामसलत पूर्ण करा →' : 'Complete Consultation →')),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _saveReport,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: Text(strings.saveReport, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: RuralCareColors.teal,
                side: const BorderSide(color: RuralCareColors.teal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
