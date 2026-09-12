import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

/// Longitudinal Records Screen conforming strictly to DESIGN.md Section 6:
/// Summary first. Simple filters for consultations, prescriptions, diagnostics, and vitals.
/// Shows date, type, clinician/facility, and clear clinical content with no decorative framing.
class LongitudinalRecordsScreen extends StatefulWidget {
  const LongitudinalRecordsScreen({super.key});

  @override
  State<LongitudinalRecordsScreen> createState() => _LongitudinalRecordsScreenState();
}

class _LongitudinalRecordsScreenState extends State<LongitudinalRecordsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Prescriptions', 'Diagnostics', 'Vitals', 'Consultations'];

  @override
  Widget build(BuildContext context) {
    final aptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        title: const Text('Health records', style: AppTypography.pageTitle),
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: RuralCareColors.surface,
              border: Border(bottom: BorderSide(color: RuralCareColors.border, width: 1.0)),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final filter = _filters[idx];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedFilter = filter),
                  selectedColor: RuralCareColors.primarySoft,
                  backgroundColor: RuralCareColors.surface,
                  labelStyle: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? RuralCareColors.primary : RuralCareColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? RuralCareColors.primary : RuralCareColors.border,
                      width: 1.0,
                    ),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([aptRepo, patientRepo]),
        builder: (context, _) {
          final patient = patientRepo.defaultPatient;
          final prescriptions = aptRepo.prescriptions;
          final vitals = patient.latestVitals;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Clinical Summary Section
              if (_selectedFilter == 'All' || _selectedFilter == 'Vitals') ...[
                _buildVitalsSummaryCard(vitals, patient),
                const SizedBox(height: 16),
              ],

              // Prescriptions Section
              if (_selectedFilter == 'All' || _selectedFilter == 'Prescriptions') ...[
                ...prescriptions.map((rx) => _buildPrescriptionCard(rx)),
                const SizedBox(height: 16),
              ],

              // Diagnostics Section
              if (_selectedFilter == 'All' || _selectedFilter == 'Diagnostics') ...[
                _buildDiagnosticReportCard(
                  title: 'Complete Blood Count (CBC) & Hb',
                  date: '08 Sep 2026',
                  facility: 'Baramati SDH Laboratory',
                  summary: 'Haemoglobin: 7.8 g/dL (Moderate Anemia). Platelets: 210,000/mcL.',
                  hasAttention: true,
                ),
                const SizedBox(height: 14),
                _buildDiagnosticReportCard(
                  title: 'Obstetric Ultrasound (USG) - 32 Weeks',
                  date: '24 Aug 2026',
                  facility: 'Baramati SDH Radiology',
                  summary: 'Single live intrauterine fetus. Cephalic presentation. Normal amniotic fluid index.',
                  hasAttention: false,
                ),
                const SizedBox(height: 16),
              ],

              // Consultations Section
              if (_selectedFilter == 'All' || _selectedFilter == 'Consultations') ...[
                _buildConsultationSummaryCard(
                  title: 'Tele-ANC Consultation Review',
                  date: '12 Aug 2026',
                  clinician: 'Dr. Anjali Deshmukh (OB/GYN)',
                  facility: 'Baramati Sub-District Hospital',
                  notes: 'Gestational hypertension monitored. Advised low salt diet, rest, and BP logging every 48 hours.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildVitalsSummaryCard(vitals, PatientDto patient) {
    if (vitals == null) return const SizedBox.shrink();

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest health measurements',
                style: AppTypography.cardTitle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(
                  background: vitals.hasWarning ? RuralCareColors.warningSoft : RuralCareColors.successSoft,
                ),
                child: Text(
                  vitals.hasWarning ? 'Review needed' : 'Normal',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: vitals.hasWarning ? RuralCareColors.warning : RuralCareColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metricTile('Blood pressure', '${vitals.systolicBp}/${vitals.diastolicBp} mmHg', isCritical: vitals.systolicBp > 140),
              const SizedBox(width: 10),
              _metricTile('Haemoglobin', '${vitals.haemoglobin} g/dL', isCritical: vitals.haemoglobin < 9.0),
              const SizedBox(width: 10),
              _metricTile('Oxygen SpO2', '${vitals.spO2}%', isCritical: vitals.spO2 < 95),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Recorded by ASHA ${patient.assignedAsha} • Safe Pregnancy Protocol',
            style: AppTypography.supporting,
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, {bool isCritical = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCritical ? RuralCareColors.warningSoft : RuralCareColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCritical ? RuralCareColors.warning.withOpacity(0.3) : RuralCareColors.border,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary), maxLines: 1),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isCritical ? RuralCareColors.warning : RuralCareColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionDto rx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rx.id, style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.primarySoft),
                child: const Text(
                  'FHIR Verified',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${rx.doctorName} • ${rx.diagnosis}', style: AppTypography.supporting),
          const Divider(color: RuralCareColors.border, height: 20),
          ...rx.medicines.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: RuralCareColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${m.name} (${m.dosage}) — ${m.frequency}',
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
              )),
          if (rx.lifestyleAdvice != null && rx.lifestyleAdvice!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Advice: ${rx.lifestyleAdvice}', style: AppTypography.supporting),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticReportCard({
    required String title,
    required String date,
    required String facility,
    required String summary,
    required bool hasAttention,
  }) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: AppTypography.cardTitle),
              ),
              if (hasAttention)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: AppDecorations.statusBadge(background: RuralCareColors.warningSoft),
                  child: const Text(
                    'Attention flag',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$facility • $date', style: AppTypography.supporting),
          const SizedBox(height: 10),
          Text(summary, style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _buildConsultationSummaryCard({
    required String title,
    required String date,
    required String clinician,
    required String facility,
    required String notes,
  }) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle),
          const SizedBox(height: 4),
          Text('$clinician • $facility • $date', style: AppTypography.supporting),
          const SizedBox(height: 10),
          Text(notes, style: AppTypography.body),
        ],
      ),
    );
  }
}
