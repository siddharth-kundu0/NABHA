import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/doctor/utils/doctor_strings.dart';
import 'package:ruralcare/features/doctor/screens/doctor_clinical_summary_screen.dart';

/// Doctor Specialist Counter-Referral Desk
class DoctorReferralsTab extends StatefulWidget {
  const DoctorReferralsTab({super.key});

  @override
  State<DoctorReferralsTab> createState() => _DoctorReferralsTabState();
}

class _DoctorReferralsTabState extends State<DoctorReferralsTab> {
  int _tabIndex = 0; // 0 = Inbound Referrals, 1 = Outbound Tracking

  void _showCounterReferralDialog(BuildContext context, ReferralDto ref, ReferralRepository refRepo, DoctorStrings strings) {
    final instructionsCtrl = TextEditingController(
      text: 'Prescribed Tab Labetalol 100mg BD. ASHA to record daily morning BP. If BP > 160/100, immediate transfer.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.counterGuidanceTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient: ${ref.patientName}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              strings.frontlineGuidance,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: instructionsCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Actionable home visit instructions...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              refRepo.dispatchCounterReferral(
                referralId: ref.id,
                counterReferral: CounterReferralDto(
                  diagnosis: ref.reason,
                  treatmentProvided: 'Specialist consultation and clinical management.',
                  prescribedMedicines: const ['Prescribed discharge medications'],
                  followUpInstructions: instructionsCtrl.text.trim(),
                  warningSigns: const ['Fever > 101F', 'Persistent severe symptoms', 'Breathing difficulty'],
                  followUpDate: DateTime.now().add(const Duration(days: 7)),
                  reasonForReturn: 'Acute condition managed; returned for frontline care monitoring.',
                  receivingFacility: ref.referringFacility,
                  dispatchedAt: DateTime.now(),
                  dispatchedBy: 'Doctor In-Charge',
                ),
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(strings.isHi ? 'आशा कार्यकर्ता को जवाबी मार्गदर्शन भेजा गया!' : (strings.isMr ? 'आशा कार्यकर्त्याला मार्गदर्शन सूचना पाठवली!' : 'Counter-referral guidance dispatched to ASHA worker!')),
                  backgroundColor: RuralCareColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.teal),
            child: Text(strings.dispatchGuidance, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refRepo = ReferralRepository();
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([refRepo, session]),
      builder: (context, _) {
        final strings = DoctorStrings.of(session);
        final referrals = refRepo.referrals;

        final inboundReferrals = referrals
            .where((r) => r.targetFacilityId == 'FAC-SDH-301' || r.targetFacilityName.contains('Baramati'))
            .toList();
        final outboundReferrals = referrals
            .where((r) => r.referringFacility.contains('Baramati') || r.targetFacilityId == 'FAC-DH-401')
            .toList();

        final displayedList = _tabIndex == 0
            ? (inboundReferrals.isNotEmpty ? inboundReferrals : referrals)
            : outboundReferrals;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                strings.referralsTitle,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: RuralCareColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                strings.referralsSub,
                style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Segmented Tabs (Inbound vs Outbound)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0 ? RuralCareColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${strings.tabInbound} (${inboundReferrals.isNotEmpty ? inboundReferrals.length : referrals.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _tabIndex == 0 ? Colors.white : RuralCareColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1 ? RuralCareColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${strings.tabOutbound} (${outboundReferrals.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _tabIndex == 1 ? Colors.white : RuralCareColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Referral Cards
              if (displayedList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.swap_calls_rounded, size: 36, color: RuralCareColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        strings.isHi ? 'इस डेस्क में कोई रेफरल नहीं है' : (strings.isMr ? 'या डेस्कवर कोणतेही संदर्भ नाहीत' : 'No Referrals in this Desk'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.isHi ? 'इनबाउंड या आउटबाउंड टैब बदल कर देखें।' : (strings.isMr ? 'इनबाउंड किंवा आउटबाउंड टॅब निवडून पहा.' : 'Switch between Inbound and Outbound tabs to view transfers.'),
                        style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...displayedList.map((ref) {
                final patient = patientRepo.patients.firstWhere(
                  (p) => p.id == ref.patientId || p.fullName == ref.patientName,
                  orElse: () => PatientDto(
                    id: ref.patientId,
                    ruralCareId: 'RC-${ref.patientId}',
                    abhaId: 'ABHA-${ref.patientId}',
                    fullName: ref.patientName,
                    age: 35,
                    gender: 'Other',
                    phoneNumber: '9876543210',
                    village: 'Bilaspur',
                    subCentre: 'Sub-Centre',
                    district: 'District',
                    assignedAsha: 'ASHA Worker',
                    emergencyContact: const EmergencyContactDto(
                      name: 'Contact',
                      relationship: 'Family',
                      phoneNumber: '9876543210',
                    ),
                  ),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: RuralCareColors.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFFFEDD5),
                            child: Text(
                              ref.patientName.isNotEmpty ? ref.patientName[0] : 'R',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ref.patientName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                                ),
                                Text(
                                  'From: ${ref.referringFacility}',
                                  style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ref.urgency,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFC2410C)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: RuralCareColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason: ${ref.reason}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Referred to: ${ref.targetFacilityName}',
                              style: const TextStyle(fontSize: 11, color: RuralCareColors.teal, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (ref.counterReferralInstructions != null && ref.counterReferralInstructions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: RuralCareColors.success),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Counter-Referral: ${ref.counterReferralInstructions}',
                                  style: const TextStyle(fontSize: 11, color: RuralCareColors.success, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => DoctorClinicalSummaryScreen(patient: patient),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: RuralCareColors.teal,
                                side: const BorderSide(color: RuralCareColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(strings.openRecord, style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showCounterReferralDialog(context, ref, refRepo, strings),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RuralCareColors.teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                strings.isHi ? 'जवाबी मार्गदर्शन' : (strings.isMr ? 'मार्गदर्शन पाठवा' : 'Counter-Refer'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
