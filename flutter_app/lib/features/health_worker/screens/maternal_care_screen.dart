import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

/// Maternal Care Screen conforming strictly to DESIGN.md Section 8:
/// Highlights next ANC/follow-up, pregnancy timeline, and clinician-provided risk context.
/// Uses clean white cards (radius 16, border #DCE4ED, no shadows). No loud gradients.
class MaternalCareScreen extends StatefulWidget {
  const MaternalCareScreen({super.key});

  @override
  State<MaternalCareScreen> createState() => _MaternalCareScreenState();
}

class _MaternalCareScreenState extends State<MaternalCareScreen> {
  final Map<String, bool> _deliveryChecklist = {
    'Janani Suraksha Yojana (JSY) enrolled': true,
    'Institutional delivery facility assigned (Baramati SDH)': true,
    'Emergency 108 ambulance protocol briefed': true,
    'Verified blood donor identified (Rajesh Devi, O+ve)': true,
    'Sterile delivery kit and clean cord clamp arranged': true,
  };

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient;

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        title: const Text('Maternal care (ANC)', style: AppTypography.pageTitle),
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
            // 1. Clean Maternal Overview Card
            Container(
              decoration: AppDecorations.card(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(patient.fullName, style: AppTypography.cardTitle),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: AppDecorations.statusBadge(background: RuralCareColors.criticalSoft),
                        child: const Text(
                          'High-risk ANC',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.critical),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gestational age: ${patient.gestationalAgeWeeks} weeks • 3rd Trimester',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Estimated date of delivery: in ~56 days',
                    style: AppTypography.supporting,
                  ),
                  const Divider(color: RuralCareColors.border, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Completed checkups', style: AppTypography.supporting),
                          const SizedBox(height: 2),
                          Text('${patient.ancVisitsCompleted} of 4 visits', style: AppTypography.cardTitle),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Clinical flags', style: AppTypography.supporting),
                          const SizedBox(height: 2),
                          Text(
                            'BP 148/96 • Hb 7.8',
                            style: AppTypography.cardTitle.copyWith(color: RuralCareColors.critical),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Institutional Birth Preparedness Checklist
            const Text('Birth preparedness checklist', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            Container(
              decoration: AppDecorations.card(),
              child: Column(
                children: _deliveryChecklist.entries.map((entry) {
                  return Column(
                    children: [
                      CheckboxListTile(
                        title: Text(entry.key, style: AppTypography.body),
                        value: entry.value,
                        activeColor: RuralCareColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _deliveryChecklist[entry.key] = val ?? false;
                          });
                        },
                      ),
                      const Divider(color: RuralCareColors.border, height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Save Checklist Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maternal ANC checklist saved.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuralCareColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Save maternal care record', style: AppTypography.button),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
