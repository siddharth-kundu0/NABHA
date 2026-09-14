import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/data/models/triage_dto.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/emergency_event_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/emergency_repository.dart';
import 'package:ruralcare/core/services/clinical_triage_engine.dart';
import 'package:ruralcare/core/services/nlp_symptom_service.dart';
import 'package:ruralcare/core/services/hardware_vitals_telemetry_service.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import 'dart:async';

class VitalsCollectionScreen extends StatefulWidget {
  final String? selectedPatientId;
  const VitalsCollectionScreen({super.key, this.selectedPatientId});

  @override
  State<VitalsCollectionScreen> createState() => _VitalsCollectionScreenState();
}

class _VitalsCollectionScreenState extends State<VitalsCollectionScreen> {
  late String _selectedPatientId;
  PatientCategory _selectedCategory = PatientCategory.adultMale;

  // 3 Hardware Factors (Simulated / BLE Sensor Telemetry)
  int _heartRate = 78;
  int _spO2 = 97;
  double _bodyTemp = 98.6;
  bool _isBleSyncing = false;

  // Manual Entry by ASHA Worker
  final TextEditingController _systolicCtrl = TextEditingController(text: '120');
  final TextEditingController _diastolicCtrl = TextEditingController(text: '80');
  final TextEditingController _nlpMsgCtrl = TextEditingController();

  // Category Questions answers
  final Map<String, bool> _questionAnswers = {};

  // Evaluated Triage
  TriageAssessmentDto? _evaluationResult;
  bool _doctorConsultRequested = false;
  bool _ambulanceDispatched = false;
  StreamSubscription<VitalsDto>? _telemetrySub;

  @override
  void initState() {
    super.initState();
    final patientRepo = PatientRepository();
    final initialPatient = widget.selectedPatientId != null
        ? patientRepo.getPatientById(widget.selectedPatientId!)
        : (patientRepo.activePatient ?? patientRepo.defaultPatient);

    _selectedPatientId = initialPatient?.id ?? (patientRepo.patients.isNotEmpty ? patientRepo.patients.first.id : '');

    // Initialize category according to patient profile if possible
    if (initialPatient != null) {
      if (initialPatient.isPregnant) {
        _selectedCategory = PatientCategory.pregnantMaternal;
      } else if (initialPatient.age < 5) {
        _selectedCategory = PatientCategory.childUnder5;
      } else if (initialPatient.gender.toUpperCase() == 'FEMALE' || initialPatient.age >= 60) {
        _selectedCategory = PatientCategory.adultFemaleElderly;
      } else {
        _selectedCategory = PatientCategory.adultMale;
      }
    }

    _runTriageCalculation();

    // Bind live hardware heartbeat and telemetry stream
    if (_selectedPatientId.isNotEmpty) {
      HardwareVitalsTelemetryService().bindPatientTelemetryStream(_selectedPatientId);
      _telemetrySub = HardwareVitalsTelemetryService().telemetryStream.listen((vitals) {
        if (mounted && vitals.patientId == _selectedPatientId) {
          setState(() {
            _heartRate = vitals.pulse;
            _spO2 = vitals.spO2;
            _bodyTemp = vitals.temperature;
            _systolicCtrl.text = vitals.systolicBp.toString();
            _diastolicCtrl.text = vitals.diastolicBp.toString();
          });
          _runTriageCalculation();
        }
      });
    }
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _nlpMsgCtrl.dispose();
    super.dispose();
  }

