import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

/// Digital Clinical Triage Screen conforming strictly to DESIGN.md Section 7:
/// Short sections: vitals -> symptoms/history -> review -> triage result.
/// Clean white cards, 52px action buttons, and clear non-alarming status badges.
class DigitalTriageScreen extends StatefulWidget {
  const DigitalTriageScreen({super.key});

  @override
  State<DigitalTriageScreen> createState() => _DigitalTriageScreenState();
}

class _DigitalTriageScreenState extends State<DigitalTriageScreen> {
  bool _hasHeadache = true;
  bool _hasBlurredVision = true;
  bool _hasPedalEdema = true;
  bool _hasEpigastricPain = false;
  bool _hasBleeding = false;

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient ?? patientRepo.activePatient;
    if (patient == null) {
      return Scaffold(
        backgroundColor: RuralCareColors.canvas,
        appBar: AppBar(
          title: const Text('Clinical triage', style: AppTypography.pageTitle),
          backgroundColor: RuralCareColors.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No patient selected. Please register or select a patient.'),
        ),
      );
    }
    final vitals = patient.latestVitals;

    final sys = vitals?.systolicBp ?? 120;
    final dia = vitals?.diastolicBp ?? 80;
    final hb = vitals?.haemoglobin ?? 12.0;

    final isEmergency = sys >= 160 || dia >= 110 || _hasBleeding || _hasEpigastricPain;
    final isHighRisk = isEmergency ? false : (sys >= 140 || dia >= 90 || hb < 9.0 || _hasHeadache || _hasBlurredVision || _hasPedalEdema);

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        title: const Text('Clinical triage', style: AppTypography.pageTitle),
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
            // 1. Patient Context Banner
            Container(
              decoration: AppDecorations.card(),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: RuralCareColors.primarySoft,
                    radius: 20,
                    child: Text(
                      patient.fullName[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: RuralCareColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.fullName, style: AppTypography.cardTitle),
                        Text('${patient.age} yrs • 32 wks pregnant • ${patient.village}', style: AppTypography.supporting),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Section: Current Vitals Snapshot
            const Text('1. Vitals telemetry', style: AppTypography.sectionTitle),
            const SizedBox(height: 10),
            Container(
              decoration: AppDecorations.card(),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _vitalDisplay('BP', '$sys/$dia mmHg', isWarning: sys >= 140 || dia >= 90),
                  _vitalDisplay('Hb', '$hb g/dL', isWarning: hb < 9.0),
                  _vitalDisplay('SpO2', '${vitals?.spO2 ?? 98}%'),
                  _vitalDisplay('Pulse', '${vitals?.pulse ?? 76} bpm'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Section: Symptoms & Danger Signs
            const Text('2. Symptoms & danger signs', style: AppTypography.sectionTitle),
            const SizedBox(height: 10),
            Container(
              decoration: AppDecorations.card(),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Severe or persistent headache', style: AppTypography.body),
                    value: _hasHeadache,
                    activeColor: RuralCareColors.primary,
                    onChanged: (val) => setState(() => _hasHeadache = val ?? false),
                  ),
                  const Divider(color: RuralCareColors.border, height: 1),
                  CheckboxListTile(
                    title: const Text('Blurred or disturbed vision', style: AppTypography.body),
                    value: _hasBlurredVision,
                    activeColor: RuralCareColors.primary,
                    onChanged: (val) => setState(() => _hasBlurredVision = val ?? false),
                  ),
                  const Divider(color: RuralCareColors.border, height: 1),
                  CheckboxListTile(
                    title: const Text('Marked facial or pedal swelling (Edema)', style: AppTypography.body),
                    value: _hasPedalEdema,
                    activeColor: RuralCareColors.primary,
                    onChanged: (val) => setState(() => _hasPedalEdema = val ?? false),
                  ),
                  const Divider(color: RuralCareColors.border, height: 1),
                  CheckboxListTile(
                    title: const Text('Upper abdominal pain (Epigastric)', style: AppTypography.body),
                    value: _hasEpigastricPain,
                    activeColor: RuralCareColors.critical,
                    onChanged: (val) => setState(() => _hasEpigastricPain = val ?? false),
                  ),
                  const Divider(color: RuralCareColors.border, height: 1),
                  CheckboxListTile(
                    title: const Text('Vaginal bleeding or fluid leakage', style: AppTypography.body),
                    value: _hasBleeding,
                    activeColor: RuralCareColors.critical,
                    onChanged: (val) => setState(() => _hasBleeding = val ?? false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Section: Triage Assessment & Outcome
            const Text('3. Triage assessment outcome', style: AppTypography.sectionTitle),
            const SizedBox(height: 10),
            Container(
              decoration: AppDecorations.card(
                borderColor: isEmergency
                    ? RuralCareColors.critical.withOpacity(0.3)
                    : (isHighRisk ? RuralCareColors.warning.withOpacity(0.3) : RuralCareColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEmergency ? 'Critical preeclampsia' : (isHighRisk ? 'High-risk gestational hypertension' : 'Routine management'),
                        style: AppTypography.cardTitle.copyWith(
                          color: isEmergency ? RuralCareColors.critical : (isHighRisk ? RuralCareColors.warning : RuralCareColors.success),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: AppDecorations.statusBadge(
                          background: isEmergency ? RuralCareColors.criticalSoft : (isHighRisk ? RuralCareColors.warningSoft : RuralCareColors.successSoft),
                        ),
                        child: Text(
                          isEmergency ? 'Tier 1 Critical' : (isHighRisk ? 'Tier 2 High-Risk' : 'Tier 3 Routine'),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isEmergency ? RuralCareColors.critical : (isHighRisk ? RuralCareColors.warning : RuralCareColors.success),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEmergency
                        ? 'Immediate transfer to First Referral Unit (Baramati SDH) required. Pre-alert triage and obstetric team.'
                        : (isHighRisk
                            ? 'Initiate specialist teleconsultation and generate digital referral to Baramati SDH.'
                            : 'Continue standard antenatal care visit schedule and IFA supplementation.'),
                    style: AppTypography.body,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Actions
            if (isEmergency)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                    );
                  },
                  icon: const Icon(Icons.emergency_outlined, size: 20),
                  label: const Text('Trigger emergency transfer', style: AppTypography.button),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.critical,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final autoDoc = DoctorRepository().autoSelectDoctor(
                      subCentre: patient.subCentre,
                      specialty: 'Obstetrics & Gynaecology',
                    );
                    final docName = autoDoc?.name ?? 'On-Duty Medical Officer';
                    final docSpec = autoDoc?.specialty ?? 'General Medicine';
                    final docFac = autoDoc?.facilityName ?? patient.subCentre;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => LiveTeleconsultRoomScreen(
                          patientName: patient.fullName,
                          doctorName: docName,
                          specialty: docSpec,
                          facilityName: docFac,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.video_call_outlined, size: 20),
                  label: const Text('Start doctor teleconsultation', style: AppTypography.button),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _vitalDisplay(String label, String value, {bool isWarning = false}) {
    return Column(
      children: [
        Text(label, style: AppTypography.supporting),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isWarning ? RuralCareColors.warning : RuralCareColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
