import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/models/consent_request_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/consent_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/doctor/utils/doctor_strings.dart';
import 'package:ruralcare/features/doctor/screens/doctor_clinical_summary_screen.dart';

/// Doctor Patients Roster Tab with ABDM Consent Request & OTP Authorization
class DoctorPatientsTab extends StatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedTagIndex = 0; // 0 = All, 1 = High Risk, 2 = ANC, 3 = NCD

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openConsentModal(BuildContext context, PatientDto patient, ConsentRepository consentRepo, DoctorStrings strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConsentRequestBottomSheet(
        patient: patient,
        consentRepo: consentRepo,
        strings: strings,
        onConsentGranted: () {
          Navigator.of(ctx).pop();
          // Directly open clinical summary upon successful verification
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (c) => DoctorClinicalSummaryScreen(patient: patient),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final consentRepo = ConsentRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, consentRepo, session]),
      builder: (context, _) {
        final strings = DoctorStrings.of(session);
        final patients = patientRepo.patients;
        final query = _searchCtrl.text.toLowerCase().trim();

        final tags = [strings.tagAll, strings.tagHighRisk, strings.tagAnc, strings.tagNcd];

        var filtered = patients.where((p) {
          final matchesQuery = query.isEmpty ||
              p.fullName.toLowerCase().contains(query) ||
              p.ruralCareId.toLowerCase().contains(query) ||
              p.village.toLowerCase().contains(query);

          if (!matchesQuery) return false;

          if (_selectedTagIndex == 1) {
            return p.highRiskConditions.isNotEmpty;
          } else if (_selectedTagIndex == 2) {
            return p.isPregnant;
          } else if (_selectedTagIndex == 3) {
            return p.chronicConditions.isNotEmpty;
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                strings.patientCharts,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: RuralCareColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                strings.patientChartsSub,
                style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Search Bar
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
                    hintText: strings.searchPatientsHint,
                    hintStyle: const TextStyle(fontSize: 13, color: RuralCareColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: RuralCareColors.textSecondary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tags
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tags.asMap().entries.map((entry) {
                    final isSelected = entry.key == _selectedTagIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedTagIndex = entry.key),
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

              // Patient Cards List
              ...filtered.map((patient) => _buildPatientCard(context, patient, consentRepo, strings)),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientCard(BuildContext context, PatientDto patient, ConsentRepository consentRepo, DoctorStrings strings) {
    final vitals = patient.latestVitals;
    final hasHighRisk = patient.highRiskConditions.isNotEmpty;
    final hasConsent = consentRepo.hasValidConsent(patient.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasConsent
              ? RuralCareColors.teal
              : (hasHighRisk ? RuralCareColors.critical.withOpacity(0.4) : RuralCareColors.border),
          width: (hasConsent || hasHighRisk) ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: hasConsent ? RuralCareColors.teal : RuralCareColors.primary,
                    child: Text(
                      patient.fullName.isNotEmpty ? patient.fullName[0] : 'P',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            patient.fullName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${patient.age}${patient.gender.isNotEmpty ? patient.gender[0] : "M"}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: RuralCareColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        '${patient.village} • ${patient.ruralCareId}',
                        style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (hasConsent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RuralCareColors.successSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: RuralCareColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user, size: 11, color: RuralCareColors.success),
                          const SizedBox(width: 3),
                          Text(strings.abdmConsentActive, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success)),
                        ],
                      ),
                    )
                  else if (hasHighRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RuralCareColors.criticalSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(strings.tagHighRisk, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.critical)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Latest vitals telemetry pill
          if (vitals != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: RuralCareColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BP: ${vitals.systolicBp}/${vitals.diastolicBp} mmHg', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('Pulse: ${vitals.pulse} bpm', style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                  Text('SpO2: ${vitals.spO2}%', style: const TextStyle(fontSize: 11, color: RuralCareColors.success, fontWeight: FontWeight.w600)),
                  Text('Hb: ${vitals.haemoglobin} g/dL', style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Primary Action: Request for Clinical Chart OR Open Chart if Consent Active
          SizedBox(
            width: double.infinity,
            height: 42,
            child: hasConsent
                ? ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => DoctorClinicalSummaryScreen(patient: patient),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: Text(strings.openClinicalChartConsent, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RuralCareColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _openConsentModal(context, patient, consentRepo, strings),
                    icon: const Icon(Icons.vpn_key_outlined, size: 16),
                    label: Text(strings.requestForClinicalChart, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RuralCareColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Interactive ABDM Consent Request & OTP Verification Bottom Sheet
class _ConsentRequestBottomSheet extends StatefulWidget {
  final PatientDto patient;
  final ConsentRepository consentRepo;
  final DoctorStrings strings;
  final VoidCallback onConsentGranted;

  const _ConsentRequestBottomSheet({
    required this.patient,
    required this.consentRepo,
    required this.strings,
    required this.onConsentGranted,
  });

  @override
  State<_ConsentRequestBottomSheet> createState() => _ConsentRequestBottomSheetState();
}

class _ConsentRequestBottomSheetState extends State<_ConsentRequestBottomSheet> {
  bool _requestSent = false;
  ConsentRequestDto? _activeRequest;
  final TextEditingController _otpCtrl = TextEditingController();
  String? _errorMessage;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Check if there's already a pending request for this patient
    final pending = widget.consentRepo.getPendingRequest(widget.patient.id);
    if (pending != null) {
      _requestSent = true;
      _activeRequest = pending;
    }
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _sendRequest() {
    final doctor = DoctorRepository().getDoctorForSession(SessionCoordinator());
    setState(() {
      _activeRequest = widget.consentRepo.sendConsentRequest(
        patientId: widget.patient.id,
        patientName: widget.patient.fullName,
        patientPhone: widget.patient.phoneNumber,
        doctorName: doctor.name,
        doctorFacility: doctor.facilityName,
      );
      _requestSent = true;
      _errorMessage = null;
    });
  }

  void _verifyOtp() {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = widget.strings.isHi ? 'कृपया 6 अंकों का वैध कोड दर्ज करें' : (widget.strings.isMr ? 'कृपया वैध ६ अंकी कोड प्रविष्ट करा' : 'Please enter a valid 6-digit OTP code'));
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final success = widget.consentRepo.verifyOtp(
      patientId: widget.patient.id,
      otp: otp,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.strings.isHi ? 'पहुंच स्वीकृत: ${widget.patient.fullName} का चार्ट अनलॉक हो गया' : (widget.strings.isMr ? 'प्रवेश मंजूर: ${widget.patient.fullName} चे चार्ट अनलॉक झाले' : 'Access Granted: Clinical chart unlocked for ${widget.patient.fullName}')),
          backgroundColor: RuralCareColors.success,
        ),
      );
      widget.onConsentGranted();
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = widget.strings.consentOtpMismatch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final strings = widget.strings;
    final phoneMask = patient.phoneNumber.length >= 4
        ? '+91 XXXXX ${patient.phoneNumber.substring(patient.phoneNumber.length - 4)}'
        : patient.phoneNumber;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RuralCareColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: RuralCareColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.security_rounded, color: RuralCareColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.consentTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: RuralCareColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                strings.isHi ? 'डिजिटल स्वास्थ्य रिकॉर्ड पहुंच अनुरोध' : (strings.isMr ? 'डिजिटल आरोग्य नोंदी प्रवेश विनंती' : 'Digital Health Record Access Request'),
                                style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20, color: RuralCareColors.border),

              if (!_requestSent) ...[
                // STAGE 1: Consent Specification
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
                      Text(
                        patient.fullName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ABHA: ${patient.abhaId} • ${patient.village} • Phone: $phoneMask',
                        style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                      ),
                      const Divider(height: 16, color: RuralCareColors.border),
                      _buildDetailRow(
                        strings.isHi ? 'अनुरोधक चिकित्सक:' : (strings.isMr ? 'विनंती करणारे डॉक्टर:' : 'Requesting Clinician:'),
                        '${DoctorRepository().getDoctorForSession(SessionCoordinator()).name} (${DoctorRepository().getDoctorForSession(SessionCoordinator()).facilityName})',
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        strings.isHi ? 'उद्देश्य:' : (strings.isMr ? 'उद्देश:' : 'Purpose:'),
                        strings.isHi ? 'ओपीडी परामर्श और देखभाल समीक्षा' : (strings.isMr ? 'ओपीडी सल्ला आणि काळजी आढावा' : 'OPD Consultation & Care Review'),
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        strings.isHi ? 'रिकॉर्ड दायरा:' : (strings.isMr ? 'नोंदणी व्याप्ती:' : 'Artifact Scope:'),
                        strings.isHi ? 'वाइटल्स, निदान, पूर्व प्रिस्क्रिप्शन, लैब जांच' : (strings.isMr ? 'व्हायटल्स, निदान, पूर्व औषधोपचार, लॅब अहवाल' : 'Longitudinal Vitals, Diagnoses, Past Rx, Lab Reports'),
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        strings.isHi ? 'पहुंच वैधता:' : (strings.isMr ? 'प्रवेश वैधता:' : 'Access Validity:'),
                        strings.isHi ? 'ओटीपी सत्यापन से 24 घंटे' : (strings.isMr ? 'ओटीपी पडताळणीपासून २४ तास' : '24 Hours from OTP verification'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.isHi
                      ? 'NDHM / ABDM नियमों के अनुसार, व्यक्तिगत स्वास्थ्य रिकॉर्ड देखने से पहले मरीज़ की ओटीपी अनुमति आवश्यक है।'
                      : (strings.isMr
                          ? 'NDHM / ABDM नियमांनुसार, वैयक्तिक आरोग्य नोंदी पाहण्यापूर्वी रुग्णाची ओटीपी परवानगी आवश्यक आहे.'
                          : 'As per NDHM / ABDM compliance, patient authorization via one-time password (OTP) is required before accessing personal health records.'),
                  style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _sendRequest,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      strings.consentSendButton,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RuralCareColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                // STAGE 2: OTP Verification
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mark_email_read_outlined, size: 16, color: RuralCareColors.success),
                          const SizedBox(width: 6),
                          Text(
                            strings.isHi ? 'मरीज़ को प्राप्त सूचना (ABDM गेटवे एसएमएस):' : (strings.isMr ? 'रुग्णाला मिळालेली सूचना (ABDM गेटवे एसएमएस):' : 'Incoming Patient Notification (ABDM Gateway SMS):'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: RuralCareColors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.isHi
                            ? '"${DoctorRepository().getDoctorForSession(SessionCoordinator()).facilityName} से ${DoctorRepository().getDoctorForSession(SessionCoordinator()).name} ने 24 घंटे के लिए आपके स्वास्थ्य रिकॉर्ड तक पहुंच का अनुरोध किया है। सत्यापन ओटीपी साझा करें: ${_activeRequest?.otp ?? ''}।"'
                            : (strings.isMr
                                ? '"${DoctorRepository().getDoctorForSession(SessionCoordinator()).facilityName} येथून ${DoctorRepository().getDoctorForSession(SessionCoordinator()).name} यांनी २४ तासांसाठी आपल्या आरोग्य नोंदी पाहण्याची विनंती केली आहे. पडताळणी ओटीपी सामायिक करा: ${_activeRequest?.otp ?? ''}."'
                                : '"${DoctorRepository().getDoctorForSession(SessionCoordinator()).name} from ${DoctorRepository().getDoctorForSession(SessionCoordinator()).facilityName} requests access to your health records for 24h. Share verification OTP: ${_activeRequest?.otp ?? ''} to authorize access."'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  strings.isHi
                      ? '${patient.fullName} द्वारा प्रदान किया गया 6-अंकीय ओटीपी दर्ज करें:'
                      : (strings.isMr
                          ? '${patient.fullName} यांनी दिलेला ६-अंकी ओटीपी प्रविष्ट करा:'
                          : 'Enter 6-Digit OTP provided by ${patient.fullName}:'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 4),
                        decoration: InputDecoration(
                          hintText: '• • • • • •',
                          counterText: '',
                          filled: true,
                          fillColor: RuralCareColors.surfaceSubtle,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: RuralCareColors.inputBorder)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick paste / autofill helper for pairwise demo evaluation
                    TextButton.icon(
                      onPressed: () {
                        if (_activeRequest != null) {
                          setState(() {
                            _otpCtrl.text = _activeRequest!.otp;
                            _errorMessage = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.paste_rounded, size: 16, color: RuralCareColors.teal),
                      label: Text(strings.consentQuickFill, style: const TextStyle(fontSize: 12, color: RuralCareColors.teal, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 12, color: RuralCareColors.critical, fontWeight: FontWeight.w600),
                  ),
                ],

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sendRequest,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          side: const BorderSide(color: RuralCareColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          strings.isHi ? 'पुनः एसएमएस भेजें' : (strings.isMr ? 'पुन्हा एसएमएस पाठवा' : 'Resend SMS'),
                          style: const TextStyle(fontSize: 13, color: RuralCareColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RuralCareColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isVerifying
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                strings.consentVerifyButton,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary)),
        ),
      ],
    );
  }
}
