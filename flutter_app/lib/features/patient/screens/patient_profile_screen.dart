import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/patient_dto.dart';

/// Patient Profile Screen conforming strictly to DESIGN.md Section 6:
/// Straightforward list rows for personal details, language, healthcare area,
/// next of kin, sharing preferences, and account actions.
/// Displays RuralCare ID cleanly without implying a government-issued identity.
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

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            title: const Text('Profile', style: AppTypography.pageTitle),
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(color: RuralCareColors.border, height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Clean RuralCare ID Card (no faux government seals, no gradients)
                _buildRuralCareIdCard(patient),

                const SizedBox(height: 24),

                // 2. Personal Details Group
                const Text('Personal details', style: AppTypography.sectionTitle),
                const SizedBox(height: 10),
                _buildSectionContainer([
                  _profileRow('Full name', patient.fullName),
                  _profileRow('Age & gender', '${patient.age} yrs • ${patient.gender.toUpperCase()}'),
                  _profileRow('Mobile number', '+91 ${patient.mobileNumber}'),
                  _profileRow('Healthcare area', '${patient.village} • ${patient.subCentre}'),
                ]),

                const SizedBox(height: 24),

                // 3. Care Network & Next of Kin Group
                const Text('Care network', style: AppTypography.sectionTitle),
                const SizedBox(height: 10),
                _buildSectionContainer([
                  _profileRow('Assigned health worker', patient.assignedAsha),
                  _profileRow('Primary health centre', 'Kashti PHC (Baramati)'),
                  _profileRow('Next of kin contact', 'Rajesh Devi (Spouse) • +91 98234 11205'),
                ]),

                const SizedBox(height: 24),

                // 4. Preferences & Settings
                const Text('Preferences', style: AppTypography.sectionTitle),
                const SizedBox(height: 10),
                _buildSectionContainer([
                  InkWell(
                    onTap: () => _openLanguageDialog(context, session),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Application language', style: AppTypography.body),
                          Row(
                            children: [
                              Text(
                                lang,
                                style: AppTypography.supporting.copyWith(
                                  color: RuralCareColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, color: RuralCareColors.textSecondary, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: RuralCareColors.border, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Offline auto-sync', style: AppTypography.body),
                        Switch.adaptive(
                          value: !cache.isOffline,
                          activeColor: RuralCareColors.primary,
                          onChanged: (val) => cache.toggleOfflineMode(),
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // 5. Account & Demo Role Switcher
                const Text('Account', style: AppTypography.sectionTitle),
                const SizedBox(height: 10),
                _buildSectionContainer([
                  ListTile(
                    title: const Text('Switch user role (Testing)', style: AppTypography.body),
                    subtitle: Text('Current: ${session.activeRole.name}', style: AppTypography.supporting),
                    trailing: const Icon(Icons.swap_horiz_rounded, color: RuralCareColors.primary),
                    onTap: () => DemoRoleSwitcher.show(context),
                  ),
                ]),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuralCareIdCard(PatientDto patient) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RuralCare Health ID',
                    style: AppTypography.supporting.copyWith(
                      fontWeight: FontWeight.w600,
                      color: RuralCareColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient.abhaId,
                    style: AppTypography.cardTitle.copyWith(letterSpacing: 0.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 40, color: RuralCareColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: RuralCareColors.border, height: 1),
          const SizedBox(height: 12),
          Text(
            patient.fullName,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 2),
          Text(
            'Primary beneficiary • ${patient.village} sector',
            style: AppTypography.supporting,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: AppDecorations.card(),
      child: Column(children: children),
    );
  }

  Widget _profileRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.supporting),
              Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const Divider(color: RuralCareColors.border, height: 1),
      ],
    );
  }

  void _openLanguageDialog(BuildContext context, SessionCoordinator session) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select language', style: AppTypography.sectionTitle),
        children: [
          SimpleDialogOption(
            onPressed: () {
              session.switchLanguage('English');
              Navigator.of(ctx).pop();
            },
            child: const Text('English', style: AppTypography.body),
          ),
          SimpleDialogOption(
            onPressed: () {
              session.switchLanguage('Hindi');
              Navigator.of(ctx).pop();
            },
            child: const Text('हिन्दी (Hindi)', style: AppTypography.body),
          ),
          SimpleDialogOption(
            onPressed: () {
              session.switchLanguage('Marathi');
              Navigator.of(ctx).pop();
            },
            child: const Text('मराठी (Marathi)', style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}
