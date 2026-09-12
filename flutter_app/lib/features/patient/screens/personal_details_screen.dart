import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

/// Screen 2: Personal Details (V2 Modern)
/// Exactly reproducing Stitch Screen `0721475508674e9c8de817dfe3143d05`
class PersonalDetailsScreen extends StatefulWidget {
  final PatientDto patient;

  const PersonalDetailsScreen({super.key, required this.patient});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  void _openEditBasicDialog(BuildContext context, PatientRepository patientRepo, PatientDto current) {
    final nameCtrl = TextEditingController(text: current.fullName);
    final ageCtrl = TextEditingController(text: current.age.toString());
    String selectedGender = current.gender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: RuralCareColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Basic Information', style: AppTypography.cardTitle),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: RuralCareColors.textSecondary),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Full Name', style: AppTypography.supporting),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: AppDecorations.input(hintText: 'Enter full name'),
                    ),
                    const SizedBox(height: 14),
                    const Text('Age', style: AppTypography.supporting),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: AppDecorations.input(hintText: 'Enter age in years'),
                    ),
                    const SizedBox(height: 14),
                    const Text('Gender', style: AppTypography.supporting),
                    const SizedBox(height: 8),
                    Row(
                      children: ['FEMALE', 'MALE', 'OTHER'].map((g) {
                        final isSel = selectedGender == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: isSel,
                            selectedColor: RuralCareColors.primarySoft,
                            labelStyle: TextStyle(
                              color: isSel ? RuralCareColors.primary : RuralCareColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setModalState(() => selectedGender = g);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: AppDecorations.primaryButton(),
                        onPressed: () {
                          final newName = nameCtrl.text.trim();
                          final newAge = int.tryParse(ageCtrl.text.trim()) ?? current.age;
                          if (newName.isNotEmpty) {
                            patientRepo.updatePatientProfile(
                              patientId: current.id,
                              fullName: newName,
                              age: newAge,
                              gender: selectedGender,
                            );
                          }
                          Navigator.of(modalCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Personal details updated successfully'),
                              backgroundColor: RuralCareColors.teal,
                            ),
                          );
                        },
                        child: const Text('Update Details'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, session]),
      builder: (context, _) {
        final currentPatient = patientRepo.patients.firstWhere(
          (p) => p.id == widget.patient.id,
          orElse: () => widget.patient,
        );

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(105),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Global Row
                Container(
                  color: RuralCareColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: RuralCareColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: RuralCareColors.primary, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RuralCare',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: RuralCareColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Language Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: RuralCareColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: RuralCareColors.border),
                              ),
                              child: Text(
                                session.activeLanguage == 'Hindi'
                                    ? 'हिन्दी'
                                    : (session.activeLanguage == 'Marathi' ? 'मराठी' : 'EN'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Compact Emergency Help
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: RuralCareColors.critical,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emergency_rounded, color: Colors.white, size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'Emergency',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: RuralCareColors.border, height: 1),
                // Sub-header title row with Back Button
                Container(
                  color: RuralCareColors.surface,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: RuralCareColors.textPrimary, size: 20),
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      const Text('Personal Details', style: AppTypography.cardTitle),
                    ],
                  ),
                ),
                const Divider(color: RuralCareColors.border, height: 1),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card 1: Basic Information
                Container(
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.badge_outlined, color: RuralCareColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text('Basic Information', style: AppTypography.cardTitle),
                            ],
                          ),
                          InkWell(
                            onTap: () => _openEditBasicDialog(context, patientRepo, currentPatient),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: AppDecorations.statusBadge(background: RuralCareColors.primarySoft),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 13, color: RuralCareColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: RuralCareColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: RuralCareColors.border, height: 24),
                      _buildDataField('Full Name', currentPatient.fullName),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildDataField('Registered Mobile', currentPatient.mobileNumber)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: AppDecorations.statusBadge(background: RuralCareColors.successSoft),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: RuralCareColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: RuralCareColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildDataField('Age / DOB', '${currentPatient.age} years')),
                          Expanded(child: _buildDataField('Gender', currentPatient.gender)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Card 2: Residential Location
                Container(
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: RuralCareColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Residential Location', style: AppTypography.cardTitle),
                        ],
                      ),
                      const Divider(color: RuralCareColors.border, height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildDataField('State', 'Maharashtra')),
                          Expanded(child: _buildDataField('District', currentPatient.district)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildDataField('Sub-District / Block', 'Baramati')),
                          Expanded(child: _buildDataField('Village / Local Area', currentPatient.village)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Card 3: Assigned Care Center
                Container(
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_hospital_outlined, color: RuralCareColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Assigned Care Center', style: AppTypography.cardTitle),
                        ],
                      ),
                      const Divider(color: RuralCareColors.border, height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: RuralCareColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RuralCareColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: RuralCareColors.primarySoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.apartment_rounded, color: RuralCareColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Kashti PHC', style: AppTypography.cardTitle),
                                      Text('Primary Facility', style: AppTypography.supporting),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(currentPatient.subCentre, style: AppTypography.supporting),
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Icon(Icons.near_me_outlined, size: 14, color: RuralCareColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        '1.8 km from residential village',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: RuralCareColors.primary,
                                        ),
                                      ),
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
                ),

                const SizedBox(height: 28),

                // Save Changes CTA Button (52px)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: AppDecorations.primaryButton(),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All personal details are confirmed and securely synced'),
                          backgroundColor: RuralCareColors.teal,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Save Changes'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.supporting),
        const SizedBox(height: 3),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
