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
import 'digital_triage_screen.dart';
import 'maternal_care_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

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

  void _switchTab(int index) {
    setState(() => _currentTabIndex = index);
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

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _buildMasterHeader(context, session, cache),
          ),
          body: IndexedStack(
            index: _currentTabIndex,
            children: [
              // Tab 0: Main Dashboard matching stitch_hw_dashboard_compact.png
              _buildMainDashboardTab(
                context,
                patients,
                highRiskPatients,
                dueTodayCount,
                activeReferralsCount,
                cache,
              ),

              // Tab 1: Patient Directory matching stitch_hw_patient_search.png
              HealthWorkerPatientDirectory(onNavigateTab: _switchTab),

              // Tab 2: Follow-up & Tasks matching stitch_hw_followup.png
              const HealthWorkerFollowUpScreen(isStandalone: false),

              // Tab 3: Referral Coordination matching stitch_hw_referral.png
              const HealthWorkerReferralScreen(),

              // Tab 4: Health Worker Profile matching Stitch V2 Profile
              const HealthWorkerProfileScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  // Master Global Top Bar matching Stitch Screen 1 & Profile
  Widget _buildMasterHeader(BuildContext context, SessionCoordinator session, LocalCacheService cache) {
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
                  session.activeLanguage == 'मराठी' ? 'आरोग्य सेविका' : 'ग्रामीण सेवा',
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Color(0xFF2E7D32), size: 7),
                  SizedBox(width: 4),
                  Text(
                    'Online',
                    style: TextStyle(
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
            const SizedBox(width: 8),

            // Health Worker Avatar squircle (tapping navigates to Profile tab)
            InkWell(
              onTap: () => setState(() => _currentTabIndex = 4),
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
    final isSel = session.activeLanguage == langName;
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kavita Verma • PHC Rampur',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ASHA Sector 3 Catchment',
                        style: TextStyle(fontSize: 10, color: AppColors.slateGray),
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
                        const SnackBar(content: Text('Offline records synchronized with PHC registry')),
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
                          '${patients.length * 8} Records Saved',
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
                  title: 'DUE TODAY',
                  value: '$dueTodayCount',
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.navyBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  title: 'PRIORITY CASES',
                  value: '${highRiskPatients.isEmpty ? 2 : highRiskPatients.length}',
                  valueColor: const Color(0xFFDC2626),
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: 'ACTIVE REFERRALS',
                  value: '$activeReferralsCount',
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppColors.forestTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  title: 'COMPLETED THIS WEEK',
                  value: '18',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981),
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
                label: 'Find Patient',
                iconBg: const Color(0xFFE0F2FE),
                iconColor: AppColors.navyBlue,
                onTap: () => _switchTab(1),
              ),
              const SizedBox(width: 8),
              _quickActionButton(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Record\nFollow-up',
                iconBg: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF065F46),
                onTap: () => _switchTab(2),
              ),
              const SizedBox(width: 8),
              _quickActionButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Referral\nSupport',
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4338CA),
                onTap: () => _switchTab(3),
              ),
              const SizedBox(width: 8),
              _quickActionButton(
                icon: Icons.flash_on_outlined,
                label: "Today's\nTasks",
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFF92400E),
                onTap: () => _switchTab(2),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4. Today's Tasks Section matching Stitch Screen 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Today's Tasks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
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
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.forestTeal)),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Task Cards
          ...patients.map((p) => _buildTaskCard(context, p)),

          const SizedBox(height: 18),

          // 5. Priority Field Tools Grid (Vitals, Triage, ANC, SOS)
          const Text('Field Screening Tools', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
          const SizedBox(height: 10),
          _buildFieldToolsGrid(context),

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
  }) {
    return Container(
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

  Widget _buildTaskCard(BuildContext context, PatientDto p) {
    String priorityLabel = '● Normal';
    Color priorityBg = const Color(0xFFF1F5F9);
    Color priorityColor = AppColors.slateGray;
    String attentionReason = 'Routine Follow-up & Vitals';
    String whenText = 'Today, 11:00 AM';
    Color whenColor = const Color(0xFFC2410C);

    if (p.isPregnant && p.highRiskConditions.isNotEmpty) {
      priorityLabel = '● ANC Priority';
      priorityBg = const Color(0xFFE0F2FE);
      priorityColor = const Color(0xFF0369A1);
      attentionReason = 'Routine 2nd Trimester Checkup';
      whenText = 'Today, 2:00 PM';
      whenColor = const Color(0xFF0369A1);
    } else if (p.isHighRisk) {
      priorityLabel = '● High Priority';
      priorityBg = const Color(0xFFFFF3E0);
      priorityColor = const Color(0xFFE65100);
      attentionReason = 'Post-Consult BP Check';
      whenText = 'Today, 11:00 AM';
      whenColor = const Color(0xFFC2410C);
    } else if (p.latestVitals?.isHighRisk ?? false) {
      priorityLabel = '● Overdue';
      priorityBg = const Color(0xFFFFEBEE);
      priorityColor = const Color(0xFFC62828);
      attentionReason = 'Fasting Sugar Follow-up';
      whenText = 'Due: Yesterday';
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
                    const Text('WHO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
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
                    const Text('WHAT NEEDS ATTENTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
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
                    const Text('WHEN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (c) => HealthWorkerFollowUpScreen(patientId: p.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestTealDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Record Visit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
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

  Widget _buildFieldToolsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _toolCard(
                icon: Icons.monitor_heart_outlined,
                title: 'Collect Vitals',
                subtitle: 'BLE or manual entry',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _toolCard(
                icon: Icons.checklist_rtl_rounded,
                title: 'Digital Triage',
                subtitle: 'ICMR protocol review',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const DigitalTriageScreen()),
                  );
                },
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
                title: 'Maternal ANC',
                subtitle: 'Trimester checklist',
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
                title: 'Emergency SOS',
                subtitle: 'Trigger SDH pre-alert',
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

  // Interactive Bottom Navigation Bar matching Stitch Screens
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.neutral200, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: _switchTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.forestTeal,
        unselectedItemColor: AppColors.slateGray,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Referrals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
