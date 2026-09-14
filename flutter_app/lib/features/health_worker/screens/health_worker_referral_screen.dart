import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'health_worker_followup_screen.dart';

class HealthWorkerReferralScreen extends StatefulWidget {
  const HealthWorkerReferralScreen({super.key});

  @override
  State<HealthWorkerReferralScreen> createState() => _HealthWorkerReferralScreenState();
}

class _HealthWorkerReferralScreenState extends State<HealthWorkerReferralScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refRepo = ReferralRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([refRepo, cache, session]),
      builder: (context, _) {
        final allReferrals = refRepo.referrals;
        final actionRequiredList = allReferrals.where((r) =>
            r.status == 'CREATED' ||
            r.status == 'REFERRED' ||
            r.status == 'HOSPITAL_NOTIFIED' ||
            r.status == 'TRIAGED').toList();

        final acceptedList = allReferrals.where((r) =>
            r.status == 'ACCEPTED' ||
            r.status == 'IN_TRANSIT' ||
            r.status == 'ARRIVED' ||
            r.status == 'ADMITTED').toList();

        List<ReferralDto> displayedReferrals = allReferrals;
        if (_selectedFilter == 'Action Required') {
          displayedReferrals = actionRequiredList;
        } else if (_selectedFilter == 'Accepted') {
          displayedReferrals = acceptedList;
        }

        final primaryReferral = displayedReferrals.isNotEmpty ? displayedReferrals.first : null;
        final secondaryReferrals = displayedReferrals.skip(1).toList();
        final isHi = session.isHindi;
        final isMr = session.isMarathi;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Offline Ready Strip matching Stitch Screen 5
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.skyBlueSoft.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 16, color: AppColors.navyBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isHi
                            ? 'ऑफ़लाइन तैयार • स्थानीय रूप से समन्वयित'
                            : (isMr
                                ? 'ऑफलाइन तयार • स्थानिक पातळीवर समक्रमित'
                                : 'Offline Ready • Referral tracking synced locally'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.navyBlue),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isHi ? 'लाइव सिंक' : (isMr ? 'थेट समक्रमण' : 'Live Sync'),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.forestTeal),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Title & Catchment Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.forestTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHi ? 'रेफरल समन्वय' : (isMr ? 'संदर्भ समन्वय' : 'Referral Coordination'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHi
                              ? 'रेफरल समन्वय एवं प्रगति ट्रैकिंग'
                              : (isMr ? 'संदर्भ समन्वय आणि प्रगती ट्रॅकिंग' : 'Referral coordination & tracking'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.forestTeal),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHi
                              ? 'उच्च सुविधाओं के लिए मरीज़ रेफरल को ट्रैक और समन्वयित करें'
                              : (isMr
                                  ? 'उच्च सुविधांसाठी रुग्ण संदर्भ ट्रॅक आणि समन्वयित करा'
                                  : 'Track and coordinate patient referrals to higher facilities'),
                          style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Filter Chips (All, Action Required, Accepted)
              Row(
                children: [
                  _filterChip(isHi ? 'सभी (${allReferrals.length})' : (isMr ? 'सर्व (${allReferrals.length})' : 'All (${allReferrals.length})'), 'All'),
                  const SizedBox(width: 8),
                  _filterChip(isHi ? '● कार्रवाई आवश्यक (${actionRequiredList.length})' : (isMr ? '● कृती आवश्यक (${actionRequiredList.length})' : '● Action Required (${actionRequiredList.length})'), 'Action Required', isAlert: true),
                  const SizedBox(width: 8),
                  _filterChip(isHi ? 'स्वीकृत (${acceptedList.length})' : (isMr ? 'स्वीकृत (${acceptedList.length})' : 'Accepted (${acceptedList.length})'), 'Accepted'),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Primary Active Referral Tracking Card
              if (primaryReferral != null)
                _buildActiveReferralCard(context, refRepo, primaryReferral)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.neutral300),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.swap_calls_rounded, size: 36, color: AppColors.slateGray),
                      const SizedBox(height: 8),
                      Text(
                        isHi ? 'इस श्रेणी में कोई रेफरल नहीं है' : (isMr ? 'या श्रेणीत कोणतेही संदर्भ नाहीत' : 'No Referrals in this Category'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHi ? 'अन्य फिल्टर चुनकर रेफरल देखें।' : (isMr ? 'इतर फिल्टर निवडून संदर्भ पहा.' : 'Select another filter to view active referrals.'),
                        style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                      ),
                    ],
                  ),
                ),

              // 5. Other Active Referrals Section
              if (secondaryReferrals.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHi ? 'अन्य सक्रिय रेफरल' : (isMr ? 'इतर सक्रिय संदर्भ' : 'Other Active Referrals'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedFilter = 'All'),
                      child: Text(
                        isHi ? 'सभी देखें' : (isMr ? 'सर्व पहा' : 'View All'),
                        style: const TextStyle(fontSize: 12, color: AppColors.forestTeal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...secondaryReferrals.map((r) => _buildSecondaryReferralRow(context, r)),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String val, {bool isAlert = false}) {
    final isSelected = _selectedFilter == val;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = val),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isAlert ? AppColors.forestTealDark : AppColors.forestTeal) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.neutral300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.slateGray,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveReferralCard(BuildContext context, ReferralRepository repo, ReferralDto ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2), // Warm sandstone card background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBCE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Patient & Referral ID
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.forestTeal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  ref.patientName.isNotEmpty ? ref.patientName[0] : 'P',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.forestTealDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ref.patientName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Priority', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Rampur Village • PHC Rampur', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ref.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
                  const Text('PHC Rampur', style: TextStyle(fontSize: 10, color: AppColors.slateGray)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Originating Doctor & Indication Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.event_note_outlined, size: 12, color: AppColors.forestTeal),
                        SizedBox(width: 4),
                        Text('Initiated: 11 Oct 2024', style: TextStyle(fontSize: 10, color: AppColors.slateGray)),
                      ],
                    ),
                    Text(
                      ref.doctorName.isNotEmpty ? ref.doctorName : '${DoctorRepository().getDoctorForSession(SessionCoordinator()).name} (${DoctorRepository().getDoctorForSession(SessionCoordinator()).facilityName})',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ref.reason,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                ),
                const SizedBox(height: 2),
                const Text(
                  'उच्च रक्तचाप मूल्यांकन एवं ईसीजी समीक्षा',
                  style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Destination Facility Card with Phone Dialer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF7F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBCE3DA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_outlined, size: 20, color: AppColors.forestTealDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.targetFacilityName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.forestTealDark),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Cardiology OPD Desk - Room 14',
                        style: TextStyle(fontSize: 10, color: AppColors.forestTeal),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.forestTealDark),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${ref.targetFacilityName} referral desk...')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Referral Track (Step 4 of 5) matching Stitch Screen 5
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Referral Track / प्रगति चक्र', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.skyBlueSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Step 4 of 5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 5-Stage Stepper
          _stepperStep(number: 1, title: '1. Referral Created', subtitle: 'Handed by ${ref.doctorName.isNotEmpty ? ref.doctorName : DoctorRepository().getDoctorForSession(SessionCoordinator()).name}', isDone: true),
          _stepperStep(number: 2, title: '2. Sent to Facility', subtitle: '11 Oct 16:40 • Tele-consult registry', isDone: true),
          _stepperStep(number: 3, title: '3. Accepted by Facility', subtitle: '12 Oct • Bilaspur Central OPD Desk', isDone: true, badge: 'Confirmed'),
          _stepperStep(number: 4, title: '4. Appointment & Visit', subtitle: 'Scheduled for Friday, 18 Oct 2024\nField follow-up reminder pending', isCurrent: true),
          _stepperStep(number: 5, title: '5. Completed', subtitle: 'Post-visit counter-referral slip upload', isPending: true),

          const SizedBox(height: 16),

          // HW Coordination Checklist matching Stitch Screen 5
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.checklist_rtl_rounded, size: 16, color: AppColors.forestTeal),
                        SizedBox(width: 6),
                        Text('HW Coordination Checklist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                      ],
                    ),
                    Text(
                      '${ref.checklistDone.where((e) => e).length} / ${ref.checklistDone.length} Done',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestTeal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _checklistCheckbox(
                  repo: repo,
                  refId: ref.id,
                  index: 0,
                  value: ref.checklistDone.isNotEmpty ? ref.checklistDone[0] : true,
                  title: 'Patient briefed on facility location & required papers',
                  subtitle: 'अस्पताल का पता व आवश्यक कागज़ात की जानकारी दी गई',
                ),
                _checklistCheckbox(
                  repo: repo,
                  refId: ref.id,
                  index: 1,
                  value: ref.checklistDone.length > 1 ? ref.checklistDone[1] : true,
                  title: 'Medical summary slip handed over',
                  subtitle: 'क्लिनिकल पर्ची व सारांश रिपोर्ट सुपुर्द की गई',
                ),
                _checklistCheckbox(
                  repo: repo,
                  refId: ref.id,
                  index: 2,
                  value: ref.checklistDone.length > 2 ? ref.checklistDone[2] : false,
                  title: 'Appointment reminder call scheduled (Pending)',
                  subtitle: 'भेंट से पूर्व सूचना कॉल (17 अक्टूबर को देय)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recent Coordination Notes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: AppColors.forestTeal),
                  SizedBox(width: 6),
                  Text('Recent Coordination Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                ],
              ),
              Text('${ref.coordinationNotes.length} Note', style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
            ],
          ),

          const SizedBox(height: 8),

          ...ref.coordinationNotes.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Text(n, style: const TextStyle(fontSize: 11, color: AppColors.darkSlate, height: 1.3)),
              )),

          // Inline Add Note Input
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neutral300),
                  ),
                  child: TextField(
                    controller: _noteCtrl,
                    style: const TextStyle(fontSize: 11),
                    decoration: const InputDecoration(
                      hintText: 'Type new coordination note...',
                      hintStyle: TextStyle(fontSize: 10, color: AppColors.slateGray),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    final text = _noteCtrl.text.trim();
                    if (text.isNotEmpty) {
                      repo.addCoordinationNote(ref.id, 'Kavita Verma (ASHA): $text');
                      _noteCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coordination note saved')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestTealDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Add Note', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Primary Action Button: Coordinate Follow-up with Patient
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (c) => HealthWorkerFollowUpScreen(patientId: ref.patientId),
                  ),
                );
              },
              icon: const Icon(Icons.phone_forwarded_outlined, color: Colors.white, size: 18),
              label: const Text(
                'Coordinate Follow-up with Patient',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestTealDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    repo.advanceStatus(ref.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral escalation logged with SDH')),
                    );
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Escalate Referral',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening clinical summary for ${ref.patientName}...')),
                    );
                  },
                  icon: const Icon(Icons.assignment_outlined, size: 14, color: AppColors.forestTeal),
                  label: const Text(
                    'Care Summary',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestTeal),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.forestTeal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperStep({
    required int number,
    required String title,
    required String subtitle,
    bool isDone = false,
    bool isCurrent = false,
    bool isPending = false,
    String? badge,
  }) {
    Color iconBg = AppColors.neutral200;
    Color iconColor = AppColors.slateGray;
    IconData icon = Icons.circle_outlined;

    if (isDone) {
      iconBg = const Color(0xFF10B981);
      iconColor = Colors.white;
      icon = Icons.check_rounded;
    } else if (isCurrent) {
      iconBg = const Color(0xFF38BDF8);
      iconColor = Colors.white;
      icon = Icons.autorenew_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPending ? AppColors.slateGray : AppColors.darkSlate,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isCurrent ? const Color(0xFFC2410C) : AppColors.slateGray,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistCheckbox({
    required ReferralRepository repo,
    required String refId,
    required int index,
    required bool value,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => repo.toggleChecklistItem(refId, index, !value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: value ? AppColors.forestTealDark : AppColors.slateGray,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: value ? TextDecoration.lineThrough : null,
                      color: value ? AppColors.slateGray : AppColors.darkSlate,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9, color: AppColors.slateGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryReferralRow(BuildContext context, ReferralDto r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.skyBlueSoft,
            radius: 18,
            child: Text(
              r.patientName.isNotEmpty ? r.patientName[0] : 'P',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.patientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                const SizedBox(height: 2),
                Text('${r.reason} • ${r.targetFacilityName}', style: const TextStyle(fontSize: 10, color: AppColors.slateGray), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Action Due', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
          ),
        ],
      ),
    );
  }
}
