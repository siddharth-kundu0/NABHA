import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

class HealthWorkerFollowUpScreen extends StatefulWidget {
  final String? patientId;
  final bool isStandalone;
  const HealthWorkerFollowUpScreen({super.key, this.patientId, this.isStandalone = true});

  @override
  State<HealthWorkerFollowUpScreen> createState() => _HealthWorkerFollowUpScreenState();
}

class _HealthWorkerFollowUpScreenState extends State<HealthWorkerFollowUpScreen> {
  String _selectedStatus = 'In Progress';
  String _visitMode = 'Home Visit';
  int _systolic = 130;
  int _diastolic = 84;
  bool _medicationVerified = true;
  bool _lifestyleReinforced = true;
  final TextEditingController _noteCtrl = TextEditingController(
    text: 'Patient taking morning medicines regularly. Reported mild headache yesterday. Advised hydration and rest. Scheduled re-check in 3 days.',
  );

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _bpClassification {
    if (_systolic >= 140 || _diastolic >= 90) {
      return 'Stage 2 Severe';
    } else if (_systolic >= 130 || _diastolic >= 80) {
      return 'Mild Stage 1';
    } else {
      return 'Normal';
    }
  }

  Color get _bpClassificationColor {
    if (_systolic >= 140 || _diastolic >= 90) {
      return const Color(0xFFDC2626);
    } else if (_systolic >= 130 || _diastolic >= 80) {
      return const Color(0xFF10B981);
    } else {
      return const Color(0xFF0369A1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patient = widget.patientId != null
        ? patientRepo.patients.firstWhere(
            (p) => p.id == widget.patientId,
            orElse: () => patientRepo.defaultPatient,
          )
        : patientRepo.defaultPatient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isStandalone
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkSlate),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tasks / कार्य सूची', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                  Text('Follow-up Visit #2', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                ],
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(color: AppColors.neutral200, height: 1),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Card matching Stitch Screen 4
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlueSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.navyBlue),
                            SizedBox(width: 4),
                            Text('Due Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Priority: Normal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slateGray)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.forestTeal, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${patient.fullName} (${patient.phoneNumber})...')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Post-Consultation Blood Pressure & Adherence',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'परामर्श एवं दवा नियमितता सत्यापन',
                    style: TextStyle(fontSize: 12, color: AppColors.slateGray),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.forestTeal),
                        const SizedBox(width: 6),
                        Text(
                          '${patient.fullName} (${patient.ruralCareId})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Status Section matching Stitch Screen 4
            const Text('Status / स्थिति', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: Column(
                children: [
                  _statusOption(
                    title: 'Not Started',
                    subtitle: 'प्रारंभ नहीं',
                    value: 'Not Started',
                    icon: Icons.radio_button_unchecked_rounded,
                  ),
                  const Divider(height: 1, color: AppColors.neutral200),
                  _statusOption(
                    title: 'In Progress',
                    subtitle: 'प्रगति पर',
                    value: 'In Progress',
                    icon: Icons.autorenew_rounded,
                    isSuccess: true,
                  ),
                  const Divider(height: 1, color: AppColors.neutral200),
                  _statusOption(
                    title: 'Completed',
                    subtitle: 'पूर्ण',
                    value: 'Completed',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const Divider(height: 1, color: AppColors.neutral200),
                  _statusOption(
                    title: 'Unable to Reach',
                    subtitle: 'संपर्क नहीं',
                    value: 'Unable to Reach',
                    icon: Icons.error_outline_rounded,
                    isWarning: true,
                  ),
                  const Divider(height: 1, color: AppColors.neutral200),
                  _statusOption(
                    title: 'Needs Escalation',
                    subtitle: 'समीक्षा आवश्यक',
                    value: 'Needs Escalation',
                    icon: Icons.warning_amber_rounded,
                    isCritical: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Field Observation Form matching Stitch Screen 4
            const Text('Field Observation Form', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
            const SizedBox(height: 2),
            const Text('स्वास्थ्य कार्यकर्ता क्षेत्रीय अवलोकन', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
            const SizedBox(height: 12),

            // Visit Mode Selector (Home Visit, Phone Call, Facility Visit)
            Row(
              children: [
                _modeButton(icon: Icons.home_outlined, label: 'Home\nVisit', mode: 'Home Visit'),
                const SizedBox(width: 8),
                _modeButton(icon: Icons.phone_outlined, label: 'Phone\nCall', mode: 'Phone Call'),
                const SizedBox(width: 8),
                _modeButton(icon: Icons.local_hospital_outlined, label: 'Facility\nVisit', mode: 'Facility Visit'),
              ],
            ),

            const SizedBox(height: 16),

            // Vitals Entry Stepper Card: Blood Pressure (Systolic & Diastolic)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vitals Entry: Blood Pressure', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                          Text('रक्तचाप माप (mmHg)', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bpClassificationColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _bpClassificationColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _bpClassification,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _bpClassificationColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Systolic Stepper
                      Expanded(
                        child: _stepperBox(
                          title: 'Systolic / सिस्टोलिक',
                          value: _systolic,
                          onDecrement: () => setState(() => _systolic = (_systolic > 70) ? _systolic - 2 : _systolic),
                          onIncrement: () => setState(() => _systolic = (_systolic < 220) ? _systolic + 2 : _systolic),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Diastolic Stepper
                      Expanded(
                        child: _stepperBox(
                          title: 'Diastolic / डायस्टोलिक',
                          value: _diastolic,
                          onDecrement: () => setState(() => _diastolic = (_diastolic > 40) ? _diastolic - 2 : _diastolic),
                          onIncrement: () => setState(() => _diastolic = (_diastolic < 140) ? _diastolic + 2 : _diastolic),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Adherence Checklist
            const Text('Adherence Checklist / दवा चेकलिस्ट', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Medication adherence verified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('दवा नियमित सेवन की पुष्टि की गई', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                    value: _medicationVerified,
                    activeColor: AppColors.forestTealDark,
                    onChanged: (val) => setState(() => _medicationVerified = val ?? false),
                  ),
                  const Divider(height: 1, color: AppColors.neutral200),
                  CheckboxListTile(
                    title: const Text('Lifestyle/diet guidance reinforced (low salt)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('कम नमक व आहार मार्गदर्शन दिया गया', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                    value: _lifestyleReinforced,
                    activeColor: AppColors.forestTealDark,
                    onChanged: (val) => setState(() => _lifestyleReinforced = val ?? false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Field Note with Voice Shortcut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Field Note / अवलोकन नोट', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audio note recorded locally (3.4s)')),
                    );
                  },
                  icon: const Icon(Icons.mic_outlined, size: 14, color: AppColors.forestTeal),
                  label: const Text('Record Voice Note', style: TextStyle(fontSize: 11, color: AppColors.forestTeal)),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: TextField(
                controller: _noteCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, color: AppColors.darkSlate),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                  hintText: 'Enter observation details here...',
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Role Boundary Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Role Notice: Health workers record observational vitals & adherence status. Clinical diagnoses and prescription changes remain with the supervising clinician.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Local persistence indicator strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_queue_rounded, size: 18, color: Color(0xFF059669)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved locally on device. Will sync automatically.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                        Text('डिवाइस पर सुरक्षित। नेटवर्क पर स्वतः सिंक होगा।', style: TextStyle(fontSize: 10, color: Color(0xFF047857))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Save Visit Record Primary Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final checklist = <String>[];
                  if (_medicationVerified) checklist.add('Medication Adherence');
                  if (_lifestyleReinforced) checklist.add('Lifestyle/Diet Guidance');

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  await patientRepo.recordFollowUpVisit(
                    patientId: patient.id,
                    systolic: _systolic,
                    diastolic: _diastolic,
                    notes: _noteCtrl.text.trim(),
                    status: _selectedStatus,
                    visitMode: _visitMode,
                    adherenceChecklist: checklist,
                  );

                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Visit recorded for ${patient.fullName} ($_systolic/$_diastolic mmHg)')),
                    );
                    if (widget.isStandalone) {
                      navigator.pop();
                    }
                  }
                },
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                label: const Text('Save Visit Record (जांच दर्ज करें)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestTealDark,
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

  Widget _statusOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    bool isSuccess = false,
    bool isWarning = false,
    bool isCritical = false,
  }) {
    final isSelected = _selectedStatus == value;
    Color iconColor = AppColors.slateGray;
    if (isSuccess) iconColor = const Color(0xFF10B981);
    if (isWarning) iconColor = const Color(0xFFD97706);
    if (isCritical) iconColor = const Color(0xFFDC2626);

    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: isSelected ? AppColors.forestTeal.withOpacity(0.08) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: AppColors.darkSlate)),
                  const SizedBox(width: 6),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected ? AppColors.forestTealDark : AppColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton({required IconData icon, required String label, required String mode}) {
    final isSelected = _visitMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _visitMode = mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.forestTealDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.forestTealDark : AppColors.neutral300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.slateGray),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.darkSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperBox({
    required String title,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: AppColors.forestTeal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                  ),
                  const SizedBox(width: 2),
                  const Text('mmHg', style: TextStyle(fontSize: 9, color: AppColors.slateGray)),
                ],
              ),
              IconButton(
                onPressed: onIncrement,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppColors.forestTeal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
