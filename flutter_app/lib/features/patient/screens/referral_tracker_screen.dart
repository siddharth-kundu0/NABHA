import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';

class ReferralTrackerScreen extends StatelessWidget {
  const ReferralTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final refRepo = ReferralRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Referral Tracker'),
        actions: [
          IconButton(
            tooltip: 'Advance Milestone (Demo)',
            icon: const Icon(Icons.fast_forward),
            onPressed: () {
              if (refRepo.referrals.isNotEmpty) {
                refRepo.advanceStatus(refRepo.referrals.first.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulated referral milestone progression.')),
                );
              }
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: refRepo,
        builder: (context, _) {
          final referrals = refRepo.referrals;
          if (referrals.isEmpty) {
            return const Center(child: Text('No active referrals.'));
          }

          final referral = referrals.first;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReferralHeaderCard(context, referral),
                const SizedBox(height: 16),
                _buildSmartMatcherRationaleCard(context, referral),
                const SizedBox(height: 16),
                _buildQrPassCard(context, referral),
                const SizedBox(height: 16),
                _buildMilestoneTimeline(context, referral),
                const SizedBox(height: 16),
                if (referral.counterReferralInstructions.isNotEmpty)
                  _buildCounterReferralCard(context, referral),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReferralHeaderCard(BuildContext context, ReferralDto referral) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referral.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.forestTealDark),
                    ),
                    Text(
                      'Patient: ${referral.patientName}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: referral.isOverdue ? AppColors.criticalRed.withOpacity(0.12) : AppColors.terracotta.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    referral.urgency,
                    style: TextStyle(
                      color: referral.isOverdue ? AppColors.criticalRed : AppColors.terracotta,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.arrow_forward_rounded, color: AppColors.forestTeal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Referred Destination:', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
                      Text(referral.targetFacilityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Clinical Indication: ${referral.reason}', style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartMatcherRationaleCard(BuildContext context, ReferralDto referral) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slateNavy.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateNavy.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.slateNavy, size: 18),
              SizedBox(width: 8),
              Text(
                'AI Smart Matching Decision Rationale',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateNavy, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            referral.recommendationRationale,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral800, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPassCard(BuildContext context, ReferralDto referral) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: const Icon(Icons.qr_code_2, size: 68, color: AppColors.slateNavy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fast-Track Triage Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text(
                    'Hospital triage desk scans this QR code to load the digital clinical file instantly.',
                    style: TextStyle(fontSize: 11, color: AppColors.neutral600),
                  ),
                  const SizedBox(height: 6),
                  Text('Token Code: ${referral.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestTealDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneTimeline(BuildContext context, ReferralDto referral) {
    final steps = [
      {'code': 'CREATED', 'title': 'Referral Initiated', 'desc': 'Raised by ASHA at Kashti Sub-Centre'},
      {'code': 'HOSPITAL_NOTIFIED', 'title': 'Hospital Pre-Alerted', 'desc': 'Baramati SDH triage desk confirmed readiness'},
      {'code': 'AMBULANCE_ASSIGNED', 'title': 'Ambulance 108 Dispatched', 'desc': 'Driver assigned • ETA 18 mins'},
      {'code': 'PATIENT_EN_ROUTE', 'title': 'Patient In Transit', 'desc': 'Continuous vital telemetry active'},
      {'code': 'PATIENT_ARRIVED', 'title': 'Patient Arrived', 'desc': 'Intake counter scanned QR pass'},
      {'code': 'ADMITTED', 'title': 'Admitted to Maternity Ward', 'desc': 'Specialist evaluation initiated'},
      {'code': 'TREATMENT_COMPLETED', 'title': 'Treatment Complete', 'desc': 'Patient stabilized & treated'},
      {'code': 'COUNTER_REFERRED', 'title': 'Counter-Referral Closed Loop', 'desc': 'Discharge care instructions synced back to ASHA'},
    ];

    final currentIndex = steps.indexWhere((s) => s['code'] == referral.status);
    final activeIdx = currentIndex == -1 ? 1 : currentIndex;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Referral Journey (8 Stages)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Step ${activeIdx + 1} of 8', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.forestTeal)),
              ],
            ),
            const Divider(height: 20),
            for (int i = 0; i < steps.length; i++) ...[
              _buildTimelineStep(
                title: steps[i]['title']!,
                subtitle: steps[i]['desc']!,
                isDone: i <= activeIdx,
                isCurrent: i == activeIdx,
                isLast: i == steps.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color iconColor;
    if (isCurrent) {
      iconColor = AppColors.terracotta;
    } else if (isDone) {
      iconColor = AppColors.forestTeal;
    } else {
      iconColor = AppColors.neutral400;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? iconColor : Colors.white,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : isCurrent
                      ? Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor))
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: isDone ? AppColors.forestTeal : AppColors.neutral300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                    color: isCurrent ? AppColors.terracotta : AppColors.neutral900,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterReferralCard(BuildContext context, ReferralDto referral) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_return, color: Color(0xFF047857), size: 20),
              SizedBox(width: 8),
              Text(
                'Counter-Referral Care Plan (Closed Loop)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            referral.counterReferralInstructions,
            style: const TextStyle(fontSize: 12, color: Color(0xFF064E3B), height: 1.4),
          ),
        ],
      ),
    );
  }
}
