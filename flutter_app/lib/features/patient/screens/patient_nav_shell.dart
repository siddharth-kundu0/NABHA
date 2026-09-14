import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';
import 'patient_home_screen.dart';
import 'symptom_checker_screen.dart';
import 'appointment_booking_screen.dart';
import 'longitudinal_records_screen.dart';
import 'patient_profile_screen.dart';

/// Fixed 5-tab navigation shell for the Patient role adhering strictly to DESIGN.md Section 4:
/// Home | Symptom Checker | Appointments | Records | Profile
/// Selected item uses blue text/icon and a small pale-blue selection background.
class PatientNavShell extends StatefulWidget {
  final int initialIndex;

  const PatientNavShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<PatientNavShell> createState() => _PatientNavShellState();
}

class _PatientNavShellState extends State<PatientNavShell> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    PatientHomeScreen(),
    SymptomCheckerScreen(),
    AppointmentBookingScreen(),
    LongitudinalRecordsScreen(),
    PatientProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final isHi = session.isHindi;
        final isMr = session.isMarathi;

        final homeLabel = isHi ? 'मुख्य पृष्ठ' : (isMr ? 'मुख्य पृष्ठ' : 'Home');
        final symptomLabel = isHi ? 'लक्षण जाँच' : (isMr ? 'लक्षण तपासणी' : 'Symptom Checker');
        final aptLabel = isHi ? 'अपॉइंटमेंट' : (isMr ? 'अपॉइंटमेंट' : 'Appointments');
        final recLabel = isHi ? 'रिकॉर्ड' : (isMr ? 'नोंदी' : 'Records');
        final profLabel = isHi ? 'प्रोफ़ाइल' : (isMr ? 'प्रोफाइल' : 'Profile');

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: RuralCareColors.surface,
              border: Border(
                top: BorderSide(color: RuralCareColors.border, width: 1.0),
              ),
              boxShadow: AppDecorations.subtleShadow,
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) {
                setState(() {
                  _currentIndex = idx;
                });
              },
              backgroundColor: RuralCareColors.surface,
              indicatorColor: RuralCareColors.primarySoft,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined, color: RuralCareColors.textSecondary, size: 24),
                  selectedIcon: const Icon(Icons.home, color: RuralCareColors.primary, size: 24),
                  label: homeLabel,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.accessibility_new_outlined, color: RuralCareColors.textSecondary, size: 24),
                  selectedIcon: const Icon(Icons.accessibility_new_rounded, color: RuralCareColors.primary, size: 24),
                  label: symptomLabel,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_today_outlined, color: RuralCareColors.textSecondary, size: 24),
                  selectedIcon: const Icon(Icons.calendar_today, color: RuralCareColors.primary, size: 24),
                  label: aptLabel,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.folder_shared_outlined, color: RuralCareColors.textSecondary, size: 24),
                  selectedIcon: const Icon(Icons.folder_shared, color: RuralCareColors.primary, size: 24),
                  label: recLabel,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline, color: RuralCareColors.textSecondary, size: 24),
                  selectedIcon: const Icon(Icons.person, color: RuralCareColors.primary, size: 24),
                  label: profLabel,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
