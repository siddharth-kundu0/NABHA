import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/app/routes.dart';

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
        final currentLang = session.activeLanguage;

        if (referrals.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.stitchSurface,
            appBar: AppBar(title: const Text('Referral Progress')),
            body: const Center(child: Text('No active referrals.')),
          );
        }

        final referral = referrals.first;

        return Scaffold(
          backgroundColor: AppColors.stitchSurface,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: _buildStitchReferralHeader(context, session, currentLang),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Context Row (Back link + Token tag)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, size: 16, color: AppColors.stitchPrimary),
                            SizedBox(width: 4),
                            Text(
                              'Back to Referrals',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.stitchPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6EEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tag, size: 14, color: AppColors.slateNavy),
                          const SizedBox(width: 2),
                          Text(
                            referral.id,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.slateNavy),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Screen Heading
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLang == 'HI'
                          ? 'रेफरल प्रगति ट्रैकर'
                          : currentLang == 'MR'
                              ? 'संदर्भ प्रगती ट्रॅकर'
                              : 'Referral Progress',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutral900),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Icon(Icons.local_hospital_rounded, size: 14, color: AppColors.slateNavy),
                        SizedBox(width: 4),
                        Text(
                          'Track status and receiving facility updates',
                          style: TextStyle(fontSize: 11, color: AppColors.neutral600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Status Header Card (Elevation 1)
                _buildStatusHeaderCard(referral),
                const SizedBox(height: 14),

                // 4. Referral Pathway Stepper / Visual Timeline (5 Stages)
                _buildPathwayTimeline(context, referral, refRepo),
                const SizedBox(height: 14),

                // 5. Receiving Facility Context Card
                _buildFacilityContextCard(context, referral),
                const SizedBox(height: 14),

                // 6. Smart Matcher Rationale
                _buildSmartMatcherRationaleCard(referral),
                const SizedBox(height: 14),

                // 7. Fast-Track QR Pass Card
                _buildQrPassCard(referral),
                const SizedBox(height: 18),

                // 8. Primary Actions & Network Integrity Status
                _buildBottomActions(context, refRepo, referral),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStitchReferralHeader(
    BuildContext context,
    SessionCoordinator session,
    String currentLang,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stitchSurface.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.stitchPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sync_alt_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text('RuralCare', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.stitchPrimary)),
                          SizedBox(width: 4),
                          Text('• Referrals', style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
                        ],
                      ),
                      Text('Patient Portal', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_done, size: 13, color: Color(0xFF15803D)),
                        SizedBox(width: 3),
                        Text('Synced', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        _buildLangChip('EN', currentLang == 'English', () => session.switchLanguage('English')),
                        _buildLangChip('हि', currentLang == 'Hindi', () => session.switchLanguage('Hindi')),
                        _buildLangChip('म', currentLang == 'Marathi', () => session.switchLanguage('Marathi')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.stitchPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.slateNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeaderCard(ReferralDto referral) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
                    const SizedBox(width: 4),
                    Text(
                      referral.statusDisplay,
                      style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Text('Stage 3 of 5', style: TextStyle(color: AppColors.slateNavy, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Action Needed',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neutral900),
          ),
          const SizedBox(height: 2),
          Text(
            'Please proceed to ${referral.targetFacilityName} for specialist evaluation.',
            style: const TextStyle(fontSize: 11, color: AppColors.slateNavy),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.domain, size: 14, color: AppColors.slateNavy),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Receiving Facility: ${referral.targetFacilityName}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slateNavy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text('Expected Wait Time', style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
                  ],
                ),
                Text('Under 48 Hours', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathwayTimeline(BuildContext context, ReferralDto referral, ReferralRepository refRepo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timeline_rounded, size: 16, color: AppColors.slateNavy),
                  SizedBox(width: 4),
                  Text('REFERRAL PATHWAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.neutral900, letterSpacing: 0.5)),
                ],
              ),
              Text('Ref #${referral.id}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
            ],
          ),
          const SizedBox(height: 14),
          _buildTimelineStep(
            title: '✓ Referral Created',
            desc: 'Initiated by referring Primary Health Centre / ASHA.',
            date: 'Today',
            isCompleted: true,
            isActive: false,
            isLast: false,
          ),
          _buildTimelineStep(
            title: '✓ Referral Sent',
            desc: 'Receiving Facility: ${referral.targetFacilityName}. Pre-alert dispatched securely.',
            date: 'Today',
            isCompleted: true,
            isActive: false,
            isLast: false,
          ),
          _buildTimelineStep(
            title: '✓ Accepted by Receiving Facility',
            desc: '${referral.targetFacilityName} accepted the referral. Bed & Specialist standing by.',
            date: 'Now',
            isCompleted: true,
            isActive: true,
            isLast: false,
            actionButton: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.stitchPrimary,
                    content: Text('Appointment slot confirmed at Baramati SDH!'),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today, size: 14),
              label: const Text('Select Date Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stitchPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
          _buildTimelineStep(
            title: '○ Appointment / Visit',
            desc: 'Consultation with specialist and diagnostic intake.',
            date: 'Upcoming',
            isCompleted: false,
            isActive: false,
            isLast: false,
          ),
          _buildTimelineStep(
            title: '○ Referral Completed',
            desc: 'Outcome summary and post-visit down-referral care plan.',
            date: 'Upcoming',
            isCompleted: false,
            isActive: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String desc,
    required String date,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
    Widget? actionButton,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator & Line
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFEFF4FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  size: 14,
                  color: isCompleted ? Colors.white : AppColors.neutral600,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: isActive ? const EdgeInsets.all(10) : EdgeInsets.zero,
                decoration: isActive
                    ? BoxDecoration(
                        color: const Color(0xFFE0F2FE).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.stitchPrimary : AppColors.neutral900,
                            ),
                          ),
                        ),
                        Text(date, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.slateNavy)),
                    if (actionButton != null) ...[
                      const SizedBox(height: 8),
                      actionButton,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityContextCard(BuildContext context, ReferralDto referral) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFD5E3FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.domain_rounded, color: AppColors.stitchPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(referral.targetFacilityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutral900)),
                const Text('Civil Lines, Ward 4 • 24.5 km away', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.stitchPrimary,
                  content: Text('Calling ${referral.targetFacilityName} Helpdesk: 02112-224101'),
                ),
              );
            },
            icon: const Icon(Icons.call, color: AppColors.stitchPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartMatcherRationaleCard(ReferralDto referral) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF15803D), size: 16),
              SizedBox(width: 6),
              Text('Smart Routing Decision Rationale', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            referral.recommendationRationale,
            style: const TextStyle(fontSize: 10, color: Color(0xFF14532D), height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPassCard(ReferralDto referral) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Icon(Icons.qr_code_2_rounded, size: 36, color: AppColors.neutral900),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Intake QR Pass Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.neutral900)),
                Text('Scan at ${referral.targetFacilityName} reception gate for direct admission.', style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ReferralRepository refRepo, ReferralDto referral) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              refRepo.advanceStatus(referral.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.stitchPrimary,
                  content: Text('Appointment confirmed! Milestone advanced to in-transit.'),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Book Appointment Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stitchPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.slateNavy,
                  content: Text('Showing map directions to ${referral.targetFacilityName}...'),
                ),
              );
            },
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('View Receiving Facility Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.slateNavy,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
            SizedBox(width: 4),
            Text('Synced with healthcare network ✓', style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
