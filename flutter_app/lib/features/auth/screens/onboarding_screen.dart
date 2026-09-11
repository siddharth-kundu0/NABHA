import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String _selectedLang = 'English';
  AppRole _selectedRole = AppRole.patient;
  final _phoneController = TextEditingController(text: '9823411204');
  final _otpController = TextEditingController(text: '123456');
  final _nameController = TextEditingController(text: 'Kavita Rajesh Devi');
  final _districtController = TextEditingController(text: 'Pune Rural');
  final _subCentreController = TextEditingController(text: 'Kashti Sub-Centre');

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _districtController.dispose();
    _subCentreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RuralCareColors.surfaceCanvas,
      appBar: AppBar(
        title: Text(_stepTitle(), style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: _step > 0 && _step < 4
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildStepContent(),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 0:
        return 'Language / भाषा निवडा';
      case 1:
        return 'Select Role / भूमिका निवडा';
      case 2:
        return 'Phone Verification';
      case 3:
        return 'Profile Setup';
      case 4:
        return 'RuralCare Health ID';
      default:
        return 'RuralCare';
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildLanguageStep();
      case 1:
        return _buildRoleStep();
      case 2:
        return _buildMobileStep();
      case 3:
        return _buildProfileStep();
      case 4:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLanguageStep() {
    final languages = [
      {'name': 'English', 'native': 'English', 'sub': 'Default'},
      {'name': 'Hindi', 'native': 'हिन्दी (Hindi)', 'sub': 'National Language'},
      {'name': 'Marathi', 'native': 'मराठी (Marathi)', 'sub': 'Regional State Language'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your preferred language',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'आपली भाषा निवडा / अपनी भाषा चुनें',
          style: TextStyle(fontSize: 14, color: RuralCareColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: languages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final lang = languages[idx];
              final isSelected = _selectedLang == lang['name'];
              return Card(
                color: isSelected ? RuralCareColors.primaryLight : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? RuralCareColors.primary : RuralCareColors.borderSubtle,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    lang['native']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? RuralCareColors.primary : RuralCareColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(lang['sub']!),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: RuralCareColors.primary)
                      : const Icon(Icons.radio_button_unchecked, color: RuralCareColors.borderInput),
                  onTap: () => setState(() => _selectedLang = lang['name']!),
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            SessionCoordinator().switchLanguage(_selectedLang);
            setState(() => _step = 1);
          },
          child: const Text('Continue / पुढे जा'),
        ),
      ],
    );
  }

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who are you registering as?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text('Select your account role:', style: TextStyle(fontSize: 14, color: RuralCareColors.textSecondary)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: AppRole.values.map((role) {
              final isSelected = _selectedRole == role;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: isSelected ? RuralCareColors.primaryLight : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? RuralCareColors.primary : RuralCareColors.borderSubtle,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      role.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? RuralCareColors.primary : RuralCareColors.textPrimary,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(role.description, style: const TextStyle(fontSize: 12)),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: RuralCareColors.primary) : null,
                    onTap: () => setState(() => _selectedRole = role),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            SessionCoordinator().switchRole(_selectedRole);
            setState(() => _step = 2);
          },
          child: const Text('Next: Mobile Verification'),
        ),
      ],
    );
  }

  Widget _buildMobileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Authentication (Firebase Phone Auth)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in with OTP via SMS & WhatsApp notifications',
          style: TextStyle(fontSize: 14, color: RuralCareColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            prefixIcon: Icon(Icons.phone_android_rounded),
            prefixText: '+91 ',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '6-digit OTP Code',
            prefixIcon: Icon(Icons.lock_clock_rounded),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => _step = 3),
          child: const Text('Verify & Proceed'),
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Healthcare Profile Setup',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Link your health records with your local Primary Health Centre',
            style: TextStyle(fontSize: 14, color: RuralCareColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name / पूर्ण नाव',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _districtController,
            decoration: const InputDecoration(
              labelText: 'District / जिल्हा',
              prefixIcon: Icon(Icons.location_city_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subCentreController,
            decoration: const InputDecoration(
              labelText: 'Nearest Sub-Centre / उप-केंद्र',
              prefixIcon: Icon(Icons.local_hospital_outlined),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RuralCareColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RuralCareColors.primary.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: RuralCareColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ABDM Compatible: Longitudinal health record will be secured under national Ayushman Bharat health standards.',
                    style: TextStyle(fontSize: 12, color: RuralCareColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _step = 4),
            child: const Text('Complete Registration'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: RuralCareColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 48, color: RuralCareColors.success),
          ),
          const SizedBox(height: 24),
          const Text(
            'Account Verified!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your RuralCare Health Identity has been generated:',
            style: TextStyle(fontSize: 14, color: RuralCareColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('RuralCare ID', style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                  const SizedBox(height: 4),
                  const Text(
                    'RC-MH-11021',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: RuralCareColors.primary,
                    ),
                  ),
                  const Divider(height: 20),
                  Text(_nameController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_subCentreController.text}, ${_districtController.text}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.onComplete,
            child: const Text('Launch Dashboard'),
          ),
        ],
      ),
    );
  }
}
