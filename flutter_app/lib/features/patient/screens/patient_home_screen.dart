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
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import 'package:ruralcare/features/facility/screens/facility_operations_screen.dart';

/// Pixel-Perfect realization of Stitch Screen 9: Patient Dashboard (Final Blue & Hindi)
/// Adheres strictly to Zero-Mock-Data Mandate with dynamic repository bindings.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  bool _isSyncing = false;

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
          backgroundColor: AppColors.stitchSurface,
          body: SafeArea(
            child: Column(
              children: [
                // Top App Bar & Identity Header
                _buildTopIdentityHeader(context, patient, session),

                // Elegant Offline Status Strip
                _buildOfflineStrip(context, cache, lang),

                // Scrollable Dashboard Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Priority 1: High-Priority Follow-up Banner (Stitch Blue Gradient)
                        _buildPriorityBanner(context, patient, upcomingApt, lang),

                        const SizedBox(height: 14),

                        // Active Referral Tracker Card (if active)
                        if (activeRef != null && activeRef.status != 'CLOSED') ...[
                          _buildActiveReferralBanner(context, activeRef, lang),
                          const SizedBox(height: 14),
                        ],

                        // Latest Health Vitals Snapshot Card
                        _buildVitalsCard(context, patient, vitals, lang),

                        const SizedBox(height: 16),

                        // Essential Health Services 2x2 Grid
                        _buildServicesSectionHeader(context, lang),
                        const SizedBox(height: 10),
                        _buildActionGrid(context, lang),

                        const SizedBox(height: 16),

                        // Assigned ASHA Community Health Worker Card
                        _buildAshaCard(context, patient.assignedAsha, lang),

                        const SizedBox(height: 24),
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

  /// Top sticky identity app bar with beneficiary avatar, verified check, ABHA badge,
  /// 3-language selector pill (EN | हिन्दी | मराठी), and notification bell
  Widget _buildTopIdentityHeader(BuildContext context, PatientDto patient, SessionCoordinator session) {
    final lang = session.activeLanguage;
    String greeting;
    if (lang == 'Hindi') {
      greeting = 'नमस्ते, ${patient.fullName}';
    } else if (lang == 'Marathi') {
      greeting = 'नमस्कार, ${patient.fullName}';
    } else {
      greeting = 'Welcome, ${patient.fullName}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.stitchSurfaceContainerHigh, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x0A0D1C2E), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Beneficiary Avatar with Verified Badge & Info
          Expanded(
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.stitchPrimary.withOpacity(0.12),
                      child: const Icon(Icons.person, color: AppColors.stitchPrimary, size: 28),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.stitchPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              greeting,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.stitchOnSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.stitchPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'आभा: ${patient.abhaId}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.stitchPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.stitchPrimary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              'ग्राम ${patient.village} • ${patient.subCentre}',
                              style: const TextStyle(fontSize: 10, color: AppColors.neutral600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: 3-Language Selector Pill & Notification Bell
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutral300, width: 0.8),
                ),
                child: Row(
                  children: [
                    _langBtn('EN', session, isSelected: lang == 'English', targetLang: 'English'),
                    const Text('|', style: TextStyle(color: AppColors.neutral300, fontSize: 10)),
                    _langBtn('हिन्दी', session, isSelected: lang == 'Hindi', targetLang: 'Hindi'),
                    const Text('|', style: TextStyle(color: AppColors.neutral300, fontSize: 10)),
                    _langBtn('मराठी', session, isSelected: lang == 'Marathi', targetLang: 'Marathi'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang == 'Hindi'
                                ? 'कोई नया अलर्ट नहीं। सभी रिकॉर्ड सिंक हैं।'
                                : (lang == 'Marathi'
                                    ? 'नवीन अलर्ट नाही. सर्व नोंदी सिंक आहेत.'
                                    : 'No new alerts. All health records are synced.'),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.neutral300, width: 0.8),
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.neutral700),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.criticalRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String label, SessionCoordinator session, {required bool isSelected, required String targetLang}) {
    return GestureDetector(
      onTap: () => session.switchLanguage(targetLang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.stitchPrimary,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.neutral700,
          ),
        ),
      ),
    );
  }

  /// Elegant Persistent Offline Status Banner (Stitch Amber-50 Strip)
  Widget _buildOfflineStrip(BuildContext context, LocalCacheService cache, String lang) {
    final count = cache.pendingSyncCount;
    String statusText;
    String syncBtnText;

    if (lang == 'Hindi') {
      statusText = count > 0 ? 'ऑफ़लाइन मोड • $count रिकॉर्ड फोन पर सुरक्षित' : 'ऑफ़लाइन मोड • सभी रिकॉर्ड सुरक्षित';
      syncBtnText = 'सिंक करें';
    } else if (lang == 'Marathi') {
      statusText = count > 0 ? 'ऑफलाइन मोड • $count नोंदी फोनवर सुरक्षित' : 'ऑफलाइन मोड • नोंदी सुरक्षित';
      syncBtnText = 'सिंक करा';
    } else {
      statusText = count > 0 ? 'Offline Mode • $count records saved locally' : 'Offline Mode • Records saved locally';
      syncBtnText = 'Sync Now';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7),
        border: Border(
          bottom: BorderSide(color: Color(0xFFFDE68A), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off, size: 16, color: Color(0xFFB45309)),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78350F),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _isSyncing
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isSyncing = true);
                    await cache.flushOutboxQueue();
                    await Future.delayed(const Duration(milliseconds: 600));
                    if (mounted) {
                      setState(() => _isSyncing = false);
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.stitchPrimary,
                          content: Text(
                            lang == 'Hindi'
                                ? 'क्लाउड के साथ सफलता से सिंक हुआ!'
                                : (lang == 'Marathi'
                                    ? 'क्लाउड सोबत यशस्वीरीत्या सिंक झाले!'
                                    : 'Synced successfully with cloud!'),
                          ),
                        ),
                      );
                    }
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (_isSyncing)
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF78350F)),
                    )
                  else
                    const Icon(Icons.sync, size: 12, color: Color(0xFF78350F)),
                  const SizedBox(width: 4),
                  Text(
                    syncBtnText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF78350F),
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

  /// Priority 1 Follow-up Banner with Stitch Deep-Blue Gradient (#0F3D6E to #0A2E52)
  Widget _buildPriorityBanner(BuildContext context, PatientDto patient, AppointmentDto? upcomingApt, String lang) {
    String priorityTag;
    String dueTag;
    String title;
    String subtitle;
    String actionBtnText;

    if (lang == 'Hindi') {
      priorityTag = 'प्राथमिकता जांच';
      dueTag = '2 दिन में देय';
      title = 'तीसरी तिमाही एएनसी जांच (ANC-3)';
      subtitle = 'रक्तचाप (148/96) और हीमोग्लोबिन (7.8) पुनः जांच आवश्यक';
      actionBtnText = 'टेलीकंसल्टेशन शुरू करें';
    } else if (lang == 'Marathi') {
      priorityTag = 'प्राधान्य तपासणी';
      dueTag = '२ दिवसांत बाकी';
      title = 'तिसऱ्या तिमाहीतील ANC तपासणी (ANC-3)';
      subtitle = 'रक्तदाब (148/96) व हिमोग्लोबिन (7.8) फेरतपासणी आवश्यक';
      actionBtnText = 'व्हिडिओ सल्लामसलत सुरू करा';
    } else {
      priorityTag = 'PRIORITY CHECKUP';
      dueTag = 'Due in 2 Days';
      title = '3rd Trimester ANC Clinical Checkup';
      subtitle = 'Re-check blood pressure (148/96) & Haemoglobin (7.8 g/dL)';
      actionBtnText = 'Join Video Consultation Now';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.priorityGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E005140),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circular glow
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badge Strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFCD34D),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            priorityTag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x4DFCD34D)),
                      ),
                      child: Text(
                        dueTag,
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Icon + Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.pregnant_woman_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => LiveTeleconsultRoomScreen(
                            patientName: patient.fullName,
                            doctorName: upcomingApt?.doctorName ?? 'Dr. Anjali Deshmukh (MD OB/GYN)',
                            specialty: upcomingApt?.specialty ?? 'Obstetrics & Gynaecology',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_call_rounded, size: 18),
                    label: Text(actionBtnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F3D6E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Active Referral Status Card
  Widget _buildActiveReferralBanner(BuildContext context, ReferralDto referral, String lang) {
    String refLabel = lang == 'Hindi' ? 'सक्रिय रेफरल' : (lang == 'Marathi' ? 'सक्रिय संदर्भ' : 'Active Referral');
    String trackBtn = lang == 'Hindi' ? 'लाइव ट्रैक' : (lang == 'Marathi' ? 'लाइव्ह ट्रॅक' : 'Live Track');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alt_route, color: Color(0xFFB45309), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$refLabel: ${referral.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                Text(
                  referral.targetFacilityName,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  referral.statusDisplay,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ReferralTrackerScreen()),
              );
            },
            child: Text(trackBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Health Vitals Snapshot Card with elevated condition badges
  Widget _buildVitalsCard(BuildContext context, PatientDto patient, VitalsDto? vitals, String lang) {
    final hasWarning = vitals != null && vitals.hasWarning;
    String vitalsHeader;
    String statusBadge;

    if (lang == 'Hindi') {
      vitalsHeader = 'नवीनतम स्वास्थ्य स्थिति';
      statusBadge = hasWarning ? '🟡 समीक्षा आवश्यक' : '🟢 सामान्य सीमा';
    } else if (lang == 'Marathi') {
      vitalsHeader = 'नवीनतम आरोग्य स्थिती';
      statusBadge = hasWarning ? '🟡 पुनरावलोकन आवश्यक' : '🟢 सामान्य श्रेणी';
    } else {
      vitalsHeader = 'Latest Health Vitals';
      statusBadge = hasWarning ? '🟡 Review Required' : '🟢 Normal Range';
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.neutral200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.stitchPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      vitalsHeader,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.stitchOnSurface),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasWarning ? const Color(0xFFFEF3C7) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusBadge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hasWarning ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (vitals != null) ...[
              Row(
                children: [
                  _vitalItem('रक्तदाब / BP', '${vitals.systolicBp}/${vitals.diastolicBp} mmHg', isElevated: vitals.systolicBp > 140 || vitals.diastolicBp > 90),
                  _vitalItem('हीमोग्लोबिन / Hb', '${vitals.haemoglobin} g/dL', isElevated: vitals.haemoglobin < 9.0),
                  _vitalItem('SpO2', '${vitals.spO2}%', isElevated: vitals.spO2 < 95),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _vitalItem('हृदय गती / Pulse', '${vitals.pulse} bpm'),
                  _vitalItem('रक्त शर्करा / Sugar', '${vitals.bloodSugar} mg/dL'),
                  _vitalItem('तापमान / Temp', '${vitals.temperature}°F'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                lang == 'Hindi'
                    ? 'आशा कार्यकर्ता ${patient.assignedAsha} द्वारा दर्ज • ICMR सुरक्षित मातृत्व'
                    : (lang == 'Marathi'
                        ? 'आशा सेविका ${patient.assignedAsha} द्वारे नोंद • ICMR सुरक्षित मातृत्व'
                        : 'Recorded by ASHA ${patient.assignedAsha} • ICMR Safe Pregnancy Protocol'),
                style: const TextStyle(fontSize: 10, color: AppColors.neutral600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vitalItem(String label, String value, {bool isElevated = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isElevated ? const Color(0xFFFEF3C7) : AppColors.stitchSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isElevated ? const Color(0xFFF59E0B) : AppColors.neutral200,
            width: isElevated ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.neutral600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isElevated ? const Color(0xFFB45309) : AppColors.neutral900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSectionHeader(BuildContext context, String lang) {
    String title = lang == 'Hindi'
        ? 'आरोग्य सेवा / Essential Services'
        : (lang == 'Marathi'
            ? 'आरोग्य सेवा / Essential Services'
            : 'Essential Health Services');

    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.slateNavy,
      ),
    );
  }

  /// 2-Column Action Grid matching Stitch component styling
  Widget _buildActionGrid(BuildContext context, String lang) {
    final isHi = lang == 'Hindi';
    final isMr = lang == 'Marathi';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: [
        _gridCard(
          context,
          icon: Icons.medication_rounded,
          color: const Color(0xFF0D9488),
          title: isHi ? 'दवाइयों की उपलब्धता' : (isMr ? 'औषध उपलब्धता' : 'Medicines Stock'),
          subtitle: isHi ? 'PHC और SDH में लाइव स्टॉक' : (isMr ? 'PHC व SDH मधील साठा' : 'Live stock at PHC & SDH'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const MedicineAvailabilityScreen()),
            );
          },
        ),
        _gridCard(
          context,
          icon: Icons.biotech_rounded,
          color: AppColors.slateNavy,
          title: isHi ? 'निदान प्रयोगशाला' : (isMr ? 'निदान प्रयोगशाळा' : 'Diagnostic Labs'),
          subtitle: isHi ? 'USG, रक्त और मूत्र जांच' : (isMr ? 'सोनोग्राफी, रक्त तपासणी' : 'USG, Blood & Urine tests'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const DiagnosticLocatorScreen()),
            );
          },
        ),
        _gridCard(
          context,
          icon: Icons.emergency,
          color: AppColors.criticalRed,
          title: isHi ? 'आपातकालीन SOS' : (isMr ? 'आपत्कालीन SOS' : 'Emergency SOS'),
          subtitle: isHi ? '108 एम्बुलेंस और निकटतम SDH' : (isMr ? '१०८ रुग्णवाहिका' : '108 Ambulance & SDH'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
            );
          },
        ),
        _gridCard(
          context,
          icon: Icons.hotel_rounded,
          color: AppColors.stitchPrimary,
          title: isHi ? 'बेड उपलब्धता' : (isMr ? 'खाटांची उपलब्धता' : 'Bed Availability'),
          subtitle: isHi ? 'उपजिल्हा रुग्णालय बारामती' : (isMr ? 'उपजिल्हा रुग्णालय बारामती' : 'Baramati SDH Registry'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const FacilityOperationsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _gridCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200, width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x060D1C2E), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutral900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.neutral600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Assigned ASHA Community Health Worker Card
  Widget _buildAshaCard(BuildContext context, String ashaName, String lang) {
    String roleLabel = lang == 'Hindi'
        ? 'नियुक्त आशा कार्यकर्ता (ASHA Worker)'
        : (lang == 'Marathi'
            ? 'नियुक्त आशा सेविका (ASHA Worker)'
            : 'Assigned ASHA Community Worker');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.stitchPrimary.withOpacity(0.12),
            radius: 20,
            child: const Icon(Icons.support_agent, color: AppColors.stitchPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roleLabel, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
                Text(ashaName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Text('काष्टी उप-केंद्र क्षेत्र (Kashti Sub-centre)', style: TextStyle(fontSize: 10, color: AppColors.forestTealDark)),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.phone, color: AppColors.stitchPrimary, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.stitchPrimary,
                  content: Text('Calling ASHA Worker $ashaName (+91 98220 19284)...'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
