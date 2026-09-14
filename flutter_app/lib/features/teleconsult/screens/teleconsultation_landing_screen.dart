import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/triage_dto.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';
import 'package:ruralcare/features/teleconsult/widgets/visual_body_diagram_widget.dart';
import 'package:ruralcare/core/services/patient_history_pdf_service.dart';
import 'package:ruralcare/core/services/nlp_symptom_service.dart';
import 'package:ruralcare/core/services/clinical_triage_engine.dart';
import 'package:ruralcare/features/patient/screens/symptom_checker_screen.dart';

class TeleconsultationLandingScreen extends StatefulWidget {
  final AnatomicalRegionDto? initialRegion;
  final List<String>? initialSymptoms;
  final double? initialPainSeverity;
  final bool hasPreCheckedSymptoms;

  const TeleconsultationLandingScreen({
    super.key,
    this.initialRegion,
    this.initialSymptoms,
    this.initialPainSeverity,
    this.hasPreCheckedSymptoms = false,
  });

  @override
  State<TeleconsultationLandingScreen> createState() => _TeleconsultationLandingScreenState();
}

class _TeleconsultationLandingScreenState extends State<TeleconsultationLandingScreen> {
  int _step = 0; // 0: Concerns, Body Map & Digital Triage, 1: Specialist Match, 2: Waiting Room
  bool _hasPreCheckedSymptoms = false;

  String _selectedSpecialty = 'General Medicine';
  final TextEditingController _symptomCtrl = TextEditingController();
  bool _consentShareRecords = true;
  RegisteredDoctorAccount? _selectedDoctor;
  final List<String> _uploadedDocs = [];

  // Triage state
  AnatomicalRegionDto? _selectedRegion;
  String _activeBodyZone = 'Right Side of Forehead (Right Frontal / Temporal)';
  List<String> _bodySymptoms = ['Right-sided Throbbing Migraine'];
  bool _isRedFlag = false;
  String? _redFlagWarning;
  TriagePriority _calculatedTriage = TriagePriority.p2Green;
  String _queueToken = 'P2-04';

  // MoHFW Pain Assessment Matrix
  double _painSeverity = 4.0;
  String _painOnset = '1 - 3 Days';
  String _painCharacter = 'Dull Ache / Burning';
  String _painRadiation = 'Localized';

  // Universal MoHFW National Triage Danger Signs
  bool _qAvpuAltered = false;
  bool _qRespiratoryFailure = false;
  bool _qCirculatoryShock = false;
  bool _qActiveHemorrhage = false;

  // Region Targeted Questionnaire Answers
  final Map<String, bool> _regionAnswers = {};

  final List<String> _specialties = [
    'General Medicine',
    'Obstetrician & Gynecologist',
    'Pediatrician',
    'Pulmonology & Fever',
    'Cardiology & BP',
  ];

  @override
  void initState() {
    super.initState();
    _hasPreCheckedSymptoms = widget.hasPreCheckedSymptoms;

    if (widget.initialRegion != null) {
      _selectedRegion = widget.initialRegion;
      _activeBodyZone = _selectedRegion!.nameEn;
      _isRedFlag = _selectedRegion!.isHighRisk;
      _redFlagWarning = _selectedRegion!.emergencyProtocol.warningMessage;
    } else {
      _selectedRegion = ClinicalTriageEngine().getRegionById('forehead_right');
      _activeBodyZone = _selectedRegion!.nameEn;
    }

    if (widget.initialSymptoms != null && widget.initialSymptoms!.isNotEmpty) {
      _bodySymptoms = List.from(widget.initialSymptoms!);
    } else {
      _bodySymptoms = List.from(_selectedRegion!.commonSymptoms.take(2));
    }

    if (widget.initialPainSeverity != null) {
      _painSeverity = widget.initialPainSeverity!;
    }

    _selectedDoctor = DoctorRepository().autoSelectDoctor(specialty: _selectedSpecialty);
    _recalculateTriage();
  }

  @override
  void dispose() {
    _symptomCtrl.dispose();
    super.dispose();
  }

  void _recalculateTriage() {
    final hasUniversalDanger = _qAvpuAltered || _qRespiratoryFailure || _qCirculatoryShock || _qActiveHemorrhage;
    final hasIschemicPain = _painCharacter == 'Crushing / Pressure' && _painRadiation.contains('Arm');
    
    // Evaluate if any checked region-targeted question is a MoHFW red-flag
    bool hasRegionDanger = false;
    if (_selectedRegion != null) {
      final questions = ClinicalTriageEngine().getQuestionsForRegion(_selectedRegion!);
      for (final q in questions) {
        if (_regionAnswers[q.id] == true && q.isRedFlag) {
          hasRegionDanger = true;
          break;
        }
      }
    }

    if (_isRedFlag || hasUniversalDanger || hasIschemicPain || hasRegionDanger) {
      _calculatedTriage = TriagePriority.p0Red;
      _queueToken = 'P0-01';
    } else if (_painSeverity >= 7 || _painOnset.contains('Hyperacute') || _painOnset.contains('< 1 Hour') || (_selectedRegion?.isHighRisk ?? false)) {
      _calculatedTriage = TriagePriority.p1Yellow;
      _queueToken = 'P1-02';
    } else {
      _calculatedTriage = TriagePriority.p2Green;
      _queueToken = 'P2-06';
    }
  }

