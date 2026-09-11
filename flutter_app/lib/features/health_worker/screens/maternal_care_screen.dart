import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

class MaternalCareScreen extends StatefulWidget {
  const MaternalCareScreen({super.key});

  @override
  State<MaternalCareScreen> createState() => _MaternalCareScreenState();
}

class _MaternalCareScreenState extends State<MaternalCareScreen> {
  final Map<String, bool> _deliveryChecklist = {
    'Janani Suraksha Yojana (JSY) Registered': true,
    'Institutional Delivery Facility Tagged: Baramati SDH': true,
    'Verified Blood Donor Identified: Rajesh Devi (O+ve)': true,
    'Emergency 108 Ambulance Transit Protocol Briefed': true,
    'Family Emergency Cash Reserve Arranged': true,
    'Sterile Delivery Cord Clamp & Kit Ready': false,
  };

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maternal & Child Health (MCP)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient overview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFBE185D), Color(0xFF9D174D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(patient.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                        child: const Text('High-Risk Mother', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Gestational Age: ${patient.gestationalAgeWeeks} Weeks (3rd Trimester)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text('Estimated Delivery Date (EDD): in 56 Days', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _mcpHeaderItem('Completed ANCs', '${patient.ancVisitsCompleted} of 4 Visits'),
                      _mcpHeaderItem('High Risk Flags', 'BP 148/96, Hb 7.8'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ANC 1-4 Stepper
            Text('Antenatal Care (ANC 1-4) Protocol', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
            const SizedBox(height: 10),
            _buildAncCard(
              visitNumber: 1,
              weeks: '10 Weeks (1st Trimester)',
              date: '18 May 2026',
              status: 'COMPLETED',
              notes: 'Pregnancy confirmation, Td-1 dose administered, Hb 9.2 g/dL, started IFA & Calcium.',
            ),
            _buildAncCard(
              visitNumber: 2,
              weeks: '20 Weeks (2nd Trimester)',
              date: '26 July 2026',
              status: 'COMPLETED',
              notes: 'Anomaly USG completed (normal anatomy), Td-2 booster given, maternal weight 52 kg.',
            ),
            _buildAncCard(
              visitNumber: 3,
              weeks: '32 Weeks (3rd Trimester)',
              date: 'Today',
              status: 'ACTIVE / TRIAGED',
              isHighRisk: true,
              notes: 'BP: 148/96 mmHg (Gestational Hypertension), Hb: 7.8 g/dL (Severe Anaemia). Referred to Baramati SDH.',
            ),
            _buildAncCard(
              visitNumber: 4,
              weeks: '36 Weeks to Term',
              date: 'Scheduled in 4 Weeks',
              status: 'UPCOMING',
              notes: 'Final delivery preparedness review, fetal presentation check, institutional transport lock.',
            ),
            const SizedBox(height: 18),

            // Institutional Delivery Preparedness Checklist
            Text('Institutional Delivery Checklist (संस्थात्मक प्रसूती)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: _deliveryChecklist.keys.map((key) {
                    final isChecked = _deliveryChecklist[key]!;
                    return CheckboxListTile(
                      title: Text(key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      value: isChecked,
                      activeColor: AppColors.forestTeal,
                      onChanged: (val) {
                        setState(() {
                          _deliveryChecklist[key] = val ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('MCP card synchronized to National RCH Portal!')),
                );
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Sync MCP Card to State RCH Registry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _mcpHeaderItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildAncCard({
    required int visitNumber,
    required String weeks,
    required String date,
    required String status,
    required String notes,
    bool isHighRisk = false,
  }) {
    Color badgeColor = isHighRisk ? AppColors.criticalRed : (status == 'COMPLETED' ? AppColors.forestTeal : AppColors.neutral600);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isHighRisk ? const BorderSide(color: AppColors.criticalRed, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ANC Visit $visitNumber • $weeks', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(status, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Text('Date: $date', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
            const SizedBox(height: 6),
            Text(notes, style: const TextStyle(fontSize: 11, color: AppColors.neutral800)),
          ],
        ),
      ),
    );
  }
}
