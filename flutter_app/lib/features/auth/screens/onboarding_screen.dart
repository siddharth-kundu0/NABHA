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
  int _step = 0; // 0: Language, 1: Role, 2: Profile, 3: ABHA Confirmation
  String _selectedLang = 'Hindi';
  AppRole _selectedRole = AppRole.patient;
  int _age = 26;
  String _selectedGender = 'female';
  final _phoneController = TextEditingController(text: '9823411204');
  final _nameController = TextEditingController(text: 'Kavita Rajesh Devi');
  final _emergencyContactController = TextEditingController(text: '9823411205');

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stitchSurface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: _buildStitchOnboardingHeader(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Micro progress indicator bar
            LinearProgressIndicator(
              value: (_step + 1) / 4,
              backgroundColor: const Color(0xFFE6EEFF),
              color: AppColors.stitchPrimary,
              minHeight: 3,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: _buildStepContent(),
              ),
            ),
            _buildBottomCtaArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchOnboardingHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 22, color: AppColors.neutral900),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _step--),
                    ),
                  if (_step > 0) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Step ${_step + 1} of 4 • चरण ${_step + 1}',
                      style: const TextStyle(color: AppColors.stitchPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF15803D)),
                    SizedBox(width: 4),
                    Text('Offline Ready', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildLanguageStep();
      case 1:
        return _buildRoleStep();
      case 2:
        return _buildProfileStep();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLanguageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Language',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutral900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the language you are most comfortable with. You can change this anytime in Settings.',
          style: TextStyle(fontSize: 12, color: AppColors.neutral600),
        ),
        const SizedBox(height: 16),
        // Language Option 1: English
        _buildLanguageCard(
          id: 'English',
          name: 'English',
          sub: 'Standard medical format',
          quote: '“Welcome! Your health is our priority.”',
          avatarLetter: 'A',
          audioLabel: 'Listen',
          isRecommended: false,
        ),
        const SizedBox(height: 12),
        // Language Option 2: Hindi
        _buildLanguageCard(
          id: 'Hindi',
          name: 'हिन्दी',
          subName: '(Hindi)',
          sub: 'सुझाया गया / Recommended',
          quote: '“नमस्ते! आपका स्वास्थ्य हमारी प्राथमिकता है।”',
          avatarLetter: 'अ',
          audioLabel: 'बोलकर सुनें',
          isRecommended: true,
        ),
        const SizedBox(height: 12),
        // Language Option 3: Marathi
        _buildLanguageCard(
          id: 'Marathi',
          name: 'मराठी',
          subName: '(Marathi)',
          sub: 'महाराष्ट्र व सीमारेषा भाग',
          quote: '“नमस्कार! आपले आरोग्य आमचे प्राधान्य आहे।”',
          avatarLetter: 'म',
          audioLabel: 'ऐका',
          isRecommended: false,
        ),
        const SizedBox(height: 16),
        // Voice assistance friendly banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFFDE68A),
                child: Icon(Icons.record_voice_over, color: Color(0xFF92400E), size: 18),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice assistance and audio guides available in all 3 languages.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF92400E)),
                    ),
                    Text(
                      'सर्व ३ भाषांमध्ये ऑडिओ मार्गदर्शन आणि आवाज सहाय्य उपलब्ध',
                      style: TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard({
    required String id,
    required String name,
    String? subName,
    required String sub,
    required String quote,
    required String avatarLetter,
    required String audioLabel,
    required bool isRecommended,
  }) {
    final isSelected = _selectedLang == id;

    return InkWell(
      onTap: () {
        setState(() => _selectedLang = id);
        SessionCoordinator().switchLanguage(id);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.stitchPrimary : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.stitchPrimary : const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        avatarLetter,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.neutral900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
                            if (subName != null) ...[
                              const SizedBox(width: 4),
                              Text(subName, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                            ],
                          ],
                        ),
                        Text(
                          sub,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isRecommended ? FontWeight.bold : FontWeight.normal,
                            color: isRecommended ? AppColors.stitchPrimary : AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.stitchPrimary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppColors.stitchPrimary : const Color(0xFFCBD5E1), width: 2),
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(quote, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.slateNavy)),
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Playing $name audio greeting...')),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up, size: 14, color: AppColors.stitchPrimary),
                          const SizedBox(width: 4),
                          Text(audioLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.stitchPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleStep() {
    final roles = [
      {'role': AppRole.patient, 'title': 'Patient / Beneficiary', 'hindi': 'मरीज / लाभार्थी', 'desc': 'Track pregnancy, check appointments, view ABHA records', 'icon': Icons.person},
      {'role': AppRole.healthWorker, 'title': 'Frontline Health Worker (ASHA / ANM)', 'hindi': 'आशा / एएनएम कार्यकर्ता', 'desc': 'Register field patients, record BLE vitals, trigger SOS', 'icon': Icons.medical_services},
      {'role': AppRole.doctor, 'title': 'Medical Officer Doctor', 'hindi': 'चिकित्सा अधिकारी (डॉक्टर)', 'desc': 'Teleconsultations, E-Prescriptions, down-referral care plan', 'icon': Icons.local_hospital},
      {'role': AppRole.facilityStaff, 'title': 'Hospital Staff & Admin', 'hindi': 'अस्पताल प्रशासन', 'desc': 'Manage bed occupancy, intake desk, blood bank inventory', 'icon': Icons.apartment},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Your Role', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        const SizedBox(height: 4),
        const Text('Choose how you will be using RuralCare. Each role has specialized field tools.', style: TextStyle(fontSize: 12, color: AppColors.neutral600)),
        const SizedBox(height: 16),
        ...roles.map((r) {
          final isSelected = _selectedRole == r['role'];
          return InkWell(
            onTap: () {
              setState(() => _selectedRole = r['role'] as AppRole);
              SessionCoordinator().switchRole(r['role'] as AppRole);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF4FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.stitchPrimary : const Color(0xFFE2E8F0),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.stitchPrimary : const Color(0xFFE6EEFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(r['icon'] as IconData, color: isSelected ? Colors.white : AppColors.stitchPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900)),
                        Text(r['hindi'] as String, style: const TextStyle(fontSize: 11, color: AppColors.stitchPrimary, fontWeight: FontWeight.w500)),
                        Text(r['desc'] as String, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.stitchPrimary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? AppColors.stitchPrimary : const Color(0xFFCBD5E1), width: 1.5),
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Profile Setup', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        const SizedBox(height: 4),
        const Text('Essential details to set up your personal ABHA health record.', style: TextStyle(fontSize: 12, color: AppColors.neutral600)),
        const SizedBox(height: 16),
        // Full Name Field
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Name *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person, color: AppColors.stitchPrimary),
                  hintText: 'Enter beneficiary full name',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Age Stepper Card (Exact Stitch)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Age *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_age > 1) setState(() => _age--);
                    },
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      alignment: Alignment.center,
                      child: Text('$_age Years', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.stitchPrimary)),
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.stitchPrimary),
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      if (_age < 110) setState(() => _age++);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Gender Selector Pills
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gender *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _genderPill('female', 'Female', Icons.female),
                  const SizedBox(width: 8),
                  _genderPill('male', 'Male', Icons.male),
                  const SizedBox(width: 8),
                  _genderPill('other', 'Other', Icons.transgender),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Emergency Contact Phone
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emergency Contact Phone (Spouse / Kin)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)),
              const SizedBox(height: 6),
              TextField(
                controller: _emergencyContactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone, color: AppColors.stitchPrimary),
                  hintText: '10-digit mobile number',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _genderPill(String id, String label, IconData icon) {
    final isSelected = _selectedGender == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedGender = id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.stitchPrimary : const Color(0xFFCBD5E1), width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.stitchPrimary : AppColors.neutral600),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.stitchPrimary : AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Official ABHA Digital Card Preview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3D6E), Color(0xFF0A2E52)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x280A2E52), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text('National Health Authority', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  Text('ABDM Verified', style: TextStyle(color: Color(0xFF93F5D8), fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_nameController.text.trim(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('ABHA: 91-4402-8812-3901', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Gender: $_selectedGender • Age: $_age', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.qr_code_2_rounded, size: 40, color: Color(0xFF0F3D6E)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF15803D), size: 18),
            SizedBox(width: 6),
            Text('ABHA Health ID Created & Synchronized!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Your clinical health record is protected and ready for offline use across Maharashtra Sub-Centres.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.neutral600),
        ),
      ],
    );
  }

  Widget _buildBottomCtaArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_step < 3) {
                  setState(() => _step++);
                } else {
                  SessionCoordinator().completeOnboarding();
                  widget.onComplete?.call();
                }
              },
              icon: Icon(_step == 3 ? Icons.check_circle : Icons.arrow_forward, size: 18),
              label: Text(
                _step == 0
                    ? 'Continue ($_selectedLang)'
                    : _step == 3
                        ? 'Enter RuralCare'
                        : 'Continue',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stitchPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_done, size: 13, color: AppColors.stitchPrimary),
              SizedBox(width: 4),
              Text('Works offline • बिना इंटरनेट भी सुरक्षित', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
            ],
          ),
        ],
      ),
    );
  }
}
