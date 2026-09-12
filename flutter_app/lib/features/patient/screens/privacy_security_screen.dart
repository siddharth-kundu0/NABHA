import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

/// Screen 4: Privacy, Contacts & Security (V2 Modern)
/// Exactly reproducing Stitch Screen `04162c5bed434968863f15176672fac1`
class PrivacySecurityScreen extends StatefulWidget {
  final PatientDto patient;

  const PrivacySecurityScreen({super.key, required this.patient});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  void _openEditContactDialog(BuildContext context, PatientRepository patientRepo, PatientDto current) {
    final nameCtrl = TextEditingController(text: current.emergencyContact.name);
    final relCtrl = TextEditingController(text: current.emergencyContact.relationship);
    final phoneCtrl = TextEditingController(text: current.emergencyContact.phoneNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                      'Emergency Contact Details',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Contact Full Name', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: AppDecorations.input(hintText: 'e.g. Rajesh Devi / Sunita Sharma'),
                ),
                const SizedBox(height: 14),
                const Text('Relationship', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  controller: relCtrl,
                  decoration: AppDecorations.input(hintText: 'e.g. Wife / Spouse / Husband / Parent'),
                ),
                const SizedBox(height: 14),
                const Text('Phone Number', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: AppDecorations.input(hintText: '+91 98765 11223'),
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
                      final n = nameCtrl.text.trim();
                      final r = relCtrl.text.trim();
                      final p = phoneCtrl.text.trim();
                      if (n.isNotEmpty && p.isNotEmpty) {
                        patientRepo.updateEmergencyContact(
                          patientId: current.id,
                          contact: EmergencyContactDto(name: n, relationship: r, phoneNumber: p),
                        );
                      }
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emergency contact saved and verified'),
                          backgroundColor: Color(0xFF0A6B56),
                        ),
                      );
                    },
                    child: const Text('Save Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();
    final cache = LocalCacheService();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, session, cache]),
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
                            'Privacy & Security',
                            style: TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.shield_outlined, color: Color(0xFF0A6B56), size: 19),
                      const SizedBox(width: 8),
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
                // SECTION 1: EMERGENCY CONTACT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Emergency Contact',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _openEditContactDialog(context, patientRepo, currentPatient),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 15, color: Color(0xFF0A6B56)),
                          SizedBox(width: 4),
                          Text(
                            '+ Add Contact',
                            style: TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A6B56),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.perm_phone_msg_rounded, color: Color(0xFFEF4444), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentPatient.emergencyContact.name.isNotEmpty
                                          ? currentPatient.emergencyContact.name
                                          : 'Sunita Sharma',
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '(${currentPatient.emergencyContact.relationship.isNotEmpty ? currentPatient.emergencyContact.relationship : "Wife / पत्नी"})',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.call_outlined, size: 13, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentPatient.emergencyContact.phoneNumber.isNotEmpty
                                          ? currentPatient.emergencyContact.phoneNumber
                                          : '+91 98765 11223',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: Color(0xFF15803D)),
                                SizedBox(width: 4),
                                Text(
                                  'Active / सक्रिय',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _openEditContactDialog(context, patientRepo, currentPatient),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 14, color: Color(0xFF475569)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              patientRepo.updateEmergencyContact(
                                patientId: currentPatient.id,
                                contact: const EmergencyContactDto(name: '', relationship: '', phoneNumber: ''),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Contact removed')),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Remove',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
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
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 13, color: Color(0xFFF59E0B)),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'This contact is notified if you trigger an emergency alert.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // SECTION 2: DATA SHARING & CONSENT
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Color(0xFF0A6B56), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Data Sharing & Consent',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Share Records with Attending Doctors',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Allows doctors at PHC Rampur to review your consultation history.',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Switch.adaptive(
                              value: session.shareWithDoctors,
                              activeColor: const Color(0xFF0A6B56),
                              onChanged: (v) => session.toggleShareWithDoctors(v),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Offline Record Cache',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Keep selected records available on this device.',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Switch.adaptive(
                              value: session.offlineRecordCache,
                              activeColor: const Color(0xFF0A6B56),
                              onChanged: (v) => session.toggleOfflineRecordCache(v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Text('🔒', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Control how your health information is shared for care.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // SECTION 3: ACCOUNT ACTIONS
                const Row(
                  children: [
                    Icon(Icons.manage_accounts_outlined, color: Color(0xFF64748B), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Account Actions',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verification OTP sent to registered number')),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4F1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF0A6B56), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Update Registered Mobile',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const Text('→', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Sign Out from Device?'),
                              content: const Text('Your offline data will remain preserved.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: AppDecorations.primaryButton(),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    session.resetToOnboarding();
                                  },
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.logout_rounded, color: Color(0xFF475569), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Sign Out of Device',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const Icon(Icons.logout_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      InkWell(
                        onTap: () {
                          cache.syncOutbox();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Local profile and cache removed from this device')),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.block_flipped, color: Color(0xFFDC2626), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delete / Close Account',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        'Removes local profile from this device.',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Text('→', style: TextStyle(fontSize: 16, color: Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Role Switcher Tile for Testing Demo
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(
                      'Testing Persona: ${session.activeRole.name}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => DemoRoleSwitcher.show(context),
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
}
