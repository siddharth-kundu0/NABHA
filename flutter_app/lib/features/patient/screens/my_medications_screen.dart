import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/features/patient/utils/patient_strings.dart';

/// Screen: My Medications (Medication Tracker & Prescriptions)
/// Adheres strictly to DESIGN.md Section 6:
/// Clear clinical information, dosage schedule, refill reminder,
/// radius 16 cards, 1px #DCE4ED border, localized in EN, HI, MR.
class MyMedicationsScreen extends StatefulWidget {
  const MyMedicationsScreen({super.key});

  @override
  State<MyMedicationsScreen> createState() => _MyMedicationsScreenState();
}

class _MyMedicationsScreenState extends State<MyMedicationsScreen> {
  int _selectedTabIndex = 0; // 0: Active, 1: Past

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final aptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([session, aptRepo, patientRepo]),
      builder: (context, _) {
        final strings = PatientStrings.of(session);
        final activePatient = patientRepo.activePatient;
        final patientId = activePatient?.id ?? '';

        final prescriptions = aptRepo.getPrescriptionsForPatient(patientId);

        // Separate into active and past
        final activeMeds = <Map<String, dynamic>>[];
        final pastMeds = <Map<String, dynamic>>[];

        for (final rx in prescriptions) {
          final isPast = DateTime.now().difference(rx.issuedAt).inDays > 30;
          for (final med in rx.medicines) {
            final entry = {
              'medicine': med,
              'doctorName': rx.doctorName,
              'diagnosis': rx.diagnosis,
              'issuedAt': rx.issuedAt,
              'isPast': isPast,
            };
            if (isPast) {
              pastMeds.add(entry);
            } else {
              activeMeds.add(entry);
            }
          }
        }

        final displayedList = _selectedTabIndex == 0 ? activeMeds : pastMeds;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              strings.myMedications,
              style: AppTypography.cardTitle,
            ),
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
                      child: _tabButton(strings.activePrescriptions, 0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _tabButton(strings.pastMedications, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: displayedList.isEmpty
              ? _buildEmptyState(strings)
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: displayedList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, idx) => _buildMedicineCard(
                    displayedList[idx],
                    session,
                    strings,
                  ),
                ),
        );
      },
    );
  }

  Widget _tabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
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

  Widget _buildEmptyState(PatientStrings strings) {
    final isPast = _selectedTabIndex == 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: RuralCareColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_outlined, color: RuralCareColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              isPast ? strings.noPastMedications : strings.noActiveMedications,
              style: AppTypography.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              strings.noActiveMedicationsSub,
              style: AppTypography.supporting,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(
    Map<String, dynamic> item,
    SessionCoordinator session,
    PatientStrings strings,
  ) {
    final med = item['medicine'] as PrescriptionItemDto;
    final doctorName = item['doctorName'] as String;
    final isPast = item['isPast'] as bool;

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  med.medicineName,
                  style: AppTypography.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(
                  background: isPast ? RuralCareColors.surfaceSubtle : RuralCareColors.successSoft,
                ),
                child: Text(
                  isPast ? strings.pastMedications : '${med.durationDays} ${strings.daysRemaining}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPast ? RuralCareColors.textSecondary : RuralCareColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: RuralCareColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${strings.dosageSchedule}: ${med.frequency}',
                style: AppTypography.supporting.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.water_drop_outlined, size: 14, color: RuralCareColors.teal),
              const SizedBox(width: 4),
              Text(
                strings.takeAfterFood,
                style: AppTypography.supporting.copyWith(color: RuralCareColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: RuralCareColors.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${strings.prescribedBy}$doctorName',
                style: AppTypography.supporting,
              ),
              if (!isPast)
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${med.medicineName}: ${strings.refillReminder} set!'),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_on, size: 14, color: RuralCareColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        strings.refillReminder,
                        style: AppTypography.supporting.copyWith(
                          color: RuralCareColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
