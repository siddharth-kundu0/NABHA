import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/features/doctor/utils/doctor_strings.dart';

/// Doctor Profile, Credentials & Settings Tab
class DoctorProfileTab extends StatefulWidget {
  const DoctorProfileTab({super.key});

  @override
  State<DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<DoctorProfileTab> {
  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final strings = DoctorStrings.of(session);
        final doctor = DoctorRepository().getDoctorForSession(session);
        final rawClean = doctor.name.replaceAll('Dr. ', '').replaceAll('Dr.', '').trim();
        final nameParts = rawClean.split(' ').where((w) => w.isNotEmpty).toList();
        final initials = nameParts.length >= 2
            ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
            : (nameParts.isNotEmpty ? nameParts[0][0].toUpperCase() : 'DR');

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Doctor Credential Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RuralCareColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RuralCareColors.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: RuralCareColors.teal,
                          child: Text(
                            initials,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: RuralCareColors.textPrimary),
                              ),
                              Text(
                                '${doctor.specialty} • ${strings.clinicianRole}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reg: ${doctor.registrationNumber} • ${doctor.qualification}',
                                style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: RuralCareColors.border),
                    const SizedBox(height: 12),
                    // ABDM HPID badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: RuralCareColors.tealSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 16, color: RuralCareColors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ABDM Healthcare Professional ID: 89-${(doctor.doctorId.hashCode.abs() % 9000 + 1000)}-${(doctor.registrationNumber.hashCode.abs() % 9000 + 1000)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.teal),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: RuralCareColors.successSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: RuralCareColors.success),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Digital E-Prescription Signature Verified & Active',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Practice Facility & Schedule
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RuralCareColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined, size: 18, color: RuralCareColors.teal),
                        const SizedBox(width: 8),
                        Text(
                          strings.practiceFacilityTimings,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(strings.primaryFacility, style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                        Text(doctor.facilityName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary)),
                      ],
                    ),
                    const Divider(height: 16, color: RuralCareColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(strings.generalOpd, style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                        const Text('Mon - Fri • 09:00 AM - 02:00 PM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16, color: RuralCareColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(strings.teleconsultRoster, style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                        const Text('Tue & Thu • 02:30 PM - 05:00 PM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.teal)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Language & Settings
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RuralCareColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.translate, size: 18, color: RuralCareColors.teal),
                        const SizedBox(width: 8),
                        Text(
                          strings.langAndAccessibility,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RuralCareColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLanguageButton('English', 'en', session),
                        const SizedBox(width: 8),
                        _buildLanguageButton('हिंदी', 'hi', session),
                        const SizedBox(width: 8),
                        _buildLanguageButton('मराठी', 'mr', session),
                      ],
                    ),
                    const Divider(height: 24, color: RuralCareColors.border),
                    // Offline Mode toggle
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(strings.simulateOffline, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(strings.queueOfflineSub, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                        value: session.isOffline,
                        activeColor: RuralCareColors.teal,
                        onChanged: (val) {
                          session.toggleOffline(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Role Switcher Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => DemoRoleSwitcher.show(context),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  label: Text(strings.switchDemoProfile, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RuralCareColors.teal,
                    side: const BorderSide(color: RuralCareColors.teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(String label, String code, SessionCoordinator session) {
    final isSelected = code == 'en'
        ? session.isEnglish
        : (code == 'hi' ? session.isHindi : session.isMarathi);

    return Expanded(
      child: GestureDetector(
        key: ValueKey('profile_lang_$code'),
        onTap: () => session.switchLanguage(code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? RuralCareColors.teal : RuralCareColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? RuralCareColors.teal : RuralCareColors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : RuralCareColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