  void _onNlpMessageChanged(String text) {
    if (text.trim().length > 3) {
      final res = NlpSymptomService().parseMessage(text);
      setState(() {
        if (res.extractedSymptoms.isNotEmpty) {
          _bodySymptoms = res.extractedSymptoms;
          _activeBodyZone = res.primaryOrganZone;
        }
        if (res.redFlagAlerts.isNotEmpty) {
          _isRedFlag = true;
          _redFlagWarning = res.redFlagAlerts.first;
        }
        _recalculateTriage();
      });
    }
  }

  String _getTriagePriorityDescription(bool isHi, bool isMr) {
    if (_calculatedTriage == TriagePriority.p0Red) {
      if (_redFlagWarning != null && _redFlagWarning!.isNotEmpty) {
        return '${_redFlagWarning!} (P0 Red - Immediate bypass)';
      }
      return isMr
          ? 'तातडीचे (P0) - त्वरित सल्ला किंवा १०८ रुग्णवाहिका'
          : (isHi
              ? 'आपातकालीन (P0) - तत्काल परामर्श या 108 एम्बुलेंस'
              : 'Emergency (P0) - Immediate bypass or 108 emergency');
    } else if (_calculatedTriage == TriagePriority.p1Yellow) {
      return isMr
          ? 'अत्यावश्यक (P1) - प्राधान्य कतार (< ५ मिनिटे)'
          : (isHi
              ? 'अत्यावश्यक (P1) - प्राथमिकता कतार (< 5 मिनट)'
              : 'Urgent (P1) - Fast-track queue (< 5 mins)');
    } else {
      return isMr
          ? 'नियमित (P2) - सामान्य कतार'
          : (isHi ? 'सामान्य (P2) - सामान्य कतार' : 'Routine (P2) - Standard queue');
    }
  }

