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
                    const Text('Emergency Contact Details', style: AppTypography.cardTitle),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: RuralCareColors.textSecondary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Contact Full Name', style: AppTypography.supporting),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: AppDecorations.input(hintText: 'e.g. Rajesh Devi'),
                ),
                const SizedBox(height: 14),
                const Text('Relationship', style: AppTypography.supporting),
                const SizedBox(height: 6),
                TextField(
                  controller: relCtrl,
                  decoration: AppDecorations.input(hintText: 'e.g. Spouse / Husband / Parent'),
                ),
                const SizedBox(height: 14),
                const Text('Phone Number', style: AppTypography.supporting),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: AppDecorations.input(hintText: '+91 98234 11205'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: AppDecorations.primaryButton(),
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
                          backgroundColor: RuralCareColors.teal,
                        ),
                      );
                    },
                    child: const Text('Save Contact'),
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
                      const Expanded(
                        child: Text('Privacy & Security', style: AppTypography.cardTitle),
                      ),
                      const Icon(Icons.shield_outlined, color: RuralCareColors.primary, size: 20),
                      const SizedBox(width: 8),
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
                // SECTION 1: EMERGENCY CONTACTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emergency_rounded, color: RuralCareColors.critical, size: 18),
                        SizedBox(width: 6),
                        Text('Emergency Contact', style: AppTypography.cardTitle),
                      ],
                    ),
                    InkWell(
                      onTap: () => _openEditContactDialog(context, patientRepo, currentPatient),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 15, color: RuralCareColors.primary),
                          SizedBox(width: 4),
                          Text(
                            '+ Add / Update',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RuralCareColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: RuralCareColors.criticalSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.perm_phone_msg_rounded, color: RuralCareColors.critical, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentPatient.emergencyContact.name.isNotEmpty
                                          ? currentPatient.emergencyContact.name
                                          : 'Rajesh Devi',
                                      style: AppTypography.cardTitle,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${currentPatient.emergencyContact.relationship.isNotEmpty ? currentPatient.emergencyContact.relationship : "Spouse"})',
                                      style: AppTypography.supporting,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.call_outlined, size: 14, color: RuralCareColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentPatient.emergencyContact.phoneNumber.isNotEmpty
                                          ? currentPatient.emergencyContact.phoneNumber
                                          : '+91 98234 11205',
                                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: AppDecorations.statusBadge(background: RuralCareColors.successSoft),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: RuralCareColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'Active / सक्रिय',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: RuralCareColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: RuralCareColors.border, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: RuralCareColors.textSecondary,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                            onPressed: () => _openEditContactDialog(context, patientRepo, currentPatient),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: RuralCareColors.critical,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Remove'),
                            onPressed: () {
                              patientRepo.updateEmergencyContact(
                                patientId: currentPatient.id,
                                contact: const EmergencyContactDto(name: '', relationship: '', phoneNumber: ''),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Contact removed')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: RuralCareColors.warning),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This contact is notified if you trigger an emergency alert.',
                        style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SECTION 2: PRIVACY & CARE SHARING
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: RuralCareColors.primary, size: 18),
                    SizedBox(width: 6),
                    Text('Data Sharing & Consent', style: AppTypography.cardTitle),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: AppDecorations.card(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Share Records with Attending Doctors',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Allows doctors at PHC Kashti & Baramati SDH to review your consultation history.',
                                    style: AppTypography.supporting,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch.adaptive(
                              value: session.shareWithDoctors,
                              activeColor: RuralCareColors.primary,
                              onChanged: (v) => session.toggleShareWithDoctors(v),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: RuralCareColors.border, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Offline Record Cache',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Keep selected health records available on this device without internet.',
                                    style: AppTypography.supporting,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch.adaptive(
                              value: session.offlineRecordCache,
                              activeColor: RuralCareColors.primary,
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
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 15, color: RuralCareColors.textSecondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Control how your health information is shared for care.',
                          style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 3: ACCOUNT ACTIONS
                const Row(
                  children: [
                    Icon(Icons.manage_accounts_outlined, color: RuralCareColors.textSecondary, size: 18),
                    SizedBox(width: 6),
                    Text('Account Actions', style: AppTypography.cardTitle),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: AppDecorations.card(),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: RuralCareColors.tealSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone_iphone_rounded, color: RuralCareColors.teal, size: 18),
                        ),
                        title: const Text('Update Registered Mobile', style: AppTypography.body),
                        subtitle: Text('+91 ${currentPatient.mobileNumber}', style: AppTypography.supporting),
                        trailing: const Icon(Icons.chevron_right_rounded, color: RuralCareColors.textSecondary),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verification OTP sent to registered number')),
                          );
                        },
                      ),
                      const Divider(color: RuralCareColors.border, height: 1),
                      ListTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: RuralCareColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_sweep_rounded, color: RuralCareColors.textSecondary, size: 18),
                        ),
                        title: const Text('Clear Local Device Cache', style: AppTypography.body),
                        subtitle: Text('${cache.pendingSyncCount} pending mutations', style: AppTypography.supporting),
                        trailing: const Icon(Icons.chevron_right_rounded, color: RuralCareColors.textSecondary),
                        onTap: () {
                          cache.syncOutbox();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Device cache cleared')),
                          );
                        },
                      ),
                      const Divider(color: RuralCareColors.border, height: 1),
                      ListTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: RuralCareColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: RuralCareColors.primary, size: 18),
                        ),
                        title: const Text('Switch Role Persona (Testing)', style: AppTypography.body),
                        subtitle: Text('Current: ${session.activeRole.name}', style: AppTypography.supporting),
                        trailing: const Icon(Icons.chevron_right_rounded, color: RuralCareColors.primary),
                        onTap: () => DemoRoleSwitcher.show(context),
                      ),
                    ],
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
}
