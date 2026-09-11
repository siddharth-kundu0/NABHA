import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';

/// Pixel-Perfect realization of Stitch Screen 1: Doctor Dashboard (70eda21ad5234c67ba2d2fa84a73cb39)
/// & Screen 4: Consultation & Care Plan (d66b6f7bbf7f49c4a0eaa5321bace718)
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final TextEditingController _rxMedicineCtrl = TextEditingController(text: 'Tab. Labetalol 100mg');
  final TextEditingController _rxDosageCtrl = TextEditingController(text: '100 mg');
  final TextEditingController _rxFrequencyCtrl = TextEditingController(text: '1-0-1 (Twice daily after food)');
  final TextEditingController _rxDaysCtrl = TextEditingController(text: '14');
  final TextEditingController _counterNotesCtrl = TextEditingController(
    text: 'Administer Tab Labetalol 100mg BD. Monitor daily BP at Kashti Sub-Centre with ASHA Sunita Tai. Review in 7 days.',
  );

  @override
  void dispose() {
    _rxMedicineCtrl.dispose();
    _rxDosageCtrl.dispose();
    _rxFrequencyCtrl.dispose();
    _rxDaysCtrl.dispose();
    _counterNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final aptRepo = AppointmentRepository();
    final refRepo = ReferralRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, aptRepo, refRepo]),
      builder: (context, _) {
        final appointments = aptRepo.appointments;
        final patient = patientRepo.defaultPatient;

        return Scaffold(
          backgroundColor: AppColors.stitchSurface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.stitchOnSurface,
            elevation: 1,
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: AppColors.slateNavy.withOpacity(0.12),
                      child: const Icon(Icons.medical_services_rounded, color: AppColors.slateNavy, size: 22),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 8, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Anjali Deshmukh (MD OB/GYN)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.stitchOnSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Baramati SDH • Tele-OPD Room 4',
                        style: TextStyle(fontSize: 10, color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF16A34A), size: 8),
                    SizedBox(width: 4),
                    Text('ON DUTY', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Switch Role (Demo)',
                icon: const Icon(Icons.switch_account_rounded, color: AppColors.slateNavy),
                onPressed: () => DemoRoleSwitcher.show(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4 Metric Overview Cards
                _buildDoctorMetrics(context, appointments.length),
                const SizedBox(height: 16),

                // 4 Quick Clinical Action Shortcuts
                _buildSectionHeader('Quick Clinical Actions', 'त्वरित कार्य'),
                const SizedBox(height: 8),
                _buildQuickActionShortcuts(context),
                const SizedBox(height: 18),

                // Today's Teleconsultation Schedule & Queue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader("Today's Tele-OPD Queue", 'आजची कतार'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.stitchPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${appointments.length} Waiting',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.stitchPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...appointments.map((apt) => _buildQueueCard(context, apt, patient)),

                const SizedBox(height: 20),

                // Digital E-Prescription Builder (ABHA FHIR)
                _buildSectionHeader('Digital E-Prescription Builder (ABHA FHIR)', 'ई-प्रिस्क्रिप्शन जनरेटर'),
                const SizedBox(height: 10),
                _buildPrescriptionBuilderCard(context, aptRepo, patient),

                const SizedBox(height: 20),

                // Counter-Referral Generator (Down-Referral)
                _buildSectionHeader('Counter-Referral Care Plan (Closed Loop To ASHA)', 'परत संदर्भ सूचना'),
                const SizedBox(height: 10),
                _buildCounterReferralCard(context, refRepo),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String english, String devanagari) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(english, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slateNavy)),
        const SizedBox(width: 6),
        Text('• $devanagari', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
      ],
    );
  }

  /// 4 Metric Cards matching Stitch Doctor Dashboard
  Widget _buildDoctorMetrics(BuildContext context, int queueCount) {
    return Row(
      children: [
        _metricCard('Total Tele-OPD', '14', Icons.video_call_rounded, AppColors.stitchPrimary, AppColors.stitchPrimary.withOpacity(0.12)),
        const SizedBox(width: 8),
        _metricCard('Waiting Queue', '$queueCount', Icons.checklist_rounded, const Color(0xFFB45309), const Color(0xFFFEF3C7)),
        const SizedBox(width: 8),
        _metricCard('In-Person OP', '7', Icons.local_hospital_rounded, AppColors.slateNavy, AppColors.stitchSurfaceContainer),
        const SizedBox(width: 8),
        _metricCard('Pending Ref.', '3', Icons.alt_route_rounded, AppColors.criticalRed, const Color(0xFFFFDAD6)),
      ],
    );
  }

  Widget _metricCard(String title, String count, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200, width: 0.8),
          boxShadow: const [
            BoxShadow(color: Color(0x050D1C2E), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: color),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
                  child: Text(count, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.neutral700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 4 Quick Clinical Action Shortcuts matching Stitch Screen 1
  Widget _buildQuickActionShortcuts(BuildContext context) {
    return Row(
      children: [
        _shortcutButton(Icons.checklist_rounded, 'Queue', 'कतार', AppColors.stitchPrimary, () {}),
        const SizedBox(width: 8),
        _shortcutButton(Icons.person_search_rounded, 'Search', 'शोध', AppColors.slateNavy, () {}),
        const SizedBox(width: 8),
        _shortcutButton(Icons.event_available_rounded, 'Follow-ups', 'फॉलो-अप', const Color(0xFF0D9488), () {}),
        const SizedBox(width: 8),
        _shortcutButton(Icons.call_split_rounded, 'Referrals', 'रेफरल', const Color(0xFFB45309), () {}),
      ],
    );
  }

  Widget _shortcutButton(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral200, width: 0.8),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
              Text(sub, style: const TextStyle(fontSize: 8, color: AppColors.neutral600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueCard(BuildContext context, AppointmentDto apt, PatientDto patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.neutral200, width: 0.8),
      ),
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
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🔴 HIGH-RISK ANC REFERRAL',
                    style: TextStyle(color: AppColors.criticalRed, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  apt.status,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.forestTealDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(apt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('Age 26 • 32 Wks Gestation • Village: Kashti', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.stitchSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.neutral200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telemetry Vitals: BP ${patient.latestVitals?.systolicBp}/${patient.latestVitals?.diastolicBp} mmHg | Hb ${patient.latestVitals?.haemoglobin} g/dL | SpO2 ${patient.latestVitals?.spO2}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text('Chief Complaint: ${apt.chiefComplaint}', style: const TextStyle(fontSize: 10, color: AppColors.neutral700)),
                  Text('Assisted by ASHA: ${patient.assignedAsha}', style: const TextStyle(fontSize: 10, color: AppColors.forestTealDark)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => LiveTeleconsultRoomScreen(
                        patientName: apt.patientName,
                        doctorName: apt.doctorName,
                        specialty: apt.specialty,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.video_camera_front_rounded, size: 18),
                label: const Text('Start Video Consultation / कॉल सुरू करा', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stitchPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionBuilderCard(BuildContext context, AppointmentRepository aptRepo, PatientDto patient) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.neutral200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _rxMedicineCtrl,
              decoration: const InputDecoration(
                labelText: 'Medicine Name & Formulation',
                prefixIcon: Icon(Icons.medication, color: AppColors.forestTeal),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rxDosageCtrl,
                    decoration: const InputDecoration(labelText: 'Strength / Dosage'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _rxDaysCtrl,
                    decoration: const InputDecoration(labelText: 'Duration (Days)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rxFrequencyCtrl,
              decoration: const InputDecoration(labelText: 'Timing / Frequency (e.g. 1-0-1 After Food)'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  aptRepo.addPrescription(
                    PrescriptionDto(
                      id: 'rx-${DateTime.now().millisecondsSinceEpoch}',
                      patientId: patient.id,
                      doctorName: 'Dr. Anjali Deshmukh (OB/GYN)',
                      issuedAt: DateTime.now(),
                      diagnosis: '32-Week Gestational Hypertension with Pre-Eclampsia risk',
                      medicines: [
                        PrescriptionItemDto(
                          medicineName: _rxMedicineCtrl.text.trim(),
                          dosage: _rxDosageCtrl.text.trim(),
                          frequency: _rxFrequencyCtrl.text.trim(),
                          durationDays: int.tryParse(_rxDaysCtrl.text.trim()) ?? 14,
                        ),
                      ],
                      adviceNotes: 'Bed rest, low salt diet, daily BP check with ASHA.',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.stitchPrimary,
                      content: Text('Prescription issued & synced to Patient ABHA PHR!'),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Issue E-Prescription & Sync ABHA PHR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stitchPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterReferralCard(BuildContext context, ReferralRepository refRepo) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.neutral200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Down-Referral Instructions for Kashti Sub-Centre ASHA & CHO:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slateNavy),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _counterNotesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter care plan, follow-up schedule and danger signs to monitor...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (refRepo.referrals.isNotEmpty) {
                    refRepo.addCounterReferral(refRepo.referrals.first.id, _counterNotesCtrl.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.stitchPrimary,
                        content: Text('Counter-Referral instructions dispatched back to Sub-Centre!'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Dispatch Counter-Referral to ASHA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.slateNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
