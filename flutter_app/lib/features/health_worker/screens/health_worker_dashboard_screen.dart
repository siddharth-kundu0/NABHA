import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'health_worker_patient_directory.dart';
import 'health_worker_followup_screen.dart';
import 'health_worker_referral_screen.dart';
import 'health_worker_profile_screen.dart';
import 'vitals_collection_screen.dart';
import 'maternal_care_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';
import 'package:ruralcare/data/repositories/patient_request_repository.dart';
import 'package:ruralcare/features/notifications/screens/notification_center_screen.dart';
import 'package:ruralcare/features/health_worker/widgets/health_worker_patient_requests_tab.dart';
import 'package:ruralcare/features/auth/screens/patient_registration_screen.dart';
import '../utils/health_worker_strings.dart';

/// Health Worker Workspace conforming strictly to Stitch Screen Designs:
/// - Screen 1: Health Worker Dashboard (Compact)
/// - Screen 2: Patient Directory & Search
/// - Screen 4: Follow-up & Task Observation Form
/// - Screen 5: Referral Coordination & Tracking
/// - Health Worker Profile & Settings
class HealthWorkerDashboardScreen extends StatefulWidget {
  const HealthWorkerDashboardScreen({super.key});

  @override
  State<HealthWorkerDashboardScreen> createState() => _HealthWorkerDashboardScreenState();
}

class _HealthWorkerDashboardScreenState extends State<HealthWorkerDashboardScreen> {
  int _currentTabIndex = 0;
  bool _isSyncing = false;
  PatientDto? _selectedPatientForTask;

