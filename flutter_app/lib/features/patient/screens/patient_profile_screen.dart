import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';
import 'package:ruralcare/features/patient/screens/personal_details_screen.dart';
import 'package:ruralcare/features/patient/screens/language_accessibility_screen.dart';
import 'package:ruralcare/features/patient/screens/privacy_security_screen.dart';

/// Screen 1: Profile Overview (V2 Modern)
/// Exactly reproducing Stitch Screen `ce2a8f8bb13f4dbfbf2f9c397e5ab57a`
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, cache, session]),
      builder: (context, _) {
        final patient = patientRepo.defaultPatient;
        final lang = session.activeLanguage;
        final initials = _getInitials(patient.fullName);

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              color: RuralCareColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: RuralCareColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: RuralCareColors.primary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'RuralCare',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: RuralCareColors.primary,
                          ),
                        ),
                      ],
                    ),
                    // Language Switcher & Emergency & Avatar Pill
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const LanguageAccessibilityScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: RuralCareColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: RuralCareColors.border),
                            ),
                            child: Text(
                              lang == 'Hindi' ? 'हिन्दी' : (lang == 'Marathi' ? 'मराठी' : 'EN'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                  'Emergency Help',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFF104A7B),
                          child: Text(
                            initials,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patient Profile', style: AppTypography.pageTitle),
                        SizedBox(height: 2),
                        Text('Manage personal details, access & preferences', style: AppTypography.supporting),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: AppDecorations.statusBadge(background: RuralCareColors.primarySoft),
                      child: const Text(
                        'Patient View',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.primary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PATIENT HERO CARD
                Container(
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with verified badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF104A7B),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: RuralCareColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check, size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.fullName, style: AppTypography.cardTitle),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: AppDecorations.statusBadge(background: RuralCareColors.primarySoft),
                              child: Text(
                                'ID: ${patient.ruralCareId}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: RuralCareColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: RuralCareColors.textSecondary),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${patient.village}, ${patient.district} • Kashti PHC',
                                    style: AppTypography.supporting,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => PersonalDetailsScreen(patient: patient)),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: RuralCareColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: RuralCareColors.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: RuralCareColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SETTINGS & CLINICAL ACCESS CARDS
                const Text(
                  'SETTINGS & PREFERENCES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: RuralCareColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                // Card 1: Personal Details
                _buildNavigationCard(
                  icon: Icons.badge_outlined,
                  iconBg: RuralCareColors.primarySoft,
                  iconColor: const Color(0xFF104A7B),
                  title: 'Personal Details',
                  subtitle: 'Name, phone, age, gender & village',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => PersonalDetailsScreen(patient: patient)),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Card 2: Language & Accessibility
                _buildNavigationCard(
                  icon: Icons.translate_rounded,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4338CA),
                  title: 'Language & Accessibility',
                  subtitle: 'English, हिन्दी, मराठी • Text size & contrast',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const LanguageAccessibilityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Card 3: Emergency Contacts
                _buildNavigationCard(
                  icon: Icons.emergency_share_outlined,
                  iconBg: RuralCareColors.criticalSoft,
                  iconColor: RuralCareColors.critical,
                  title: 'Emergency Contacts',
                  subtitle: '1 contact configured',
                  statusPill: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: AppDecorations.statusBadge(background: RuralCareColors.successSoft),
                    child: const Text(
                      'Active',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RuralCareColors.success),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => PrivacySecurityScreen(patient: patient)),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Card 4: Privacy & Data Sharing
                _buildNavigationCard(
                  icon: Icons.shield_outlined,
                  iconBg: RuralCareColors.warningSoft,
                  iconColor: RuralCareColors.warning,
                  title: 'Privacy & Data Sharing',
                  subtitle: 'Manage care record sharing with clinic',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => PrivacySecurityScreen(patient: patient)),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Card 5: Account & Security
                _buildNavigationCard(
                  icon: Icons.lock_reset_rounded,
                  iconBg: RuralCareColors.surfaceSubtle,
                  iconColor: RuralCareColors.textPrimary,
                  title: 'Account & Security',
                  subtitle: 'Phone number, session & preferences',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => PrivacySecurityScreen(patient: patient)),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // FOOTER NOTE & APP PERSISTENCE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: RuralCareColors.teal, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data saved on this device (Offline Outbox Ready)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: RuralCareColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Role Switcher Tile (Testing Persona)
                InkWell(
                  onTap: () => DemoRoleSwitcher.show(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: RuralCareColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RuralCareColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.swap_horiz_rounded, color: RuralCareColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Switch Role Persona', style: AppTypography.body),
                                Text('Current: ${session.activeRole.name}', style: AppTypography.supporting),
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right_rounded, color: RuralCareColors.textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RuralCareColors.critical,
                      backgroundColor: RuralCareColors.criticalSoft,
                      side: BorderSide(color: RuralCareColors.critical.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out from Device?'),
                          content: const Text('All queued local records will remain safely saved in offline outbox cache.'),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out from Device',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? statusPill,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTypography.cardTitle),
                      if (statusPill != null) ...[
                        const SizedBox(width: 8),
                        statusPill,
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.supporting, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: RuralCareColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'PT';
  }
}
