import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'patient_home_screen.dart';
import 'appointment_booking_screen.dart';
import 'longitudinal_records_screen.dart';
import 'referral_tracker_screen.dart';
import 'patient_profile_screen.dart';

/// Locked 5-tab navigation shell for the Patient role.
/// Strictly adheres to: Home | Appointments | Records | Referrals | Profile.
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
        indicatorColor: AppColors.forestTealLight.withOpacity(0.3),
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.forestTeal),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppColors.forestTeal),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared, color: AppColors.forestTeal),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route, color: AppColors.forestTeal),
            label: 'Referrals',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.forestTeal),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
