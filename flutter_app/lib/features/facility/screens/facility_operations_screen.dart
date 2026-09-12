import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/models/referral_dto.dart';

/// Facility Operations Screen conforming strictly to DESIGN.md Section 7:
/// Compact operational summary, current intake queue, and actionable referrals.
/// Live bed capacity updating, fresh stock status, and clean card styling.
class FacilityOperationsScreen extends StatefulWidget {
  const FacilityOperationsScreen({super.key});

  @override
  State<FacilityOperationsScreen> createState() => _FacilityOperationsScreenState();
}

class _FacilityOperationsScreenState extends State<FacilityOperationsScreen> {
  final TextEditingController _intakeTokenCtrl = TextEditingController(text: 'REF-BAR-2026-0891');

  @override
  void dispose() {
    _intakeTokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facRepo = FacilityRepository();
    final refRepo = ReferralRepository();
    final facilities = facRepo.facilities;
    final facility = facilities.firstWhere((f) => f.id == 'FAC-SDH-301', orElse: () => facilities.first);

    return ListenableBuilder(
      listenable: Listenable.merge([facRepo, refRepo]),
      builder: (context, _) {
        final referrals = refRepo.referrals;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(facility.name, style: AppTypography.cardTitle),
                const Text('Facility Operations & Intake Desk', style: AppTypography.supporting),
              ],
            ),
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
                // 1. Bed Capacity Management Card
                _buildBedManagementCard(facility, facRepo),

                const SizedBox(height: 24),

                // 2. Inbound Urgent Referrals & Intake Queue
                const Text('Inbound referral queue', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                ...referrals.map((ref) => _buildReferralIntakeCard(context, ref, refRepo)),

                const SizedBox(height: 24),

                // 3. Fast-Track Arrival Token Scanner / Intake Entry
                _buildTokenIntakeCard(context, refRepo),

                const SizedBox(height: 24),

                // 4. Blood Bank & Critical Inventory Summary
                const Text('Critical facility supplies', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                _buildBloodBankCard(facility),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBedManagementCard(FacilityDto fac, FacilityRepository facRepo) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bed capacity & occupancy', style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.tealSoft),
                child: const Text(
                  'Live telemetry',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${fac.availableBeds} / ${fac.totalBeds}',
                    style: AppTypography.pageTitle.copyWith(color: RuralCareColors.primary),
                  ),
                  const Text('Vacant beds available', style: AppTypography.supporting),
                ],
              ),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: fac.availableBeds > 0
                        ? () => facRepo.updateAvailableBeds(fac.id, fac.availableBeds - 1)
                        : null,
                    icon: const Icon(Icons.remove, size: 20),
                    tooltip: 'Admit patient (-1 bed)',
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: fac.availableBeds < fac.totalBeds
                        ? () => facRepo.updateAvailableBeds(fac.id, fac.availableBeds + 1)
                        : null,
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Discharge patient (+1 bed)',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (fac.totalBeds - fac.availableBeds) / fac.totalBeds,
              minHeight: 8,
              backgroundColor: RuralCareColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(RuralCareColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralIntakeCard(BuildContext context, ReferralDto ref, ReferralRepository refRepo) {
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
              Text(ref.id, style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.warningSoft),
                child: Text(
                  ref.statusDisplay,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Patient: ${ref.patientName} • Re-routing from ${ref.referringFacilityName}', style: AppTypography.supporting),
          const SizedBox(height: 4),
          Text('Reason: ${ref.reasonSummary}', style: AppTypography.body),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                refRepo.updateStatus(ref.id, 'ACCEPTED');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Referral ${ref.id} accepted. Bed & clinical team reserved.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Accept & reserve bed'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenIntakeCard(BuildContext context, ReferralRepository refRepo) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fast-track arrival token check-in', style: AppTypography.cardTitle),
          const SizedBox(height: 6),
          const Text('Enter patient arrival token from mobile or scan QR pass.', style: AppTypography.supporting),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _intakeTokenCtrl,
                  decoration: const InputDecoration(hintText: 'Enter referral token...'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Token ${_intakeTokenCtrl.text} verified. Fast-track intake confirmed.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Check-in'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBloodBankCard(FacilityDto fac) {
    final bloodGroups = [
      {'group': 'A+', 'units': 8},
      {'group': 'B+', 'units': 12},
      {'group': 'O+', 'units': 15},
      {'group': 'AB+', 'units': 3},
      {'group': 'O-', 'units': 2}, // low stock
    ];

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Blood bank inventory', style: AppTypography.cardTitle),
              Text('Updated 1 hr ago', style: AppTypography.supporting),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: bloodGroups.map((b) {
              final units = b['units'] as int;
              final isLow = units < 4;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isLow ? RuralCareColors.criticalSoft : RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isLow ? RuralCareColors.critical.withOpacity(0.3) : RuralCareColors.border),
                ),
                child: Column(
                  children: [
                    Text(b['group'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      '$units units',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        color: isLow ? RuralCareColors.critical : RuralCareColors.textSecondary,
                        fontWeight: isLow ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
