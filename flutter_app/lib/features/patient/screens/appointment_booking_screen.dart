import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/appointment_dto.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/facility_repository.dart';
import '../../features/teleconsult/screens/live_teleconsult_room_screen.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _complaintController = TextEditingController();

  String _selectedSpecialty = 'All Specialties';
  String _selectedSlot = '11:30 AM - 12:00 PM';

  final List<String> _specialties = [
    'All Specialties',
    'Obstetrics & Gynecology',
    'General Medicine',
    'Pediatrics',
    'Surgery & Ortho',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _complaintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aptRepo = AppointmentRepository();
    final facRepo = FacilityRepository();
    final patientRepo = PatientRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations & Appointments'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.terracotta,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.video_call), text: 'Teleconsultation'),
            Tab(icon: Icon(Icons.local_hospital), text: 'Facility In-Person'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: aptRepo,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTeleconsultTab(context, aptRepo, facRepo, patientRepo),
              _buildInPersonTab(context, aptRepo, facRepo, patientRepo),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewBookingSheet(context, aptRepo, facRepo, patientRepo),
        backgroundColor: AppColors.forestTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book New Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTeleconsultTab(
    BuildContext context,
    AppointmentRepository aptRepo,
    FacilityRepository facRepo,
    PatientRepository patientRepo,
  ) {
    final teleconsults = aptRepo.appointments.where((a) => a.type == 'TELECONSULTATION').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Assisted Teleconsultation via ASHA Worker',
          'Connect with specialists at Baramati SDH or Pune District Hospital without traveling 25+ kilometers.',
          Icons.wifi_tethering,
        ),
        const SizedBox(height: 16),
        Text(
          'Scheduled Teleconsultations (${teleconsults.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (teleconsults.isEmpty)
          _buildEmptyState('No scheduled teleconsultations.')
        else
          ...teleconsults.map((apt) => _buildAppointmentCard(context, apt, isTeleconsult: true)),
        const SizedBox(height: 24),
        Text(
          'Available On-Duty Specialists for Teleconsult',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDoctorListing(
          doctorName: 'Dr. Anjali Patil',
          specialty: 'Obstetrician & Gynecologist (MBBS, MD)',
          facility: 'Baramati Sub-District Hospital',
          waitTime: 'Next available: Today, 11:30 AM',
          onBook: () => _openQuickBookDialog(context, aptRepo, patientRepo, 'Dr. Anjali Patil', 'Obstetrics & Gynecology', 'Baramati Sub-District Hospital', 'TELECONSULTATION'),
        ),
        _buildDoctorListing(
          doctorName: 'Dr. Suresh More',
          specialty: 'Pediatrician (MBBS, DCH)',
          facility: 'Baramati Sub-District Hospital',
          waitTime: 'Next available: Today, 02:00 PM',
          onBook: () => _openQuickBookDialog(context, aptRepo, patientRepo, 'Dr. Suresh More', 'Pediatrics', 'Baramati Sub-District Hospital', 'TELECONSULTATION'),
        ),
        _buildDoctorListing(
          doctorName: 'Dr. Arvind Sharma',
          specialty: 'General Physician (MBBS)',
          facility: 'Daund CHC',
          waitTime: 'Next available: Tomorrow, 10:00 AM',
          onBook: () => _openQuickBookDialog(context, aptRepo, patientRepo, 'Dr. Arvind Sharma', 'General Medicine', 'Daund CHC', 'TELECONSULTATION'),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildInPersonTab(
    BuildContext context,
    AppointmentRepository aptRepo,
    FacilityRepository facRepo,
    PatientRepository patientRepo,
  ) {
    final inPersonApts = aptRepo.appointments.where((a) => a.type == 'IN_PERSON').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'OPD Appointment & Fast-Track Token',
          'Book priority token at CHC/SDH to bypass long queues. Show QR code at the intake counter.',
          Icons.qr_code_scanner,
        ),
        const SizedBox(height: 16),
        Text(
          'In-Person Appointments (${inPersonApts.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (inPersonApts.isEmpty)
          _buildEmptyState('No in-person OPD bookings yet.')
        else
          ...inPersonApts.map((apt) => _buildAppointmentCard(context, apt, isTeleconsult: false)),
        const SizedBox(height: 24),
        Text(
          'Nearby Hospitals & Facilities',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...facRepo.facilities.map((fac) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.slateNavy.withOpacity(0.12),
                  child: const Icon(Icons.local_hospital, color: AppColors.slateNavy),
                ),
                title: Text(fac.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${fac.typeDisplay} • ${fac.distanceKm} km away\nBeds: ${fac.availableBeds}/${fac.totalBeds} Available', style: const TextStyle(fontSize: 11)),
                isThreeLine: true,
                trailing: TextButton(
                  onPressed: () => _openQuickBookDialog(
                    context,
                    aptRepo,
                    patientRepo,
                    fac.onDutySpecialists.isNotEmpty ? fac.onDutySpecialists.first : 'Duty Medical Officer',
                    'General OPD',
                    fac.name,
                    'IN_PERSON',
                  ),
                  child: const Text('Book OPD'),
                ),
              ),
            )),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildInfoBanner(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.forestTealLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.forestTeal.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.forestTealDark, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestTealDark, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.neutral700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentDto apt, {required bool isTeleconsult}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isTeleconsult ? AppColors.forestTeal.withOpacity(0.15) : AppColors.slateNavy.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isTeleconsult ? '📹 Teleconsultation' : '🏥 Hospital Visit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isTeleconsult ? AppColors.forestTealDark : AppColors.slateNavy,
                    ),
                  ),
                ),
                Text(
                  apt.status,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestTeal),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(apt.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${apt.specialty} • ${apt.facilityName}', style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.neutral600),
                const SizedBox(width: 4),
                Text('Scheduled: ${apt.scheduledTime.hour}:${apt.scheduledTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            if (apt.chiefComplaint.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Notes: ${apt.chiefComplaint}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.neutral600)),
            ],
            const SizedBox(height: 10),
            if (isTeleconsult)
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
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Enter Waiting Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestTeal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 38),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorListing({
    required String doctorName,
    required String specialty,
    required String facility,
    required String waitTime,
    required VoidCallback onBook,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.forestTealLight,
          child: Icon(Icons.person, color: AppColors.forestTealDark),
        ),
        title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('$specialty\n$facility • $waitTime', style: const TextStyle(fontSize: 11)),
        isThreeLine: true,
        trailing: ElevatedButton(
          onPressed: onBook,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(70, 36),
          ),
          child: const Text('Book', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceAntiGlare,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Text(msg, style: const TextStyle(color: AppColors.neutral600, fontSize: 13)),
    );
  }

  void _openQuickBookDialog(
    BuildContext context,
    AppointmentRepository aptRepo,
    PatientRepository patientRepo,
    String doctor,
    String specialty,
    String facility,
    String type,
  ) {
    final patient = patientRepo.defaultPatient;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Slot for $doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialty: $specialty', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Facility: $facility'),
            Text('Type: $type'),
            const SizedBox(height: 12),
            const Text('Time Slot: Today, 11:30 AM - 12:00 PM'),
            const SizedBox(height: 8),
            TextField(
              controller: _complaintController,
              decoration: const InputDecoration(
                labelText: 'Chief Complaint / लक्षणे',
                hintText: 'e.g. Headache, high BP, swelling',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newApt = AppointmentDto(
                id: 'APT-${DateTime.now().millisecondsSinceEpoch % 10000}',
                patientId: patient.id,
                patientName: patient.fullName,
                doctorName: doctor,
                specialty: specialty,
                facilityName: facility,
                scheduledTime: DateTime.now().add(const Duration(hours: 2)),
                type: type,
                status: 'CONFIRMED',
                chiefComplaint: _complaintController.text.isNotEmpty ? _complaintController.text : 'Routine evaluation',
              );
              aptRepo.addAppointment(newApt);
              _complaintController.clear();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Appointment booked successfully with $doctor!')),
              );
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  void _openNewBookingSheet(
    BuildContext context,
    AppointmentRepository aptRepo,
    FacilityRepository facRepo,
    PatientRepository patientRepo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule a Consultation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedSpecialty,
              decoration: const InputDecoration(labelText: 'Select Specialty'),
              items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSpecialty = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSlot,
              decoration: const InputDecoration(labelText: 'Select Time Slot'),
              items: const [
                DropdownMenuItem(value: '10:00 AM - 10:30 AM', child: Text('10:00 AM - 10:30 AM')),
                DropdownMenuItem(value: '11:30 AM - 12:00 PM', child: Text('11:30 AM - 12:00 PM')),
                DropdownMenuItem(value: '02:00 PM - 02:30 PM', child: Text('02:00 PM - 02:30 PM')),
                DropdownMenuItem(value: '04:00 PM - 04:30 PM', child: Text('04:00 PM - 04:30 PM')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedSlot = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _complaintController,
              decoration: const InputDecoration(
                labelText: 'Symptoms / तक्रार',
                hintText: 'Describe current symptoms',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
              ),
              onPressed: () {
                final patient = patientRepo.defaultPatient;
                final newApt = AppointmentDto(
                  id: 'APT-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  patientId: patient.id,
                  patientName: patient.fullName,
                  doctorName: 'Dr. Anjali Patil (OB/GYN)',
                  specialty: _selectedSpecialty == 'All Specialties' ? 'Obstetrics & Gynecology' : _selectedSpecialty,
                  facilityName: 'Baramati Sub-District Hospital',
                  scheduledTime: DateTime.now().add(const Duration(hours: 3)),
                  type: _tabController.index == 0 ? 'TELECONSULTATION' : 'IN_PERSON',
                  status: 'CONFIRMED',
                  chiefComplaint: _complaintController.text.isNotEmpty ? _complaintController.text : 'Patient consultation request',
                );
                aptRepo.addAppointment(newApt);
                _complaintController.clear();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment successfully scheduled!')),
                );
              },
              child: const Text('Book Appointment'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
