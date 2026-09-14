import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import 'package:ruralcare/features/patient/screens/personal_details_screen.dart';
import 'package:ruralcare/features/patient/screens/language_accessibility_screen.dart';
import 'package:ruralcare/features/patient/screens/privacy_security_screen.dart';
import 'package:ruralcare/features/patient/screens/emergency_contacts_screen.dart';
import 'package:ruralcare/features/patient/screens/account_security_screen.dart';
import 'package:ruralcare/features/auth/screens/patient_registration_screen.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/core/services/patient_history_pdf_service.dart';

/// Screen 1: Profile Overview (V2 Modern)
/// Exactly reproducing Stitch Screen `ce2a8f8bb13f4dbfbf2f9c397e5ab57a`
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, cache, session]),
      builder: (context, _) {
        final patient = patientRepo.activePatient;
        if (patient == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text('RuralCare', style: TextStyle(color: Color(0xFF104A7B), fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: RuralCareColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline, color: RuralCareColors.primary, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      session.isHindi ? 'कोई मरीज प्रोफ़ाइल नहीं मिली' : (session.isMarathi ? 'कोणतीही रुग्ण प्रोफाइल आढळली नाही' : 'No Patient Profile Found'),
                      style: AppTypography.pageTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.isHindi
                          ? 'अपनी ABHA हेल्थ आईडी से प्रोफ़ाइल पंजीकृत करें।'
                          : (session.isMarathi ? 'आपल्या आभा हेल्थ आयडीसह नोंदणी करा.' : 'Register a patient profile with ABHA Health ID to access records.'),
                      style: AppTypography.supporting,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PatientRegistrationScreen()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          session.isHindi ? '+ मरीज प्रोफ़ाइल बनाएं' : (session.isMarathi ? '+ नोंदणी करा' : '+ Register Patient Profile'),
                          style: AppTypography.button,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RuralCareColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final initials = _getInitials(patient.fullName);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo + Wordmark
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
                    // Controls: Language Pill + Emergency Help + Profile Avatar
                    Row(
                      children: [
                        // Language Selector Pill with interactive buttons
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
                        // Emergency Help Button (Solid Red)
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
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
                                  session.isHindi
                                      ? 'आपातकालीन सहायता'
                                      : (session.isMarathi ? 'तातडीची मदत' : 'Emergency Help'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Profile Avatar Pill
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF0F2942),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.isHindi
                                ? 'मरीज़ प्रोफ़ाइल'
                                : (session.isMarathi ? 'रुग्ण प्रोफाइल' : 'Patient Profile'),
                            style: const TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session.isHindi
                                ? 'व्यक्तिगत विवरण, पहुंच और प्राथमिकताएं प्रबंधित करें'
                                : (session.isMarathi
                                    ? 'वैयक्तिक तपशील, प्रवेश आणि प्राधान्ये व्यवस्थापित करा'
                                    : 'Manage personal details, access & preferences'),
                            style: const TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // PATIENT HERO CARD
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with verified badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF104A7B),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check, size: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.fullName,
                              style: const TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Text(
                                'ID: ${patient.ruralCareId}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${patient.village}, ${patient.district} • Kashti PHC',
                                    style: const TextStyle(
                                      fontFamily: 'Noto Sans',
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => PersonalDetailsScreen(patient: patient)),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF104A7B)),
                              const SizedBox(width: 4),
                              Text(
                                session.isHindi ? 'संपादित करें' : (session.isMarathi ? 'संपादित करा' : 'Edit'),
                                style: const TextStyle(
                                  fontFamily: 'Noto Sans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF104A7B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ABDM Digital Health ID & QR Access Pass
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF005140).withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF005140).withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF005140), size: 36),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  session.isHindi ? 'डिजिटल स्वास्थ्य कार्ड (ABDM)' : (session.isMarathi ? 'डिजिटल आरोग्य कार्ड (ABDM)' : 'ABDM Digital Health Pass'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF005140)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF005140),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('QR READY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${patient.abhaId.isNotEmpty ? patient.abhaId : 'ABHA-9824-1102-8491'} • Scan for Fast-Track Token',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF33647B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Single Link or Button for All Patient History Downloaded in PDF
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2457C5).withOpacity(0.3)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2457C5), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.isHindi
                                  ? 'संपूर्ण स्वास्थ्य इतिहास (ABDM PDF)'
                                  : (session.isMarathi ? 'संपूर्ण आरोग्य इतिहास (ABDM PDF)' : 'Download Complete Health History (PDF)'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF172B4D)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.isHindi
                                  ? 'ABDM प्रमाणित नुस्खे, वाइटल्स एवं जांच सारांश'
                                  : (session.isMarathi ? 'ABDM प्रमाणित औषधे, मापदंड व तपासणी अहवाल' : 'ABDM-certified prescriptions, vitals telemetry & lab summary'),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF52637A)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2457C5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => PatientHistoryPdfService().exportOrPrintPatientHistory(context, patient),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: Text(session.isHindi ? 'डाउनलोड' : (session.isMarathi ? 'डाउनलोड' : 'PDF'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Suggested / Prescribed Medicines from Doctor
                Builder(
                  builder: (context) {
                    final rxList = AppointmentRepository().getPrescriptionsForPatient(patient.id);
                    if (rxList.isEmpty) return const SizedBox.shrink();

                    final latestRx = rxList.first;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF147D78).withOpacity(0.3)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.medication_outlined, size: 18, color: Color(0xFF147D78)),
                                  const SizedBox(width: 6),
                                  Text(
                                    session.isHindi ? 'सुझाई गई दवाएं (डॉक्टर नुस्खा)' : (session.isMarathi ? 'सुचवलेली औषधे (डॉक्टर प्रिस्क्रिप्शन)' : 'Suggested Medicines (Doctor Rx)'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF172B4D)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF7F4),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  latestRx.doctorName,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF147D78)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Diagnosis: ${latestRx.diagnosis}', style: const TextStyle(fontSize: 11, color: Color(0xFF52637A))),
                          const SizedBox(height: 8),
                          ...latestRx.medicines.map((m) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFDCE4ED)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.medicineName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF172B4D))),
                                        Text('${m.dosage} • ${m.frequency}', style: const TextStyle(fontSize: 10, color: Color(0xFF52637A))),
                                      ],
                                    ),
                                    Text('${m.durationDays} Days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF147D78))),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // SETTINGS & PREFERENCES SECTION TITLE
                Padding(
                  padding: const EdgeInsets.only(left: 2.0, bottom: 8.0),
                  child: Text(
                    session.isHindi
                        ? 'सेटिंग्स और प्राथमिकताएं'
                        : (session.isMarathi ? 'सेटिंग्ज आणि प्राधान्ये' : 'SETTINGS & PREFERENCES'),
                    style: const TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),

                // Card 1: Personal Details
                _buildFloatingCard(
                  icon: Icons.badge_outlined,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0369A1),
                  title: session.isHindi ? 'व्यक्तिगत विवरण' : (session.isMarathi ? 'वैयक्तिक तपशील' : 'Personal Details'),
                  subtitle: session.isHindi
                      ? 'नाम, फोन, आयु, लिंग एवं गांव'
                      : (session.isMarathi ? 'नाव, फोन, वय, लिंग आणि गाव' : 'Name, phone, age, gender & village'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => PersonalDetailsScreen(patient: patient)),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Card 2: Language & Accessibility
                _buildFloatingCard(
                  icon: Icons.translate_rounded,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4338CA),
                  title: session.isHindi ? 'भाषा और पहुंच' : (session.isMarathi ? 'भाषा आणि सुलभता' : 'Language & Accessibility'),
                  subtitle: session.isHindi
                      ? 'English, हिन्दी, मराठी • टेक्स्ट आकार'
                      : (session.isMarathi ? 'English, हिन्दी, मराठी • मजकूर आकार' : 'English, हिन्दी, मराठी • Text size & contrast'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const LanguageAccessibilityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Card 3: Emergency Contacts
                _buildFloatingCard(
                  icon: Icons.emergency_share_outlined,
                  iconBg: const Color(0xFFFFE4E6),
                  iconColor: const Color(0xFFE11D48),
                  title: session.isHindi ? 'आपातकालीन संपर्क' : (session.isMarathi ? 'तातडीचे संपर्क' : 'Emergency Contacts'),
                  subtitle: session.isHindi
                      ? '1 संपर्क कॉन्फ़िगर किया गया'
                      : (session.isMarathi ? '१ संपर्क कॉन्फिगर केला' : '1 contact configured'),
                  statusBadge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.isHindi ? 'सक्रिय' : (session.isMarathi ? 'सक्रिय' : 'Active'),
                      style: const TextStyle(
                        fontFamily: 'Noto Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => EmergencyContactsScreen(patient: patient)),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Card 4: Privacy & Data Sharing
                _buildFloatingCard(
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFB45309),
                  title: session.isHindi ? 'गोपनीयता और डेटा साझाकरण' : (session.isMarathi ? 'गोपनीयता आणि डेटा सामायिकरण' : 'Privacy & Data Sharing'),
                  subtitle: session.isHindi
                      ? 'क्लिनिक के साथ देखभाल रिकॉर्ड साझाकरण प्रबंधित करें'
                      : (session.isMarathi ? 'क्लिनिकसह आरोग्य नोंदी शेअरिंग व्यवस्थापित करा' : 'Manage care record sharing with clinic'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => PrivacySecurityScreen(patient: patient)),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Card 5: Account & Security
                _buildFloatingCard(
                  icon: Icons.lock_reset_rounded,
                  iconBg: const Color(0xFFF1F5F9),
                  iconColor: const Color(0xFF475569),
                  title: session.isHindi ? 'खाता और सुरक्षा' : (session.isMarathi ? 'खाते आणि सुरक्षा' : 'Account & Security'),
                  subtitle: session.isHindi
                      ? 'फोन नंबर, सत्र और प्राथमिकताएं'
                      : (session.isMarathi ? 'फोन नंबर, सत्र आणि प्राधान्ये' : 'Phone number, session & preferences'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => AccountSecurityScreen(patient: patient)),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Persistence Verification Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        session.isHindi
                            ? 'डेटा इस डिवाइस पर सुरक्षित है'
                            : (session.isMarathi ? 'डेटा या डिव्हाइसवर सुरक्षित जतन आहे' : 'Data saved on this device'),
                        style: const TextStyle(
                          fontFamily: 'Noto Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Sign Out Button (Soft Red)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEE2E2),
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            session.isHindi
                                ? 'डिवाइस से साइन आउट करें?'
                                : (session.isMarathi ? 'डिव्हाइसवरून साइन आउट करायचे?' : 'Sign Out from Device?'),
                          ),
                          content: Text(
                            session.isHindi
                                ? 'सभी रिकॉर्ड सुरक्षित रूप से ऑफ़लाइन कैश में सहेजे गए हैं।'
                                : (session.isMarathi
                                    ? 'सर्व नोंदी ऑफलाइन कॅशेमध्ये सुरक्षित जतन केल्या आहेत.'
                                    : 'All queued records remain safely saved in offline cache.'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(session.isHindi ? 'रद्द करें' : (session.isMarathi ? 'रद्द करा' : 'Cancel')),
                            ),
                            ElevatedButton(
                              style: AppDecorations.primaryButton(),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                session.resetToOnboarding();
                              },
                              child: Text(session.isHindi ? 'साइन आउट' : (session.isMarathi ? 'साइन आउट' : 'Sign Out')),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          session.isHindi
                              ? 'डिवाइस से साइन आउट करें'
                              : (session.isMarathi ? 'डिव्हाइसवरून साइन आउट करा' : 'Sign Out from Device'),
                          style: const TextStyle(
                            fontFamily: 'Noto Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Role Switcher for Testing Demo
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(
                      'Testing Mode: Switch Role (${session.activeRole.name})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => DemoRoleSwitcher.show(context),
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

  Widget _buildFloatingCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? statusBadge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (statusBadge != null) ...[
                        const SizedBox(width: 8),
                        statusBadge,
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'RS';
  }
}