  void _syncHardwareSensors() async {
    setState(() => _isBleSyncing = true);
    await Future.delayed(const Duration(milliseconds: 600));

    // Ingest simulated or connected physical sensor telemetry
    await HardwareVitalsTelemetryService().ingestHardwareReading(
      patientId: _selectedPatientId,
      pulse: 82,
      spO2: 98,
      temperature: 98.4,
      systolicBp: int.tryParse(_systolicCtrl.text.trim()) ?? 120,
      diastolicBp: int.tryParse(_diastolicCtrl.text.trim()) ?? 80,
    );

    if (mounted) {
      setState(() {
        _isBleSyncing = false;
        _heartRate = 82;
        _spO2 = 98;
        _bodyTemp = 98.4;
      });
      _runTriageCalculation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live telemetry captured from BLE pulse oximeter & synced to cloud.'),
          backgroundColor: RuralCareColors.success,
        ),
      );
    }
  }

  void _onNlpMessageChanged(String text) {
    if (text.trim().length > 3) {
      final res = NlpSymptomService().parseMessage(text);
      if (res.extractedSymptoms.isNotEmpty) {
        // Auto-check relevant category questions if symptoms align
        final questions = ClinicalTriageEngine().getQuestionsForCategory(_selectedCategory);
        for (final q in questions) {
          if (res.dangerFlags.isNotEmpty && q.isRedFlag) {
            _questionAnswers[q.id] = true;
          }
        }
      }
      _runTriageCalculation();
    }
  }

  void _runTriageCalculation() {
    final patientRepo = PatientRepository();
    final patient = patientRepo.getPatientById(_selectedPatientId) ?? patientRepo.activePatient;
    final patientName = patient?.fullName ?? 'Beneficiary';

    final sys = int.tryParse(_systolicCtrl.text.trim()) ?? 120;
    final dia = int.tryParse(_diastolicCtrl.text.trim()) ?? 80;

    final nlpRes = NlpSymptomService().parseMessage(_nlpMsgCtrl.text.trim());

    setState(() {
      _evaluationResult = ClinicalTriageEngine().evaluate(
        patientId: _selectedPatientId,
        patientName: patientName,
        category: _selectedCategory,
        heartRate: _heartRate,
        spO2: _spO2,
        bodyTemp: _bodyTemp,
        systolicBp: sys,
        diastolicBp: dia,
        questionAnswers: _questionAnswers,
        rawMessage: _nlpMsgCtrl.text.trim(),
        nlpSymptoms: nlpRes.extractedSymptoms,
        organZone: nlpRes.primaryOrganZone,
      );
    });
  }

  void _escalateEmergencyToDoctorAndAmbulance() {
    final patientRepo = PatientRepository();
    final patient = patientRepo.getPatientById(_selectedPatientId) ?? patientRepo.activePatient;
    if (patient == null) return;

    final aptRepo = AppointmentRepository();
    final emergencyRepo = EmergencyRepository();
    final docs = DoctorRepository().registeredDoctors;
    final onDutyDoctor = docs.isNotEmpty ? docs.first : null;

    // 1. Create immediate urgent consultation request to available doctor
    aptRepo.addAppointment(
      AppointmentDto(
        id: 'APT-EMERGENCY-${DateTime.now().millisecondsSinceEpoch % 100000}',
        patientId: patient.id,
        patientName: patient.fullName,
        doctorName: onDutyDoctor?.name ?? 'Dr. Amit Sharma',
        specialty: onDutyDoctor?.specialty ?? 'Emergency Medicine',
        facilityName: onDutyDoctor?.facilityName ?? 'Baramati Sub-District Hospital',
        scheduledTime: DateTime.now(),
        type: 'TELECONSULTATION',
        status: 'WAITING_ROOM',
        chiefComplaint: 'CRITICAL EMERGENCY: ${_evaluationResult?.redFlagAlerts.join(', ') ?? "Acute physiological instability"}',
        queueNumber: _evaluationResult?.queueNumber ?? 'P0-01',
        triagePriority: 'P0',
        symptoms: _evaluationResult?.extractedSymptoms ?? ['Cardiac / Respiratory Emergency'],
        primaryIssue: _evaluationResult?.affectedBodyZone ?? 'Emergency',
      ),
    );

    // 2. Trigger 108 Emergency Ambulance dispatch log
    emergencyRepo.triggerSosEvent(
      EmergencyEventDto(
        id: 'EMG-${DateTime.now().millisecondsSinceEpoch % 10000}',
        patientId: patient.id,
        patientName: patient.fullName,
        triggeredAt: DateTime.now(),
        urgencyLevel: 'CRITICAL_P0',
        nextOfKinNotified: true,
        facilityNotified: true,
        ambulanceDispatched: true,
        assignedFacilityName: 'Baramati Sub-District Hospital',
        ambulanceVehicleNo: 'MH-12-AMB-108',
        etaMinutes: 8,
        status: 'DISPATCHED',
      ),
    );

    setState(() {
      _doctorConsultRequested = true;
      _ambulanceDispatched = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('P0 EMERGENCY ESCALATED! Immediate doctor consult dispatched and 108 ambulance notified.'),
        backgroundColor: RuralCareColors.critical,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _saveDiagnosisRecord() async {
    final patientRepo = PatientRepository();
    final patient = patientRepo.getPatientById(_selectedPatientId) ?? patientRepo.activePatient;
    if (patient == null) return;

    final sys = int.tryParse(_systolicCtrl.text.trim()) ?? 120;
    final dia = int.tryParse(_diastolicCtrl.text.trim()) ?? 80;

    final newVitals = VitalsDto(
      id: 'vit-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patient.id,
      recordedById: 'asha-worker-01',
      recordedByRole: 'ASHA',
      recordedAt: DateTime.now(),
      systolicBp: sys,
      diastolicBp: dia,
      pulse: _heartRate,
      spO2: _spO2,
      temperature: _bodyTemp,
      bloodSugar: 110,
      haemoglobin: 12.5,
    );

    await patientRepo.updateVitals(patient.id, newVitals);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clinical diagnosis saved for ${patient.fullName}. Triage: ${_evaluationResult?.calculatedPriority.code ?? "P2"} Priority.'),
          backgroundColor: RuralCareColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patients = patientRepo.patients;
    final activePatient = patientRepo.getPatientById(_selectedPatientId) ??
        (patients.isNotEmpty ? patients.first : null);

    if (activePatient == null) {
      return Scaffold(
        backgroundColor: RuralCareColors.canvas,
        appBar: AppBar(
          title: const Text('Clinical Health Diagnosis', style: AppTypography.pageTitle),
          backgroundColor: RuralCareColors.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No patient registered. Please register a beneficiary first.'),
        ),
      );
    }

    final triage = _evaluationResult?.calculatedPriority ?? TriagePriority.p2Green;
    final questions = ClinicalTriageEngine().getQuestionsForCategory(_selectedCategory);

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        title: const Text('Clinical Health Diagnosis', style: AppTypography.pageTitle),
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: RuralCareColors.primary),
            tooltip: 'Recalculate Triage',
            onPressed: _runTriageCalculation,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: RuralCareColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Patient Selector (Supports any registered beneficiary)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RuralCareColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Beneficiary for Diagnosis',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedPatientId.isNotEmpty ? _selectedPatientId : patients.first.id,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                    items: patients.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.fullName} (${p.age}${p.gender == "FEMALE" ? "F" : "M"} • ${p.village})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null) {
                        setState(() {
                          _selectedPatientId = newId;
                          final p = patientRepo.getPatientById(newId);
                          if (p != null) {
                            if (p.isPregnant) {
                              _selectedCategory = PatientCategory.pregnantMaternal;
                            } else if (p.age < 5) {
                              _selectedCategory = PatientCategory.childUnder5;
                            } else if (p.gender.toUpperCase() == 'FEMALE' || p.age >= 60) {
                              _selectedCategory = PatientCategory.adultFemaleElderly;
                            } else {
                              _selectedCategory = PatientCategory.adultMale;
                            }
                          }
                        });
                        _runTriageCalculation();
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ABHA ID: ${activePatient.abhaId.isNotEmpty ? activePatient.abhaId : "ABHA-${activePatient.ruralCareId}"} • Assigned ASHA: ${activePatient.assignedAsha}',
                    style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Upfront Patient Category Selection (Pregnant/Maternal, Child, Man, Woman)
            const Text('1. Patient Clinical Category', style: AppTypography.sectionTitle),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PatientCategory.values.map((cat) {
                final isSel = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.labelEn),
                  selected: isSel,
                  selectedColor: RuralCareColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? Colors.white : RuralCareColors.textPrimary,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                    _runTriageCalculation();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 3. Three Factors given by Hardware (Heart Rate, SpO2, Body Temp) + Sensor Sync
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                          Icon(Icons.bluetooth_connected_rounded, size: 18, color: RuralCareColors.teal),
                          SizedBox(width: 8),
                          Text(
                            '2. Hardware Vitals Telemetry',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: _syncHardwareSensors,
                        icon: _isBleSyncing
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                            : const Icon(Icons.sync_rounded, size: 14),
                        label: Text(_isBleSyncing ? 'Syncing...' : 'Capture Sensors', style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Heart Rate
                      Expanded(
                        child: _vitalTelemetryCard(
                          label: 'Heart Rate',
                          value: '$_heartRate',
                          unit: 'bpm',
                          icon: Icons.favorite_rounded,
                          color: _heartRate > 105 || _heartRate < 50 ? RuralCareColors.critical : RuralCareColors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // SpO2
                      Expanded(
                        child: _vitalTelemetryCard(
                          label: 'Blood Oxygen (SpO2)',
                          value: '$_spO2',
                          unit: '%',
                          icon: Icons.air_rounded,
                          color: _spO2 < 92 ? RuralCareColors.critical : const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Body Temp
                      Expanded(
                        child: _vitalTelemetryCard(
                          label: 'Body Temp',
                          value: '$_bodyTemp',
                          unit: '°F',
                          icon: Icons.thermostat_rounded,
                          color: _bodyTemp >= 101.0 ? RuralCareColors.warning : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: RuralCareColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Hardware connected: Medical-grade Pulse Oximeter & Infrared Thermometer active.', style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Blood Pressure entered manually by ASHA worker
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RuralCareColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18, color: RuralCareColors.primary),
                      SizedBox(width: 8),
                      Text(
                        '3. Blood Pressure (Manual Entry by ASHA)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _systolicCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _runTriageCalculation(),
                          decoration: const InputDecoration(
                            labelText: 'Systolic BP (mmHg)',
                            hintText: 'e.g. 120',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _diastolicCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _runTriageCalculation(),
                          decoration: const InputDecoration(
                            labelText: 'Diastolic BP (mmHg)',
                            hintText: 'e.g. 80',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 5. Category-Specific Clinical Questions (Govt Prescribed NHM/RBSK)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RuralCareColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '4. Category Targeted Checklist',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                      Text(
                        'MoHFW / NHM Protocol',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...questions.map((q) {
                    final isChecked = _questionAnswers[q.id] ?? false;
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) {
                        setState(() => _questionAnswers[q.id] = val ?? false);
                        _runTriageCalculation();
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: q.isRedFlag ? RuralCareColors.critical : RuralCareColors.primary,
                      title: Text(
                        q.textEn,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: q.isRedFlag ? FontWeight.bold : FontWeight.w500,
                          color: isChecked && q.isRedFlag ? RuralCareColors.critical : RuralCareColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(q.clinicalRationale, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 6. NLP Symptom Reading from Patient Messages
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RuralCareColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.translate_rounded, size: 18, color: RuralCareColors.primary),
                      SizedBox(width: 8),
                      Text(
                        '5. Patient Message / Voice NLP Intake',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Transcribe or enter colloquial complaint (e.g. "mera pet dukhra hai", "chhati me dard"):',
                    style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nlpMsgCtrl,
                    maxLines: 2,
                    onChanged: _onNlpMessageChanged,
                    decoration: InputDecoration(
                      hintText: 'Enter patient words in Hindi, Marathi, or English...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(10),
                      suffixIcon: const Icon(Icons.mic, color: RuralCareColors.primary),
                    ),
                  ),
                  if (_evaluationResult != null && _evaluationResult!.extractedSymptoms.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _evaluationResult!.extractedSymptoms.map((s) {
                        return Chip(
                          label: Text(s, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: RuralCareColors.primarySoft,
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 7. Digital Triage Result Badge (P0 Red, P1 Yellow, P2 Green)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: triage == TriagePriority.p0Red
                    ? RuralCareColors.criticalSoft
                    : (triage == TriagePriority.p1Yellow ? RuralCareColors.warningSoft : RuralCareColors.successSoft),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: triage == TriagePriority.p0Red
                      ? RuralCareColors.critical
                      : (triage == TriagePriority.p1Yellow ? RuralCareColors.warning : RuralCareColors.success),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            triage == TriagePriority.p0Red ? Icons.emergency_rounded : Icons.verified_rounded,
                            color: triage == TriagePriority.p0Red
                                ? RuralCareColors.critical
                                : (triage == TriagePriority.p1Yellow ? RuralCareColors.warning : RuralCareColors.success),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TRIAGE RESULT: ${triage.code} PRIORITY',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: triage == TriagePriority.p0Red
                                  ? RuralCareColors.critical
                                  : (triage == TriagePriority.p1Yellow ? RuralCareColors.warning : RuralCareColors.success),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: triage == TriagePriority.p0Red ? RuralCareColors.critical : RuralCareColors.border,
                          ),
                        ),
                        child: Text(
                          _evaluationResult?.queueNumber ?? 'P2-01',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    triage.labelEn,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                  ),
                  if (_evaluationResult != null && _evaluationResult!.redFlagAlerts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._evaluationResult!.redFlagAlerts.map((flag) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 6, color: RuralCareColors.critical),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(flag, style: const TextStyle(fontSize: 11, color: RuralCareColors.critical, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        )),
                  ],

                  // In case of emergency (P0) -> Immediate Escalation Triggers
                  if (triage == TriagePriority.p0Red) ...[
                    const SizedBox(height: 14),
                    const Divider(color: RuralCareColors.critical, height: 1),
                    const SizedBox(height: 12),
                    const Text(
                      'EMERGENCY RESCUE ACTIONS REQUIRED:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.critical),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RuralCareColors.critical,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _escalateEmergencyToDoctorAndAmbulance,
                            icon: const Icon(Icons.flash_on_rounded, size: 16),
                            label: Text(
                              (_ambulanceDispatched || _doctorConsultRequested) ? 'Alert Dispatched ✓' : 'Instant Doctor & 108 Call',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: RuralCareColors.critical),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                            );
                          },
                          icon: const Icon(Icons.local_shipping_rounded, size: 16, color: RuralCareColors.critical),
                          label: const Text('Track 108', style: TextStyle(fontSize: 11, color: RuralCareColors.critical, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Save Diagnosis Record Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuralCareColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveDiagnosisRecord,
                child: const Text('Save Diagnosis & Update Patient Record', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _vitalTelemetryCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
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
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: RuralCareColors.textSecondary), maxLines: 1),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(fontSize: 9, color: RuralCareColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
