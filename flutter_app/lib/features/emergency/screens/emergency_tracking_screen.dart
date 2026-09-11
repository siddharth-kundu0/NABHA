import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/emergency_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';

class EmergencyTrackingScreen extends StatefulWidget {
  const EmergencyTrackingScreen({super.key});

  @override
  State<EmergencyTrackingScreen> createState() => _EmergencyTrackingScreenState();
}

class _EmergencyTrackingScreenState extends State<EmergencyTrackingScreen> with SingleTickerProviderStateMixin {
  int _etaMinutes = 14;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 35), (_) {
      if (mounted && _etaMinutes > 1) {
        setState(() => _etaMinutes--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergRepo = EmergencyRepository();
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();
    final patient = patientRepo.defaultPatient;

    return ListenableBuilder(
      listenable: Listenable.merge([emergRepo, session]),
      builder: (context, _) {
        final event = emergRepo.activeEvent;
        final currentLang = session.activeLanguage;

        return Scaffold(
          backgroundColor: AppColors.stitchSurface,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: _buildStitchEmergencyHeader(context, session, currentLang),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Active Tactical Alarm Banner (Pulsing Red)
                _buildActiveTacticalBanner(currentLang),
                const SizedBox(height: 14),

                // 2. 108 Ambulance Telemetry & Countdown Card
                _buildAmbulanceTelemetryCard(event),
                const SizedBox(height: 14),

                // 3. Card 1: Notification Delivery Status (3 Destinations)
                _buildNotificationDeliveryCard(patient, event),
                const SizedBox(height: 14),

                // 4. Card 2: Active Location Link (GPS Map Preview)
                _buildActiveLocationLinkCard(context),
                const SizedBox(height: 14),

                // 5. Multi-Tier Escalation Ladder
                _buildEscalationLadder(patient, event),
                const SizedBox(height: 20),

                // 6. Thumb-Accessible Primary Action Buttons
                _buildActionButtons(context, event, emergRepo),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStitchEmergencyHeader(
    BuildContext context,
    SessionCoordinator session,
    String currentLang,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stitchSurface.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.slateNavy),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB91C1C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text('RuralCare SOS', style: TextStyle(fontSize: 10, color: AppColors.neutral600, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          CircleAvatar(radius: 3, backgroundColor: Color(0xFF15803D)),
                          SizedBox(width: 3),
                          Text('Synced', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text('Emergency Help', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildLangChip('EN', currentLang == 'English', () => session.switchLanguage('English')),
                        _buildLangChip('हि', currentLang == 'Hindi', () => session.switchLanguage('Hindi')),
                        _buildLangChip('म', currentLang == 'Marathi', () => session.switchLanguage('Marathi')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFD5E3FC),
                    child: Icon(Icons.person, size: 18, color: AppColors.slateNavy),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB91C1C) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.slateNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTacticalBanner(String currentLang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x14DC2626), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FadeTransition(
                    opacity: _pulseCtrl,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EMERGENCY ALERT ACTIVE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sensors, size: 12, color: Color(0xFFB91C1C)),
                    SizedBox(width: 4),
                    Text('Alert Active', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Emergency alert broadcast in progress. Emergency notifications dispatched to FRU hospital and ALS ambulance.',
            style: TextStyle(fontSize: 12, color: AppColors.neutral900, height: 1.3),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMetaPill(Icons.schedule, 'Today, 10:42 AM', Colors.white, AppColors.neutral700),
              _buildMetaPill(Icons.sync, 'Active • Monitoring', Colors.white, AppColors.stitchPrimary),
              _buildMetaPill(Icons.my_location, 'Location Shared ✓', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildAmbulanceTelemetryCard(dynamic event) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.airport_shuttle_rounded, color: Color(0xFFBA1A1A), size: 22),
                  SizedBox(width: 8),
                  Text(
                    '108 ALS Ambulance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neutral900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ETA: $_etaMinutes MINS',
                  style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          _infoRow('Vehicle Number', event?.ambulanceVehicleNumber ?? 'MH-12-RN-4402 (ALS Mobile ICU)'),
          _infoRow('Assigned Driver', '${event?.ambulanceDriverName ?? "Santosh More"} (Ph: ${event?.ambulanceContact ?? "108"})'),
          _infoRow('Target Hospital', event?.assignedHospital ?? 'Baramati Sub-District Hospital (SDH)'),
          _infoRow('Corridor Route', 'Kashti Village → Patas Bypass → Baramati (24.5 km)'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDeliveryCard(dynamic patient, dynamic event) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.hub_rounded, color: AppColors.stitchPrimary, size: 18),
                  SizedBox(width: 6),
                  Text('Notification Delivery Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900)),
                ],
              ),
              Text('3 Destinations', style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
            ],
          ),
          const SizedBox(height: 10),
          // Destination 1: Primary Contact
          _buildDeliveryItem(
            icon: Icons.family_restroom_rounded,
            title: '${patient.emergencyContact.name} (${patient.emergencyContact.relationship})',
            sub: 'SMS delivered • 10:42 AM',
            status: 'Location available',
            statusBg: const Color(0xFFDCFCE7),
            statusColor: const Color(0xFF15803D),
          ),
          const SizedBox(height: 8),
          // Destination 2: Hospital FRU
          _buildDeliveryItem(
            icon: Icons.local_hospital_rounded,
            title: 'Baramati SDH Emergency Room',
            sub: 'Obstetric OT & 2 units O+ve blood reserved',
            status: 'Alert Sent',
            statusBg: const Color(0xFFE0F2FE),
            statusColor: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 8),
          // Destination 3: 108 ALS Ambulance Desk
          _buildDeliveryItem(
            icon: Icons.emergency_rounded,
            title: '108 ALS Ambulance Staging Point',
            sub: 'Dispatched from Daund staging depot',
            status: 'En Route',
            statusBg: const Color(0xFFFFEDD5),
            statusColor: const Color(0xFFC2410C),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem({
    required IconData icon,
    required String title,
    required String sub,
    required String status,
    required Color statusBg,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EEFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.stitchPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.neutral900)),
                Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLocationLinkCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.share_location_rounded, color: Color(0xFF15803D), size: 18),
                  SizedBox(width: 6),
                  Text('Active Location Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                child: const Text('GPS Live', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Map preview tactical container
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFFDC2626), size: 28),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kashti Village, Sector 3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('18.618° N, 74.571° E • ~24.5 km to SDH', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationLadder(dynamic patient, dynamic event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Multi-Tier Escalation Ladder (त्रि-स्तरीय आपातकाल)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
        ),
        const SizedBox(height: 8),
        _buildStep(
          tier: 'TIER 1',
          title: 'Next-of-Kin Emergency Alert',
          desc: 'SMS & IVR call triggered to ${patient.emergencyContact.name}',
          isDone: event?.isNextOfKinAlerted ?? true,
        ),
        const SizedBox(height: 6),
        _buildStep(
          tier: 'TIER 2',
          title: 'First Referral Unit (FRU) Pre-Alert',
          desc: 'Baramati SDH Emergency Department alerted. Obstetric OT reserved.',
          isDone: event?.isHospitalAlerted ?? true,
        ),
        const SizedBox(height: 6),
        _buildStep(
          tier: 'TIER 3',
          title: '108 ALS Ambulance Dispatch',
          desc: 'Driver Santosh More dispatched with live telemetry.',
          isDone: event?.isAmbulanceDispatched ?? true,
        ),
      ],
    );
  }

  Widget _buildStep({required String tier, required String title, required String desc, required bool isDone}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(tier, style: TextStyle(color: isDone ? const Color(0xFF15803D) : AppColors.neutral600, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.neutral900)),
                Text(desc, style: const TextStyle(fontSize: 9, color: AppColors.neutral600)),
              ],
            ),
          ),
          Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 16, color: isDone ? const Color(0xFF15803D) : AppColors.neutral600),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic event, EmergencyRepository emergRepo) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFFBA1A1A),
                  content: Text('Dialing 108 Emergency Ambulance Dispatcher (${event?.ambulanceContact ?? "108"})...'),
                ),
              );
            },
            icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
            label: const Text('Call 108 Ambulance Dispatcher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Cancel Emergency SOS?'),
                  content: const Text('Are you sure you want to stand down the emergency alert? Responders and FRU will be notified.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Keep Active')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white),
                      onPressed: () {
                        emergRepo.resolveEmergency();
                        Navigator.of(dialogCtx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Stand Down SOS'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Stand Down Emergency Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.neutral700,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
