import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/offline_status_bar.dart';
import 'package:ruralcare/app/routes.dart';

import 'package:ruralcare/features/auth/screens/onboarding_screen.dart';
import 'package:ruralcare/features/patient/screens/patient_nav_shell.dart';
import 'package:ruralcare/features/health_worker/screens/health_worker_dashboard_screen.dart';
import 'package:ruralcare/features/doctor/screens/doctor_dashboard_screen.dart';
import 'package:ruralcare/features/facility/screens/facility_dashboard_screen.dart';
import 'package:ruralcare/features/admin/screens/district_analytics_screen.dart';

class RuralCareAppShell extends StatelessWidget {
  const RuralCareAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        if (!session.hasCompletedOnboarding) {
          return const OnboardingScreen();
        }

        Widget currentRoleView;
        switch (session.activeRole) {
          case AppRole.patient:
            currentRoleView = const PatientNavShell();
            break;
          case AppRole.healthWorker:
            currentRoleView = const HealthWorkerDashboardScreen();
            break;
          case AppRole.doctor:
            currentRoleView = const DoctorDashboardScreen();
            break;
          case AppRole.facilityStaff:
            currentRoleView = const FacilityDashboardScreen();
            break;
          case AppRole.admin:
            currentRoleView = const DistrictAnalyticsScreen();
            break;
        }

        return Column(
          children: [
            const OfflineStatusBar(),
            Expanded(child: currentRoleView),
          ],
        );
      },
    );
  }
}