  void _switchTab(int index, {PatientDto? patient}) {
    setState(() {
      _currentTabIndex = index;
      if (patient != null) {
        _selectedPatientForTask = patient;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final refRepo = ReferralRepository();
    final aptRepo = AppointmentRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, refRepo, aptRepo, cache, session]),
      builder: (context, _) {
        final patients = patientRepo.patients;
        final highRiskPatients = patients.where((p) => p.isHighRisk || p.highRiskConditions.isNotEmpty).toList();
        final dueTodayCount = (patients.length > 2 ? 4 : patients.length) + (aptRepo.appointments.length);
        final activeReferralsCount = refRepo.referrals.length;
        final strings = HealthWorkerStrings.of(session);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _buildMasterHeader(context, session, cache, strings),
          ),
          body: _buildCurrentTab(
            context,
            patients,
            highRiskPatients,
            dueTodayCount,
            activeReferralsCount,
            cache,
            strings,
          ),
          bottomNavigationBar: _buildBottomNav(dueTodayCount, activeReferralsCount, strings),
        );
      },
    );
  }

  Widget _buildCurrentTab(
    BuildContext context,
    List<PatientDto> patients,
    List<PatientDto> highRiskPatients,
    int dueTodayCount,
    int activeReferralsCount,
    LocalCacheService cache,
    HealthWorkerStrings strings,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildMainDashboardTab(
          context,
          patients,
          highRiskPatients,
          dueTodayCount,
          activeReferralsCount,
          cache,
          strings,
        );
      case 1:
        return HealthWorkerPatientDirectory(
          onNavigateTab: (targetTab) => _switchTab(targetTab),
        );
      case 2:
        return const HealthWorkerPatientRequestsTab();
      case 3:
        return HealthWorkerFollowUpScreen(
          isStandalone: false,
          patientId: _selectedPatientForTask?.id,
        );
      case 4:
        return const HealthWorkerReferralScreen();
      case 5:
        return const HealthWorkerProfileScreen();
      default:
        return _buildMainDashboardTab(
          context,
          patients,
          highRiskPatients,
          dueTodayCount,
          activeReferralsCount,
          cache,
          strings,
        );
    }
  }

  // Master Global Top Bar matching Stitch Screen 1 & Profile
  Widget _buildMasterHeader(BuildContext context, SessionCoordinator session, LocalCacheService cache, HealthWorkerStrings strings) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: SafeArea(
        child: Row(
          children: [
            // RuralCare Logo
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.navyBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RuralCare',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  session.isMarathi ? 'आरोग्य सेविका' : (session.isHindi ? 'स्वास्थ्य कार्यकर्ता' : 'Rural Care'),
                  style: const TextStyle(fontSize: 9, color: AppColors.forestTeal, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),

            // Online Indicator Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Color(0xFF2E7D32), size: 7),
                  const SizedBox(width: 4),
                  Text(
                    strings.online,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Language Selector Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: Row(
                children: [
                  _headerLangOption(session, 'EN', 'English'),
                  const Text(' | ', style: TextStyle(fontSize: 10, color: AppColors.neutral400)),
                  _headerLangOption(session, 'हि', 'हिन्दी'),
                  const Text(' | ', style: TextStyle(fontSize: 10, color: AppColors.neutral400)),
                  _headerLangOption(session, 'म', 'मराठी'),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // Notification Bell with Live Unread Count
            ListenableBuilder(
              listenable: NotificationRepository(),
              builder: (context, _) {
                final unread = NotificationRepository().getUnreadCount(AppRole.healthWorker);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.navyBlue, size: 24),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                        );
                      },
                      tooltip: 'Health Worker Notifications',
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC2410C),
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
            const SizedBox(width: 4),

            // + New Patient Registration Shortcut
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.forestTeal, size: 22),
              tooltip: 'Register New Patient',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PatientRegistrationScreen()),
                );
              },
            ),
            const SizedBox(width: 4),

            // Health Worker Avatar squircle (tapping navigates to Profile tab)
            InkWell(
              onTap: () => setState(() => _currentTabIndex = 5),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.forestTealDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'HW',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerLangOption(SessionCoordinator session, String label, String langName) {
    final isSel = (langName == 'English' || langName == 'en')
        ? session.isEnglish
        : (langName == 'Hindi' || langName == 'हिंदी' || langName == 'हिन्दी' || langName == 'hi')
            ? session.isHindi
            : session.isMarathi;
    return InkWell(
      onTap: () => session.switchLanguage(langName),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
          color: isSel ? AppColors.forestTeal : AppColors.slateGray,
        ),
      ),
    );
  }

  // Tab 0: Master Dashboard
  Widget _buildMainDashboardTab(
    BuildContext context,
    List<PatientDto> patients,
    List<PatientDto> highRiskPatients,
    int dueTodayCount,
    int activeReferralsCount,
    LocalCacheService cache,
    HealthWorkerStrings strings,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Worker Identity & Local Persistence Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.neutral300),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.forestTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.badge_outlined, size: 18, color: AppColors.forestTeal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kavita Verma • PHC Rampur',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        strings.roleSubtitle,
                        style: const TextStyle(fontSize: 10, color: AppColors.slateGray),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isSyncing = true);
                    await cache.flushOutboxQueue();
                    if (mounted) {
                      setState(() => _isSyncing = false);
                      messenger.showSnackBar(
                        SnackBar(content: Text(strings.syncSuccess)),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.skyBlueSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isSyncing
                            ? const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.navyBlue),
                              )
                            : const Icon(Icons.cloud_done_outlined, size: 12, color: AppColors.navyBlue),
                        const SizedBox(width: 4),
                        Text(
                          '${patients.length * 8} ${strings.recordsSaved}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. 2x2 Performance Metrics Grid matching Stitch Screen 1
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: strings.dueToday,
                  value: '$dueTodayCount',
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.navyBlue,
                  onTap: () => _switchTab(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  title: strings.priorityCases,
                  value: '${highRiskPatients.isEmpty ? 2 : highRiskPatients.length}',
                  valueColor: const Color(0xFFDC2626),
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFDC2626),
                  onTap: () => _switchTab(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: strings.activeReferrals,
                  value: '$activeReferralsCount',
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppColors.forestTeal,
                  onTap: () => _switchTab(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  title: strings.completedThisWeek,
                  value: '18',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                  onTap: () => _showCompletedSummary(context, strings),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Quick Action Buttons Grid (4 squircle buttons with vibrant pastel boxes)
          Row(
            children: [
              _quickActionButton(
                icon: Icons.person_search_outlined,
                label: strings.findPatient,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: AppColors.navyBlue,
                onTap: () => _switchTab(1),
              ),
              const SizedBox(width: 8),
              _quickActionButton(
                icon: Icons.person_add_alt_1_outlined,
                label: strings.isHi ? '+ नया मरीज' : (strings.isMr ? '+ नवीन रुग्ण' : '+ New Patient'),
                iconBg: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF065F46),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const PatientRegistrationScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              _quickActionButton(
                icon: Icons.inbox_outlined,
                label: strings.isHi ? 'अनुरोध डेस्क' : (strings.isMr ? 'विनंती डेस्क' : 'Requests'),
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4338CA),
                onTap: () => _switchTab(2),
              ),
              const SizedBox(width: 8),
              _quickActionButton(
                icon: Icons.swap_horiz_rounded,
                label: strings.referralSupport,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFF92400E),
                onTap: () => _switchTab(4),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Cluster Multi-Patient Roster Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    strings.isHi ? 'ग्राम क्लस्टर मरीज' : (strings.isMr ? 'ग्राम क्लस्टर रुग्ण' : 'Cluster Patients'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${patients.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const PatientRegistrationScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 14, color: AppColors.forestTeal),
                label: Text(
                  strings.isHi ? '+ पंजीकरण' : (strings.isMr ? '+ नोंदणी' : '+ Register'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.forestTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBeneficiaryCarousel(context, patients, strings),
          const SizedBox(height: 16),

          // 4. Today's Tasks Section matching Stitch Screen 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(strings.todaysTasks, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${patients.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _switchTab(1),
                child: Text(strings.viewAll, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.forestTeal)),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Task Cards
          ...patients.map((p) => _buildTaskCard(context, p, strings)),

          const SizedBox(height: 18),

          // 5. Priority Field Tools Grid (Vitals, Triage, ANC, SOS)
          Text(strings.fieldScreeningTools, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
          const SizedBox(height: 10),
          _buildFieldToolsGrid(context, strings),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
                  Icon(icon, size: 16, color: iconColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.darkSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletedSummary(BuildContext context, HealthWorkerStrings strings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.weeklyLogTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            _completedRow(strings.hypertensionFollowups, '8 visits', Icons.speed_rounded, AppColors.forestTeal),
            const SizedBox(height: 8),
            _completedRow(strings.maternalAncChecks, '6 checks', Icons.pregnant_woman_rounded, AppColors.navyBlue),
            const SizedBox(height: 8),
            _completedRow(strings.childImmunization, '4 records', Icons.child_care_rounded, const Color(0xFF10B981)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestTealDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(strings.closeSummary, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completedRow(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkSlate))),
          Text(count, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral300),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.darkSlate, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeneficiaryCarousel(BuildContext context, List<PatientDto> patients, HealthWorkerStrings strings) {
    if (patients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded, size: 32, color: AppColors.slateGray),
            const SizedBox(height: 6),
            Text(
              strings.isHi ? 'कोई मरीज पंजीकृत नहीं है' : (strings.isMr ? 'कोणतेही रुग्ण नोंदणीकृत नाहीत' : 'No patients registered yet'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkSlate),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const PatientRegistrationScreen()),
                );
              },
              icon: const Icon(Icons.person_add_alt_1, size: 16, color: Colors.white),
              label: Text(strings.isHi ? '+ नया मरीज जोड़ें' : (strings.isMr ? '+ नवीन रुग्ण जोडा' : '+ Register Beneficiary')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestTealDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: patients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, index) {
          final p = patients[index];
          final isSelected = _selectedPatientForTask?.id == p.id;
          return Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.forestTeal : AppColors.neutral300,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: p.isPregnant ? const Color(0xFFFCE7F3) : const Color(0xFFE0F2FE),
                      child: Icon(
                        p.isPregnant ? Icons.pregnant_woman_rounded : Icons.person_rounded,
                        size: 18,
                        color: p.isPregnant ? const Color(0xFFBE185D) : AppColors.navyBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.fullName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${p.age}y • ${p.gender.toUpperCase()}',
                            style: const TextStyle(fontSize: 10, color: AppColors.slateGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (p.abhaId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ABHA: ${p.abhaId}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.forestTealDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPatientForTask = p;
                            });
                            PatientRepository().selectPatientById(p.id);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => VitalsCollectionScreen(selectedPatientId: p.id),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: AppColors.forestTeal, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            strings.isHi ? 'निदान (3+BP)' : (strings.isMr ? 'निदान (३+BP)' : 'Diagnose'),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.forestTeal),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 30,
                      width: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.slateGray),
                        onPressed: () {
                          setState(() {
                            _selectedPatientForTask = p;
                          });
                          PatientRepository().selectPatientById(p.id);
                          _switchTab(3, patient: p);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, PatientDto p, HealthWorkerStrings strings) {
    String priorityLabel = strings.priorityNormal;
    Color priorityBg = const Color(0xFFF1F5F9);
    Color priorityColor = AppColors.slateGray;
    String attentionReason = strings.isHi ? 'नियमित फॉलो-अप एवं वाइटल्स' : (strings.isMr ? 'नियमित फॉलो-अप आणि मापदंड' : 'Routine Follow-up & Vitals');
    String whenText = strings.isHi ? 'आज, 11:00 AM' : (strings.isMr ? 'आज, ११:०० AM' : 'Today, 11:00 AM');
    Color whenColor = const Color(0xFFC2410C);

    if (p.isPregnant && p.highRiskConditions.isNotEmpty) {
      priorityLabel = strings.priorityAnc;
      priorityBg = const Color(0xFFE0F2FE);
      priorityColor = const Color(0xFF0369A1);
      attentionReason = strings.isHi ? 'नियमित दूसरी तिमाही जांच' : (strings.isMr ? 'नियमित दुसरी तिमाही तपासणी' : 'Routine 2nd Trimester Checkup');
      whenText = strings.isHi ? 'आज, 2:00 PM' : (strings.isMr ? 'आज, २:०० PM' : 'Today, 2:00 PM');
      whenColor = const Color(0xFF0369A1);
    } else if (p.isHighRisk) {
      priorityLabel = strings.priorityHigh;
      priorityBg = const Color(0xFFFFF3E0);
      priorityColor = const Color(0xFFE65100);
      attentionReason = strings.isHi ? 'परामर्श उपरांत बीपी जांच' : (strings.isMr ? 'सल्ल्यानंतर बीपी तपासणी' : 'Post-Consult BP Check');
      whenText = strings.isHi ? 'आज, 11:00 AM' : (strings.isMr ? 'आज, ११:०० AM' : 'Today, 11:00 AM');
      whenColor = const Color(0xFFC2410C);
    } else if (p.latestVitals?.isHighRisk ?? false) {
      priorityLabel = strings.priorityOverdue;
      priorityBg = const Color(0xFFFFEBEE);
      priorityColor = const Color(0xFFC62828);
      attentionReason = strings.isHi ? 'फास्टिंग शुगर फॉलो-अप' : (strings.isMr ? 'फास्टिंग साखर फॉलो-अप' : 'Fasting Sugar Follow-up');
      whenText = strings.isHi ? 'देय: कल' : (strings.isMr ? 'देय: काल' : 'Due: Yesterday');
      whenColor = const Color(0xFFC62828);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WHO Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.whoLabel, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      '${p.fullName} (${p.age}${p.gender == "FEMALE" ? "F" : "M"} • ${p.village})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.neutral200),
          const SizedBox(height: 10),

          // WHAT & WHEN
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.isHi ? 'क्या ध्यान देने योग्य है' : (strings.isMr ? 'कशाकडे लक्ष देणे गरजेचे आहे' : 'WHAT NEEDS ATTENTION'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      attentionReason,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkSlate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.whenLabel, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      whenText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: whenColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Actions: Phone button + Record Visit Primary Button
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.phone_outlined, color: Color(0xFF2E7D32), size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing ${p.fullName} (${p.phoneNumber})...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      _switchTab(3, patient: p);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestTealDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          strings.isHi ? 'दौरा दर्ज करें' : (strings.isMr ? 'भेट नोंदवा' : 'Record Visit'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldToolsGrid(BuildContext context, HealthWorkerStrings strings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _toolCard(
                icon: Icons.monitor_heart_outlined,
                title: strings.isHi ? 'स्वास्थ्य निदान व ट्राइएज' : (strings.isMr ? 'आरोग्य निदान व ट्रायेज' : 'Health Diagnosis'),
                subtitle: strings.isHi ? '3 हार्डवेयर कारक + बीपी' : (strings.isMr ? '३ घटक + बीपी' : '3 Factors + BP + MoHFW'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => VitalsCollectionScreen(selectedPatientId: _selectedPatientForTask?.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _toolCard(
                icon: Icons.inbox_outlined,
                title: strings.isHi ? 'मरीज अनुरोध' : (strings.isMr ? 'रुग्ण विनंत्या' : 'Patient Requests'),
                subtitle: strings.isHi ? 'एसओएस एवं लक्षण डेस्क' : (strings.isMr ? 'एसओएस व लक्षण डेस्क' : 'SOS & message triage'),
                onTap: () => _switchTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _toolCard(
                icon: Icons.pregnant_woman_rounded,
                title: strings.isHi ? 'मातृ एएनसी' : (strings.isMr ? 'मातृ एएनसी' : 'Maternal ANC'),
                subtitle: strings.isHi ? 'तिमाही चेकलिस्ट' : (strings.isMr ? 'तिमाही चेकलिस्ट' : 'Trimester checklist'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const MaternalCareScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _toolCard(
                icon: Icons.emergency_outlined,
                title: strings.emergencySos,
                subtitle: strings.isHi ? 'एसडीएच प्री-अलर्ट' : (strings.isMr ? 'एसडीएच प्री-अलर्ट' : 'Trigger SDH pre-alert'),
                isCritical: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _toolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isCritical = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCritical ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCritical ? const Color(0xFFFECACA) : AppColors.neutral300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isCritical ? const Color(0xFFDC2626) : AppColors.forestTeal, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCritical ? const Color(0xFFDC2626) : AppColors.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isCritical ? const Color(0xFF991B1B) : AppColors.slateGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interactive Bottom Navigation Bar matching Stitch Screens with rock-solid hit testing
  Widget _buildBottomNav(int taskCount, int referralCount, HealthWorkerStrings strings) {
    final pendingRequests = PatientRequestRepository().pendingRequests.length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.neutral200, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, strings.tabDashboard),
              _buildNavItem(1, Icons.people_alt_outlined, strings.tabPatients),
              _buildNavItem(2, Icons.inbox_outlined, strings.isHi ? 'अनुरोध' : (strings.isMr ? 'विनंत्या' : 'Requests'), badgeCount: pendingRequests),
              _buildNavItem(3, Icons.checklist_rounded, strings.tabTasks, badgeCount: taskCount),
              _buildNavItem(4, Icons.swap_horiz_rounded, strings.tabReferrals, badgeCount: referralCount),
              _buildNavItem(5, Icons.person_outline_rounded, strings.tabProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _switchTab(index),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? AppColors.forestTealDark : AppColors.slateGray,
                      size: 22,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        alignment: Alignment.center,
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.forestTealDark : AppColors.slateGray,
                ),
              ),
            ],
          ),
        ),
      );
  }
}
