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
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo + Wordmark
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
                    // Controls: Language Pill + Emergency Help + Profile Avatar
                    Row(
                      children: [
                        // Language Selector Pill
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const LanguageAccessibilityScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
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
                                    color: lang == 'English' ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                  ),
                                ),
                                const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                Text(
                                  'हि',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: lang == 'Hindi' ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                  ),
                                ),
                                const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                Text(
                                  'म',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: lang == 'Marathi' ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Emergency Help Button (Solid Red)
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Profile Avatar Pill
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF0F2942),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Profile',
                            style: TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage personal details, access & preferences',
                            style: TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Text(
                        'Patient View',
                        style: TextStyle(
                          fontFamily: 'Noto Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // PATIENT HERO CARD
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
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
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check, size: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.fullName,
                              style: const TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Text(
                                'ID: ${patient.ruralCareId}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${patient.village}, ${patient.district} • Kashti PHC',
                                    style: const TextStyle(
                                      fontFamily: 'Noto Sans',
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
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
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 13, color: Color(0xFF104A7B)),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF104A7B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SETTINGS & PREFERENCES SECTION TITLE
                const Padding(
                  padding: EdgeInsets.only(left: 2.0, bottom: 8.0),
                  child: Text(
                    'SETTINGS & PREFERENCES',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),

                // Card 1: Personal Details
                _buildFloatingCard(
                  icon: Icons.badge_outlined,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0369A1),
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
                _buildFloatingCard(
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
                _buildFloatingCard(
                  icon: Icons.emergency_share_outlined,
                  iconBg: const Color(0xFFFFE4E6),
                  iconColor: const Color(0xFFE11D48),
                  title: 'Emergency Contacts',
                  subtitle: '1 contact configured',
                  statusBadge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontFamily: 'Noto Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
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
                _buildFloatingCard(
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFB45309),
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
                _buildFloatingCard(
                  icon: Icons.lock_reset_rounded,
                  iconBg: const Color(0xFFF1F5F9),
                  iconColor: const Color(0xFF475569),
                  title: 'Account & Security',
                  subtitle: 'Phone number, session & preferences',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => PrivacySecurityScreen(patient: patient)),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Persistence Verification Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Data saved on this device',
                        style: TextStyle(
                          fontFamily: 'Noto Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Sign Out Button (Soft Red)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEE2E2),
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out from Device?'),
                          content: const Text('All queued records remain safely saved in offline cache.'),
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
                        SizedBox(width: 6),
                        Text(
                          'Sign Out from Device',
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Role Switcher for Testing Demo
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(
                      'Testing Mode: Switch Role (${session.activeRole.name})',
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

  Widget _buildFloatingCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? statusBadge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (statusBadge != null) ...[
                        const SizedBox(width: 8),
                        statusBadge,
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
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
    return 'RS';
  }
}
