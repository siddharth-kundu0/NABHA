import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';

/// Doctor Workspace conforming strictly to DESIGN.md Section 7:
/// Patient summary above clinical workspace. Sections: concern, vitals, history,
/// assessment, and care plan. Simple, quiet forms with 52px primary actions.
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final TextEditingController _rxMedicineCtrl = TextEditingController(text: 'Tab. Labetalol 100mg');
  final TextEditingController _rxDosageCtrl = TextEditingController(text: '100 mg');
  final TextEditingController _rxFrequencyCtrl = TextEditingController(text: 'Twice daily after meals');
  final TextEditingController _carePlanNotesCtrl = TextEditingController(
    text: 'Daily blood pressure monitoring with ASHA Sunita Gaikwad. Review in 7 days or immediate transfer if BP > 160/100.',
  );

  @override
  void dispose() {
    _rxMedicineCtrl.dispose();
    _rxDosageCtrl.dispose();
    _rxFrequencyCtrl.dispose();
    _carePlanNotesCtrl.dispose();
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
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dr. Anjali Deshmukh (OB/GYN)', style: AppTypography.cardTitle),
                Text('Baramati Sub-District Hospital • Room 4', style: AppTypography.supporting),
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
                // 1. Teleconsultation Waiting Room Queue
                const Text('Teleconsultation queue', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                ...appointments.map((apt) => _buildQueueCard(context, apt, patient)),

                const SizedBox(height: 24),

                // 2. Active Patient Summary (DESIGN.md: patient name & essential context above workspace)
                Text('Active patient workspace: ${patient.fullName}', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                _buildPatientClinicalSummary(patient),

                const SizedBox(height: 24),

                // 3. Clinical Care Plan & E-Prescription Form
                const Text('Care plan & prescription', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                _buildCarePlanCard(context, patient, aptRepo, refRepo),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueCard(BuildContext context, AppointmentDto apt, PatientDto patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(apt.patientName, style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.primarySoft),
                child: Text(
                  apt.appointmentTime,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chief concern: ${apt.chiefComplaint.isNotEmpty ? apt.chiefComplaint : "ANC 3rd Trimester evaluation"}',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => LiveTeleconsultRoomScreen(
                      patientName: apt.patientName,
                      doctorName: 'Dr. Anjali Deshmukh',
                      specialty: apt.specialty,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.video_call_outlined, size: 20),
              label: const Text('Start video consultation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientClinicalSummary(PatientDto patient) {
    final vitals = patient.latestVitals;

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Demographics & history', style: AppTypography.cardTitle),
              Text(
                'ABHA: ${patient.abhaId}',
                style: AppTypography.supporting.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Age: ${patient.age} yrs • Gestational age: 32 weeks • Gravida 2, Para 1',
            style: AppTypography.body,
          ),
          const SizedBox(height: 6),
          Text(
            'Flagged risks: ${patient.highRiskConditions.join(", ")}',
            style: AppTypography.supporting.copyWith(color: RuralCareColors.critical, fontWeight: FontWeight.w600),
          ),
          const Divider(color: RuralCareColors.border, height: 24),
          if (vitals != null) ...[
            const Text('Telemetry vitals from Sub-Centre', style: AppTypography.cardTitle),
            const SizedBox(height: 10),
            Row(
              children: [
                _vitalTile('BP', '${vitals.systolicBp}/${vitals.diastolicBp} mmHg', isCritical: vitals.systolicBp > 140),
                const SizedBox(width: 8),
                _vitalTile('Hb', '${vitals.haemoglobin} g/dL', isCritical: vitals.haemoglobin < 9.0),
                const SizedBox(width: 8),
                _vitalTile('SpO2', '${vitals.spO2}%'),
                const SizedBox(width: 8),
                _vitalTile('Pulse', '${vitals.pulse} bpm'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _vitalTile(String label, String value, {bool isCritical = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCritical ? RuralCareColors.warningSoft : RuralCareColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isCritical ? RuralCareColors.warning : RuralCareColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCritical ? RuralCareColors.warning : RuralCareColors.textPrimary,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarePlanCard(
    BuildContext context,
    PatientDto patient,
    AppointmentRepository aptRepo,
    ReferralRepository refRepo,
  ) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prescribe medication', style: AppTypography.cardTitle),
          const SizedBox(height: 12),
          TextField(
            controller: _rxMedicineCtrl,
            decoration: const InputDecoration(labelText: 'Medicine name & strength'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rxDosageCtrl,
                  decoration: const InputDecoration(labelText: 'Dosage (e.g. 100mg)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _rxFrequencyCtrl,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Counter-referral instructions to ASHA', style: AppTypography.cardTitle),
          const SizedBox(height: 8),
          TextField(
            controller: _carePlanNotesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Actionable instructions for frontline home visit...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                final newPrescription = PrescriptionDto(
                  id: 'RX-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  patientId: patient.id,
                  doctorName: 'Dr. Anjali Deshmukh',
                  diagnosis: 'Gestational Hypertension (32 Weeks ANC)',
                  issuedAt: DateTime.now(),
                  medicines: [
                    PrescriptionItemDto(
                      medicineName: _rxMedicineCtrl.text,
                      dosage: _rxDosageCtrl.text,
                      frequency: _rxFrequencyCtrl.text,
                      durationDays: 14,
                    ),
                  ],
                  adviceNotes: _carePlanNotesCtrl.text,
                );
                aptRepo.addPrescription(newPrescription);
                refRepo.dispatchCounterReferral(
                  referralId: 'REF-BAR-2026-0891',
                  instructions: _carePlanNotesCtrl.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prescription issued & care plan dispatched to ASHA!')),
                );
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Issue prescription & care plan', style: AppTypography.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
