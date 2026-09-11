import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/offline_status_bar.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/app/routes.dart';

import 'package:ruralcare/features/auth/screens/onboarding_screen.dart';
import 'package:ruralcare/features/patient/screens/patient_nav_shell.dart';
import 'package:ruralcare/features/health_worker/screens/health_worker_dashboard_screen.dart';
import 'package:ruralcare/features/doctor/screens/doctor_dashboard_screen.dart';
import 'package:ruralcare/features/facility/screens/facility_operations_screen.dart';
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
            currentRoleView = const FacilityOperationsScreen();
            break;
          case AppRole.admin:
            currentRoleView = const DistrictAnalyticsScreen();
            break;
        }

        return Stack(
          children: [
            Column(
              children: [
                const OfflineStatusBar(),
                Expanded(child: currentRoleView),
              ],
            ),
            // Floating interactive Role Switcher for pairwise demo evaluation
            Positioned(
              right: 16,
              bottom: session.activeRole == AppRole.patient ? 96 : 32,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(30),
                color: AppColors.forestTealDark,
                child: InkWell(
                  onTap: () => DemoRoleSwitcher.show(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          session.activeRole.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
