import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';

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
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Specialist Tele-OPD Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text('Dr. Anjali Patil, MD (OB/GYN) • Baramati SDH', style: TextStyle(fontSize: 12, color: AppColors.forestTealLight)),
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
                // Doctor Status Banner
                _buildDoctorHeader(context),
                const SizedBox(height: 16),

                // Active Teleconsult Queue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Teleconsultation Queue (${appointments.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.forestTealLight.withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Live OPD Online', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.forestTealDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...appointments.map((apt) => _buildQueueCard(context, apt, patient)),

                const SizedBox(height: 20),

                // E-Prescription Builder
                Text('Digital E-Prescription Builder (ABHA FHIR)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
                const SizedBox(height: 8),
                _buildPrescriptionBuilderCard(context, aptRepo, patient),

                const SizedBox(height: 20),

                // Counter-Referral Generator (Down-Referral)
                Text('Counter-Referral Generator (Closed Loop To ASHA)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
                const SizedBox(height: 8),
                _buildCounterReferralCard(context, refRepo),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAntiGlare,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.slateNavy,
            radius: 22,
            child: Icon(Icons.medical_information, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Specialist on Duty', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
                Text('Dr. Anjali Patil (OB/GYN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Baramati Sub-District Hospital • OPD Chamber 4', style: TextStyle(fontSize: 11, color: AppColors.slateNavy)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF16A34A), size: 8),
                SizedBox(width: 4),
                Text('Available', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(BuildContext context, AppointmentDto apt, dynamic patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: AppColors.terracotta.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('🔴 HIGH-RISK REFERRAL', style: TextStyle(color: AppColors.terracotta, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(
                  apt.status,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.forestTealDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(apt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Age 26 • 32 Wks Gestation • Village: Kashti', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surfaceAntiGlare, borderRadius: BorderRadius.circular(6)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Telemetry Vitals: BP ${patient.latestVitals?.systolicBp}/${patient.latestVitals?.diastolicBp} mmHg | Hb ${patient.latestVitals?.haemoglobin} g/dL | SpO2 ${patient.latestVitals?.spO2}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Assisted by ASHA: ${patient.assignedAsha}', style: const TextStyle(fontSize: 10, color: AppColors.neutral700)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showClinicalHistoryModal(context, patient),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Clinical History', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => LiveTeleconsultRoomScreen(
                            patientName: apt.patientName,
                            doctorName: 'Dr. Anjali Patil',
                            specialty: 'Obstetrics & Gynecology',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_call, size: 16),
                    label: const Text('Start Teleconsult', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestTeal, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionBuilderCard(BuildContext context, AppointmentRepository aptRepo, dynamic patient) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _rxMedicineCtrl,
              decoration: const InputDecoration(labelText: 'Medicine Name', hintText: 'Tab. Labetalol 100mg'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rxDosageCtrl,
                    decoration: const InputDecoration(labelText: 'Dosage', hintText: '100 mg'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rxDaysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Days', hintText: '14'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rxFrequencyCtrl,
              decoration: const InputDecoration(labelText: 'Frequency / Timing', hintText: '1-0-1 (After food)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final rx = PrescriptionDto(
                  id: 'RX-${DateTime.now().millisecondsSinceEpoch % 100000}',
                  patientId: patient.id,
                  doctorName: 'Dr. Anjali Patil (OB/GYN)',
                  diagnosis: 'Gestational Hypertension (32 Wks) + Severe Nutritional Anaemia',
                  medicines: [
                    PrescriptionItemDto(
                      medicineName: _rxMedicineCtrl.text,
                      dosage: _rxDosageCtrl.text,
                      frequency: _rxFrequencyCtrl.text,
                      durationDays: int.tryParse(_rxDaysCtrl.text) ?? 14,
                    ),
                    const PrescriptionItemDto(
                      medicineName: 'Tab. Iron & Folic Acid (IFA)',
                      dosage: '100mg',
                      frequency: '0-0-1 (Bedtime)',
                      durationDays: 30,
                    ),
                  ],
                  adviceNotes: 'Bed rest, daily BP monitoring by ASHA worker, reduce salt intake.',
                  issuedAt: DateTime.now(),
                );
                aptRepo.addPrescription(rx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('E-Prescription ${rx.id} generated and signed via ABDM!')),
                );
              },
              icon: const Icon(Icons.verified),
              label: const Text('Sign & Issue Digital E-Prescription'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestTeal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 42)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterReferralCard(BuildContext context, ReferralRepository refRepo) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _counterNotesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Discharge & Down-Referral Care Plan to Field ASHA',
                hintText: 'Enter clinical instructions for local health worker follow-up...',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                if (refRepo.referrals.isNotEmpty) {
                  refRepo.advanceStatus(refRepo.referrals.first.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Counter-Referral instructions dispatched to ASHA Sunita Tai Gaikwad! Closed loop care established.')),
                  );
                }
              },
              icon: const Icon(Icons.assignment_return),
              label: const Text('Emit Counter-Referral & Close Loop'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.slateNavy, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 42)),
            ),
          ],
        ),
      ),
    );
  }

  void _showClinicalHistoryModal(BuildContext context, dynamic patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Clinical File: ${patient.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            Text('ABHA: ${patient.abhaId} • RuralCare ID: ${patient.ruralCareId}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
            const Divider(height: 20),
            const Text('Maternal Longitudinal History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            const Text('• Gravida 2, Para 1 (Previous normal vaginal delivery in 2023)'),
            const Text('• Current: 32 Weeks Gestation, Single intrauterine live pregnancy'),
            const Text('• High Risk Flags: Gestational Hypertension, Severe Nutritional Anaemia (Hb 7.8 g/dL)'),
            const SizedBox(height: 12),
            const Text('Recent Diagnostics:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            const Text('• Ultrasound (30 Wks): FHR 144 bpm, AFI 12.4 cm, Normal fetal anatomy'),
            const Text('• Urine Albumin: 1+ Proteinuria confirmed'),
            const Text('• Blood Sugar: Fasting 102 mg/dL, Postprandial 142 mg/dL'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestTeal, foregroundColor: Colors.white),
              child: const Text('Done Reviewing'),
            ),
          ],
        ),
      ),
    );
  }
}
