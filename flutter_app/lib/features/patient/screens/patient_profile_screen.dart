import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/patient_dto.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  int _age = 26;
  String _selectedGender = 'female';
  final TextEditingController _nameCtrl = TextEditingController(text: 'Kavita Rajesh Devi');
  final TextEditingController _phoneCtrl = TextEditingController(text: '9823411204');
  final TextEditingController _emergencyPhoneCtrl = TextEditingController(text: '9823411205');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, cache, session]),
      builder: (context, _) {
        final patient = patientRepo.defaultPatient;
        final currentLang = session.activeLanguage;

        return Scaffold(
          backgroundColor: AppColors.stitchSurface,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: _buildStitchProfileHeader(context, session, currentLang),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Digital ABHA Card (National Health Authority Style)
                _buildAbhaDigitalCard(context, patient),
                const SizedBox(height: 16),

                // 2. Personal Demographics & Interactive Form Card (Stitch Screen 6)
                _buildDemographicsCard(patient),
                const SizedBox(height: 16),

                // 3. Assigned Care Network Card (ASHA & Next of Kin)
                _buildCareNetworkCard(context, patient),
                const SizedBox(height: 16),

                // 4. Offline & Connectivity Ledger (Outbox Sync)
                _buildOfflineLedgerCard(context, cache),
                const SizedBox(height: 16),

                // 5. Language & Preferences Selector (3 Languages)
                _buildLanguagePreferencesCard(session, currentLang),
                const SizedBox(height: 18),

                // 6. Demo Role Switcher
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => DemoRoleSwitcher.show(context),
                    icon: const Icon(Icons.switch_account),
                    label: const Text('Switch Role (Demo Evaluator)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.stitchPrimary,
                      side: const BorderSide(color: AppColors.stitchPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
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

  Widget _buildStitchProfileHeader(
    BuildContext context,
    SessionCoordinator session,
    String currentLang,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stitchSurface.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.stitchPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'RuralCare ABHA',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.stitchPrimary),
                      ),
                      Text(
                        'Patient Health Profile',
                        style: TextStyle(fontSize: 10, color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: Color(0xFF15803D)),
                        SizedBox(width: 4),
                        Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        _buildLangChip('EN', currentLang == 'English', () => session.switchLanguage('English')),
                        _buildLangChip('हि', currentLang == 'Hindi', () => session.switchLanguage('Hindi')),
                        _buildLangChip('म', currentLang == 'Marathi', () => session.switchLanguage('Marathi')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.stitchPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.slateNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildAbhaDigitalCard(BuildContext context, PatientDto patient) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D6E), Color(0xFF0A2E52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x300A2E52), blurRadius: 12, offset: Offset(0, 4))],
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('राष्ट्रीय स्वास्थ्य प्राधिकरण', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text('National Health Authority', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF93F5D8), size: 14),
                  SizedBox(width: 3),
                  Text('ABDM Active', style: TextStyle(color: Color(0xFF93F5D8), fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ABHA Number: ${patient.abhaId}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5),
                  ),
                  Text(
                    'ABHA Address: ${patient.id}@abdm',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gender: ${patient.gender} • Age: ${patient.age} Yrs',
                    style: const TextStyle(color: Color(0xFF93F5D8), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.qr_code_2_rounded, size: 50, color: Color(0xFF0F3D6E)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsCard(PatientDto patient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Demographics (व्यक्तिगत विवरण)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
          ),
          const SizedBox(height: 12),
          // Full Name
          _buildFieldLabel('Full Name (पूरा नाम)'),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.person, color: AppColors.stitchPrimary, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          // Age Stepper (Stitch Screen 6)
          _buildFieldLabel('Age (उम्र)'),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove, size: 16),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (_age > 1) setState(() => _age--);
                },
              ),
              Expanded(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  alignment: Alignment.center,
                  child: Text('$_age Years', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.stitchPrimary)),
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.stitchPrimary),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (_age < 110) setState(() => _age++);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gender Selector Pills
          _buildFieldLabel('Gender (लिंग)'),
          Row(
            children: [
              _genderPill('female', 'Female / महिला', Icons.female),
              const SizedBox(width: 8),
              _genderPill('male', 'Male / पुरुष', Icons.male),
              const SizedBox(width: 8),
              _genderPill('other', 'Other / अन्य', Icons.transgender),
            ],
          ),
          const SizedBox(height: 12),
          // Phone Number
          _buildFieldLabel('Phone Number (मोबाइल नंबर)'),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.phone, color: AppColors.stitchPrimary, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          // Village & District Readonly
          _buildFieldLabel('Village, Sub-Centre & District'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 18, color: AppColors.stitchPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${patient.village}, ${patient.subCentre} • ${patient.district}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700),
      ),
    );
  }

  Widget _genderPill(String id, String label, IconData icon) {
    final isSelected = _selectedGender == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedGender = id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.stitchPrimary : const Color(0xFFCBD5E1), width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.stitchPrimary : AppColors.neutral600),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.stitchPrimary : AppColors.neutral700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareNetworkCard(BuildContext context, PatientDto patient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned Care Network (स्वास्थ्य सहायता)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
          ),
          const SizedBox(height: 10),
          // ASHA Worker
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFD5E3FC),
                  child: Icon(Icons.volunteer_activism, size: 18, color: AppColors.stitchPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASHA: ${patient.assignedAsha}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutral900),
                      ),
                      const Text('Kashti Sector 3 • Field Health Worker', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing ASHA Worker ${patient.assignedAsha}...')),
                    );
                  },
                  icon: const Icon(Icons.call, color: AppColors.stitchPrimary, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Next of Kin
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE2E8F0),
                  child: Icon(Icons.contact_phone, size: 18, color: AppColors.slateNavy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next of Kin: ${patient.emergencyContact.name} (${patient.emergencyContact.relationship})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutral900),
                      ),
                      Text('Emergency Phone: ${patient.emergencyContact.phoneNumber}', style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineLedgerCard(BuildContext context, LocalCacheService cache) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offline Outbox Ledger (ऑफ़लाइन सिंक)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate Offline Mode (डेटा बंद करा)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            subtitle: Text(
              cache.isOffline
                  ? 'Offline: All clinical logs saved locally to Outbox (${cache.pendingCount} pending)'
                  : 'Online: Cloud synchronization active',
              style: const TextStyle(fontSize: 10, color: AppColors.neutral600),
            ),
            value: cache.isOffline,
            activeColor: AppColors.stitchPrimary,
            onChanged: (val) => cache.toggleOffline(val),
          ),
          if (cache.pendingCount > 0) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  cache.syncOutbox();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.stitchPrimary,
                      content: Text('All outbox mutations successfully synchronized to Cloud!'),
                    ),
                  );
                },
                icon: const Icon(Icons.sync, size: 16),
                label: Text('Sync ${cache.pendingCount} Pending Outbox Records', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stitchPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguagePreferencesCard(SessionCoordinator session, String currentLang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Language & Preferences (भाषा प्राधान्ये)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _langPreferenceBtn('English', 'English', currentLang == 'English', () => session.switchLanguage('English')),
              const SizedBox(width: 8),
              _langPreferenceBtn('हिन्दी', 'Hindi', currentLang == 'Hindi', () => session.switchLanguage('Hindi')),
              const SizedBox(width: 8),
              _langPreferenceBtn('मराठी', 'Marathi', currentLang == 'Marathi', () => session.switchLanguage('Marathi')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langPreferenceBtn(String title, String code, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.stitchPrimary : const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.slateNavy,
            ),
          ),
        ),
      ),
    );
  }
}
