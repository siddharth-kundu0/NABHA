import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/app/routes.dart';

/// Referral Tracker Screen strictly adhering to DESIGN.md Section 6:
/// Shows receiving facility, reason summary, current stage, and next action.
/// Vertical timeline: Created -> Sent -> Accepted -> Visit -> Completed -> Follow-up.
/// Pending milestone must not look completed. Clean arrival pass.
class ReferralTrackerScreen extends StatelessWidget {
  const ReferralTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final refRepo = ReferralRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([refRepo, session]),
      builder: (context, _) {
        final referrals = refRepo.referrals;
        final lang = session.activeLanguage;

        if (referrals.isEmpty) {
          return Scaffold(
            backgroundColor: RuralCareColors.canvas,
            appBar: AppBar(title: const Text('Referrals', style: AppTypography.pageTitle)),
            body: const Center(
              child: Text('No active referrals.', style: AppTypography.body),
            ),
          );
        }

        final referral = referrals.first;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            title: const Text('Referral details', style: AppTypography.pageTitle),
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
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
                // 1. Referral Overview Card
                _buildOverviewCard(referral, lang),

                const SizedBox(height: 24),

                // 2. Timeline Heading
                const Text('Referral progress', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),

                // 3. Vertical Timeline: Created -> Sent -> Accepted -> Visit -> Completed -> Follow-up
                _buildVerticalTimeline(referral),

                const SizedBox(height: 24),

                // 4. Digital Arrival Pass
                _buildArrivalPass(referral, context),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(ReferralDto ref, String lang) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ref.id,
                style: AppTypography.supporting.copyWith(
                  fontWeight: FontWeight.w600,
                  color: RuralCareColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(
                  background: RuralCareColors.primarySoft,
                ),
                child: Text(
                  ref.statusDisplay,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: RuralCareColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ref.targetFacilityName,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Referred from: ${ref.referringFacilityName}',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: ${ref.reasonSummary}',
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }

  /// 6-stage vertical timeline per DESIGN.md Section 6:
  /// Created -> Sent -> Accepted -> Visit -> Completed -> Follow-up
  Widget _buildVerticalTimeline(ReferralDto ref) {
    final stages = [
      {'title': 'Referral created', 'desc': 'Initiated by Kashti Sub-Centre ASHA / CHO', 'stage': 1},
      {'title': 'Clinical dossier sent', 'desc': 'Dispatched with vitals and FHIR telemetry', 'stage': 2},
      {'title': 'Accepted by facility', 'desc': 'Obstetrics bed reserved at Baramati SDH', 'stage': 3},
      {'title': 'Facility in-person visit', 'desc': 'Present arrival pass at hospital reception', 'stage': 4},
      {'title': 'Consultation completed', 'desc': 'Specialist evaluation and management', 'stage': 5},
      {'title': 'Follow-up care plan', 'desc': 'Counter-referral instructions to ASHA', 'stage': 6},
    ];

    final currentStage = ref.currentStage; // 1 to 6

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(stages.length, (idx) {
          final item = stages[idx];
          final stageNum = item['stage'] as int;
          final isCompleted = stageNum < currentStage;
          final isCurrent = stageNum == currentStage;
          final isPending = stageNum > currentStage;
          final isLast = idx == stages.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator column
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? RuralCareColors.success
                            : (isCurrent ? RuralCareColors.primary : RuralCareColors.surfaceSubtle),
                        border: Border.all(
                          color: isCompleted
                              ? RuralCareColors.success
                              : (isCurrent ? RuralCareColors.primary : RuralCareColors.border),
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : (isCurrent
                                ? const Text('•', style: TextStyle(color: Colors.white, fontSize: 18, height: 1))
                                : Text('$stageNum', style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary))),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted ? RuralCareColors.success : RuralCareColors.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Text details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                            color: isPending ? RuralCareColors.textSecondary : RuralCareColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['desc'] as String,
                          style: AppTypography.supporting.copyWith(
                            color: isPending ? RuralCareColors.textSecondary.withOpacity(0.7) : RuralCareColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildArrivalPass(ReferralDto ref, BuildContext context) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fast-track arrival pass', style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.tealSoft),
                child: const Text(
                  'Valid today',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Present this token at Baramati SDH triage desk to bypass standard registration queue.',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RuralCareColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 96, color: RuralCareColors.textPrimary),
                const SizedBox(height: 8),
                Text(
                  'TOKEN: ${ref.id}-PRIORITY-ANC',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: RuralCareColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
