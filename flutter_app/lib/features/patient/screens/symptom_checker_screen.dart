import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/services/clinical_triage_engine.dart';
import 'package:ruralcare/data/models/triage_dto.dart';
import 'package:ruralcare/features/teleconsult/widgets/visual_body_diagram_widget.dart';
import 'package:ruralcare/features/teleconsult/screens/teleconsultation_landing_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import 'package:ruralcare/data/repositories/emergency_repository.dart';

/// Dedicated Symptom Checker screen conforming to DESIGN.md Section 4 & 6:
/// - Plain everyday language (no clinical jargon)
/// - Trilingual (English, Hindi, Marathi) with instant AppBar language switch pill
/// - Interactive Visual Body Diagram
/// - Pain severity rating with plain labels
/// - Universal MoHFW emergency danger signs checklist
/// - Seamless 1-tap handoff to Teleconsultation doctor queue
class SymptomCheckerScreen extends StatefulWidget {
  final bool isModal;

  const SymptomCheckerScreen({
    super.key,
    this.isModal = false,
  });

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  AnatomicalRegionDto? _selectedRegion;
  List<String> _selectedSymptoms = [];
  bool _isRedFlag = false;
  String? _redFlagWarning;

  // Discomfort / Pain severity
  double _painSeverity = 3.0;
  int _painOnsetIndex = 0; // 0: Today, 1: 1-3 Days, 2: > 1 Week
  int _painCharacterIndex = 0; // 0: Dull/heavy, 1: Sharp/stabbing, 2: Burning, 3: Throbbing

  // Universal danger questions
  bool _qUnconscious = false;
  bool _qBreathingDifficulty = false;
  bool _qColdHandsDizzy = false;
  bool _qHeavyBleeding = false;

  @override
  void initState() {
    super.initState();
    _selectedRegion = ClinicalTriageEngine().getRegionById('forehead_right');
    _selectedSymptoms = _selectedRegion?.commonSymptoms.take(2).toList() ?? [];
    _isRedFlag = _selectedRegion?.isHighRisk ?? false;
  }

  void _onBodySelectionChanged(BodyDiagramSelection sel) {
    setState(() {
      _selectedRegion = sel.region;
      _selectedSymptoms = sel.selectedSymptoms;
      _isRedFlag = sel.isRedFlag;
      _redFlagWarning = sel.redFlagWarning;
    });
  }

  bool get _hasEmergencyDanger =>
      _isRedFlag || _qUnconscious || _qBreathingDifficulty || _qColdHandsDizzy || _qHeavyBleeding;

  bool get _isUrgent =>
      !_hasEmergencyDanger && (_painSeverity >= 7 || _painOnsetIndex == 0 && _painSeverity >= 5);

