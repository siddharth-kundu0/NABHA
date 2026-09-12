import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';

/// Onboarding Screen strictly conforming to DESIGN.md Section 6:
/// One decision per step: welcome -> language -> role -> basic profile -> account created.
/// Small product mark, short heading, one-sentence explanation, bottom 52px Continue action.
/// No marketing carousels or oversized illustrations.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0: Welcome, 1: Language, 2: Role, 3: Profile, 4: Confirmed
  String _selectedLang = 'Hindi';
  AppRole _selectedRole = AppRole.patient;
  final TextEditingController _nameCtrl = TextEditingController(text: 'Kavita Rajesh Devi');
  final TextEditingController _mobileCtrl = TextEditingController(text: '9823411204');
  final TextEditingController _villageCtrl = TextEditingController(text: 'Kashti Village, Sector 3');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      final session = SessionCoordinator();
      session.switchRole(_selectedRole);
      session.switchLanguage(_selectedLang);
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
                onPressed: () => setState(() => _step--),
              )
            : null,
        title: Text('Step ${_step + 1} of 5', style: AppTypography.supporting),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: (_step + 1) / 5,
            minHeight: 2,
            backgroundColor: RuralCareColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(RuralCareColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: _buildCurrentStep(),
              ),
            ),
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: RuralCareColors.surface,
                border: Border(top: BorderSide(color: RuralCareColors.border, width: 1.0)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _step == 4 ? 'Enter application' : 'Continue',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _stepWelcome();
      case 1:
        return _stepLanguage();
      case 2:
        return _stepRole();
      case 3:
        return _stepProfile();
      case 4:
        return _stepConfirmed();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Welcome
  Widget _stepWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: RuralCareColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.health_and_safety_outlined, color: RuralCareColors.primary, size: 28),
        ),
        const SizedBox(height: 24),
        const Text('Welcome to RuralCare', style: AppTypography.pageTitle),
        const SizedBox(height: 8),
        const Text(
          'Connecting rural families, frontline ASHA workers, and district hospitals through coordinated primary healthcare.',
          style: AppTypography.body,
        ),
        const SizedBox(height: 24),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy and consent', style: AppTypography.cardTitle),
              SizedBox(height: 4),
              Text(
                'Your health measurements and consultations are securely stored locally on this phone and synced with your designated clinic care team.',
                style: AppTypography.supporting,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 1: Language Selection
  Widget _stepLanguage() {
    final languages = [
      {'name': 'English', 'native': 'English', 'desc': 'Standard English'},
      {'name': 'Hindi', 'native': 'हिन्दी', 'desc': 'देवनागरी लिपि में संपूर्ण इंटरफ़ेस'},
      {'name': 'Marathi', 'native': 'मराठी', 'desc': 'स्थानिक आरोग्य संदर्भ व संपूर्ण सहाय्य'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose your language', style: AppTypography.pageTitle),
        const SizedBox(height: 8),
        const Text('Select your preferred language for consultations, reports, and reminders.', style: AppTypography.body),
        const SizedBox(height: 20),
        ...languages.map((l) {
          final isSelected = _selectedLang == l['name'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: AppDecorations.card(
              borderColor: isSelected ? RuralCareColors.primary : RuralCareColors.border,
            ),
            child: ListTile(
              onTap: () => setState(() => _selectedLang = l['name']!),
              title: Text(l['native']!, style: AppTypography.cardTitle),
              subtitle: Text(l['desc']!, style: AppTypography.supporting),
              trailing: Radio<String>(
                value: l['name']!,
                groupValue: _selectedLang,
                activeColor: RuralCareColors.primary,
                onChanged: (val) => setState(() => _selectedLang = val!),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Step 2: Role Selection
  Widget _stepRole() {
    final roles = [
      {
        'role': AppRole.patient,
        'title': 'Patient / Family',
        'desc': 'View appointments, test reports, prescriptions, and request teleconsultations.',
      },
      {
        'role': AppRole.healthWorker,
        'title': 'ASHA / Health Worker',
        'desc': 'Register beneficiaries, record vitals, conduct triage, and follow up ANC.',
      },
      {
        'role': AppRole.doctor,
        'title': 'Medical Officer / Doctor',
        'desc': 'Review clinical queue, conduct video teleconsultations, and issue care plans.',
      },
      {
        'role': AppRole.facilityStaff,
        'title': 'Hospital & Facility Staff',
        'desc': 'Coordinate bed availability, triage incoming referrals, and blood inventory.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select your user role', style: AppTypography.pageTitle),
        const SizedBox(height: 8),
        const Text('Choose how you will participate in the care network.', style: AppTypography.body),
        const SizedBox(height: 20),
        ...roles.map((r) {
          final role = r['role'] as AppRole;
          final isSelected = _selectedRole == role;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: AppDecorations.card(
              borderColor: isSelected ? RuralCareColors.primary : RuralCareColors.border,
            ),
            child: ListTile(
              onTap: () => setState(() => _selectedRole = role),
              title: Text(r['title'] as String, style: AppTypography.cardTitle),
              subtitle: Text(r['desc'] as String, style: AppTypography.supporting),
              trailing: Radio<AppRole>(
                value: role,
                groupValue: _selectedRole,
                activeColor: RuralCareColors.primary,
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Step 3: Basic Profile Setup
  Widget _stepProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic profile', style: AppTypography.pageTitle),
        const SizedBox(height: 8),
        const Text('Enter your details to create your RuralCare health record.', style: AppTypography.body),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Mobile number'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _villageCtrl,
          decoration: const InputDecoration(labelText: 'Village / Sector'),
        ),
      ],
    );
  }

  // Step 4: Account Confirmed
  Widget _stepConfirmed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: RuralCareColors.successSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check_circle_outline, color: RuralCareColors.success, size: 28),
        ),
        const SizedBox(height: 24),
        const Text('Account ready', style: AppTypography.pageTitle),
        const SizedBox(height: 8),
        const Text('Your profile has been created and assigned to the local care network.', style: AppTypography.body),
        const SizedBox(height: 24),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RuralCare Health ID', style: AppTypography.supporting),
              const SizedBox(height: 4),
              const Text('91-8821-4492-1084', style: AppTypography.cardTitle),
              const Divider(color: RuralCareColors.border, height: 24),
              Text('Beneficiary: ${_nameCtrl.text}', style: AppTypography.body),
              const SizedBox(height: 4),
              Text('Healthcare area: ${_villageCtrl.text}', style: AppTypography.supporting),
            ],
          ),
        ),
      ],
    );
  }
}
