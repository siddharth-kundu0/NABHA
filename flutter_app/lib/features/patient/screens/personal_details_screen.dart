import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import '../utils/patient_strings.dart';

/// Screen 2: Personal Details (V2 Modern)
/// Exactly reproducing Stitch Screen `0721475508674e9c8de817dfe3143d05`
class PersonalDetailsScreen extends StatefulWidget {
  final PatientDto patient;

  const PersonalDetailsScreen({super.key, required this.patient});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  void _openEditBasicDialog(BuildContext context, PatientRepository patientRepo, PatientDto current, PatientStrings strings) {
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
                        Text(
                          strings.editBasicInfoTitle,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(strings.fullNameLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: AppDecorations.input(hintText: strings.fullNameLabel),
                    ),
                    const SizedBox(height: 14),
                    Text(strings.ageDobLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: AppDecorations.input(hintText: strings.ageDobLabel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime(DateTime.now().year - (int.tryParse(ageCtrl.text) ?? current.age), 1, 1),
                              firstDate: DateTime(1920),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              final now = DateTime.now();
                              int calculated = now.year - picked.year;
                              if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
                                calculated--;
                              }
                              setModalState(() {
                                ageCtrl.text = '$calculated';
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF0A6B56)),
                          label: const Text('Pick DOB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(strings.genderLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        {'code': 'FEMALE', 'label': strings.female},
                        {'code': 'MALE', 'label': strings.male},
                        {'code': 'OTHER', 'label': strings.otherGender},
                      ].map((item) {
                        final g = item['code']!;
                        final label = item['label']!;
                        final isSel = selectedGender == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(label),
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
                            SnackBar(
                              content: Text(strings.detailsUpdatedToast),
                              backgroundColor: const Color(0xFF0A6B56),
                            ),
                          );
                        },
                        child: Text(strings.updateDetailsBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        final strings = PatientStrings.of(session);

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
                            // Interactive Language Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => session.switchLanguage('en'),
                                    child: Text(
                                      'EN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isEnglish ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                  InkWell(
                                    onTap: () => session.switchLanguage('hi'),
                                    child: Text(
                                      'हि',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isHindi ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                  InkWell(
                                    onTap: () => session.switchLanguage('mr'),
                                    child: Text(
                                      'म',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isMarathi ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emergency_rounded, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      strings.emergencyHelp,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_back, size: 18, color: Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Text(
                                strings.back,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            strings.personalDetailsItem,
                            style: const TextStyle(
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
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined, color: Color(0xFF0A6B56), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                strings.basicInfoTitle,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _openEditBasicDialog(context, patientRepo, currentPatient, strings),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5F2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF0A6B56)),
                                  const SizedBox(width: 4),
                                  Text(
                                    strings.edit,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0A6B56)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildField(strings.fullNameLabel, currentPatient.fullName),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildField(strings.registeredMobileLabel, currentPatient.mobileNumber)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 12, color: Color(0xFF15803D)),
                                const SizedBox(width: 4),
                                Text(
                                  strings.verified,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField(strings.ageDobLabel, '${currentPatient.age} years (15 Aug 1982)')),
                          Expanded(child: _buildField(strings.genderLabel, currentPatient.gender == 'FEMALE' ? strings.female : strings.male)),
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
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Color(0xFF0A6B56), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            strings.addressLocationTitle,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildField(session.isHindi ? 'राज्य' : (session.isMarathi ? 'राज्य' : 'State'), 'Maharashtra')),
                          Expanded(child: _buildField(strings.districtLabel, currentPatient.district)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField(strings.talukaLabel, 'Baramati')),
                          Expanded(child: _buildField(strings.villageLabel, currentPatient.village)),
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
                      Row(
                        children: [
                          const Icon(Icons.local_hospital_outlined, color: Color(0xFF0A6B56), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            session.isHindi ? 'संबद्ध स्वास्थ्य केंद्र' : (session.isMarathi ? 'संलग्न आरोग्य केंद्र' : 'Assigned Care Center'),
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Kashti PHC',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        session.isHindi ? 'प्राथमिक केंद्र' : (session.isMarathi ? 'प्राथमिक केंद्र' : 'Primary Facility'),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    currentPatient.subCentre,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.near_me_outlined, size: 14, color: Color(0xFF0A6B56)),
                                      const SizedBox(width: 4),
                                      Text(
                                        session.isHindi
                                            ? 'गांव से 1.8 किमी दूर'
                                            : (session.isMarathi ? 'गावापासून १.८ किमी' : '1.8 km from residential village'),
                                        style: const TextStyle(
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
                      final msg = session.isHindi
                          ? 'सभी व्यक्तिगत विवरण पुष्ट और सुरक्षित रूप से सिंक किए गए हैं'
                          : (session.isMarathi
                              ? 'सर्व वैयक्तिक तपशील निश्चित आणि सुरक्षितपणे सिंक केले आहेत'
                              : 'All personal details are confirmed and securely synced');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: const Color(0xFF0A6B56),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 18),
                        const SizedBox(width: 6),
                        Text(strings.save, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Cancel Text Button
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      strings.cancel,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
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
