import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/emergency_event_dto.dart';
import 'package:ruralcare/data/repositories/emergency_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

class EmergencyTrackingScreen extends StatefulWidget {
  const EmergencyTrackingScreen({super.key});

  @override
  State<EmergencyTrackingScreen> createState() => _EmergencyTrackingScreenState();
}

class _EmergencyTrackingScreenState extends State<EmergencyTrackingScreen> {
  int _etaMinutes = 14;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 40), (_) {
      if (mounted && _etaMinutes > 1) {
        setState(() => _etaMinutes--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergRepo = EmergencyRepository();
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient;

    return ListenableBuilder(
      listenable: emergRepo,
      builder: (context, _) {
        final event = emergRepo.activeEvent;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.criticalRed,
            foregroundColor: Colors.white,
            title: const Text('🚨 Emergency SOS Dispatch & Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // High-visibility Emergency Alarm Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.criticalRed, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.criticalRed, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CRITICAL PRE-ECLAMPSIA ALERT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.criticalRed)),
                            Text('Patient: ${patient.fullName} (32 Wks Pregnant)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const Text('GPS: Kashti Village (18.618° N, 74.571° E)', style: TextStyle(fontSize: 10, color: AppColors.neutral700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ambulance ETA Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.airport_shuttle, color: AppColors.criticalRed, size: 26),
                                SizedBox(width: 8),
                                Text('108 Emergency Ambulance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                              child: Text('ETA: $_etaMinutes MINS', style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _infoRow('Ambulance Vehicle', event.ambulanceVehicleNumber),
                        _infoRow('Assigned Driver', '${event.ambulanceDriverName} (${event.ambulanceContact})'),
                        _infoRow('Target Hospital', event.assignedHospital),
                        _infoRow('Route Corridor', 'Kashti $\\rightarrow$ Patas $\\rightarrow$ Baramati SDH (24.5 km)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Multi-Tier Escalation Ladder
                Text('Multi-Tier Escalation Ladder (Real-time Status)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
                const SizedBox(height: 10),
                _buildEscalationStep(
                  tier: 'TIER 1',
                  title: 'Next-of-Kin Emergency Alert',
                  desc: 'SMS and automated IVR voice call triggered to ${patient.emergencyContact?.name ?? "Rajesh Devi"} (${patient.emergencyContact?.phoneNumber ?? ""})',
                  status: 'CONFIRMED ACKNOWLEDGED',
                  isSuccess: event.isNextOfKinAlerted,
                ),
                const SizedBox(height: 8),
                _buildEscalationStep(
                  tier: 'TIER 2',
                  title: 'First Referral Unit (FRU) Pre-Alert',
                  desc: 'Baramati SDH Emergency Department alerted. Obstetric OT & 2 units O+ve blood reserved.',
                  status: 'READY & STANDING BY',
                  isSuccess: event.isHospitalAlerted,
                ),
                const SizedBox(height: 8),
                _buildEscalationStep(
                  tier: 'TIER 3',
                  title: '108 Advanced Life Support (ALS) Ambulance',
                  desc: 'Driver Santosh More dispatched from Daund staging point. Telemetry synchronized with ER.',
                  status: 'EN ROUTE TO VILLAGE',
                  isSuccess: event.isAmbulanceDispatched,
                ),
                const SizedBox(height: 20),

                // Emergency Calling Hotlines
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dialing 108 Ambulance Dispatcher (${event.ambulanceContact})...')),
                          );
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Ambulance'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed, foregroundColor: Colors.white, minimumSize: const Size(0, 46)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dialing Baramati SDH Emergency Room (+91 2112 224003)...')),
                          );
                        },
                        icon: const Icon(Icons.local_hospital),
                        label: const Text('Call Hospital ER'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.slateNavy, foregroundColor: Colors.white, minimumSize: const Size(0, 46)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Emergency event stands recorded in ABDM safety audit.')),
                      );
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Return to Safety Dashboard', style: TextStyle(color: AppColors.neutral700)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        ],
      ),
    );
  }

  Widget _buildEscalationStep({
    required String tier,
    required String title,
    required String desc,
    required String status,
    required bool isSuccess,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isSuccess ? const Color(0xFFDCFCE7) : AppColors.neutral200,
              radius: 14,
              child: Icon(isSuccess ? Icons.check : Icons.hourglass_top, color: isSuccess ? const Color(0xFF15803D) : AppColors.neutral600, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$tier: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                        child: Text(status, style: const TextStyle(color: Color(0xFF15803D), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.neutral700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
