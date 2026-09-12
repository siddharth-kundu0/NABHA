import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/teleconsult/screens/live_teleconsult_room_screen.dart';

/// Appointments screen adhering strictly to DESIGN.md Section 6:
/// Default to upcoming appointments; provide a quiet Past view.
/// Each row shows date/time, clinician/service, facility, and status.
/// Clean booking flow with 52px primary action, radius 16 cards, radius 24 bottom sheets.
class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  int _selectedView = 0; // 0: Upcoming, 1: Past
  final TextEditingController _complaintController = TextEditingController();

  String _selectedSpecialty = 'Obstetrics & Gynecology';
  String _selectedSlot = 'Today, 11:30 AM - 12:00 PM';
  String _selectedType = 'TELECONSULTATION';

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aptRepo = AppointmentRepository();
    final facRepo = FacilityRepository();
    final patientRepo = PatientRepository();

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        title: const Text('Appointments', style: AppTypography.pageTitle),
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: RuralCareColors.surface,
              border: Border(bottom: BorderSide(color: RuralCareColors.border, width: 1.0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _viewTabButton('Upcoming', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _viewTabButton('Past', 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: aptRepo,
        builder: (context, _) {
          final appointments = _selectedView == 0
              ? aptRepo.appointments
              : <AppointmentDto>[]; // Past appointments view

          if (appointments.isEmpty) {
            return _buildEmptyView();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: appointments.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
            itemBuilder: (ctx, idx) => _buildAppointmentRow(ctx, appointments[idx], patientRepo),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: RuralCareColors.surface,
          border: Border(top: BorderSide(color: RuralCareColors.border, width: 1.0)),
          boxShadow: AppDecorations.subtleShadow,
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openBookingSheet(context, aptRepo, facRepo, patientRepo),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Book appointment', style: AppTypography.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: RuralCareColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewTabButton(String title, int index) {
    final isSelected = _selectedView == index;
    return InkWell(
      onTap: () => setState(() => _selectedView = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? RuralCareColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? RuralCareColors.primary : RuralCareColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentRow(BuildContext context, AppointmentDto apt, PatientRepository patientRepo) {
    final isTeleconsult = apt.type == 'TELECONSULTATION';

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                apt.appointmentTime,
                style: AppTypography.supporting.copyWith(
                  fontWeight: FontWeight.w600,
                  color: RuralCareColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(
                  background: apt.status == 'CONFIRMED'
                      ? RuralCareColors.successSoft
                      : RuralCareColors.warningSoft,
                ),
                child: Text(
                  apt.status,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: apt.status == 'CONFIRMED'
                        ? RuralCareColors.success
                        : RuralCareColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            apt.doctorName,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 2),
          Text(
            '${apt.specialty} • ${apt.facilityName}',
            style: AppTypography.supporting,
          ),
          if (apt.chiefComplaint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${apt.chiefComplaint}',
              style: AppTypography.supporting.copyWith(color: RuralCareColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (isTeleconsult)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final patient = patientRepo.defaultPatient;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => LiveTeleconsultRoomScreen(
                              patientName: patient.fullName,
                              doctorName: apt.doctorName,
                              specialty: apt.specialty,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.video_call_outlined, size: 18),
                      label: const Text('Join consultation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RuralCareColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fast-track arrival pass confirmed for ${apt.doctorName}')),
                        );
                      },
                      icon: const Icon(Icons.qr_code_outlined, size: 18),
                      label: const Text('View arrival pass'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RuralCareColors.primary,
                        side: const BorderSide(color: RuralCareColors.inputBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note_outlined, size: 48, color: RuralCareColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              _selectedView == 0 ? 'No upcoming appointments' : 'No past appointments',
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: 6),
            Text(
              _selectedView == 0
                  ? 'Your scheduled teleconsultations and facility OPD visits will appear here.'
                  : 'Your completed consultations and records will be archived here.',
              textAlign: TextAlign.center,
              style: AppTypography.supporting,
            ),
          ],
        ),
      ),
    );
  }

  void _openBookingSheet(
    BuildContext context,
    AppointmentRepository aptRepo,
    FacilityRepository facRepo,
    PatientRepository patientRepo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RuralCareColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)), // DESIGN.md: radius 24
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Schedule an appointment', style: AppTypography.sectionTitle),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: RuralCareColors.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Consultation Type Selector
              Row(
                children: [
                  Expanded(
                    child: _typeSelectorOption(
                      'Teleconsultation',
                      'TELECONSULTATION',
                      _selectedType == 'TELECONSULTATION',
                      () => setSheetState(() => _selectedType = 'TELECONSULTATION'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeSelectorOption(
                      'In-Person OPD',
                      'IN_PERSON',
                      _selectedType == 'IN_PERSON',
                      () => setSheetState(() => _selectedType = 'IN_PERSON'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Specialty', style: AppTypography.supporting),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                items: const [
                  DropdownMenuItem(value: 'Obstetrics & Gynecology', child: Text('Obstetrics & Gynecology')),
                  DropdownMenuItem(value: 'General Medicine', child: Text('General Medicine')),
                  DropdownMenuItem(value: 'Pediatrics', child: Text('Pediatrics')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => _selectedSpecialty = val);
                },
              ),
              const SizedBox(height: 14),
              const Text('Time slot', style: AppTypography.supporting),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedSlot,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                items: const [
                  DropdownMenuItem(value: 'Today, 11:30 AM - 12:00 PM', child: Text('Today, 11:30 AM - 12:00 PM')),
                  DropdownMenuItem(value: 'Today, 02:00 PM - 02:30 PM', child: Text('Today, 02:00 PM - 02:30 PM')),
                  DropdownMenuItem(value: 'Tomorrow, 10:00 AM - 10:30 AM', child: Text('Tomorrow, 10:00 AM - 10:30 AM')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => _selectedSlot = val);
                },
              ),
              const SizedBox(height: 14),
              const Text('Reason for visit', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _complaintController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 3rd Trimester ANC routine follow-up',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final patient = patientRepo.defaultPatient;
                    final newApt = AppointmentDto(
                      id: 'APT-${DateTime.now().millisecondsSinceEpoch % 10000}',
                      patientId: patient.id,
                      patientName: patient.fullName,
                      doctorName: 'Dr. Anjali Patil',
                      specialty: _selectedSpecialty,
                      facilityName: 'Baramati Sub-District Hospital',
                      scheduledTime: DateTime.now().add(const Duration(hours: 3)),
                      type: _selectedType,
                      status: 'CONFIRMED',
                      chiefComplaint: _complaintController.text.isNotEmpty
                          ? _complaintController.text
                          : 'Clinical follow-up',
                    );
                    aptRepo.addAppointment(newApt);
                    _complaintController.clear();
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment confirmed successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Confirm appointment', style: AppTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeSelectorOption(String label, String value, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? RuralCareColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? RuralCareColors.primary : RuralCareColors.inputBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? RuralCareColors.primary : RuralCareColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
