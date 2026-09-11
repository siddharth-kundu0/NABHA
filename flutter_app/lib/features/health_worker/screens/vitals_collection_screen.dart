import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'digital_triage_screen.dart';

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

  void _simulateBleSync() async {
    setState(() => _isBleConnecting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
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
        const SnackBar(content: Text('Synced with BLE Omron BP Monitor & Pulse Oximeter!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patients = patientRepo.patients;
    final selectedPatient = patients.firstWhere((p) => p.id == _patientId, orElse: () => patients.first);

    final sys = int.tryParse(_systolicCtrl.text) ?? 120;
    final dia = int.tryParse(_diastolicCtrl.text) ?? 80;
    final hb = double.tryParse(_hbCtrl.text) ?? 12.0;

    String triageTier = '🟢 ROUTINE';
    Color triageColor = AppColors.forestTealDark;
    if (sys >= 160 || dia >= 110) {
      triageTier = '🔴 EMERGENCY (Severe Preeclampsia Risk)';
      triageColor = AppColors.criticalRed;
    } else if (sys >= 140 || dia >= 90 || hb < 9.0) {
      triageTier = '🟡 HIGH RISK (Gestational Hypertension / Anaemia)';
      triageColor = AppColors.terracotta;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Patient Vitals'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: _patientId,
                  decoration: const InputDecoration(labelText: 'Select Patient in Household Visit'),
                  items: patients
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.fullName} (${p.age} Y, ${p.isPregnant ? "Pregnant" : p.gender})'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _patientId = val;
                        if (val == 'pat-002') {
                          _systolicCtrl.text = '155';
                          _diastolicCtrl.text = '92';
                          _pulseCtrl.text = '78';
                          _spo2Ctrl.text = '97';
                          _sugarCtrl.text = '210';
                          _hbCtrl.text = '13.2';
                        } else {
                          _systolicCtrl.text = '148';
                          _diastolicCtrl.text = '96';
                          _pulseCtrl.text = '88';
                          _spo2Ctrl.text = '96';
                          _sugarCtrl.text = '142';
                          _hbCtrl.text = '7.8';
                        }
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // BLE Device Sync Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isBleSynced ? const Color(0xFFEFF6FF) : AppColors.surfaceAntiGlare,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isBleSynced ? const Color(0xFF3B82F6) : AppColors.neutral300),
              ),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_searching, color: _isBleSynced ? const Color(0xFF2563EB) : AppColors.slateNavy, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isBleSynced ? 'BLE Devices Connected & Synced' : 'Bluetooth Diagnostic Sensor Kit',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isBleSynced ? const Color(0xFF1D4ED8) : AppColors.neutral900),
                        ),
                        Text(
                          _isBleSynced ? 'Omron BP HEM-7120 & Contec SpO2 telemetry received' : 'Pair with field BP cuff or pulse oximeter for auto-capture',
                          style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isBleConnecting ? null : _simulateBleSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBleSynced ? const Color(0xFF2563EB) : AppColors.slateNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: _isBleConnecting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isBleSynced ? 'Re-Sync' : 'Auto-Read', style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live ICMR Triage Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: triageColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: triageColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.health_and_safety, color: triageColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ICMR Clinical Assessment Indicator', style: TextStyle(fontSize: 10, color: AppColors.neutral700)),
                        Text(triageTier, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: triageColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _systolicCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Systolic BP (mmHg)', hintText: '120'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _diastolicCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Diastolic BP (mmHg)', hintText: '80'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pulseCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pulse (bpm)', hintText: '72'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _spo2Ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Oxygen SpO2 (%)', hintText: '98'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tempCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Temperature (°F)', hintText: '98.6'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hbCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Haemoglobin (g/dL)', hintText: '12.0'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sugarCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Random Blood Sugar (mg/dL)', hintText: '110'),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                final vitals = VitalsDto(
                  id: 'vit-${DateTime.now().millisecondsSinceEpoch}',
                  patientId: selectedPatient.id,
                  recordedById: 'asha-904',
                  recordedByRole: 'HEALTH_WORKER',
                  recordedAt: DateTime.now(),
                  systolicBp: int.tryParse(_systolicCtrl.text) ?? 120,
                  diastolicBp: int.tryParse(_diastolicCtrl.text) ?? 80,
                  pulse: int.tryParse(_pulseCtrl.text) ?? 72,
                  spO2: int.tryParse(_spo2Ctrl.text) ?? 98,
                  temperature: double.tryParse(_tempCtrl.text) ?? 98.6,
                  bloodSugar: int.tryParse(_sugarCtrl.text),
                  haemoglobin: double.tryParse(_hbCtrl.text),
                  isFromBleDevice: _isBleSynced,
                );

                patientRepo.updateVitals(selectedPatient.id, vitals);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vitals updated for ${selectedPatient.fullName}! Launching Clinical Triage...')),
                );

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const DigitalTriageScreen()),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Save & Evaluate Clinical Triage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
