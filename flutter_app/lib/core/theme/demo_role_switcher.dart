import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../database/local_cache.dart';
import 'app_theme.dart';

class DemoRoleSwitcher extends StatelessWidget {
  const DemoRoleSwitcher({super.key});

  static void show(BuildContext context) {
    final session = SessionCoordinator();
    final cache = LocalCacheService();
    _openModal(context, session, cache);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final cache = LocalCacheService();

    return Positioned(
      bottom: 24,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(28),
        color: RuralCareColors.primary,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _openModal(context, session, cache),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _shortTitle(session.activeRole),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _shortTitle(AppRole role) {
    switch (role) {
      case AppRole.patient:
        return 'Patient Role';
      case AppRole.healthWorker:
        return 'ASHA Worker Role';
      case AppRole.doctor:
        return 'Doctor Role';
      case AppRole.facilityStaff:
        return 'Facility Staff Role';
      case AppRole.admin:
        return 'District Admin Role';
    }
  }

  static void _openModal(BuildContext context, SessionCoordinator session, LocalCacheService cache) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Switch Role & Environment',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Test systematic features for each public health persona:',
                        style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ...AppRole.values.map((role) {
                        final isSelected = session.activeRole == role;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? RuralCareColors.primaryLight : Colors.white,
                            border: Border.all(
                              color: isSelected ? RuralCareColors.primary : RuralCareColors.borderSubtle,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getRoleIcon(role),
                              color: isSelected ? RuralCareColors.primary : RuralCareColors.secondary,
                            ),
                            title: Text(
                              role.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? RuralCareColors.primary : RuralCareColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(role.description, style: const TextStyle(fontSize: 11)),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: RuralCareColors.primary)
                                : null,
                            onTap: () {
                              session.switchRole(role);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                cache.isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                                color: cache.isOffline ? RuralCareColors.warning : RuralCareColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cache.isOffline ? 'Simulate Disconnected Network (Offline)' : 'Network Connection: Online',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Switch(
                            value: cache.isOffline,
                            activeColor: RuralCareColors.warning,
                            onChanged: (val) {
                              cache.toggleOfflineMode();
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static IconData _getRoleIcon(AppRole role) {
    switch (role) {
      case AppRole.patient:
        return Icons.person_rounded;
      case AppRole.healthWorker:
        return Icons.volunteer_activism_rounded;
      case AppRole.doctor:
        return Icons.medical_services_rounded;
      case AppRole.facilityStaff:
        return Icons.local_hospital_rounded;
      case AppRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }
}
