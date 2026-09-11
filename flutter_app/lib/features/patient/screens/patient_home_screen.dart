import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/referral_repository.dart';
import 'medicine_availability_screen.dart';
import 'diagnostic_locator_screen.dart';
import '../../features/teleconsult/screens/live_teleconsult_room_screen.dart';
import '../../features/emergency/screens/emergency_tracking_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final aptRepo = AppointmentRepository();
    final refRepo = ReferralRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, aptRepo, refRepo]),
      builder: (context, _) {
        final patient = patientRepo.defaultPatient;
        final vitals = patient.latestVitals;
        final upcomingApt = aptRepo.appointments.isNotEmpty ? aptRepo.appointments.first : null;
        final activeRef = refRepo.referrals.isNotEmpty ? refRepo.referrals.first : null;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('नमस्ते, ${patient.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('ABHA: ${patient.abhaId}', style: const TextStyle(fontSize: 12, color: AppColors.forestTealLight)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new alerts. Your records are synced.')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Urgent / Ongoing Action Banner
                if (activeRef != null && activeRef.status != 'CLOSED')
                  _buildActiveReferralBanner(context, activeRef),

                const SizedBox(height: 12),

                // Health Vitals Snapshot Card
                _buildVitalsCard(context, patient, vitals),

                const SizedBox(height: 16),

                // Next Teleconsultation / Appointment
                if (upcomingApt != null)
                  _buildUpcomingAppointmentCard(context, upcomingApt),

                const SizedBox(height: 16),

                // Quick Action Services Grid
                Text(
                  'Essential Health Services / आरोग्य सेवा',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.slateNavy,
                      ),
                ),
                const SizedBox(height: 10),
                _buildActionGrid(context),

                const SizedBox(height: 16),

                // Assigned ASHA worker contact card
                _buildAshaCard(context, patient.assignedAsha),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveReferralBanner(BuildContext context, dynamic referral) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.alt_route, color: Color(0xFFB45309), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Referral: ${referral.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Target: ${referral.targetFacilityName}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${referral.statusDisplay}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 36),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tap the Referrals tab in the bottom bar to view full live tracking')),
              );
            },
            child: const Text('Track', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(BuildContext context, dynamic patient, dynamic vitals) {
    final hasWarning = vitals != null && vitals.hasWarning;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.forestTeal, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Latest Health Vitals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasWarning ? AppColors.terracotta.withOpacity(0.15) : AppColors.forestTealLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasWarning ? '🟡 Review Required' : '🟢 Normal Range',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasWarning ? AppColors.terracotta : AppColors.forestTealDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (vitals != null) ...[
              Row(
                children: [
                  _vitalItem('Blood Pressure', '${vitals.systolicBp}/${vitals.diastolicBp} mmHg', isElevated: vitals.systolicBp > 140 || vitals.diastolicBp > 90),
                  _vitalItem('Haemoglobin', '${vitals.haemoglobin ?? "--"} g/dL', isElevated: (vitals.haemoglobin ?? 12) < 9.0),
                  _vitalItem('SpO2', '${vitals.spO2}%', isElevated: vitals.spO2 < 95),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _vitalItem('Pulse Rate', '${vitals.pulse} bpm'),
                  _vitalItem('Random Sugar', '${vitals.bloodSugar ?? "--"} mg/dL'),
                  _vitalItem('Temperature', '${vitals.temperature}°F'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Recorded by ASHA ${patient.assignedAsha} • ICMR Safe Pregnancy Protocol',
                style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vitalItem(String label, String value, {bool isElevated = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isElevated ? AppColors.terracotta.withOpacity(0.08) : AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: isElevated ? Border.all(color: AppColors.terracotta, width: 1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isElevated ? AppColors.terracotta : AppColors.neutral900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context, dynamic apt) {
    return Card(
      color: AppColors.forestTealLight.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.forestTeal, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.video_camera_front_rounded, color: AppColors.forestTeal),
                const SizedBox(width: 8),
                const Text(
                  'Teleconsultation Waiting Room',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestTealDark, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.forestTeal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('READY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(apt.doctorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('${apt.specialty} • ${apt.facilityName}', style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
            const SizedBox(height: 8),
            Text('Reason: ${apt.chiefComplaint}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => LiveTeleconsultRoomScreen(
                      patientName: apt.patientName,
                      doctorName: apt.doctorName,
                      specialty: apt.specialty,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Join Video Consultation Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _gridCard(
          context,
          icon: Icons.medication_rounded,
          color: const Color(0xFF0D9488),
          title: 'Medicines Availability',
          subtitle: 'Live stock at PHC & SDH',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const MedicineAvailabilityScreen()),
            );
          },
        ),
        _gridCard(
          context,
          icon: Icons.biotech_rounded,
          color: AppColors.slateNavy,
          title: 'Diagnostic Labs',
          subtitle: 'USG, Blood & Urine tests',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const DiagnosticLocatorScreen()),
            );
          },
        ),
        _gridCard(
          context,
          icon: Icons.emergency,
          color: AppColors.criticalRed,
          title: 'Emergency SOS',
          subtitle: '108 Ambulance & Nearest SDH',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
            );
          },
        ),
        _gridCard(
          context,
          icon: Icons.assignment_turned_in_rounded,
          color: AppColors.terracotta,
          title: 'ANC Maternal Tracker',
          subtitle: '32 Wks • Visit 3 Completed',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Viewing maternal milestones in health records tab.')),
            );
          },
        ),
      ],
    );
  }

  Widget _gridCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              radius: 18,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.neutral600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAshaCard(BuildContext context, String ashaName) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAntiGlare,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.forestTeal,
            radius: 20,
            child: Icon(Icons.support_agent, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned ASHA Worker (आरोग्य सेविका)', style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
                Text(ashaName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('Kashti Village Sub-centre Sector', style: TextStyle(fontSize: 11, color: AppColors.forestTealDark)),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.phone, color: AppColors.forestTeal),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling ASHA Worker $ashaName (+91 98220 19284)...')),
              );
            },
          ),
        ],
      ),
    );
  }
}