  void _enterLiveCall() {
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient ?? patientRepo.activePatient;
    final patientName = patient?.fullName ?? (SessionCoordinator().isHindi ? 'नागरिक' : 'Patient');
    final doctor = _selectedDoctor ?? DoctorRepository().autoSelectDoctor(specialty: _selectedSpecialty);
    
    // Register live teleconsultation appointment
    final aptId = 'APT-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final newApt = AppointmentDto(
      id: aptId,
      patientId: patient?.id ?? 'pat-${DateTime.now().millisecondsSinceEpoch % 10000}',
      patientName: patientName,
      doctorName: doctor.name,
      specialty: doctor.specialty,
      facilityName: doctor.facilityName,
      scheduledTime: DateTime.now(),
      type: 'TELECONSULTATION',
      status: 'IN_PROGRESS',
      triagePriority: _calculatedTriage.code,
      queueNumber: _queueToken,
      chiefComplaint: _symptomCtrl.text.trim().isNotEmpty ? _symptomCtrl.text.trim() : _bodySymptoms.join(', '),
      symptoms: _bodySymptoms,
      primaryIssue: _activeBodyZone,
    );
    AppointmentRepository().addAppointment(newApt);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LiveTeleconsultRoomScreen(
          patientName: patientName,
          doctorName: doctor.name,
          specialty: doctor.specialty,
          appointmentId: aptId,
        ),
      ),
    );
  }

  void _requestOfflineConsultation() {
    final cache = LocalCacheService();
    cache.queueMutation('TELECONSULTATION_REQUEST', 'CREATE', {
      'specialty': _selectedSpecialty,
      'symptoms': _symptomCtrl.text.trim().isNotEmpty ? _symptomCtrl.text.trim() : _bodySymptoms.join(', '),
      'triage': _calculatedTriage.code,
      'queueNumber': _queueToken,
      'requestedAt': DateTime.now().toIso8601String(),
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: RuralCareColors.primary),
            SizedBox(width: 8),
            Text('Consultation Queued', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Your teleconsultation request has been securely stored offline with priority queue tag. As soon as the network connects or the specialist logs on, your consultation will automatically sync and trigger an alert notification.',
          style: TextStyle(fontSize: 12, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _downloadHistoryPdf() async {
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient ?? patientRepo.activePatient;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient record found to export.')),
      );
      return;
    }
    await PatientHistoryPdfService().exportOrPrintPatientHistory(context, patient);
  }

  void _simulateUploadDocument() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Attach Clinical Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined, color: RuralCareColors.primary),
              title: const Text('Recent Blood & Urine Lab Report (PDF)', style: TextStyle(fontSize: 13)),
              onTap: () {
                setState(() => _uploadedDocs.add('Baramati SDH Lab CBC Report.pdf'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: RuralCareColors.primary),
              title: const Text('ANC Ultrasound Scan (USG Image)', style: TextStyle(fontSize: 13)),
              onTap: () {
                setState(() => _uploadedDocs.add('ANC Obstetric USG Scan.png'));
                Navigator.pop(ctx);
              },
            ),
          ],
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
        final isMr = session.isMarathi;
        final isHi = session.isHindi;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            leading: _step > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
                    onPressed: () => setState(() => _step--),
                  )
                : IconButton(
                    icon: const Icon(Icons.close, color: RuralCareColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
            title: Text(_getTitle(isHi, isMr), style: AppTypography.cardTitle),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RuralCareColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _langPill(session, 'en', 'EN'),
                    _langPill(session, 'hi', 'हिं'),
                    _langPill(session, 'mr', 'म'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: RuralCareColors.primary),
                tooltip: 'Download Health Record PDF',
                onPressed: _downloadHistoryPdf,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildCurrentStep(session, isHi, isMr),
            ),
          ),
        );
      },
    );
  }

  Widget _langPill(SessionCoordinator session, String code, String label) {
    final isSel = session.canonicalLanguageCode == code;
    return InkWell(
      onTap: () => session.switchLanguage(code),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? RuralCareColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? Colors.white : RuralCareColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _getTitle(bool isHi, bool isMr) {
    switch (_step) {
      case 0:
        return isMr ? 'लक्षणे व डिजिटल ट्रायज' : (isHi ? 'लक्षण एवं डिजिटल ट्रायज' : 'Step 1: Symptoms & Digital Triage');
      case 1:
        return isMr ? 'तज्ज्ञ डॉक्टर निवडा' : (isHi ? 'चिकित्सक चयन' : 'Step 2: Matching Specialists');
      case 2:
        return isMr ? 'प्रतीक्षालय व कतार क्रमांक' : (isHi ? 'प्रतीक्षालय एवं कतार टोकन' : 'Step 3: Waiting Room & Queue Ticket');
      default:
        return 'Teleconsultation';
    }
  }

  Widget _buildCurrentStep(SessionCoordinator session, bool isHi, bool isMr) {
    switch (_step) {
      case 0:
        return _step0BodyDiagramAndTriage(session, isHi, isMr);
      case 1:
        return _step1DoctorMatch(session, isHi, isMr);
      case 2:
        return _step2WaitingRoom(session, isHi, isMr);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 0: Visual Body Diagram, Clinical Questions & Digital Triage Model
  Widget _step0BodyDiagramAndTriage(SessionCoordinator session, bool isHi, bool isMr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Pre-consultation Prompt Banner (Prompt user to check symptoms first)
        if (!_hasPreCheckedSymptoms) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RuralCareColors.primary.withOpacity(0.35), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RuralCareColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr
                                ? 'प्रथम लक्षण तपासणी करा'
                                : (isHi ? 'पहले लक्षण जाँच का उपयोग करें' : 'Check Symptoms in Symptom Checker First'),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: RuralCareColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMr
                                ? 'कृपया आधी लक्षण तपासणीमध्ये शरीराचा भाग निवडून लक्षणे तपासा, जेणेकरून आम्ही तुम्हाला योग्य तज्ज्ञ डॉक्टरांशी त्वरित जोडू शकू.'
                                : (isHi
                                    ? 'कृपया पहले लक्षण जाँच में शरीर का अंग और लक्षण बताएं, ताकि हम आपको सही विशेषज्ञ डॉक्टर से तुरंत जोड़ सकें।'
                                    : 'Please check your symptoms first in the Symptom Checker so we can match and connect you with the right specialist right away.'),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: RuralCareColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RuralCareColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const SymptomCheckerScreen(isModal: true),
                              ),
                            );
                          },
                          icon: const Icon(Icons.touch_app_rounded, size: 16),
                          label: Text(
                            isMr ? 'लक्षण तपासणी उघडा' : (isHi ? 'लक्षण जाँच खोलें' : 'Open Symptom Checker'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _hasPreCheckedSymptoms = true),
                      child: Text(
                        isMr ? 'वगळा' : (isHi ? 'छोड़ें' : 'Continue'),
                        style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        // 1. Interactive Visual Human Body Diagram with Red-Flag Safety Alert
        VisualBodyDiagramWidget(
          onSelectionChanged: (sel) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedRegion = sel.region;
                  _activeBodyZone = sel.activeZone;
                  _bodySymptoms = sel.selectedSymptoms;
                  _isRedFlag = sel.isRedFlag;
                  _redFlagWarning = sel.redFlagWarning;
                  _recalculateTriage();
                });
              }
            });
          },
        ),

        const SizedBox(height: 16),

        // 2. Specialty Category Selector
        Text(
          isMr ? 'आरोग्य समस्या प्रकार' : (isHi ? 'स्वास्थ्य चिंता श्रेणी' : 'Select Clinical Specialty'),
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _specialties.map((spec) {
            final isSel = _selectedSpecialty == spec;
            return ChoiceChip(
              label: Text(spec),
              selected: isSel,
              selectedColor: RuralCareColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? Colors.white : RuralCareColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _selectedSpecialty = spec),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 3. NLP Natural Language Symptom Input (e.g. "mera pet dukhra hai")
        Text(
          isMr ? 'आपल्या भाषेत सांगा (NLP वाचक)' : (isHi ? 'अपनी भाषा में बताएं (NLP रीडर)' : 'Describe in Your Own Words (NLP Reader)'),
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: 4),
        Text(
          isMr
              ? 'उदा. "माझे पोट खूप दुखत आहे", "छातीत जडपणा वाटतोय"'
              : (isHi ? 'उदा. "मेरा पेट दुख रहा है", "सीने में भारीपन और चक्कर आ रहा है"' : 'e.g. "mera pet dukhra hai", "severe chest tightness and breathlessness"'),
          style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _symptomCtrl,
          maxLines: 3,
          onChanged: _onNlpMessageChanged,
          decoration: InputDecoration(
            hintText: isMr
                ? 'येथे लिहा किंवा बोला...'
                : (isHi ? 'यहाँ लिखें या बोलें...' : 'Type or dictate your message...'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.mic, color: RuralCareColors.primary),
          ),
        ),

        const SizedBox(height: 16),

        // 4. Clinical Triage Questions Checklist (MoHFW National Guidelines)
        _buildMohfwClinicalQuestionnaire(isHi, isMr),

        const SizedBox(height: 16),

        // 5. Calculated Digital Triage Result Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _calculatedTriage == TriagePriority.p0Red
                ? RuralCareColors.criticalSoft
                : (_calculatedTriage == TriagePriority.p1Yellow ? RuralCareColors.warningSoft : RuralCareColors.successSoft),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _calculatedTriage == TriagePriority.p0Red
                  ? RuralCareColors.critical
                  : (_calculatedTriage == TriagePriority.p1Yellow ? RuralCareColors.warning : RuralCareColors.success),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _calculatedTriage == TriagePriority.p0Red ? Icons.emergency_rounded : Icons.verified_user_outlined,
                color: _calculatedTriage == TriagePriority.p0Red
                    ? RuralCareColors.critical
                    : (_calculatedTriage == TriagePriority.p1Yellow ? RuralCareColors.warning : RuralCareColors.success),
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIGITAL TRIAGE: ${_calculatedTriage.code} PRIORITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _calculatedTriage == TriagePriority.p0Red
                            ? RuralCareColors.critical
                            : (_calculatedTriage == TriagePriority.p1Yellow ? RuralCareColors.warning : RuralCareColors.success),
                      ),
                    ),
                    Text(
                      _getTriagePriorityDescription(isHi, isMr),
                      style: const TextStyle(fontSize: 11, color: RuralCareColors.textPrimary, height: 1.3),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _queueToken,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: RuralCareColors.textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 6. Record Sharing Consent Card
        Container(
          decoration: BoxDecoration(
            color: RuralCareColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RuralCareColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: _consentShareRecords,
                activeColor: RuralCareColors.primary,
                onChanged: (v) => setState(() => _consentShareRecords = v ?? true),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'I consent to share my longitudinal health records, vitals, and ABHA profile with the consulting physician.',
                  style: TextStyle(fontSize: 11, height: 1.3, color: RuralCareColors.textSecondary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _calculatedTriage == TriagePriority.p0Red ? RuralCareColors.critical : RuralCareColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_symptomCtrl.text.trim().isEmpty) {
                _symptomCtrl.text = _bodySymptoms.join(', ');
              }
              setState(() => _step = 1);
            },
            child: Text(
              isMr ? 'पुढील पायरी: डॉक्टर शोधा' : (isHi ? 'आगे बढ़ें: चिकित्सक खोजें' : 'Proceed to Match Specialists'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // MoHFW Clinical Questionnaire Widgets
  Widget _buildMohfwClinicalQuestionnaire(bool isHi, bool isMr) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: RuralCareColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.health_and_safety_outlined, color: RuralCareColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMr
                          ? 'राष्ट्रीय आरोग्य अभियान (MoHFW) ट्रायज प्रश्नावली'
                          : (isHi
                              ? 'राष्ट्रीय स्वास्थ्य मिशन (MoHFW) ट्रायज प्रश्नावली'
                              : 'MoHFW / NHM Clinical Triage Assessment'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                    ),
                    Text(
                      isMr
                          ? 'शासकीय मानकांनुसार अचूक वर्गवारी व जोखीम मूल्यांकन'
                          : (isHi
                              ? 'शासकीय मानकों के अनुसार सटीक वर्गीकरण व जोखिम आकलन'
                              : 'Calibrated with AVPU, RBSK & Emergency Triage Guidelines'),
                      style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: RuralCareColors.border),
          const SizedBox(height: 14),

          // SECTION A: Universal Danger Signs (Red Flags)
          _buildUniversalDangerSection(isHi, isMr),

          const SizedBox(height: 16),
          const Divider(height: 1, color: RuralCareColors.border),
          const SizedBox(height: 16),

          // SECTION B: WHO / MoHFW Pain Matrix (0-10 Scale)
          _buildPainMatrixSection(isHi, isMr),

          // SECTION C: Region-Targeted Screening
          if (_selectedRegion != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: RuralCareColors.border),
            const SizedBox(height: 16),
            _buildRegionTargetedSection(isHi, isMr),
          ],
        ],
      ),
    );
  }

  Widget _buildUniversalDangerSection(bool isHi, bool isMr) {
    final anyDanger = _qAvpuAltered || _qRespiratoryFailure || _qCirculatoryShock || _qActiveHemorrhage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isMr ? '१. सार्वत्रिक गंभीर धोक्याची लक्षणे' : (isHi ? '१. सार्वभौमिक गंभीर खतरे के संकेत' : '1. Universal MoHFW National Danger Signs'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: anyDanger ? RuralCareColors.criticalSoft : RuralCareColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: anyDanger ? RuralCareColors.critical : RuralCareColors.border),
              ),
              child: Text(
                anyDanger ? 'P0 RED TRIGGERED' : 'SAFETY CHECK',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: anyDanger ? RuralCareColors.critical : RuralCareColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isMr
              ? 'खालीलपैकी कोणतेही एक लक्षण आढळल्यास रुग्ण तातडीच्या (P0 Red) श्रेणीत जाईल:'
              : (isHi
                  ? 'निम्नलिखित में से कोई भी एक संकेत दिखने पर मरीज तत्काल (P0 Red) आपातकालीन श्रेणी में जाएगा:'
                  : 'Presence of ANY single sign triggers immediate P0 Red priority escalation:'),
          style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
        ),
        const SizedBox(height: 8),

        _buildDangerCheckTile(
          value: _qAvpuAltered,
          title: isMr
              ? 'बेशुद्धावस्था, चक्कर येऊन पडणे किंवा ओळखू न येणे'
              : (isHi
                  ? 'मरीज बेहोश है, तेज चक्कर खाकर गिर रहा है, या पहचान नहीं पा रहा'
                  : 'Person is unconscious, fainting, or unable to recognize family'),
          subtitle: isMr
              ? 'रुग्ण सुस्त आहे, प्रतिसाद देत नाही किंवा बोलू शकत नाही'
              : (isHi
                  ? 'मरीज सुस्त है, जवाब नहीं दे रहा या ठीक से बोल नहीं पा रहा'
                  : 'Patient is drowsy, unresponsive, or cannot speak properly'),
          onChanged: (v) {
            setState(() {
              _qAvpuAltered = v ?? false;
              _recalculateTriage();
            });
          },
        ),
        _buildDangerCheckTile(
          value: _qRespiratoryFailure,
          title: isMr
              ? 'श्वास घेण्यास खूप त्रास होणे, शिट्टीचा आवाज किंवा ओठ निळे पडणे'
              : (isHi
                  ? 'सांस लेने में बहुत जोर लग रहा है, सीटी की आवाज या होंठ नीले हैं'
                  : 'Extreme struggle to breathe, whistling sound, or blue lips'),
          subtitle: isMr
              ? 'जोराने धाप लागणे किंवा छाती आत ओढली जाणे'
              : (isHi
                  ? 'तेज हांफना, सांस फूलना या छाती अंदर धंसना'
                  : 'Fast gasping breaths, chest pulling in heavily'),
          onChanged: (v) {
            setState(() {
              _qRespiratoryFailure = v ?? false;
              _recalculateTriage();
            });
          },
        ),
        _buildDangerCheckTile(
          value: _qCirculatoryShock,
          title: isMr
              ? 'हात-पाय बर्फासारखे गार पडणे आणि अत्यंत भोवळ किंवा अशक्तपणा'
              : (isHi
                  ? 'हाथ-पैर बर्फ जैसे ठंडे पड़ना और तेज चक्कर या अत्यधिक कमजोरी'
                  : 'Hands & feet ice cold with extreme dizziness or collapse'),
          subtitle: isMr
              ? 'अंग गार व घामाने डबडबलेले, नाडी मंद, उभे राहता न येणे'
              : (isHi
                  ? 'शरीर ठंडा व पसीने से भीगा, नब्ज बहुत कमजोर, खड़ा न हो पाना'
                  : 'Body cold and clammy, pulse very faint, unable to stand'),
          onChanged: (v) {
            setState(() {
              _qCirculatoryShock = v ?? false;
              _recalculateTriage();
            });
          },
        ),
        _buildDangerCheckTile(
          value: _qActiveHemorrhage,
          title: isMr
              ? 'सतत जास्त रक्त वाहणे किंवा रक्ताची उलटी होणे'
              : (isHi
                  ? 'लगातार अधिक खून बहना या खून की उल्टी होना'
                  : 'Continuous heavy bleeding or vomiting blood'),
          subtitle: isMr
              ? 'दाबून धरल्यावरही रक्त न थांबणे किंवा रक्ताच्या गुठळ्या पडणे'
              : (isHi
                  ? 'दबाने पर भी खून न रुकना या खून के बड़े थक्के निकलना'
                  : 'Bleeding that does not stop with pressure, or blood clots'),
          onChanged: (v) {
            setState(() {
              _qActiveHemorrhage = v ?? false;
              _recalculateTriage();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDangerCheckTile({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: value ? RuralCareColors.criticalSoft.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? RuralCareColors.critical : RuralCareColors.border,
          width: value ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        activeColor: RuralCareColors.critical,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: value ? RuralCareColors.critical : RuralCareColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPainMatrixSection(bool isHi, bool isMr) {
    final score = _painSeverity.toInt();
    Color scoreColor;
    String scoreText;
    if (score == 0) {
      scoreColor = RuralCareColors.success;
      scoreText = isMr ? 'वेदना नाही (0)' : (isHi ? 'कोई दर्द नहीं (0)' : '0/10 - No Pain');
    } else if (score <= 3) {
      scoreColor = RuralCareColors.teal;
      scoreText = isMr ? 'सौम्य वेदना ($score)' : (isHi ? 'हल्का दर्द ($score)' : '$score/10 - Mild Discomfort');
    } else if (score <= 6) {
      scoreColor = RuralCareColors.warning;
      scoreText = isMr ? 'मध्यम वेदना ($score)' : (isHi ? 'मध्यम दर्द ($score)' : '$score/10 - Moderate Pain');
    } else {
      scoreColor = RuralCareColors.critical;
      scoreText = isMr ? 'अति तीव्र वेदना ($score)' : (isHi ? 'असहनीय तीव्र दर्द ($score)' : '$score/10 - Severe / Incapacitating');
    }

    final onsetOptions = [
      '< 1 Hour (Hyperacute)',
      '< 24 Hours (Acute)',
      '1 - 3 Days (Subacute)',
      '> 1 Week (Chronic)',
    ];

    final characterOptions = [
      'Dull Ache / Burning',
      'Sharp / Stabbing',
      'Throbbing / Pulsating',
      'Crushing / Pressure',
      'Colicky / Cramping',
    ];

    final radiationOptions = [
      'Localized (No spread)',
      'Radiating to Jaw / Left Arm',
      'Radiating to Back / Spine',
      'Radiating to Groin / Leg',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isMr ? '२. वेदना तीव्रता व स्वरूप (WHO / MoHFW स्केल)' : (isHi ? '२. दर्द की तीव्रता और लक्षण (WHO / MoHFW स्केल)' : '2. WHO / MoHFW Pain Assessment Matrix'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scoreColor),
              ),
              child: Text(
                scoreText,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scoreColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isMr
              ? '० ते १० च्या स्लाईडरवर वेदनेची तीव्रता निवडा:'
              : (isHi
                  ? '0 से 10 के पैमाने पर दर्द की गंभीरता निर्धारित करें:'
                  : 'Calibrate severity score on the 0-10 clinical analog scale:'),
          style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
        ),
        const SizedBox(height: 6),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: scoreColor,
            thumbColor: scoreColor,
            inactiveTrackColor: scoreColor.withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _painSeverity,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (val) {
              setState(() {
                _painSeverity = val;
                _recalculateTriage();
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        // Pain Onset
        Text(
          isMr ? 'लक्षण सुरू होण्याची वेळ (Onset):' : (isHi ? 'लक्षण शुरुआत समय (Onset):' : 'Symptom Onset Timing:'),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: onsetOptions.map((opt) {
            final isSel = _painOnset == opt;
            return ChoiceChip(
              label: Text(opt, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : RuralCareColors.textPrimary)),
              selected: isSel,
              selectedColor: RuralCareColors.primary,
              backgroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              onSelected: (_) {
                setState(() {
                  _painOnset = opt;
                  _recalculateTriage();
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        // Pain Character
        Text(
          isMr ? 'वेदनेचे स्वरूप (Character):' : (isHi ? 'दर्द का प्रकार (Character):' : 'Pain Character / Nature:'),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: characterOptions.map((opt) {
            final isSel = _painCharacter == opt;
            final isWarning = opt == 'Crushing / Pressure';
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isWarning) ...[
                    Icon(Icons.warning_amber_rounded, size: 12, color: isSel ? Colors.white : RuralCareColors.critical),
                    const SizedBox(width: 4),
                  ],
                  Text(opt, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : (isWarning ? RuralCareColors.critical : RuralCareColors.textPrimary))),
                ],
              ),
              selected: isSel,
              selectedColor: isWarning ? RuralCareColors.critical : RuralCareColors.primary,
              backgroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              onSelected: (_) {
                setState(() {
                  _painCharacter = opt;
                  _recalculateTriage();
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        // Pain Radiation
        Text(
          isMr ? 'वेदना पसरणे (Radiation):' : (isHi ? 'दर्द का फैलाव (Radiation):' : 'Radiation Pattern:'),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: radiationOptions.map((opt) {
            final isSel = _painRadiation == opt;
            final isArm = opt.contains('Arm');
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isArm) ...[
                    Icon(Icons.flash_on_rounded, size: 12, color: isSel ? Colors.white : RuralCareColors.critical),
                    const SizedBox(width: 4),
                  ],
                  Text(opt, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : (isArm ? RuralCareColors.critical : RuralCareColors.textPrimary))),
                ],
              ),
              selected: isSel,
              selectedColor: isArm ? RuralCareColors.critical : RuralCareColors.primary,
              backgroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              onSelected: (_) {
                setState(() {
                  _painRadiation = opt;
                  _recalculateTriage();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRegionTargetedSection(bool isHi, bool isMr) {
    if (_selectedRegion == null) return const SizedBox.shrink();
    final questions = ClinicalTriageEngine().getQuestionsForRegion(_selectedRegion!);
    if (questions.isEmpty) return const SizedBox.shrink();

    final regName = isMr
        ? _selectedRegion!.nameMr
        : (isHi ? _selectedRegion!.nameHi : _selectedRegion!.nameEn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMr ? '३. अवयव-विशिष्ट क्लिनिकल तपासणी' : (isHi ? '३. अंग-विशिष्ट नैदानिक प्रश्नोत्तरी' : '3. Targeted Region-Specific Screening'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                  ),
                  Text(
                    regName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.primary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: RuralCareColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: RuralCareColors.teal),
              ),
              child: Text(
                _selectedRegion!.localizedSystemType(isHi, isMr),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...questions.map((q) {
          final isChecked = _regionAnswers[q.id] ?? false;
          final qText = isMr ? q.textMr : (isHi ? q.textHi : q.textEn);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: isChecked
                  ? (q.isRedFlag ? RuralCareColors.criticalSoft.withValues(alpha: 0.3) : RuralCareColors.surface)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isChecked
                    ? (q.isRedFlag ? RuralCareColors.critical : RuralCareColors.primary)
                    : RuralCareColors.border,
                width: isChecked ? 1.5 : 1,
              ),
            ),
            child: CheckboxListTile(
              value: isChecked,
              onChanged: (val) {
                setState(() {
                  _regionAnswers[q.id] = val ?? false;
                  _recalculateTriage();
                });
              },
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              activeColor: q.isRedFlag ? RuralCareColors.critical : RuralCareColors.primary,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      qText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isChecked && q.isRedFlag ? RuralCareColors.critical : RuralCareColors.textPrimary,
                      ),
                    ),
                  ),
                  if (q.isRedFlag)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: RuralCareColors.criticalSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'RED-FLAG',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: RuralCareColors.critical),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                'Clinical rationale: ${q.clinicalRationale}',
                style: const TextStyle(fontSize: 9, color: RuralCareColors.textSecondary),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 1: Matching Specialist with Doctor Specialty Prominently Displayed
  Widget _step1DoctorMatch(SessionCoordinator session, bool isHi, bool isMr) {
    final allDoctors = DoctorRepository().registeredDoctors;

    final matchingDoctors = allDoctors.where((d) {
      return d.specialty.toLowerCase().contains(_selectedSpecialty.toLowerCase()) ||
          _selectedSpecialty == 'General Medicine';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMr ? 'उपलब्ध विशेषज्ञ डॉक्टर' : (isHi ? 'उपलब्ध विशेषज्ञ चिकित्सक' : 'Available Specialists'),
                  style: AppTypography.sectionTitle,
                ),
                Text(
                  'Specialty Filter: $_selectedSpecialty',
                  style: const TextStyle(fontSize: 12, color: RuralCareColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: RuralCareColors.successSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${matchingDoctors.isNotEmpty ? matchingDoctors.length : 1} Online',
                style: const TextStyle(fontSize: 10, color: RuralCareColors.success, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (matchingDoctors.isNotEmpty)
          ...matchingDoctors.map((doc) => _doctorTile(doc))
        else ...[
          _doctorTile(DoctorRepository().autoSelectDoctor(specialty: _selectedSpecialty)),
        ],

        const SizedBox(height: 20),

        // Offline booking alternative banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDBA74)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFFC05621), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMr
                      ? 'नेटवर्क कमकुवत असल्यास किंवा डॉक्टर व्यस्त असल्यास ऑफलाइन सल्ला विनंती नोंदवा.'
                      : (isHi
                          ? 'कमजोर नेटवर्क या डॉक्टर व्यस्त होने पर ऑफलाइन परामर्श कतार में जुड़ें।'
                          : 'Poor signal or specialist busy? Queue offline consultation request with auto-sync.'),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
                ),
              ),
              TextButton(
                onPressed: _requestOfflineConsultation,
                child: const Text('Queue Offline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC05621))),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Register appointment with queue number and triage priority
              final patientRepo = PatientRepository();
              final sessionCoordinator = SessionCoordinator();
              final patient = patientRepo.activePatient ??
                  patientRepo.defaultPatient ??
                  patientRepo.getOrCreatePatientForIdentifier(sessionCoordinator.currentUserId ?? 'citizen');
              final doctor = _selectedDoctor ??
                  DoctorRepository().autoSelectDoctor(specialty: _selectedSpecialty);

              final aptRepo = AppointmentRepository();
              aptRepo.addAppointment(
                AppointmentDto(
                  id: 'APT-${DateTime.now().millisecondsSinceEpoch % 100000}',
                  patientId: patient.id,
                  patientName: patient.fullName,
                  doctorName: doctor.name,
                  specialty: doctor.specialty.isNotEmpty ? doctor.specialty : _selectedSpecialty,
                  facilityName: doctor.facilityName,
                  scheduledTime: DateTime.now(),
                  type: 'TELECONSULTATION',
                  status: 'WAITING_ROOM',
                  chiefComplaint: _symptomCtrl.text.trim().isNotEmpty
                      ? _symptomCtrl.text.trim()
                      : (_bodySymptoms.isNotEmpty ? _bodySymptoms.join(', ') : 'General Consultation'),
                  queueNumber: _queueToken,
                  triagePriority: _calculatedTriage.code,
                  symptoms: _bodySymptoms,
                  primaryIssue: _activeBodyZone,
                ),
              );
              setState(() => _step = 2);
            },
            child: Text(
              isMr ? 'प्रतीक्षालयात जा' : (isHi ? 'प्रतीक्षालय में जाएं' : 'Proceed to Waiting Room'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _doctorTile(RegisteredDoctorAccount doc) {
    final session = SessionCoordinator();
    final isHi = session.isHindi;
    final isMr = session.isMarathi;
    final isSel = _selectedDoctor?.doctorId == doc.doctorId || _selectedDoctor == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSel ? RuralCareColors.primary : RuralCareColors.border,
          width: isSel ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => setState(() => _selectedDoctor = doc),
        leading: const CircleAvatar(
          backgroundColor: RuralCareColors.primarySoft,
          child: Icon(Icons.medical_services_rounded, color: RuralCareColors.primary, size: 20),
        ),
        title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${doc.specialty} • ${doc.qualification}', style: const TextStyle(fontSize: 11, color: RuralCareColors.primary, fontWeight: FontWeight.w600)),
            Text('${doc.facilityName} • Reg: ${doc.registrationNumber}', style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? RuralCareColors.primary.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? RuralCareColors.primary : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 14,
                color: isSel ? RuralCareColors.primary : RuralCareColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                isSel ? (isHi ? 'चयनित डॉक्टर' : (isMr ? 'निवडलेले डॉक्टर' : 'Auto-Selected')) : (isHi ? 'उपलब्ध' : 'Available'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSel ? RuralCareColors.primary : RuralCareColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 2: Virtual Waiting Room with Queue Number on basis of Digital Triage & ABHA ID
  Widget _step2WaitingRoom(SessionCoordinator session, bool isHi, bool isMr) {
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient ?? patientRepo.activePatient;
    final abhaId = patient?.abhaId.isNotEmpty == true ? patient!.abhaId : '91-4920-1123-8832@abdm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _calculatedTriage == TriagePriority.p0Red ? RuralCareColors.criticalSoft : RuralCareColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.video_camera_front_outlined,
            color: _calculatedTriage == TriagePriority.p0Red ? RuralCareColors.critical : RuralCareColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isMr ? 'आपण आभासी प्रतीक्षालयात आहात' : (isHi ? 'आप आभासी प्रतीक्षालय में हैं' : 'Virtual Waiting Room'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          '${_selectedDoctor?.name ?? 'Dr. Neha Kulkarni'} (${_selectedDoctor?.specialty ?? _selectedSpecialty})',
          style: const TextStyle(fontSize: 12, color: RuralCareColors.primary, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Prominent ABHA ID Display Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RuralCareColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 16, color: RuralCareColors.primary),
                  const SizedBox(width: 8),
                  Text('ABHA ID: $abhaId', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RuralCareColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ABDM LINKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Queue Card prioritized by Digital Triage
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _calculatedTriage == TriagePriority.p0Red ? RuralCareColors.critical : RuralCareColors.border,
              width: _calculatedTriage == TriagePriority.p0Red ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Queue Token #:', style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _calculatedTriage == TriagePriority.p0Red
                          ? RuralCareColors.criticalSoft
                          : (_calculatedTriage == TriagePriority.p1Yellow ? RuralCareColors.warningSoft : RuralCareColors.successSoft),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Token #$_queueToken (${_calculatedTriage.code})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _calculatedTriage == TriagePriority.p0Red
                            ? RuralCareColors.critical
                            : (_calculatedTriage == TriagePriority.p1Yellow ? RuralCareColors.warning : RuralCareColors.success),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, color: RuralCareColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Triage Priority:', style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                  Text(_calculatedTriage.labelEn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _calculatedTriage == TriagePriority.p0Red ? RuralCareColors.critical : RuralCareColors.textPrimary)),
                ],
              ),
              const Divider(height: 16, color: RuralCareColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Wait Time:', style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                  Text(_calculatedTriage.waitTimeEn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RuralCareColors.success)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Single Link/Button to Download Complete Patient Health History in PDF
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: RuralCareColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RuralCareColors.primary.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RuralCareColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: RuralCareColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMr ? 'संपूर्ण आरोग्य इतिहास (ABDM PDF)' : (isHi ? 'संपूर्ण स्वास्थ्य इतिहास (ABDM PDF)' : 'Longitudinal Health History (PDF)'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: RuralCareColors.textPrimary),
                    ),
                    const Text(
                      'Download and share past consults, vitals & tests',
                      style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuralCareColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _downloadHistoryPdf,
                child: const Text('Download PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Pre-Call Documents
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RuralCareColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pre-Call Clinical Documents', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _simulateUploadDocument,
                    icon: const Icon(Icons.upload_file_rounded, size: 14),
                    label: const Text('Attach Doc', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_uploadedDocs.isEmpty)
                const Text(
                  'No reports attached. Doctor can access your synced ABDM health history.',
                  style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                )
              else
                Column(
                  children: _uploadedDocs.map((doc) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RuralCareColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: RuralCareColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined, size: 16, color: RuralCareColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(doc, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          ),
                          const Icon(Icons.check_circle_rounded, size: 14, color: RuralCareColors.success),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _calculatedTriage == TriagePriority.p0Red ? RuralCareColors.critical : RuralCareColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _enterLiveCall,
            icon: const Icon(Icons.video_call_rounded, size: 20),
            label: Text(
              isMr ? 'कॉलमध्ये सामील व्हा' : (isHi ? 'कॉल में शामिल हों' : 'Join Live Teleconsultation Call'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
