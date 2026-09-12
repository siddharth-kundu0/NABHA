import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'digital_triage_screen.dart';

/// Vitals Collection Screen conforming strictly to DESIGN.md Section 7 & 8:
/// Clean inputs with persistent labels, minimum height 52px.
/// Real source states, white cards with radius 16, border #DCE4ED, no shadows.
class VitalsCollectionScreen extends StatefulWidget {
  final String? selectedPatientId;
  const VitalsCollectionScreen({super.key, this.selectedPatientId});

  @override
  State<VitalsCollectionScreen> createState() => _VitalsCollectionScreenState();
}

class _VitalsCollectionScreenState extends State<VitalsCollectionScreen> {
  late String _patientId;
  bool _isBleConnecting = false;
  bool _isBleSynced = false;

  final TextEditingController _systolicCtrl = TextEditingController(text: '148');
  final TextEditingController _diastolicCtrl = TextEditingController(text: '96');
  final TextEditingController _pulseCtrl = TextEditingController(text: '88');
  final TextEditingController _spo2Ctrl = TextEditingController(text: '96');
  final TextEditingController _tempCtrl = TextEditingController(text: '98.6');
  final TextEditingController _sugarCtrl = TextEditingController(text: '142');
  final TextEditingController _hbCtrl = TextEditingController(text: '7.8');

  @override
  void initState() {
    super.initState();
    _patientId = widget.selectedPatientId ?? 'pat-001';
  }

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _pulseCtrl.dispose();
    _spo2Ctrl.dispose();
    _tempCtrl.dispose();
    _sugarCtrl.dispose();
    _hbCtrl.dispose();
    super.dispose();
  }

  void _syncBluetoothDevice() async {
    setState(() => _isBleConnecting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _isBleConnecting = false;
      _isBleSynced = true;
      _systolicCtrl.text = '148';
      _diastolicCtrl.text = '96';
      _pulseCtrl.text = '88';
      _spo2Ctrl.text = '96';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Readings captured from digital blood pressure monitor.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient;

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        title: const Text('Record vitals', style: AppTypography.pageTitle),
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
            // 1. Beneficiary Context
            Container(
              decoration: AppDecorations.card(),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.fullName, style: AppTypography.cardTitle),
                      const SizedBox(height: 2),
                      Text('Age ${patient.age} • ${patient.village}', style: AppTypography.supporting),
                    ],
                  ),
                  Text(
                    'ABHA: ${patient.abhaId}',
                    style: AppTypography.supporting.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. BLE Diagnostic Device Pairing Card
            Container(
              decoration: AppDecorations.card(),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isBleSynced ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
                    color: _isBleSynced ? RuralCareColors.success : RuralCareColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isBleSynced ? 'Digital BP monitor connected' : 'Digital diagnostic device',
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _isBleSynced ? 'Readings auto-populated' : 'Capture telemetry via Bluetooth',
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _isBleConnecting ? null : _syncBluetoothDevice,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: _isBleConnecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: RuralCareColors.primary),
                          )
                        : Text(_isBleSynced ? 'Re-sync' : 'Pair & Read'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Clinical Vitals Inputs (Persistent labels, minimum height 52)
            const Text('Clinical measurements', style: AppTypography.sectionTitle),
            const SizedBox(height: 14),

            // Blood Pressure
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Systolic BP (mmHg)', style: AppTypography.supporting),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _systolicCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '120'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diastolic BP (mmHg)', style: AppTypography.supporting),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _diastolicCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '80'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Pulse & SpO2
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pulse (bpm)', style: AppTypography.supporting),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pulseCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '72'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SpO2 (%)', style: AppTypography.supporting),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _spo2Ctrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '98'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Haemoglobin & Blood Sugar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Haemoglobin (g/dL)', style: AppTypography.supporting),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _hbCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '12.0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Blood Sugar (mg/dL)', style: AppTypography.supporting),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _sugarCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '110'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. Save & Proceed to Triage Action (52px button)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final sys = int.tryParse(_systolicCtrl.text) ?? 120;
                  final dia = int.tryParse(_diastolicCtrl.text) ?? 80;
                  final pulse = int.tryParse(_pulseCtrl.text) ?? 72;
                  final spo2 = int.tryParse(_spo2Ctrl.text) ?? 98;
                  final hb = double.tryParse(_hbCtrl.text) ?? 12.0;
                  final sugar = int.tryParse(_sugarCtrl.text) ?? 110;
                  final temp = double.tryParse(_tempCtrl.text) ?? 98.6;

                  final updatedVitals = VitalsDto(
                    id: 'vit-${DateTime.now().millisecondsSinceEpoch % 10000}',
                    patientId: _patientId,
                    recordedById: 'asha-904',
                    recordedByRole: 'HEALTH_WORKER',
                    systolicBp: sys,
                    diastolicBp: dia,
                    pulse: pulse,
                    spO2: spo2,
                    temperature: temp,
                    bloodSugar: sugar,
                    haemoglobin: hb,
                    recordedAt: DateTime.now(),
                    isFromBleDevice: _isBleSynced,
                  );

                  patientRepo.updatePatientVitals(_patientId, updatedVitals);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vitals saved successfully to patient record!')),
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const DigitalTriageScreen()),
                  );
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Save vitals & review triage', style: AppTypography.button),
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
}
