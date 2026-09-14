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
import 'my_medications_screen.dart';
import 'package:ruralcare/features/auth/screens/patient_registration_screen.dart';
import 'medicine_availability_screen.dart';
import 'diagnostic_locator_screen.dart';
import 'referral_tracker_screen.dart';
import 'appointment_booking_screen.dart';
import 'longitudinal_records_screen.dart';
import 'symptom_checker_screen.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';
import 'package:ruralcare/features/teleconsult/screens/teleconsultation_landing_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import 'package:ruralcare/features/patient/screens/find_facility_screen.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';
import 'package:ruralcare/features/notifications/screens/notification_center_screen.dart';
import '../utils/patient_strings.dart';

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
        final patient = patientRepo.activePatient;
        final strings = PatientStrings.of(session);

        if (patient == null) {
          return _buildNoPatientState(context, session, strings);
        }

        final vitals = patient.latestVitals;
        final patientAppts = aptRepo.getAppointmentsForPatient(
          patient,
          sessionUid: session.currentUserId,
          displayName: session.userDisplayName,
        );
        final activeCall = aptRepo.getActiveCallForPatient(
          patient,
          sessionUid: session.currentUserId,
          displayName: session.userDisplayName,
        );
        final upcomingApt = patientAppts.where((a) => a.status != 'COMPLETED' && a.status != 'CANCELLED').isNotEmpty
            ? patientAppts.firstWhere((a) => a.status != 'COMPLETED' && a.status != 'CANCELLED')
            : null;
        final activeRef = refRepo.referrals.where((r) => r.patientId == patient.id && r.status != 'CLOSED').isNotEmpty
            ? refRepo.referrals.firstWhere((r) => r.patientId == patient.id && r.status != 'CLOSED')
            : null;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Compact Header: Greeting, Healthcare area, Language shortcut & Notifications
                _buildCompactHeader(context, patient, session, strings),

                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Teleconsultation Incoming Call Banner
                        if (activeCall != null)
                          _buildActiveCallBanner(context, activeCall, patient, session, strings),

                        // 2. Next Care Card (Single primary action per section)
                        _buildNextCareCard(context, patient, upcomingApt, session, strings),

                        const SizedBox(height: 24),

                        // 3. Quick Actions: "How can we help?"
                        Text(
                          strings.howCanWeHelp,
                          style: AppTypography.sectionTitle,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionsGrid(context, session, strings),

                        const SizedBox(height: 24),

                        // 4. Active Referral Tracker (if active and not duplicating Next Care)
                        if (activeRef != null && activeRef.status != 'CLOSED') ...[
                          _buildActiveReferralSection(context, activeRef, session, strings),
                          const SizedBox(height: 24),
                        ],

                        // 5. Your Health Snapshot: Recent vitals & consultations
                        Text(
                          strings.yourHealthSnapshot,
                          style: AppTypography.sectionTitle,
                        ),
                        const SizedBox(height: 12),
                        _buildHealthSnapshotCard(context, patient, vitals, session, strings),

                        const SizedBox(height: 24),

                        // 6. Assigned Frontline Care Network
                        _buildAssignedCareRow(context, patient.assignedAsha, session, strings),

                        const SizedBox(height: 24),

                        // 7. Visible, Restrained Emergency Help Action (DESIGN.md Section 6)
                        _buildEmergencyAction(context, session, strings),

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
  Widget _buildCompactHeader(BuildContext context, PatientDto patient, SessionCoordinator session, PatientStrings strings) {
    final greeting = strings.greeting(patient.fullName);

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
                    _langItem('EN', session, isSelected: session.isEnglish, target: 'en'),
                    const Text('·', style: TextStyle(color: RuralCareColors.textSecondary, fontSize: 12)),
                    _langItem('हिन्दी', session, isSelected: session.isHindi, target: 'hi'),
                    const Text('·', style: TextStyle(color: RuralCareColors.textSecondary, fontSize: 12)),
                    _langItem('मराठी', session, isSelected: session.isMarathi, target: 'mr'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ListenableBuilder(
                listenable: NotificationRepository(),
                builder: (context, _) {
                  final unread = NotificationRepository().getUnreadCount(AppRole.patient);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: RuralCareColors.textPrimary, size: 24),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                          );
                        },
                        tooltip: 'Notifications',
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0A6B56),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
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

  /// Prominent Live Teleconsultation Calling Banner
  Widget _buildActiveCallBanner(
    BuildContext context,
    AppointmentDto activeCall,
    PatientDto patient,
    SessionCoordinator session,
    PatientStrings strings,
  ) {
    final isHi = session.isHi;
    final isMr = session.isMr;
    final title = isHi
        ? 'डॉक्टर से लाइव वीडियो कॉल जारी है'
        : (isMr ? 'डॉक्टरांशी थेट व्हिडिओ कॉल सुरू आहे' : 'Live Doctor Teleconsultation Call');
    final subtitle = isHi
        ? '${activeCall.doctorName} (${activeCall.specialty}) वीडियो कॉल में आपकी प्रतीक्षा कर रहे हैं।'
        : (isMr
            ? '${activeCall.doctorName} (${activeCall.specialty}) व्हिडिओ कॉलमध्ये आपली वाट पाहत आहेत.'
            : '${activeCall.doctorName} (${activeCall.specialty}) is waiting in the video room.');
    final buttonText = isHi ? 'वीडियो कॉल में अभी जुड़ें' : (isMr ? 'व्हिडिओ कॉलमध्ये आत्ताच सामील व्हा' : 'Join Video Call Now');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x1215803D), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isHi ? 'लाइव परामर्श सक्रिय' : (isMr ? 'थेट सल्लामसलत सुरू' : 'LIVE CONSULTATION ACTIVE'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14532D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF166534),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => LiveTeleconsultRoomScreen(
                      patientName: patient.fullName,
                      doctorName: activeCall.doctorName,
                      specialty: activeCall.specialty,
                      appointmentId: activeCall.id,
                      facilityName: activeCall.facilityName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.videocam_rounded, size: 18),
              label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Next Care Card per DESIGN.md Section 6:
  /// The most relevant appointment or follow-up with one clear action.
  /// White fill, 1px border (#DCE4ED), radius 16, no shadow.
  Widget _buildNextCareCard(BuildContext context, PatientDto patient, AppointmentDto? upcomingApt, SessionCoordinator session, PatientStrings strings) {
    final hasApt = upcomingApt != null;
    final cardHeading = strings.nextCareHeading;

    if (!hasApt) {
      return Container(
        width: double.infinity,
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cardHeading,
              style: AppTypography.supporting.copyWith(
                fontWeight: FontWeight.w600,
                color: RuralCareColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.noUpcomingApts,
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: 4),
            Text(
              strings.noUpcomingAptsSub,
              style: AppTypography.supporting,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const AppointmentBookingScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(strings.bookAppointment, style: AppTypography.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuralCareColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isTeleconsult = upcomingApt.type == 'TELECONSULTATION';
    final isCallActive = upcomingApt.status == 'IN_PROGRESS' || upcomingApt.status == 'CALLING';

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
                  background: isCallActive ? const Color(0xFFDCFCE7) : RuralCareColors.primarySoft,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCallActive) ...[
                      const Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isCallActive
                          ? (session.isHi ? 'कॉल जारी है' : (session.isMr ? 'कॉल सुरू आहे' : 'CALL ACTIVE'))
                          : strings.confirmed,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCallActive ? const Color(0xFF15803D) : RuralCareColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            upcomingApt.doctorName,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 4),
          Text(
            '${upcomingApt.appointmentTime} • ${upcomingApt.facilityName}',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (isTeleconsult) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => LiveTeleconsultRoomScreen(
                        patientName: patient.fullName,
                        doctorName: upcomingApt.doctorName,
                        specialty: upcomingApt.specialty,
                        appointmentId: upcomingApt.id,
                        facilityName: upcomingApt.facilityName,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const AppointmentBookingScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCallActive ? const Color(0xFF16A34A) : RuralCareColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                isCallActive
                    ? (session.isHi ? 'वीडियो कॉल से अभी जुड़ें' : (session.isMr ? 'व्हिडिओ कॉलमध्ये आत्ताच सामील व्हा' : 'Join Video Call Now'))
                    : (isTeleconsult ? strings.joinTeleconsult : strings.viewArrivalPass),
                style: AppTypography.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Actions: Prominent Symptom Checker + 2-column arrangement + full-width Diagnostics row (DESIGN.md Section 6)
  Widget _buildQuickActionsGrid(BuildContext context, SessionCoordinator session, PatientStrings strings) {
    return Column(
      children: [
        // 1. Prominent Hero Symptom Checker Quick Action
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const SymptomCheckerScreen(isModal: true)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  RuralCareColors.primary.withOpacity(0.08),
                  RuralCareColors.teal.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RuralCareColors.primary.withOpacity(0.3), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: RuralCareColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.symptomChecker,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: RuralCareColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.symptomCheckerSub,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: RuralCareColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: RuralCareColors.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionTile(
                icon: Icons.medication_outlined,
                title: strings.myMedications,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const MyMedicationsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionTile(
                icon: Icons.video_call_outlined,
                title: strings.teleconsultation,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const TeleconsultationLandingScreen(),
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
                title: strings.findFacility,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const FindFacilityScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionTile(
                icon: Icons.local_pharmacy_outlined,
                title: strings.medicines,
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
          title: strings.diagnostics,
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
  Widget _buildActiveReferralSection(BuildContext context, ReferralDto referral, SessionCoordinator session, PatientStrings strings) {
    final refTitle = strings.activeReferral;
    final viewBtn = strings.viewReferral;
    final statusText = strings.localizeReferralStatus(referral.status);

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
                  statusText,
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
  Widget _buildHealthSnapshotCard(BuildContext context, PatientDto patient, VitalsDto? vitals, SessionCoordinator session, PatientStrings strings) {
    final aptRepo = AppointmentRepository();
    final completedApts = aptRepo.appointments.where((a) => a.patientId == patient.id && a.status == 'COMPLETED').toList();
    final prescriptions = aptRepo.getPrescriptionsForPatient(patient.id);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.recentConsultation,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          completedApts.isNotEmpty
                              ? '${completedApts.first.appointmentTime} • ${completedApts.first.doctorName}'
                              : (session.isHindi ? 'कोई हालिया परामर्श नहीं' : (session.isMarathi ? 'कोणतीही अलिकडील भेट नाही' : 'No recent consultations recorded')),
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    strings.view,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.latestHealthReadings,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vitals != null
                            ? 'BP ${vitals.systolicBp}/${vitals.diastolicBp} mmHg • SpO2 ${vitals.spO2}%'
                            : (session.isHindi ? 'कोई वाइटल्स दर्ज नहीं' : (session.isMarathi ? 'कोणतीही नोंद उपलब्ध नाही' : 'No vitals recorded yet')),
                        style: AppTypography.supporting,
                      ),
                    ],
                  ),
                ),
                if (vitals != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: AppDecorations.statusBadge(
                      background: vitals.hasWarning ? RuralCareColors.warningSoft : RuralCareColors.successSoft,
                    ),
                    child: Text(
                      vitals.hasWarning ? strings.reviewNeeded : strings.normal,
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

          // Row 3: Latest prescription
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const MyMedicationsScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.latestPrescription,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prescriptions.isNotEmpty && prescriptions.first.medicines.isNotEmpty
                              ? '${prescriptions.first.medicines.first.medicineName} (${prescriptions.first.medicines.first.frequency})'
                              : strings.noActiveMedications,
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    strings.view,
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

  Widget _buildNoPatientState(BuildContext context, SessionCoordinator session, PatientStrings strings) {
    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        title: Text(strings.appTitle, style: AppTypography.pageTitle),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RuralCareColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _langItem('EN', session, isSelected: session.isEnglish, target: 'en'),
                const Text(' • ', style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                _langItem('हिं', session, isSelected: session.isHindi, target: 'hi'),
                const Text(' • ', style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                _langItem('म', session, isSelected: session.isMarathi, target: 'mr'),
              ],
            ),
          ),
        ],
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
                child: const Icon(Icons.person_add_alt_1_outlined, color: RuralCareColors.primary, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                session.isHindi
                    ? 'कोई मरीज प्रोफ़ाइल पंजीकृत नहीं है'
                    : (session.isMarathi ? 'कोणतीही रुग्ण प्रोफाइल नोंदणीकृत नाही' : 'No Patient Profile Registered'),
                style: AppTypography.pageTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                session.isHindi
                    ? 'अपॉइंटमेंट बुक करने, नुस्खे देखने और स्वास्थ्य रिकॉर्ड प्रबंधित करने के लिए अपनी प्रोफाइल बनाएं।'
                    : (session.isMarathi
                        ? 'भेटी बुक करण्यासाठी, औषधे पाहण्यासाठी आणि आरोग्य नोंदी व्यवस्थापित करण्यासाठी नोंदणी करा.'
                        : 'Register your patient profile with ABHA Health ID to book appointments, view prescriptions, and manage care.'),
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
                      MaterialPageRoute(
                        builder: (_) => const PatientRegistrationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    session.isHindi
                        ? '+ मरीज प्रोफ़ाइल बनाएं'
                        : (session.isMarathi ? '+ रुग्ण प्रोफाइल नोंदणी करा' : '+ Register Patient Profile'),
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

  /// Assigned ASHA Community Health Worker row
  Widget _buildAssignedCareRow(BuildContext context, String ashaName, SessionCoordinator session, PatientStrings strings) {
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
                  strings.assignedAsha,
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
              final callMsg = session.isHindi
                  ? 'आशा कार्यकर्ता $ashaName (+91 98220 19284) से संपर्क किया जा रहा है...'
                  : (session.isMarathi
                      ? 'आशा सेविका $ashaName (+91 98220 19284) यांच्याशी संपर्क साधत आहे...'
                      : 'Contacting ASHA worker $ashaName (+91 98220 19284)...');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(callMsg)),
              );
            },
            icon: const Icon(Icons.phone_outlined, size: 16),
            label: Text(strings.callAsha, style: const TextStyle(fontSize: 13)),
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
  Widget _buildEmergencyAction(BuildContext context, SessionCoordinator session, PatientStrings strings) {
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
                    strings.emergencyHelp,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: RuralCareColors.critical,
                    ),
                  ),
                  Text(
                    strings.emergencySub,
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
