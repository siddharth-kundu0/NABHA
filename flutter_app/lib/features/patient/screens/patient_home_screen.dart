import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'medicine_availability_screen.dart';
import 'diagnostic_locator_screen.dart';
import 'referral_tracker_screen.dart';
import 'appointment_booking_screen.dart';
import 'longitudinal_records_screen.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import 'package:ruralcare/features/facility/screens/facility_operations_screen.dart';

/// Patient Home Screen conforming strictly to DESIGN.md Section 6:
/// A quiet care companion with generous breathing room, white surface cards (radius 16, border #DCE4ED, no shadows),
/// clear Noto Sans typography, single primary actions per section, and restrained emergency action.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final aptRepo = AppointmentRepository();
    final refRepo = ReferralRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, aptRepo, refRepo, cache, session]),
      builder: (context, _) {
        final patient = patientRepo.defaultPatient;
        final vitals = patient.latestVitals;
        final upcomingApt = aptRepo.appointments.isNotEmpty ? aptRepo.appointments.first : null;
        final activeRef = refRepo.referrals.isNotEmpty ? refRepo.referrals.first : null;
        final lang = session.activeLanguage;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Compact Header: Greeting, Healthcare area, Language shortcut & Notifications
                _buildCompactHeader(context, patient, session),

                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Next Care Card (Single primary action per section)
                        _buildNextCareCard(context, patient, upcomingApt, lang),

                        const SizedBox(height: 24),

                        // 3. Quick Actions: "How can we help?"
                        Text(
                          lang == 'Hindi' ? 'हम आपकी कैसे मदद कर सकते हैं?' : (lang == 'Marathi' ? 'आम्ही कशी मदत करू शकतो?' : 'How can we help?'),
                          style: AppTypography.sectionTitle,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionsGrid(context, lang),

                        const SizedBox(height: 24),

                        // 4. Active Referral Tracker (if active and not duplicating Next Care)
                        if (activeRef != null && activeRef.status != 'CLOSED') ...[
                          _buildActiveReferralSection(context, activeRef, lang),
                          const SizedBox(height: 24),
                        ],

                        // 5. Your Health Snapshot: Recent vitals & consultations
                        Text(
                          lang == 'Hindi' ? 'आपकी स्वास्थ्य स्थिति' : (lang == 'Marathi' ? 'तुमचे आरोग्य' : 'Your health'),
                          style: AppTypography.sectionTitle,
                        ),
                        const SizedBox(height: 12),
                        _buildHealthSnapshotCard(context, patient, vitals, lang),

                        const SizedBox(height: 24),

                        // 6. Assigned Frontline Care Network
                        _buildAssignedCareRow(context, patient.assignedAsha, lang),

                        const SizedBox(height: 24),

                        // 7. Visible, Restrained Emergency Help Action (DESIGN.md Section 6)
                        _buildEmergencyAction(context, lang),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Compact header per DESIGN.md Section 4 & 6:
  /// Greeting, healthcare area, notification access, and discreet language selector.
  Widget _buildCompactHeader(BuildContext context, PatientDto patient, SessionCoordinator session) {
    final lang = session.activeLanguage;
    String greeting;
    if (lang == 'Hindi') {
      greeting = 'नमस्ते, ${patient.fullName}';
    } else if (lang == 'Marathi') {
      greeting = 'नमस्कार, ${patient.fullName}';
    } else {
      greeting = 'Good morning, ${patient.fullName}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: RuralCareColors.surface,
        border: Border(
          bottom: BorderSide(color: RuralCareColors.border, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Greeting & Healthcare Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: AppTypography.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: RuralCareColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${patient.village} • ${patient.subCentre}',
                        style: AppTypography.supporting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Discreet Language Selector & Notification Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RuralCareColors.border, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _langItem('EN', session, isSelected: lang == 'English', target: 'English'),
                    const Text('·', style: TextStyle(color: RuralCareColors.textSecondary, fontSize: 12)),
                    _langItem('हिन्दी', session, isSelected: lang == 'Hindi', target: 'Hindi'),
                    const Text('·', style: TextStyle(color: RuralCareColors.textSecondary, fontSize: 12)),
                    _langItem('मराठी', session, isSelected: lang == 'Marathi', target: 'Marathi'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: RuralCareColors.textPrimary, size: 24),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'Hindi'
                            ? 'सभी रिकॉर्ड सुरक्षित और सिंक हैं।'
                            : (lang == 'Marathi'
                                ? 'सर्व नोंदी सुरक्षित आणि सिंक आहेत.'
                                : 'All records are saved and synced.'),
                      ),
                    ),
                  );
                },
                tooltip: 'Notifications',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langItem(String label, SessionCoordinator session, {required bool isSelected, required String target}) {
    return GestureDetector(
      onTap: () => session.switchLanguage(target),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: isSelected
            ? BoxDecoration(
                color: RuralCareColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RuralCareColors.border, width: 1.0),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? RuralCareColors.primary : RuralCareColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Next Care Card per DESIGN.md Section 6:
  /// The most relevant appointment or follow-up with one clear action.
  /// White fill, 1px border (#DCE4ED), radius 16, no shadow.
  Widget _buildNextCareCard(BuildContext context, PatientDto patient, AppointmentDto? upcomingApt, String lang) {
    final hasApt = upcomingApt != null;

    final cardHeading = lang == 'Hindi'
        ? 'आपकी अगली अपॉइंटमेंट'
        : (lang == 'Marathi' ? 'तुमची पुढची अपॉइंटमेंट' : 'Your next appointment');

    final clinicianText = hasApt
        ? upcomingApt.doctorName
        : (lang == 'Hindi' ? 'डॉ. अंजलि देशमुख (स्त्री रोग विशेषज्ञ)' : (lang == 'Marathi' ? 'डॉ. अंजली देशमुख (स्त्रीरोग तज्ज्ञ)' : 'Dr. Anjali Deshmukh (OB/GYN)'));

    final detailsText = hasApt
        ? '${upcomingApt.appointmentTime} • ${upcomingApt.facilityName}'
        : (lang == 'Hindi' ? '14 सितंबर • 10:30 AM • बारामती उप-जिला अस्पताल' : (lang == 'Marathi' ? '१४ सप्टेंबर • १०:३० AM • बारामती उपजिल्हा रुग्णालय' : '14 Sep • 10:30 AM • Baramati Sub-District Hospital'));

    final actionLabel = lang == 'Hindi'
        ? 'अपॉइंटमेंट विवरण देखें'
        : (lang == 'Marathi' ? 'तपशील पहा' : 'View appointment');

    return Container(
      width: double.infinity,
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cardHeading,
                style: AppTypography.supporting.copyWith(
                  fontWeight: FontWeight.w600,
                  color: RuralCareColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(
                  background: RuralCareColors.primarySoft,
                ),
                child: Text(
                  lang == 'Hindi' ? 'पुष्टि' : (lang == 'Marathi' ? 'पुष्टी' : 'Confirmed'),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: RuralCareColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            clinicianText,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 4),
          Text(
            detailsText,
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => LiveTeleconsultRoomScreen(
                      patientName: patient.fullName,
                      doctorName: clinicianText,
                      specialty: hasApt ? upcomingApt.specialty : 'Obstetrics & Gynaecology',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(actionLabel, style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Actions: 2-column arrangement + full-width Diagnostics row (DESIGN.md Section 6)
  Widget _buildQuickActionsGrid(BuildContext context, String lang) {
    final isHi = lang == 'Hindi';
    final isMr = lang == 'Marathi';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickActionTile(
                icon: Icons.calendar_today_outlined,
                title: isHi ? 'अपॉइंटमेंट बुक करें' : (isMr ? 'अपॉइंटमेंट बुक करा' : 'Book appointment'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const AppointmentBookingScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionTile(
                icon: Icons.video_call_outlined,
                title: isHi ? 'टेलीकंसल्टेशन' : (isMr ? 'टेलीसल्ला' : 'Teleconsultation'),
                onTap: () {
                  final patient = PatientRepository().defaultPatient;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => LiveTeleconsultRoomScreen(
                        patientName: patient.fullName,
                        doctorName: 'Dr. Anjali Deshmukh',
                        specialty: 'Obstetrics & Gynaecology',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionTile(
                icon: Icons.local_hospital_outlined,
                title: isHi ? 'अस्पताल खोजें' : (isMr ? 'रुग्णालय शोधा' : 'Find facility'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const FacilityOperationsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionTile(
                icon: Icons.medication_outlined,
                title: isHi ? 'दवाइयां' : (isMr ? 'औषधे' : 'Medicines'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const MedicineAvailabilityScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Full width row for Diagnostics
        _quickActionTile(
          icon: Icons.biotech_outlined,
          title: isHi ? 'निदान जांच' : (isMr ? 'निदान चाचण्या' : 'Diagnostics & lab tests'),
          fullWidth: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const DiagnosticLocatorScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: fullWidth ? 56 : 72,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppDecorations.card(),
        child: Row(
          children: [
            Icon(icon, color: RuralCareColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: RuralCareColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  /// Active Referral Tracker Section (Quiet, purposeful)
  Widget _buildActiveReferralSection(BuildContext context, ReferralDto referral, String lang) {
    final refTitle = lang == 'Hindi' ? 'सक्रिय रेफरल' : (lang == 'Marathi' ? 'सक्रिय संदर्भ' : 'Active referral');
    final viewBtn = lang == 'Hindi' ? 'देखें' : (lang == 'Marathi' ? 'पहा' : 'View referral');

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
                refTitle,
                style: AppTypography.cardTitle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.warningSoft),
                child: Text(
                  referral.statusDisplay,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: RuralCareColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            referral.targetFacilityName,
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ReferralTrackerScreen()),
                );
              },
              child: Text(viewBtn, style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }

  /// Health Snapshot Card per DESIGN.md Section 6:
  /// Recent consultation and latest prescription/report as quiet rows.
  Widget _buildHealthSnapshotCard(BuildContext context, PatientDto patient, VitalsDto? vitals, String lang) {
    final isHi = lang == 'Hindi';
    final isMr = lang == 'Marathi';

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Row 1: Recent consultation
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const LongitudinalRecordsScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? 'हालिया परामर्श' : (isMr ? 'नुकतीच झालेली सल्लामसलत' : 'Recent consultation'),
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '12 Aug • Dr. Deshmukh • Baramati SDH',
                        style: AppTypography.supporting,
                      ),
                    ],
                  ),
                  Text(
                    isHi ? 'देखें' : (isMr ? 'पहा' : 'View'),
                    style: AppTypography.supporting.copyWith(
                      color: RuralCareColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: RuralCareColors.border, height: 20),

          // Row 2: Latest vitals
          if (vitals != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? 'नवीनतम स्वास्थ्य रीडिंग' : (isMr ? 'नवीनतम नोंदी' : 'Latest health readings'),
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'BP ${vitals.systolicBp}/${vitals.diastolicBp} mmHg • SpO2 ${vitals.spO2}%',
                        style: AppTypography.supporting,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: AppDecorations.statusBadge(
                      background: vitals.hasWarning ? RuralCareColors.warningSoft : RuralCareColors.successSoft,
                    ),
                    child: Text(
                      vitals.hasWarning
                          ? (isHi ? 'जांच आवश्यक' : (isMr ? 'तपासणी आवश्यक' : 'Review needed'))
                          : (isHi ? 'सामान्य' : (isMr ? 'सामान्य' : 'Normal')),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: vitals.hasWarning ? RuralCareColors.warning : RuralCareColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: RuralCareColors.border, height: 20),
          ],

          // Row 3: Latest prescription
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const LongitudinalRecordsScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? 'नवीनतम नुस्खा' : (isMr ? 'नवीनतम औषधोपचार' : 'Latest prescription'),
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Iron & Folic Acid, Labetalol 100mg',
                        style: AppTypography.supporting,
                      ),
                    ],
                  ),
                  Text(
                    isHi ? 'देखें' : (isMr ? 'पहा' : 'View'),
                    style: AppTypography.supporting.copyWith(
                      color: RuralCareColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Assigned ASHA Community Health Worker row
  Widget _buildAssignedCareRow(BuildContext context, String ashaName, String lang) {
    final isHi = lang == 'Hindi';
    final isMr = lang == 'Marathi';

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: RuralCareColors.tealSoft,
            radius: 20,
            child: Icon(Icons.person_outline, color: RuralCareColors.teal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHi ? 'नियुक्त आशा कार्यकर्ता' : (isMr ? 'नियुक्त आशा सेविका' : 'Assigned health worker'),
                  style: AppTypography.supporting,
                ),
                Text(
                  ashaName,
                  style: AppTypography.cardTitle,
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Contacting ASHA worker $ashaName (+91 98220 19284)...')),
              );
            },
            icon: const Icon(Icons.phone_outlined, size: 16),
            label: Text(isHi ? 'संपर्क' : (isMr ? 'संपर्क' : 'Call'), style: const TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Restrained Emergency Help Action per DESIGN.md Section 6:
  /// "Visible, restrained Emergency help action with red icon/text—not a large permanent alarming banner."
  Widget _buildEmergencyAction(BuildContext context, String lang) {
    final isHi = lang == 'Hindi';
    final isMr = lang == 'Marathi';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: RuralCareColors.criticalSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RuralCareColors.critical.withOpacity(0.3), width: 1.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.emergency_outlined, color: RuralCareColors.critical, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHi ? 'आपातकालीन सहायता (108)' : (isMr ? 'तातडीची मदत (108)' : 'Emergency help (108)'),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: RuralCareColors.critical,
                    ),
                  ),
                  Text(
                    isHi ? 'आपात स्थिति में एम्बुलेंस व अस्पताल सहायता' : (isMr ? 'रुग्णवाहिका व वैद्यकीय मदत' : 'Ambulance and facility emergency support'),
                    style: AppTypography.supporting.copyWith(
                      color: RuralCareColors.critical,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: RuralCareColors.critical, size: 14),
          ],
        ),
      ),
    );
  }
}
