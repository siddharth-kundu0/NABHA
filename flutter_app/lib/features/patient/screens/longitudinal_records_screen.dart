import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

class LongitudinalRecordsScreen extends StatefulWidget {
  const LongitudinalRecordsScreen({super.key});

  @override
  State<LongitudinalRecordsScreen> createState() => _LongitudinalRecordsScreenState();
}

class _LongitudinalRecordsScreenState extends State<LongitudinalRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Longitudinal Health Records'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.terracotta,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Prescriptions'),
            Tab(icon: Icon(Icons.science), text: 'Lab Reports'),
            Tab(icon: Icon(Icons.trending_up), text: 'Vitals Trend'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([aptRepo, patientRepo]),
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildPrescriptionsTab(context, aptRepo.prescriptions),
              _buildLabReportsTab(context),
              _buildVitalsTrendTab(context, patientRepo.defaultPatient),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrescriptionsTab(BuildContext context, List<PrescriptionDto> prescriptions) {
    if (prescriptions.isEmpty) {
      return const Center(child: Text('No active prescriptions found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prescriptions.length,
      itemBuilder: (context, idx) {
        final rx = prescriptions[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, color: AppColors.forestTeal),
                        const SizedBox(width: 8),
                        Text(
                          rx.id,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.forestTealDark),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.forestTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ABHA FHIR Verified', style: TextStyle(fontSize: 10, color: AppColors.forestTealDark, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Prescribed by: ${rx.doctorName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('Diagnosis: ${rx.diagnosis}', style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                const Divider(height: 20),
                const Text('Medications / औषधे:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                ...rx.medicines.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAntiGlare,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.forestTeal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('Dose: ${m.dosage} • ${m.frequency} (${m.durationDays} Days)', style: const TextStyle(fontSize: 11, color: AppColors.neutral700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                if (rx.adviceNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Doctor\'s Advice: ${rx.adviceNotes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.neutral700)),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Exporting ${rx.id} to ABDM Health Locker...')),
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share to ABDM', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabReportsTab(BuildContext context) {
    final labReports = [
      {
        'title': 'Complete Blood Count (CBC)',
        'date': 'Yesterday, 04:30 PM',
        'facility': 'Baramati SDH Laboratory',
        'isCritical': true,
        'parameters': [
          {'name': 'Haemoglobin (Hb)', 'value': '7.8 g/dL', 'range': '11.0 - 15.0 g/dL', 'alert': true},
          {'name': 'Total Leukocyte Count (WBC)', 'value': '8,400 /mcL', 'range': '4,000 - 11,000', 'alert': false},
          {'name': 'Platelet Count', 'value': '210,000 /mcL', 'range': '150,000 - 450,000', 'alert': false},
        ],
      },
      {
        'title': 'Obstetric Ultrasound (USG)',
        'date': '3 Days Ago',
        'facility': 'Baramati SDH Diagnostic Centre',
        'isCritical': false,
        'parameters': [
          {'name': 'Gestational Age', 'value': '32 Weeks ± 4 Days', 'range': 'Target: 40 Wks', 'alert': false},
          {'name': 'Fetal Heart Rate (FHR)', 'value': '144 bpm', 'range': '120 - 160 bpm', 'alert': false},
          {'name': 'Amniotic Fluid Index (AFI)', 'value': '12.4 cm', 'range': '8.0 - 18.0 cm', 'alert': false},
          {'name': 'Placental Location', 'value': 'Fundal, Grade II', 'range': 'Normal', 'alert': false},
        ],
      },
      {
        'title': 'Urine Routine & Albumin',
        'date': '3 Days Ago',
        'facility': 'Kashti Sub-Centre Point of Care',
        'isCritical': true,
        'parameters': [
          {'name': 'Urine Albumin (Proteinuria)', 'value': '1+ (30 mg/dL)', 'range': 'Nil', 'alert': true},
          {'name': 'Urine Sugar', 'value': 'Nil', 'range': 'Nil', 'alert': false},
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: labReports.length,
      itemBuilder: (context, idx) {
        final rep = labReports[idx];
        final isCritical = rep['isCritical'] as bool;
        final params = rep['parameters'] as List<Map<String, dynamic>>;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rep['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    if (isCritical)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Attention Flag', style: TextStyle(color: AppColors.terracotta, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Text('${rep['facility']} • ${rep['date']}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                const Divider(height: 16),
                ...params.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p['name'] as String, style: const TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              Text(
                                p['value'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: (p['alert'] as bool) ? AppColors.terracotta : AppColors.neutral900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('(${p['range']})', style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalsTrendTab(BuildContext context, dynamic patient) {
    final history = [
      {
        'timestamp': 'Today, 08:30 AM',
        'worker': 'Sunita Tai Gaikwad (ASHA)',
        'bp': '148/96 mmHg',
        'hb': '7.8 g/dL',
        'spo2': '96%',
        'bs': '142 mg/dL',
        'isElevated': true,
      },
      {
        'timestamp': '5 Days Ago',
        'worker': 'Kashti Sub-Centre CHO',
        'bp': '142/92 mmHg',
        'hb': '8.1 g/dL',
        'spo2': '97%',
        'bs': '138 mg/dL',
        'isElevated': true,
      },
      {
        'timestamp': '2 Weeks Ago',
        'worker': 'Sunita Tai Gaikwad (ASHA)',
        'bp': '130/84 mmHg',
        'hb': '8.4 g/dL',
        'spo2': '98%',
        'bs': '124 mg/dL',
        'isElevated': false,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.forestTealLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.forestTeal.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.monitor_heart, color: AppColors.forestTealDark),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Continuous longitudinal monitoring tracks blood pressure and haemoglobin trends to prevent pre-eclampsia.',
                  style: TextStyle(fontSize: 11, color: AppColors.neutral800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...history.map((h) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(h['timestamp'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        if (h['isElevated'] as bool)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.terracotta.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Elevated', style: TextStyle(color: AppColors.terracotta, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    Text('Recorded by: ${h['worker']}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _vitalCol('BP', h['bp'] as String, isElevated: h['isElevated'] as bool),
                        _vitalCol('Hb', h['hb'] as String, isElevated: true),
                        _vitalCol('SpO2', h['spo2'] as String),
                        _vitalCol('Sugar', h['bs'] as String),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _vitalCol(String label, String val, {bool isElevated = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
