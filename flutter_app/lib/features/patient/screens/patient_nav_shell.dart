import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';
import 'patient_home_screen.dart';
import 'appointment_booking_screen.dart';
import 'longitudinal_records_screen.dart';
import 'referral_tracker_screen.dart';
import 'patient_profile_screen.dart';

/// Locked 5-tab navigation shell for the Patient role.
/// Dynamically updates labels based on active bilingual language selection in SessionCoordinator.
class PatientNavShell extends StatefulWidget {
  const PatientNavShell({super.key});

  @override
  State<PatientNavShell> createState() => _PatientNavShellState();
}

class _PatientNavShellState extends State<PatientNavShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PatientHomeScreen(),
    AppointmentBookingScreen(),
    LongitudinalRecordsScreen(),
    ReferralTrackerScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final lang = session.activeLanguage;
        final isHi = lang == 'Hindi';
        final isMr = lang == 'Marathi';

        final homeLabel = isHi ? 'मुख्य पृष्ठ' : (isMr ? 'मुख्य पृष्ठ' : 'Home');
        final aptLabel = isHi ? 'अपॉइंटमेंट' : (isMr ? 'अपॉइंटमेंट' : 'Appointments');
        final recLabel = isHi ? 'रिकॉर्ड' : (isMr ? 'नोंदी' : 'Records');
        final refLabel = isHi ? 'रेफरल' : (isMr ? 'संदर्भ' : 'Referrals');
        final profLabel = isHi ? 'प्रोफ़ाइल' : (isMr ? 'प्रोफाइल' : 'Profile');

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            backgroundColor: Colors.white,
            indicatorColor: AppColors.stitchPrimary.withOpacity(0.15),
            elevation: 4,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home, color: AppColors.stitchPrimary),
                label: homeLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_today_outlined),
                selectedIcon: const Icon(Icons.calendar_today, color: AppColors.stitchPrimary),
                label: aptLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.folder_shared_outlined),
                selectedIcon: const Icon(Icons.folder_shared, color: AppColors.stitchPrimary),
                label: recLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.alt_route_outlined),
                selectedIcon: const Icon(Icons.alt_route, color: AppColors.stitchPrimary),
                label: refLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person, color: AppColors.stitchPrimary),
                label: profLabel,
              ),
            ],
          ),
        );
      },
    );
  }
}
