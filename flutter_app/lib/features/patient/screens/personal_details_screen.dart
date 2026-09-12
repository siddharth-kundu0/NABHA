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
                color: Colors.white,
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
                        const Text(
                          'Edit Basic Information',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Full Name', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: AppDecorations.input(hintText: 'Enter full name'),
                    ),
                    const SizedBox(height: 14),
                    const Text('Age', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: AppDecorations.input(hintText: 'Enter age in years'),
                    ),
                    const SizedBox(height: 14),
                    const Text('Gender', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      children: ['FEMALE', 'MALE', 'OTHER'].map((g) {
                        final isSel = selectedGender == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: isSel,
                            selectedColor: const Color(0xFFE8F5F2),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF0A6B56) : const Color(0xFF0F172A),
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
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A6B56),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                              backgroundColor: Color(0xFF0A6B56),
                            ),
                          );
                        },
                        child: const Text('Update Details', style: TextStyle(fontWeight: FontWeight.bold)),
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
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(102),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Global Row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                              decoration: const BoxDecoration(
                                color: Color(0xFF104A7B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RuralCare',
                              style: TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF104A7B),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Language Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'EN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: session.activeLanguage == 'English' ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                  Text(
                                    'हि',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: session.activeLanguage == 'Hindi' ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                  Text(
                                    'म',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: session.activeLanguage == 'Marathi' ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Emergency Button
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emergency_rounded, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Emergency Help',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                // Sub-header with Back button & Centered Title
                Container(
                  color: Colors.white,
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back, size: 18, color: Color(0xFF475569)),
                              SizedBox(width: 4),
                              Text(
                                'Back',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Personal Details',
                            style: TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 60), // Balance back button width
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card 1: Basic Information
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                              Icon(Icons.badge_outlined, color: Color(0xFF0A6B56), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Basic Information',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _openEditBasicDialog(context, patientRepo, currentPatient),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5F2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 13, color: Color(0xFF0A6B56)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0A6B56)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildField('Full Name', currentPatient.fullName),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildField('Registered Mobile', currentPatient.mobileNumber)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Color(0xFF15803D)),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField('Age / DOB', '${currentPatient.age} years (15 Aug 1982)')),
                          Expanded(child: _buildField('Gender', currentPatient.gender == 'FEMALE' ? 'Female' : 'Male')),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Card 2: Residential Location
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Color(0xFF0A6B56), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Residential Location',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildField('State', 'Maharashtra')),
                          Expanded(child: _buildField('District', currentPatient.district)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField('Sub-District / Block', 'Baramati')),
                          Expanded(child: _buildField('Village / Local Area', currentPatient.village)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Card 3: Assigned Care Center
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_hospital_outlined, color: Color(0xFF0A6B56), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Assigned Care Center',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4F1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.apartment_rounded, color: Color(0xFF0A6B56), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Kashti PHC',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        'Primary Facility',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    currentPatient.subCentre,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(Icons.near_me_outlined, size: 14, color: Color(0xFF0A6B56)),
                                      SizedBox(width: 4),
                                      Text(
                                        '1.8 km from residential village',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0A6B56),
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

                const SizedBox(height: 24),

                // Save Changes CTA Button (Solid Teal #0A6B56)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6B56),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All personal details are confirmed and securely synced'),
                          backgroundColor: Color(0xFF0A6B56),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 6),
                        Text('Save Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Cancel Text Button
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
