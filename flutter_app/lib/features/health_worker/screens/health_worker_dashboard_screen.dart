import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'vitals_collection_screen.dart';
import 'digital_triage_screen.dart';
import 'maternal_care_screen.dart';
import 'package:ruralcare/data/models/patient_dto.dart';

class HealthWorkerDashboardScreen extends StatelessWidget {
  const HealthWorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final refRepo = ReferralRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, refRepo]),
      builder: (context, _) {
        final patients = patientRepo.patients;
        final highRiskCount = patients.where((p) => p.isPregnant && p.highRiskConditions.isNotEmpty).length;

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASHA Field Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Sunita Tai Gaikwad • Kashti Sub-Centre', style: TextStyle(fontSize: 12, color: AppColors.forestTealLight)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Switch Role (Demo)',
                icon: const Icon(Icons.switch_account),
                onPressed: () => DemoRoleSwitcher.show(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Summary Header
                _buildSummaryHeader(context, total: patients.length, highRisk: highRiskCount),
                const SizedBox(height: 16),

                // Quick Action Buttons
                Text(
                  'Clinical Field Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy),
                ),
                const SizedBox(height: 10),
                _buildActionButtons(context),
                const SizedBox(height: 20),

                // Prioritized Daily Tasks Queue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prioritized Task Queue (ICMR Triage)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Triaged Order', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTaskQueue(context, patients),
                const SizedBox(height: 24),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen()),
              );
            },
            backgroundColor: AppColors.forestTeal,
            icon: const Icon(Icons.favorite, color: Colors.white),
            label: const Text('Record Vitals / BLE Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(BuildContext context, {required int total, required int highRisk}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forestTealLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.forestTeal.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('Assigned Families', '48', Icons.home_work),
          Container(width: 1, height: 40, color: AppColors.forestTeal.withOpacity(0.3)),
          _statCol('High-Risk Mothers', '$highRisk', Icons.warning_amber_rounded, color: AppColors.terracotta),
          Container(width: 1, height: 40, color: AppColors.forestTeal.withOpacity(0.3)),
          _statCol('Today\'s Visits', '6', Icons.checklist_rtl, color: AppColors.forestTealDark),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, IconData icon, {Color color = AppColors.forestTealDark}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.neutral700)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.monitor_heart,
            color: AppColors.forestTeal,
            label: 'Record Vitals\n& BLE Sensor',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.rule_sharp,
            color: AppColors.slateNavy,
            label: 'Digital Triage\nEvaluation',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const DigitalTriageScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.pregnant_woman,
            color: AppColors.terracotta,
            label: 'Maternal ANC\n1-4 Tracker',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const MaternalCareScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context, {required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              radius: 18,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskQueue(BuildContext context, List<PatientDto> patients) {
    return Column(
      children: [
        // Priority 1: 32-Week Gestational Hypertension
        _buildPriorityCard(
          context,
          badgeText: '🔴 PRIORITY 1: HIGH RISK ANC',
          badgeColor: AppColors.criticalRed,
          name: 'Kavita Rajesh Devi (26 Yrs, 32 Wks)',
          village: 'Kashti Village • House #42',
          vitalsSnippet: 'BP: 148/96 mmHg (Elevated) • Hb: 7.8 g/dL (Severe Anaemia)',
          instruction: 'Monitor BP, verify Labetalol adherence, ensure Baramati SDH referral transit.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const DigitalTriageScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        // Priority 2: Uncontrolled Diabetes
        _buildPriorityCard(
          context,
          badgeText: '🟡 PRIORITY 2: CHRONIC NCD',
          badgeColor: AppColors.terracotta,
          name: 'Ramesh Balu Jadhav (54 Yrs)',
          village: 'Kashti Village • House #88',
          vitalsSnippet: 'Sugar: 210 mg/dL • BP: 155/92 mmHg',
          instruction: 'NCD follow-up. Check Metformin stock at sub-centre and schedule doctor review.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen(selectedPatientId: 'pat-002')),
            );
          },
        ),
        const SizedBox(height: 12),
        // Priority 3: Routine ANC & Immunization
        _buildPriorityCard(
          context,
          badgeText: '🟢 PRIORITY 3: ROUTINE IMMUNIZATION',
          badgeColor: AppColors.forestTealDark,
          name: 'Sunita Pandurang Shinde (22 Yrs)',
          village: 'Kashti Village • House #12',
          vitalsSnippet: 'ANC Visit 2 • Td-2 Vaccine Due',
          instruction: 'Administer Td Booster and distribute 30-day supply of IFA tablets.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const MaternalCareScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriorityCard(
    BuildContext context, {
    required String badgeText,
    required Color badgeColor,
    required String name,
    required String village,
    required String vitalsSnippet,
    required String instruction,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.neutral600),
                ],
              ),
              const SizedBox(height: 8),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(village, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAntiGlare,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(vitalsSnippet, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral800)),
              ),
              const SizedBox(height: 6),
              Text(instruction, style: const TextStyle(fontSize: 11, color: AppColors.neutral700)),
            ],
          ),
        ),
      ),
    );
  }
}
