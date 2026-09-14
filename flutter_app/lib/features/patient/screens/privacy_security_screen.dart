import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/consent_repository.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import '../utils/patient_strings.dart';

/// Screen 4: Privacy, Contacts & Security (V2 Modern)
/// Exactly reproducing Stitch Screen `04162c5bed434968863f15176672fac1`
class PrivacySecurityScreen extends StatefulWidget {
  final PatientDto patient;

  const PrivacySecurityScreen({super.key, required this.patient});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  void _openEditContactDialog(BuildContext context, PatientRepository patientRepo, PatientDto current, PatientStrings strings) {
    final nameCtrl = TextEditingController(text: current.emergencyContact.name);
    final relCtrl = TextEditingController(text: current.emergencyContact.relationship);
    final phoneCtrl = TextEditingController(text: current.emergencyContact.phoneNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      strings.emergencyContactDetails,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(strings.contactFullName, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: AppDecorations.input(hintText: 'e.g. Rajesh Devi / Sunita Sharma'),
                ),
                const SizedBox(height: 14),
                Text(strings.relationshipLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  controller: relCtrl,
                  decoration: AppDecorations.input(hintText: 'e.g. Wife / Spouse / Husband / Parent'),
                ),
                const SizedBox(height: 14),
                Text(strings.phoneNumberLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: AppDecorations.input(hintText: '+91 98765 11223'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6B56),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      final r = relCtrl.text.trim();
                      final p = phoneCtrl.text.trim();
                      if (n.isNotEmpty && p.isNotEmpty) {
                        patientRepo.updateEmergencyContact(
                          patientId: current.id,
                          contact: EmergencyContactDto(name: n, relationship: r, phoneNumber: p),
                        );
                      }
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.contactSavedToast),
                          backgroundColor: const Color(0xFF0A6B56),
                        ),
                      );
                    },
                    child: Text(strings.saveContactBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();
    final cache = LocalCacheService();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, session, cache]),
      builder: (context, _) {
        final currentPatient = patientRepo.patients.firstWhere(
          (p) => p.id == widget.patient.id,
          orElse: () => widget.patient,
        );
        final strings = PatientStrings.of(session);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(102),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Global Row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFF104A7B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RuralCare',
                              style: TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF104A7B),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Interactive Language Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => session.switchLanguage('en'),
                                    child: Text(
                                      'EN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isEnglish ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                  InkWell(
                                    onTap: () => session.switchLanguage('hi'),
                                    child: Text(
                                      'हि',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isHindi ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                  InkWell(
                                    onTap: () => session.switchLanguage('mr'),
                                    child: Text(
                                      'म',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isMarathi ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Emergency Button
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emergency_rounded, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      strings.emergencyHelp,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                // Sub-header with Back button & Centered Title
                Container(
                  color: Colors.white,
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_back, size: 18, color: Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Text(
                                strings.back,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            strings.privacySecurityTitle,
                            style: const TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.shield_outlined, color: Color(0xFF0A6B56), size: 19),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: EMERGENCY CONTACT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          strings.emergencyContactsItem,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _openEditContactDialog(context, patientRepo, currentPatient, strings),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 15, color: Color(0xFF0A6B56)),
                          const SizedBox(width: 4),
                          Text(
                            session.isHindi ? '+ संपर्क जोड़ें' : (session.isMarathi ? '+ संपर्क जोडा' : '+ Add Contact'),
                            style: const TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A6B56),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.perm_phone_msg_rounded, color: Color(0xFFEF4444), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentPatient.emergencyContact.name.isNotEmpty
                                          ? currentPatient.emergencyContact.name
                                          : 'Sunita Sharma',
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '(${currentPatient.emergencyContact.relationship.isNotEmpty ? currentPatient.emergencyContact.relationship : (session.isHindi ? "पत्नी" : (session.isMarathi ? "पत्नी" : "Spouse"))})',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.call_outlined, size: 13, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentPatient.emergencyContact.phoneNumber.isNotEmpty
                                          ? currentPatient.emergencyContact.phoneNumber
                                          : '+91 98765 11223',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: Color(0xFF15803D)),
                                const SizedBox(width: 4),
                                Text(
                                  strings.verified,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _openEditContactDialog(context, patientRepo, currentPatient, strings),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF475569)),
                                  const SizedBox(width: 4),
                                  Text(
                                    strings.edit,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              patientRepo.updateEmergencyContact(
                                patientId: currentPatient.id,
                                contact: const EmergencyContactDto(name: '', relationship: '', phoneNumber: ''),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(session.isHindi ? 'संपर्क हटाया गया' : (session.isMarathi ? 'संपर्क काढून टाकला' : 'Contact removed'))),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 4),
                                  Text(
                                    session.isHindi ? 'हटाएं' : (session.isMarathi ? 'काढून टाका' : 'Remove'),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        session.isHindi
                            ? 'यदि आप आपातकालीन अलर्ट ट्रिगर करते हैं तो इस संपर्क को सूचित किया जाएगा।'
                            : (session.isMarathi ? 'आपण आपत्कालीन सूचना दिल्यास या संपर्कास कळवले जाईल.' : 'This contact is notified if you trigger an emergency alert.'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // SECTION 2: DATA SHARING & CONSENT
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Color(0xFF0A6B56), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      strings.privacySecurityItem,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.isHindi
                                        ? 'उपस्थित डॉक्टरों के साथ रिकॉर्ड साझा करें'
                                        : (session.isMarathi ? 'उपस्थित डॉक्टरांसोबत नोंदी शेअर करा' : 'Share Records with Attending Doctors'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    session.isHindi
                                        ? 'पीएचसी रामपुर के डॉक्टरों को आपकी परामर्श हिस्ट्री देखने की अनुमति देता है।'
                                        : (session.isMarathi
                                            ? 'प्राथमिक आरोग्य केंद्रातील डॉक्टरांना तुमचा पूर्वेतिहास पाहण्याची परवानगी देतो.'
                                            : 'Allows doctors at PHC Rampur to review your consultation history.'),
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Switch.adaptive(
                              value: session.shareWithDoctors,
                              activeColor: const Color(0xFF0A6B56),
                              onChanged: (v) => session.toggleShareWithDoctors(v),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.isHindi ? 'ऑफलाइन रिकॉर्ड कैश' : (session.isMarathi ? 'ऑफलाइन रेकॉर्ड कॅशे' : 'Offline Record Cache'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    session.isHindi
                                        ? 'इस डिवाइस पर चयनित रिकॉर्ड उपलब्ध रखें।'
                                        : (session.isMarathi ? 'या डिव्हाइसवर निवडलेल्या नोंदी उपलब्ध ठेवा.' : 'Keep selected records available on this device.'),
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Switch.adaptive(
                              value: session.offlineRecordCache,
                              activeColor: const Color(0xFF0A6B56),
                              onChanged: (v) => session.toggleOfflineRecordCache(v),
                            ),
                          ],
                        ),
                      ),
                      // ABDM Digital Consent Artifacts
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      ListenableBuilder(
                        listenable: ConsentRepository(),
                        builder: (context, _) {
                          final consentRepo = ConsentRepository();
                          final patientRequests = consentRepo.requests.where((r) => r.patientId == widget.patient.id).toList();

                          if (patientRequests.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF0A6B56)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      session.isHindi
                                          ? 'कोई लंबित डॉक्टर पहुंच अनुरोध नहीं। आपका डेटा सुरक्षित और निजी है।'
                                          : (session.isMarathi
                                              ? 'कोणतीही प्रलंबित डॉक्टर प्रवेश विनंती नाही. तुमचा डेटा सुरक्षित आणि खाजगी आहे.'
                                              : 'No pending doctor access requests. Your records are private.'),
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: patientRequests.map((req) {
                              final isGranted = req.isGranted;
                              final doctorReqTitle = session.isHindi
                                  ? '${req.doctorName} से अनुरोध'
                                  : (session.isMarathi ? '${req.doctorName} कडून विनंती' : 'Request from ${req.doctorName}');
                              final authBadgeLabel = isGranted
                                  ? (session.isHindi ? 'सत्यापित / अधिकृत' : (session.isMarathi ? 'अधिकृत' : 'Authorized'))
                                  : (session.isHindi ? 'ओटीपी लंबित' : (session.isMarathi ? 'ओटीपी प्रलंबित' : 'Pending OTP'));
                              final facilityPrefix = session.isHindi ? 'अस्पताल: ' : (session.isMarathi ? 'रुग्णालय: ' : 'Facility: ');
                              final purposePrefix = session.isHindi ? 'उद्देश्य: ' : (session.isMarathi ? 'उद्देश: ' : 'Purpose: ');
                              final otpLabel = session.isHindi ? 'सत्यापन ओटीपी: ' : (session.isMarathi ? 'पडताळणी ओटीपी: ' : 'Your Verification OTP: ');

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                color: isGranted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          doctorReqTitle,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isGranted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            authBadgeLabel,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isGranted ? const Color(0xFF166534) : const Color(0xFF92400E)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$facilityPrefix${req.doctorFacility} • $purposePrefix${req.purpose}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    if (!isGranted) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(otpLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                          Text(
                                            req.otp,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0A6B56), letterSpacing: 1),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // SECTION 3: ACCOUNT ACTIONS
                Row(
                  children: [
                    const Icon(Icons.manage_accounts_outlined, color: Color(0xFF64748B), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      session.isHindi ? 'खाता कार्रवाई' : (session.isMarathi ? 'खाते कृती' : 'Account Actions'),
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(session.isHindi
                                  ? 'पंजीकृत नंबर पर सत्यापन ओटीपी भेजा गया'
                                  : (session.isMarathi
                                      ? 'नोंदणीकृत क्रमांकावर पडताळणी ओटीपी पाठवला'
                                      : 'Verification OTP sent to registered number')),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4F1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF0A6B56), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    session.isHindi
                                        ? 'पंजीकृत मोबाइल अपडेट करें'
                                        : (session.isMarathi ? 'नोंदणीकृत मोबाइल अद्ययावत करा' : 'Update Registered Mobile'),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const Text('→', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(session.isHindi ? 'डिवाइस से लॉग आउट करें?' : (session.isMarathi ? 'डिव्हाइसमधून लॉग आउट करायचे?' : 'Sign Out from Device?')),
                              content: Text(session.isHindi ? 'आपका ऑफलाइन डेटा सुरक्षित रहेगा।' : (session.isMarathi ? 'तुमचा ऑफलाइन डेटा सुरक्षित राहील.' : 'Your offline data will remain preserved.')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(strings.cancel),
                                ),
                                ElevatedButton(
                                  style: AppDecorations.primaryButton(),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    session.resetToOnboarding();
                                  },
                                  child: Text(strings.logOut),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.logout_rounded, color: Color(0xFF475569), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    strings.logOut,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const Icon(Icons.logout_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      InkWell(
                        onTap: () {
                          cache.syncOutbox();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(session.isHindi
                                  ? 'स्थानीय कैश सफलतापूर्वक सिंक और साफ़ किया गया'
                                  : (session.isMarathi
                                      ? 'स्थानिक कॅशे यशस्वीरित्या समक्रमित आणि साफ केला'
                                      : 'Local profile and cache synced')),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.block_flipped, color: Color(0xFFDC2626), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.isHindi
                                            ? 'अकाउंट हटाएं / बंद करें'
                                            : (session.isMarathi ? 'खाते हटवा / बंद करा' : 'Delete / Close Account'),
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        session.isHindi
                                            ? 'इस डिवाइस से स्थानीय प्रोफ़ाइल हटाता है।'
                                            : (session.isMarathi
                                                ? 'या डिव्हाइसवरून स्थानिक प्रोफाइल काढून टाकते.'
                                                : 'Removes local profile from this device.'),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Text('→', style: TextStyle(fontSize: 16, color: Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ),
                    ],
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
