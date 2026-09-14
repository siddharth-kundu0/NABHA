import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/doctor/utils/doctor_strings.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_home_tab.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_patients_tab.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_queue_tab.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_referrals_tab.dart';
import 'package:ruralcare/features/doctor/widgets/doctor_profile_tab.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';
import 'package:ruralcare/features/notifications/screens/notification_center_screen.dart';

/// Doctor / Specialist Workspace conforming strictly to Stitch Design & DESIGN.md
/// Hosts 5 Primary Destinations: Dashboard, Patients, Queue, Referrals, Profile
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return DoctorHomeTab(onTabSelected: _onTabSelected);
      case 1:
        return const DoctorPatientsTab();
      case 2:
        return const DoctorQueueTab();
      case 3:
        return const DoctorReferralsTab();
      case 4:
        return const DoctorProfileTab();
      default:
        return DoctorHomeTab(onTabSelected: _onTabSelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final strings = DoctorStrings.of(session);

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: RuralCareColors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_hospital, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RuralCare',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: RuralCareColors.teal,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: session.isOffline ? RuralCareColors.warning : RuralCareColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.isOffline ? strings.offline : strings.online,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: session.isOffline ? RuralCareColors.warning : RuralCareColors.success,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Language selector
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _langBadge('EN', 'en', session),
                    _langBadge('हि', 'hi', session),
                    _langBadge('म', 'mr', session),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Notification Bell
              ListenableBuilder(
                listenable: NotificationRepository(),
                builder: (context, _) {
                  final unread = NotificationRepository().getUnreadCount(AppRole.doctor);
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
                        tooltip: 'Doctor Notifications',
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 8,
                          right: 8,
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
              // Profile avatar
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 4),
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: RuralCareColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('AR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: RuralCareColors.border),
            ),
          ),
          body: _buildCurrentTab(),
          bottomNavigationBar: _buildBottomNavigationBar(strings),
        );
      },
    );
  }

  Widget _langBadge(String text, String code, SessionCoordinator session) {
    final isSelected = code == 'en'
        ? session.isEnglish
        : (code == 'hi' ? session.isHindi : session.isMarathi);

    return GestureDetector(
      key: ValueKey('doctor_lang_$code'),
      onTap: () => session.switchLanguage(code),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? RuralCareColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x10000000), blurRadius: 2, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? RuralCareColors.teal : RuralCareColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(DoctorStrings strings) {
    return Container(
      decoration: const BoxDecoration(
        color: RuralCareColors.surface,
        border: Border(top: BorderSide(color: RuralCareColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, strings.tabDashboard),
              _buildNavItem(1, Icons.group_outlined, Icons.group_rounded, strings.tabPatients),
              _buildNavItem(2, Icons.checklist_outlined, Icons.checklist_rounded, strings.tabQueue),
              _buildNavItem(3, Icons.swap_horiz_outlined, Icons.swap_horiz_rounded, strings.tabReferrals),
              _buildNavItem(4, Icons.account_circle_outlined, Icons.account_circle_rounded, strings.tabProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        key: ValueKey('doctor_nav_$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 22,
              color: isSelected ? RuralCareColors.teal : RuralCareColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? RuralCareColors.teal : RuralCareColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
