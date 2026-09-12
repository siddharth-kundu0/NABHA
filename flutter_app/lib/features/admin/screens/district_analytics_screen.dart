import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';

/// District Administration Screen conforming strictly to DESIGN.md Section 7:
/// Prioritizes pending approvals and actionable system issues over vanity metrics.
/// Clean, labeled rows, explicit role management, and calm visual hierarchy.
class DistrictAnalyticsScreen extends StatelessWidget {
  const DistrictAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final facRepo = FacilityRepository();

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        title: const Text('District administration', style: AppTypography.pageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: RuralCareColors.textSecondary),
            tooltip: 'Switch role',
            onPressed: () => DemoRoleSwitcher.show(context),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: RuralCareColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Actionable System Issues Section
            const Text('Actionable alerts', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            _buildActionItem(
              title: 'Low blood inventory (O- negative)',
              facility: 'Baramati Sub-District Hospital',
              subtitle: 'Only 2 units remaining in cold storage',
              badge: 'Critical',
              isCritical: true,
            ),
            const SizedBox(height: 10),
            _buildActionItem(
              title: 'Pending ASHA practitioner credential approval',
              facility: 'Kashti Sub-Centre Sector 3',
              subtitle: 'Sunita Gaikwad submitted biometric verification',
              badge: 'Approval needed',
              isCritical: false,
            ),

            const SizedBox(height: 24),

            // 2. Facility Network Capacity Overview
            const Text('Facility capacity registry', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: facRepo,
              builder: (ctx, _) {
                return Column(
                  children: facRepo.facilities.map((fac) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppDecorations.card(),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fac.name, style: AppTypography.cardTitle),
                              const SizedBox(height: 2),
                              Text('${fac.typeDisplay} • ${fac.distanceKm} km', style: AppTypography.supporting),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: AppDecorations.statusBadge(background: RuralCareColors.surfaceSubtle),
                            child: Text(
                              '${fac.availableBeds}/${fac.totalBeds} beds',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: RuralCareColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // 3. ABDM Compliance & Audit Ledger
            const Text('ABDM digital health compliance', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            Container(
              decoration: AppDecorations.card(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _auditRow('FHIR Milestone Compliant', '100% verified'),
                  _auditRow('Baramati SDH Health Facility Registry', 'HFR-413102-ACTIVE'),
                  _auditRow('Kashti Sub-Centre Registry', 'HFR-413108-ACTIVE'),
                  _auditRow('Encryption at rest & transit', 'TLS 1.3 / AES-256 GCM'),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required String facility,
    required String subtitle,
    required String badge,
    required bool isCritical,
  }) {
    return Container(
      decoration: AppDecorations.card(
        borderColor: isCritical ? RuralCareColors.critical.withOpacity(0.3) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(
                  background: isCritical ? RuralCareColors.criticalSoft : RuralCareColors.warningSoft,
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCritical ? RuralCareColors.critical : RuralCareColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$facility • $subtitle', style: AppTypography.supporting),
        ],
      ),
    );
  }

  Widget _auditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.supporting),
          Text(value, style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
