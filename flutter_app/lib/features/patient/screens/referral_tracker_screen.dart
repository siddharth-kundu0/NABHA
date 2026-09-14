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
            title: Text(
              session.isHindi ? 'रेफरल विवरण' : (session.isMarathi ? 'संदर्भ तपशील' : 'Referral details'),
              style: AppTypography.pageTitle,
            ),
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
                _buildOverviewCard(referral, session),

                const SizedBox(height: 16),

                // 1b. Assigned Specialist & 108 Ambulance Transit
                _buildAssignedSpecialistAndAmbulanceCard(referral, session, context),

                const SizedBox(height: 24),

                // 2. Timeline Heading
                Text(
                  session.isHindi ? 'रेफरल प्रगति' : (session.isMarathi ? 'संदर्भ प्रगती' : 'Referral progress'),
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: 12),

                // 3. Vertical Timeline: Created -> Sent -> Accepted -> Visit -> Completed -> Follow-up
                _buildVerticalTimeline(referral, session),

                const SizedBox(height: 24),

                // 4. Digital Arrival Pass
                _buildArrivalPass(referral, context, session),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(ReferralDto ref, SessionCoordinator session) {
    final fromPrefix = session.isHindi ? 'रेफरल स्रोत: ' : (session.isMarathi ? 'संदर्भ स्रोत: ' : 'Referred from: ');
    final reasonPrefix = session.isHindi ? 'कारण: ' : (session.isMarathi ? 'कारण: ' : 'Reason: ');

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
            '$fromPrefix${ref.referringFacilityName}',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 8),
          Text(
            '$reasonPrefix${ref.reasonSummary}',
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedSpecialistAndAmbulanceCard(ReferralDto ref, SessionCoordinator session, BuildContext context) {
    final isHi = session.isHindi;
    final isMr = session.isMarathi;

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF005140).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Color(0xFF005140), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMr ? 'नियुक्त तज्ज्ञ व रुग्णवाहिका' : (isHi ? 'नामित विशेषज्ञ व एम्बुलेंस' : 'Assigned Specialist & Transit'),
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ref.targetFacilityName} • Reserved Bed #04',
                      style: AppTypography.supporting,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isMr ? 'बेड आरक्षित' : (isHi ? 'बेड आरक्षित' : 'Bed Reserved'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Doctor Info
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE8F5F2),
                child: Icon(Icons.person, color: Color(0xFF005140), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dr. Neha Kulkarni, MD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      isMr ? 'स्त्रीरोग व प्रसूती तज्ज्ञ (OB/GYN)' : (isHi ? 'स्त्री रोग विशेषज्ञ (OB/GYN)' : 'Obstetrician & High-Risk Care Specialist'),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 108 Ambulance Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emergency_rounded, color: Color(0xFFC05621), size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '108 Emergency Ambulance Dispatched',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF9A3412)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pilot: Santosh Jadhav • MH-12-RN-1082 • ETA: 14 Mins',
                        style: TextStyle(fontSize: 11, color: Color(0xFFC05621)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Color(0xFFC05621), size: 18),
                  tooltip: 'Call 108 Driver',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling 108 Ambulance Driver Santosh Jadhav...')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 6-stage vertical timeline per DESIGN.md Section 6:
  /// Created -> Sent -> Accepted -> Visit -> Completed -> Follow-up
  Widget _buildVerticalTimeline(ReferralDto ref, SessionCoordinator session) {
    final isHi = session.isHindi;
    final isMr = session.isMarathi;

    final stages = [
      {
        'title': isHi ? 'रेफरल बनाया गया' : (isMr ? 'संदर्भ तयार केला' : 'Referral created'),
        'desc': isHi ? 'काष्टी उप-केंद्र आशा / सीएचओ द्वारा प्रारंभ' : (isMr ? 'काष्टी उपकेंद्र आशा / सीएचओ द्वारे सुरू' : 'Initiated by Kashti Sub-Centre ASHA / CHO'),
        'stage': 1,
      },
      {
        'title': isHi ? 'क्लिनिकल डोजियर भेजा गया' : (isMr ? 'वैद्यकीय माहिती पाठवली' : 'Clinical dossier sent'),
        'desc': isHi ? 'वाइटल्स और टेलीमेट्री के साथ भेजा गया' : (isMr ? 'व्हायटल्स आणि टेलिमेट्रीसह पाठवले' : 'Dispatched with vitals and FHIR telemetry'),
        'stage': 2,
      },
      {
        'title': isHi ? 'अस्पताल द्वारा स्वीकृत' : (isMr ? 'रुग्णालयाने स्वीकारले' : 'Accepted by facility'),
        'desc': isHi ? 'बारामती एसडीएच में प्रसूति बिस्तर आरक्षित' : (isMr ? 'बारामती उपजिल्हा रुग्णालयात प्रसूती बेड आरक्षित' : 'Obstetrics bed reserved at Baramati SDH'),
        'stage': 3,
      },
      {
        'title': isHi ? 'अस्पताल आगमन एवं चेक-इन' : (isMr ? 'रुग्णालयात प्रत्यक्ष भेट' : 'Facility in-person visit'),
        'desc': isHi ? 'अस्पताल स्वागत कक्ष पर अराइवल पास प्रस्तुत करें' : (isMr ? 'स्वागत कक्षात अरायव्हल पास दाखवा' : 'Present arrival pass at hospital reception'),
        'stage': 4,
      },
      {
        'title': isHi ? 'परामर्श पूर्ण हुआ' : (isMr ? 'सल्लामसलत पूर्ण झाली' : 'Consultation completed'),
        'desc': isHi ? 'विशेषज्ञ मूल्यांकन और उपचार' : (isMr ? 'तज्ज्ञ तपासणी आणि उपचार' : 'Specialist evaluation and management'),
        'stage': 5,
      },
      {
        'title': isHi ? 'फॉलो-अप देखभाल योजना' : (isMr ? 'फॉलो-अप काळजी योजना' : 'Follow-up care plan'),
        'desc': isHi ? 'आशा कार्यकर्ता को प्रति-संदर्भ निर्देश' : (isMr ? 'आशा सेविकेला प्रति-संदर्भ सूचना' : 'Counter-referral instructions to ASHA'),
        'stage': 6,
      },
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

  Widget _buildArrivalPass(ReferralDto ref, BuildContext context, SessionCoordinator session) {
    final isHi = session.isHindi;
    final isMr = session.isMarathi;

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
                isHi ? 'फास्ट-ट्रैक अराइवल पास' : (isMr ? 'फास्ट-ट्रॅक अरायव्हल पास' : 'Fast-track arrival pass'),
                style: AppTypography.cardTitle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.tealSoft),
                child: Text(
                  isHi ? 'आज मान्य' : (isMr ? 'आज वैध' : 'Valid today'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isHi
                ? 'सामान्य पंजीकरण कतार से बचने के लिए बारामती एसडीएच ट्राइएज डेस्क पर यह टोकन प्रस्तुत करें।'
                : (isMr
                    ? 'नोंदणी रांग टाळण्यासाठी बारामती उपजिल्हा रुग्णालय ट्रायज डेस्कवर हा टोकन दाखवा.'
                    : 'Present this token at Baramati SDH triage desk to bypass standard registration queue.'),
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
