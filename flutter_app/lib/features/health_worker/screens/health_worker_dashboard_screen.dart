import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'vitals_collection_screen.dart';
import 'digital_triage_screen.dart';
import 'maternal_care_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

/// Health Worker Workspace conforming strictly to DESIGN.md Section 7:
/// Uses the same calm visual system. Prioritizes Today: Emergency, High risk,
/// Due follow-up, then Routine. Each task shows patient identity, reason, and one next action.
class HealthWorkerDashboardScreen extends StatefulWidget {
  const HealthWorkerDashboardScreen({super.key});

  @override
  State<HealthWorkerDashboardScreen> createState() => _HealthWorkerDashboardScreenState();
}

class _HealthWorkerDashboardScreenState extends State<HealthWorkerDashboardScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final refRepo = ReferralRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, refRepo, cache, session]),
      builder: (context, _) {
        final patients = patientRepo.patients;
        final highRiskPatients = patients.where((p) => p.isPregnant && p.highRiskConditions.isNotEmpty).toList();

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sunita Gaikwad (ASHA)', style: AppTypography.cardTitle),
                Text('Kashti Sub-Centre Sector 3 • PHC', style: AppTypography.supporting),
              ],
            ),
            actions: [
              IconButton(
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: RuralCareColors.primary),
                      )
                    : const Icon(Icons.sync_rounded, color: RuralCareColors.primary),
                tooltip: 'Sync outbox',
                onPressed: _isSyncing
                    ? null
                    : () async {
                        setState(() => _isSyncing = true);
                        await cache.flushOutboxQueue();
                        if (mounted) setState(() => _isSyncing = false);
                      },
              ),
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
                // 1. Priority Field Tools Grid (Vitals, Triage, ANC, SOS)
                const Text('Field screening tools', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                _buildFieldToolsGrid(context),

                const SizedBox(height: 24),

                // 2. Today's Priority Queue per DESIGN.md Section 7:
                // Prioritizes high risk, overdue follow-up, due follow-up, then routine.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Today’s priority visits', style: AppTypography.sectionTitle),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: AppDecorations.statusBadge(background: RuralCareColors.criticalSoft),
                      child: Text(
                        '${highRiskPatients.length} High risk',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: RuralCareColors.critical,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...highRiskPatients.map((patient) => _buildPatientVisitCard(context, patient)),

                const SizedBox(height: 24),

                // 3. Routine Registered Beneficiaries
                const Text('Registered beneficiaries', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                ...patients.where((p) => !p.highRiskConditions.isNotEmpty).map((p) => _buildRoutinePatientRow(context, p)),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
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
                title: 'Collect vitals',
                subtitle: 'BLE or manual entry',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _toolCard(
                icon: Icons.checklist_rtl_rounded,
                title: 'Digital triage',
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
        const SizedBox(height: 12),
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
            const SizedBox(width: 12),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.card(
          borderColor: isCritical ? RuralCareColors.critical.withOpacity(0.3) : null,
          color: isCritical ? RuralCareColors.criticalSoft : RuralCareColors.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: isCritical ? RuralCareColors.critical : RuralCareColors.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCritical ? RuralCareColors.critical : RuralCareColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.supporting.copyWith(
                      fontSize: 11,
                      color: isCritical ? RuralCareColors.critical : RuralCareColors.textSecondary,
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

  Widget _buildPatientVisitCard(BuildContext context, PatientDto patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(patient.fullName, style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.criticalSoft),
                child: Text(
                  patient.highRiskConditions.first,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: RuralCareColors.critical,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${patient.village} Sector 3 • Due for 32-week ANC follow-up',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen()),
                );
              },
              icon: const Icon(Icons.favorite_border_rounded, size: 18),
              label: const Text('Record vitals visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutinePatientRow(BuildContext context, PatientDto patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.fullName, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
              Text('${patient.village} • ABHA: ${patient.abhaId}', style: AppTypography.supporting),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: RuralCareColors.textSecondary, size: 16),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