  void _trigger108Emergency(bool isHi, bool isMr) {
    final facility = _selectedRegion?.emergencyProtocol.localizedTargetFacility(isHi, isMr) ??
        (isMr ? 'जिल्हा सामान्य रुग्णालय' : (isHi ? 'जिला अस्पताल' : 'District Hospital Emergency'));
    EmergencyRepository().triggerEmergency(
      patientId: 'P-101',
      patientName: 'Kavita Rajesh Devi',
      assignedFacilityName: facility,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmergencyTrackingScreen()),
    );
  }

  void _proceedToDoctor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeleconsultationLandingScreen(
          initialRegion: _selectedRegion,
          initialSymptoms: _selectedSymptoms,
          initialPainSeverity: _painSeverity,
          hasPreCheckedSymptoms: true,
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
        final isHi = session.isHindi;
        final isMr = session.isMarathi;

        final title = isMr
            ? 'लक्षण तपासणी'
            : (isHi ? 'लक्षण जाँच' : 'Symptom Checker');
        final subtitle = isMr
            ? 'शरीराच्या भागावर टॅप करा, त्रास सांगा व डॉक्टरांशी बोला'
            : (isHi
                ? 'शरीर के अंग पर टैप करें, परेशानी बताएं और डॉक्टर से सलाह लें'
                : 'Tap body map to identify issue, check warning signs, and consult a doctor');

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            leading: widget.isModal
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: RuralCareColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: RuralCareColors.textPrimary,
              ),
            ),
            actions: [
              // Trilingual 1-tap language switch pill
              Container(
                margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
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
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Plain Header Guide Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RuralCareColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: RuralCareColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: RuralCareColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.accessibility_new_rounded, color: RuralCareColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMr
                                    ? 'सोप्या भाषेत आरोग्य तपासणी'
                                    : (isHi ? 'सरल भाषा में स्वास्थ्य जाँच' : 'Easy Symptom Self-Check'),
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: RuralCareColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
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
                  ),

                  const SizedBox(height: 16),

                  // 2. Interactive Vector Body Diagram
                  VisualBodyDiagramWidget(
                    onSelectionChanged: _onBodySelectionChanged,
                  ),

                  const SizedBox(height: 16),

                  // 3. Pain / Discomfort Severity Rating (Plain language)
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isMr
                                  ? 'त्रास किंवा वेदनेचे प्रमाण (० ते १०):'
                                  : (isHi
                                      ? 'दर्द या तकलीफ का स्तर (0 से 10):'
                                      : 'Pain or Discomfort Level (0 to 10):'),
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: RuralCareColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _painSeverity >= 7
                                    ? RuralCareColors.criticalSoft
                                    : (_painSeverity >= 4 ? const Color(0xFFFEF3C7) : RuralCareColors.primarySoft),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_painSeverity.toInt()} / 10',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _painSeverity >= 7
                                      ? RuralCareColors.critical
                                      : (_painSeverity >= 4 ? const Color(0xFFD97706) : RuralCareColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _painSeverity >= 7
                                ? RuralCareColors.critical
                                : RuralCareColors.primary,
                            inactiveTrackColor: RuralCareColors.surfaceSubtle,
                            thumbColor: _painSeverity >= 7
                                ? RuralCareColors.critical
                                : RuralCareColors.primary,
                            overlayColor: (_painSeverity >= 7 ? RuralCareColors.critical : RuralCareColors.primary)
                                .withOpacity(0.12),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _painSeverity,
                            min: 0,
                            max: 10,
                            divisions: 10,
                            onChanged: (val) {
                              setState(() {
                                _painSeverity = val;
                              });
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isMr ? 'काहीच नाही (०)' : (isHi ? 'कोई नहीं (0)' : 'None (0)'),
                              style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                            ),
                            Text(
                              isMr ? 'मध्यम (४-६)' : (isHi ? 'मध्यम (4-6)' : 'Moderate (4-6)'),
                              style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                            ),
                            Text(
                              isMr ? 'असहनीय (१०)' : (isHi ? 'असहनीय (10)' : 'Severe (10)'),
                              style: const TextStyle(fontSize: 10, color: RuralCareColors.critical, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(color: RuralCareColors.border, height: 1),
                        const SizedBox(height: 12),

                        // Pain Duration
                        Text(
                          isMr ? 'हा त्रास कधीपासून आहे?' : (isHi ? 'यह परेशानी कब से है?' : 'Since when do you have this?'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _durationChip(0, isMr ? 'आजच सुरू झाले' : (isHi ? 'आज ही शुरू हुआ' : 'Started Today')),
                            _durationChip(1, isMr ? '१ ते ३ दिवस' : (isHi ? '1 से 3 दिन' : '1 to 3 Days')),
                            _durationChip(2, isMr ? '१ आठवड्यापेक्षा जास्त' : (isHi ? '1 हफ्ते से ज्यादा' : 'More than 1 Week')),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Sensation Character
                        Text(
                          isMr ? 'त्रासाचा प्रकार कसा वाटतो?' : (isHi ? 'परेशानी का अहसास कैसा है?' : 'What does the feeling feel like?'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _characterChip(0, isMr ? 'मंद किंवा जडपणा' : (isHi ? 'हल्का या भारीपन' : 'Dull / Heavy')),
                            _characterChip(1, isMr ? 'काट्यासारखे टोचणारे' : (isHi ? 'तेज चुभन जैसा' : 'Sharp / Pricking')),
                            _characterChip(2, isMr ? 'जळजळ किंवा आग' : (isHi ? 'जलन या आग जैसा' : 'Burning / Hot')),
                            _characterChip(3, isMr ? 'ठसठसणारे' : (isHi ? 'धड़कता हुआ' : 'Throbbing / Pounding')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Universal Plain Language Emergency Danger Questions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _hasEmergencyDanger ? const Color(0xFFFFF5F5) : RuralCareColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasEmergencyDanger ? RuralCareColors.critical : RuralCareColors.border,
                        width: _hasEmergencyDanger ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.health_and_safety_outlined,
                              color: _hasEmergencyDanger ? RuralCareColors.critical : RuralCareColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isMr
                                    ? 'तातडीच्या धोक्याची लक्षणे (लागू असल्यास निवडा):'
                                    : (isHi
                                        ? 'तत्काल खतरे के लक्षण (यदि कोई हो तो चुनें):'
                                        : 'Immediate Warning Signs (Check if present):'),
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _hasEmergencyDanger ? RuralCareColors.critical : RuralCareColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _dangerCheckTile(
                          title: isMr
                              ? 'रुग्ण बेशुद्ध आहे, चक्कर येऊन पडत आहे किंवा ओळखू शकत नाही'
                              : (isHi
                                  ? 'मरीज बेहोश है, तेज चक्कर खाकर गिर रहा है, या पहचान नहीं पा रहा'
                                  : 'Person is unconscious, fainting, or unable to recognize family'),
                          value: _qUnconscious,
                          onChanged: (val) => setState(() => _qUnconscious = val ?? false),
                        ),
                        _dangerCheckTile(
                          title: isMr
                              ? 'श्वास घेण्यास खूप त्रास होतोय, शिट्टीसारखा आवाज येतोय किंवा ओठ निळे पडलेत'
                              : (isHi
                                  ? 'सांस लेने में बहुत जोर लग रहा है, सीटी की आवाज या होंठ नीले हैं'
                                  : 'Struggling heavily to breathe, whistling sound, or blue lips'),
                          value: _qBreathingDifficulty,
                          onChanged: (val) => setState(() => _qBreathingDifficulty = val ?? false),
                        ),
                        _dangerCheckTile(
                          title: isMr
                              ? 'हात-पाय बर्फासारखे गार पडले आहेत आणि उठल्यावर खूप भोवळ येते'
                              : (isHi
                                  ? 'हाथ-पैर बर्फ जैसे ठंडे हैं और उठने पर बहुत तेज चक्कर आ रहे हैं'
                                  : 'Hands and feet are ice cold, with extreme spinning dizziness'),
                          value: _qColdHandsDizzy,
                          onChanged: (val) => setState(() => _qColdHandsDizzy = val ?? false),
                        ),
                        _dangerCheckTile(
                          title: isMr
                              ? 'सतत जास्त रक्त वाहत आहे किंवा रक्ताची उलटी झाली आहे'
                              : (isHi
                                  ? 'लगातार अधिक खून बह रहा है या खून की उल्टी हुई है'
                                  : 'Continuous heavy bleeding or blood in vomit'),
                          value: _qHeavyBleeding,
                          onChanged: (val) => setState(() => _qHeavyBleeding = val ?? false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Dynamic Calculated Recommendation Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _hasEmergencyDanger
                          ? const Color(0xFFFFF1F0)
                          : (_isUrgent ? const Color(0xFFFEF9C3) : const Color(0xFFF0FDF4)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasEmergencyDanger
                            ? RuralCareColors.critical
                            : (_isUrgent ? const Color(0xFFEAB308) : const Color(0xFF16A34A)),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _hasEmergencyDanger
                                  ? Icons.emergency_rounded
                                  : (_isUrgent ? Icons.speed_rounded : Icons.check_circle_outline_rounded),
                              color: _hasEmergencyDanger
                                  ? RuralCareColors.critical
                                  : (_isUrgent ? const Color(0xFFCA8A04) : const Color(0xFF16A34A)),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hasEmergencyDanger
                                  ? (isMr ? 'तातडीची वैद्यकीय मदत आवश्यक (P0)' : (isHi ? 'तत्काल आपातकालीन सहायता जरूरी (P0)' : 'Emergency Care Needed (P0)'))
                                  : (_isUrgent
                                      ? (isMr ? 'प्राधान्य तपासणी (P1 - 5 मिनिटांत)' : (isHi ? 'प्राथमिकता जाँच (P1 - 5 मिनट में)' : 'Prompt Doctor Review (P1 - within 5 mins)'))
                                      : (isMr ? 'नियमित सल्लामसलत (P2)' : (isHi ? 'सामान्य परामर्श (P2)' : 'Routine Consultation (P2)'))),
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _hasEmergencyDanger
                                    ? RuralCareColors.critical
                                    : (_isUrgent ? const Color(0xFF854D0E) : const Color(0xFF166534)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hasEmergencyDanger
                            ? ((_redFlagWarning != null && _redFlagWarning!.isNotEmpty)
                                ? _redFlagWarning!
                                : (isMr
                                    ? 'गंभीर धोक्याची लक्षणे आढळली आहेत. त्वरित १०८ रुग्णवाहिका बोलवा किंवा जवळच्या रुग्णालयात जा.'
                                    : (isHi
                                        ? 'गंभीर खतरे के संकेत मिले हैं। तुरंत 108 एम्बुलेंस बुलाएं या नजदीकी अस्पताल जाएं।'
                                        : 'Severe warning signs detected. Call 108 ambulance immediately or visit nearest facility.')))
                            : (_isUrgent
                                ? (isMr
                                    ? 'तुमच्या लक्षणांमुळे त्वरित डॉक्टरांचा सल्ला घेणे हितावह आहे. तुम्हाला प्राधान्य कतार दिली जाईल.'
                                    : (isHi
                                        ? 'आपकी परेशानी के लिए जल्द डॉक्टर को दिखाना बेहतर होगा। आपको प्राथमिकता कतार मिलेगी।'
                                        : 'Symptoms warrant prompt doctor attention. You will receive priority queue placement.'))
                                : (isMr
                                    ? 'तुमची लक्षणे सामान्य आहेत. तुम्ही व्हिडिओ कॉलद्वारे डॉक्टरांशी बोलू शकता.'
                                    : (isHi
                                        ? 'आपकी स्थिति स्थिर है। आप वीडियो कॉल द्वारा डॉक्टर से आराम से परामर्श ले सकते हैं।'
                                        : 'Symptoms appear stable. Connect with a medical officer via teleconsultation.'))),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            color: _hasEmergencyDanger
                                ? RuralCareColors.critical
                                : (_isUrgent ? const Color(0xFF713F12) : const Color(0xFF14532D)),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Primary Action Buttons (DESIGN.md 52px height)
                  if (_hasEmergencyDanger) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RuralCareColors.critical,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () => _trigger108Emergency(isHi, isMr),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                        label: Text(
                          isMr ? '१०८ रुग्णवाहिका बोलवा (तातडीने)' : (isHi ? '108 एम्बुलेंस बुलाएं (तत्काल)' : 'Call 108 Ambulance (SOS)'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: RuralCareColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _proceedToDoctor(context),
                        child: Text(
                          isMr ? 'तरीही डॉक्टरांशी बोला' : (isHi ? 'फिर भी डॉक्टर से बात करें' : 'Still Talk to Doctor'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RuralCareColors.primary),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RuralCareColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () => _proceedToDoctor(context),
                        icon: const Icon(Icons.video_call_rounded, size: 22),
                        label: Text(
                          isMr
                              ? 'या समस्येसाठी डॉक्टरांशी बोला'
                              : (isHi ? 'इस समस्या के लिए डॉक्टर से बात करें' : 'Consult Doctor for this Issue'),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
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

  Widget _durationChip(int index, String label) {
    final isSel = _painOnsetIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: RuralCareColors.primarySoft,
      backgroundColor: RuralCareColors.surfaceSubtle,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
        color: isSel ? RuralCareColors.primary : RuralCareColors.textPrimary,
      ),
      side: BorderSide(
        color: isSel ? RuralCareColors.primary : RuralCareColors.border,
      ),
      onSelected: (_) => setState(() => _painOnsetIndex = index),
    );
  }

  Widget _characterChip(int index, String label) {
    final isSel = _painCharacterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: RuralCareColors.primarySoft,
      backgroundColor: RuralCareColors.surfaceSubtle,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
        color: isSel ? RuralCareColors.primary : RuralCareColors.textPrimary,
      ),
      side: BorderSide(
        color: isSel ? RuralCareColors.primary : RuralCareColors.border,
      ),
      onSelected: (_) => setState(() => _painCharacterIndex = index),
    );
  }

  Widget _dangerCheckTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFFEE2E2) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? RuralCareColors.critical : RuralCareColors.border,
        ),
      ),
      child: CheckboxListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        activeColor: RuralCareColors.critical,
        checkColor: Colors.white,
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: value ? FontWeight.w700 : FontWeight.w500,
            color: value ? RuralCareColors.critical : RuralCareColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
