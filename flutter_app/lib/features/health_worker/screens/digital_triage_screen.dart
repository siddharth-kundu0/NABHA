import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/referral_dto.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/referral_repository.dart';
import '../../features/teleconsult/screens/live_teleconsult_room_screen.dart';
import '../../features/emergency/screens/emergency_tracking_screen.dart';

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
  bool _hasReducedFetalMovements = false;

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final refRepo = ReferralRepository();
    final patient = patientRepo.defaultPatient;
    final vitals = patient.latestVitals;

    final sys = vitals?.systolicBp ?? 120;
    final dia = vitals?.diastolicBp ?? 80;
    final hb = vitals?.haemoglobin ?? 12.0;

    final isEmergency = sys >= 160 || dia >= 110 || _hasBleeding || _hasEpigastricPain;
    final isHighRisk = isEmergency ? false : (sys >= 140 || dia >= 90 || hb < 9.0 || _hasHeadache || _hasBlurredVision || _hasPedalEdema);

    final String triageBadge = isEmergency
        ? '🔴 TIER 1: EMERGENCY (Severe Preeclampsia / Complication)'
        : (isHighRisk ? '🟡 TIER 2: HIGH-RISK (Gestational Hypertension & Anaemia)' : '🟢 TIER 3: ROUTINE (Mild / Managed)');

    final Color triageColor = isEmergency ? AppColors.criticalRed : (isHighRisk ? AppColors.terracotta : AppColors.forestTealDark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ICMR Digital Clinical Triage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Demographics banner
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.forestTealLight,
                      child: Text(patient.fullName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestTealDark)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Age ${patient.age} • ${patient.gestationalAgeWeeks} Wks Pregnant • ${patient.village}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                          Text('ABHA: ${patient.abhaId}', style: const TextStyle(fontSize: 10, color: AppColors.forestTealDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Triage Decision Strip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: triageColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: triageColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: triageColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          triageBadge,
                          style: TextStyle(fontWeight: FontWeight.bold, color: triageColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEmergency
                        ? 'Immediate 108 Emergency Ambulance dispatch required. Baramati SDH Emergency Room must be pre-alerted.'
                        : (isHighRisk
                            ? 'Specialist evaluation by OB/GYN required. Initiate assisted teleconsultation and generate smart referral.'
                            : 'Patient vitals within manageable threshold. Dispense IFA supplements and review in 14 days.'),
                    style: const TextStyle(fontSize: 11, color: AppColors.neutral800, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Measured Vitals Overview
            Text('Measured Vitals Overview', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.neutral300)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _vitalsBadge('BP', '$sys/$dia mmHg', isElevated: sys >= 140 || dia >= 90),
                  _vitalsBadge('Hb', '$hb g/dL', isElevated: hb < 9.0),
                  _vitalsBadge('SpO2', '${vitals?.spO2 ?? 98}%'),
                  _vitalsBadge('Pulse', '${vitals?.pulse ?? 78} bpm'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danger Signs Checklist
            Text('Maternal Danger Signs Checklist (लक्षणे तपासा)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Severe Headache or Blurred Vision', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Indicates cerebral edema in pre-eclampsia', style: TextStyle(fontSize: 10)),
                    value: _hasHeadache,
                    activeColor: AppColors.criticalRed,
                    onChanged: (v) => setState(() => _hasHeadache = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Marked Facial / Hand Swelling (Edema)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Pathological fluid retention', style: TextStyle(fontSize: 10)),
                    value: _hasPedalEdema,
                    activeColor: AppColors.terracotta,
                    onChanged: (v) => setState(() => _hasPedalEdema = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Epigastric Pain / Upper Abdomen Pain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Impending eclampsia or hepatic capsular distension', style: TextStyle(fontSize: 10)),
                    value: _hasEpigastricPain,
                    activeColor: AppColors.criticalRed,
                    onChanged: (v) => setState(() => _hasEpigastricPain = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Vaginal Bleeding or Water Discharge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Abruption placenta or premature rupture', style: TextStyle(fontSize: 10)),
                    value: _hasBleeding,
                    activeColor: AppColors.criticalRed,
                    onChanged: (v) => setState(() => _hasBleeding = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Reduced Fetal Movements (< 10 kicks)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Fetal distress indicator', style: TextStyle(fontSize: 10)),
                    value: _hasReducedFetalMovements,
                    activeColor: AppColors.criticalRed,
                    onChanged: (v) => setState(() => _hasReducedFetalMovements = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Smart Actions
            if (isEmergency) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                  );
                },
                icon: const Icon(Icons.emergency),
                label: const Text('DISPATCH 108 AMBULANCE & PRE-ALERT HOSPITAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.criticalRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 10),
            ],

            ElevatedButton.icon(
              onPressed: () {
                final newRef = ReferralDto(
                  id: 'REF-${DateTime.now().millisecondsSinceEpoch % 100000}',
                  patientId: patient.id,
                  patientName: patient.fullName,
                  referringFacility: 'Kashti Sub-Centre (ASHA Assisted)',
                  targetFacilityId: 'FAC-SDH-301',
                  targetFacilityName: 'Baramati Sub-District Hospital (SDH)',
                  reason: '32-Week Gestational Hypertension with Severe Anaemia requiring specialist OB/GYN evaluation',
                  urgency: isEmergency ? 'EMERGENCY' : 'URGENT',
                  requiredSpecialty: 'Obstetrician & Gynecologist',
                  status: 'HOSPITAL_NOTIFIED',
                  createdAt: DateTime.now(),
                  expectedTransitMinutes: 40,
                  isOverdue: false,
                  counterReferralInstructions: 'Administer Tab Labetalol 100mg BD. Daily BP check via ASHA.',
                  recommendationRationale: 'Baramati SDH (24.5 km) chosen over Daund CHC (12 km) because Daund CHC lacks an on-duty Gynecologist and Blood Bank capability.',
                );
                refRepo.addReferral(newRef);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Smart Referral ${newRef.id} successfully initiated with Baramati SDH!')),
                );
              },
              icon: const Icon(Icons.alt_route),
              label: const Text('Initiate Smart AI Referral to Baramati SDH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => LiveTeleconsultRoomScreen(
                      patientName: patient.fullName,
                      doctorName: 'Dr. Anjali Patil (OB/GYN)',
                      specialty: 'Obstetrics & Gynecology',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.video_call),
              label: const Text('Launch Assisted Teleconsultation with Dr. Patil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.slateNavy,
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _vitalsBadge(String label, String val, {bool isElevated = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isElevated ? AppColors.terracotta : AppColors.neutral900,
          ),
        ),
      ],
    );
  }
}
