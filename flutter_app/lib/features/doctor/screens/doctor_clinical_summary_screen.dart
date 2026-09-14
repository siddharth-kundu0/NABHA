import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/features/doctor/screens/doctor_care_plan_screen.dart';

/// Stitch Screen 3: Patient Clinical Summary (Mobile 780x3716)
/// Screen ID: fc13d323e65a4581a6863f406205fe5d
class DoctorClinicalSummaryScreen extends StatefulWidget {
  final PatientDto? patient;
  final String? appointmentId;

  const DoctorClinicalSummaryScreen({
    super.key,
    this.patient,
    this.appointmentId,
  });

  @override
  State<DoctorClinicalSummaryScreen> createState() => _DoctorClinicalSummaryScreenState();
}

class _DoctorClinicalSummaryScreenState extends State<DoctorClinicalSummaryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Full Records', 'Diagnostics (3)', 'Referrals (1)', 'Rx History'];

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patient = widget.patient ??
        (patientRepo.patients.isNotEmpty
            ? patientRepo.patients.first
            : patientRepo.activePatient);

    if (patient == null) {
      return Scaffold(
        backgroundColor: RuralCareColors.canvas,
        appBar: AppBar(
          backgroundColor: RuralCareColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Clinical Summary', style: TextStyle(color: RuralCareColors.textPrimary)),
        ),
        body: const Center(
          child: Text('No patient record found. Please register or select a patient.'),
        ),
      );
    }
    final vitals = patient.latestVitals;

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RuralCare',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: RuralCareColors.teal,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: RuralCareColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Online • Sync 10:42 AM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: RuralCareColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: RuralCareColors.tealSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: RuralCareColors.teal.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, size: 14, color: RuralCareColors.teal),
                SizedBox(width: 4),
                Text(
                  'Clinical Review',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                ),
              ],
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: RuralCareColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Patient Demographics Card
            _buildPatientHeaderCard(patient),
            const SizedBox(height: 14),

            // 2. Filter Pills
            _buildFilterPills(),
            const SizedBox(height: 16),

            // 3. Current Visit Intake Section
            _buildCurrentVisitIntake(vitals),
            const SizedBox(height: 16),

            // 4. Existing Record Context (Read-Only)
            _buildExistingRecordContext(patient),
            const SizedBox(height: 20),

            // 5. Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _openCarePlan(patient),
                icon: const Icon(Icons.edit_note_rounded, size: 22),
                label: const Text(
                  'Start Consultation & Care Plan →',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuralCareColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openCarePlan(PatientDto patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DoctorCarePlanScreen(
          patient: patient,
          appointmentId: widget.appointmentId ?? 'APT-101',
        ),
      ),
    );
  }

  Widget _buildPatientHeaderCard(PatientDto patient) {
    final initials = patient.fullName
        .split(' ')
        .map((s) => s.isNotEmpty ? s[0] : '')
        .take(2)
        .join();

    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RuralCareColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: RuralCareColors.teal,
                child: Text(
                  initials.isNotEmpty ? initials : 'PT',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            patient.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: RuralCareColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${patient.age}${patient.gender.isNotEmpty ? patient.gender[0] : "M"} • ${patient.village}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: RuralCareColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: RuralCareColors.tealSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            patient.ruralCareId,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: RuralCareColors.teal,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'OPD Counter #02',
                          style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.badge_outlined, color: RuralCareColors.textSecondary, size: 22),
                onPressed: () {},
                tooltip: 'ABHA Card',
              ),
            ],
          ),
          const Divider(height: 24, color: RuralCareColors.border),
          // Demographic chips
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.translate, size: 16, color: RuralCareColors.textSecondary),
                    SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        text: 'Language: ',
                        style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Hindi / Primary',
                            style: TextStyle(fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: RuralCareColors.success),
                    const SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        text: 'Allergies: ',
                        style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                        children: [
                          TextSpan(
                            text: patient.allergies.isEmpty ? 'NKDA' : patient.allergies.join(', '),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: patient.allergies.isEmpty ? RuralCareColors.success : RuralCareColors.critical,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_hospital_outlined, size: 16, color: RuralCareColors.teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'In-Person General OPD Encounter',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: RuralCareColors.textPrimary),
                  ),
                ),
                Text(
                  'Today',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final isSelected = entry.key == _selectedFilterIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilterIndex = entry.key),
              selectedColor: RuralCareColors.teal,
              backgroundColor: RuralCareColors.surface,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : RuralCareColors.textSecondary,
              ),
              side: BorderSide(
                color: isSelected ? RuralCareColors.teal : RuralCareColors.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentVisitIntake(dynamic vitals) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RuralCareColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: RuralCareColors.teal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CURRENT VISIT INTAKE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: RuralCareColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: RuralCareColors.tealSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sub-Center Sync',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chief Complaint Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RuralCareColors.border.withOpacity(0.5)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHIEF COMPLAINT / REASON',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  'Hypertension follow-up; mild morning headaches resolved.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Field worker intake note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RuralCareColors.border.withOpacity(0.5)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_ind_outlined, size: 14, color: RuralCareColors.teal),
                        SizedBox(width: 4),
                        Text(
                          'Field Worker Intake Note',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                        ),
                      ],
                    ),
                    Text(
                      'Kavita Verma (Rampur)',
                      style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '“Vitals recorded by Field Worker Kavita Verma at Rampur Sub-Center. Adherent to daily Telmisartan 40mg. No chest discomfort reported.”',
                  style: TextStyle(fontSize: 12, color: RuralCareColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Recorded Vitals Grid
          const Text(
            'RECENT RECORDED VITALS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.textSecondary),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildVitalBox(
                icon: Icons.favorite,
                iconColor: RuralCareColors.success,
                label: 'Blood Pressure',
                value: '${vitals?.systolicBp ?? 130} / ${vitals?.diastolicBp ?? 84}',
                unit: 'mmHg',
                status: '● Normal / Managed',
                statusColor: RuralCareColors.success,
              ),
              _buildVitalBox(
                icon: Icons.favorite_border,
                iconColor: RuralCareColors.critical,
                label: 'Heart Rate',
                value: '${vitals?.pulse ?? 72}',
                unit: 'bpm',
                status: '● Regular Rhythm',
                statusColor: RuralCareColors.success,
              ),
              _buildVitalBox(
                icon: Icons.air,
                iconColor: AppColors.skyBlue,
                label: 'SpO2',
                value: '${vitals?.spO2 ?? 98}%',
                unit: '',
                status: '● Optimal',
                statusColor: RuralCareColors.success,
              ),
              _buildVitalBox(
                icon: Icons.device_thermostat,
                iconColor: RuralCareColors.warning,
                label: 'Temp / Wt',
                value: '${vitals?.temperature ?? 98.4}°F',
                unit: '• 68 kg',
                status: '● Afebrile',
                statusColor: RuralCareColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RuralCareColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RuralCareColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: RuralCareColors.textPrimary,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                ),
              ],
            ],
          ),
          Text(
            status,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingRecordContext(PatientDto patient) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RuralCareColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_edu_outlined, size: 18, color: RuralCareColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Existing Record Context',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: RuralCareColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'READ-ONLY',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: RuralCareColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active Medications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.medication_outlined, size: 16, color: RuralCareColors.teal),
                  SizedBox(width: 6),
                  Text(
                    'Active Medications (2)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RuralCareColors.successSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Good adherence',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RuralCareColors.border.withOpacity(0.6)),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tab Telmisartan 40mg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('1 tab daily (morning) • 30 days supplied', style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                      ],
                    ),
                    Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success)),
                  ],
                ),
                Divider(height: 16, color: RuralCareColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tab Amlodipine 5mg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('1 tab at bedtime • 30 days supplied', style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                      ],
                    ),
                    Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Diagnostic Lab Results
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.science_outlined, size: 16, color: RuralCareColors.teal),
                  SizedBox(width: 6),
                  Text(
                    'Diagnostic Laboratory Results',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              Text(
                '2 weeks ago',
                style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RuralCareColors.border.withOpacity(0.6)),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Serum Creatinine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Ref 0.7 - 1.2 mg/dL', style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('0.9 mg/dL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('Normal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.success)),
                      ],
                    ),
                  ],
                ),
                Divider(height: 14, color: RuralCareColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fasting Blood Sugar (FBS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Ref 70 - 100 mg/dL', style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('98 mg/dL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('Normal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.success)),
                      ],
                    ),
                  ],
                ),
                Divider(height: 14, color: RuralCareColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lipid Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Total Cholesterol', style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('210 mg/dL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.warning)),
                        Text('Borderline High', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.warning)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Active Referrals
          const Row(
            children: [
              Icon(Icons.share_location_outlined, size: 16, color: AppColors.skyBlue),
              SizedBox(width: 6),
              Text(
                'Active Referrals & Care Coordination',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.skyBlueSoft.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_outlined, size: 18, color: AppColors.skyBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cardiology Consult — Bilaspur District Hospital',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Scheduled for routine baseline echocardiogram check.',
                        style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Clinical History Context
          const Row(
            children: [
              Icon(Icons.medical_information_outlined, size: 16, color: RuralCareColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Clinical History Context',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RuralCareColors.border),
            ),
            child: const Text(
              'Essential Hypertension diagnosed 2 years ago at Rampur PHC. Well maintained with regular community follow-up.',
              style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
