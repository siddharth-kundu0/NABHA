import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile & ABHA Card'),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([patientRepo, cache, session]),
        builder: (context, _) {
          final patient = patientRepo.defaultPatient;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAbhaDigitalCard(context, patient),
                const SizedBox(height: 20),
                _buildSectionHeader('Personal Demographics'),
                _buildInfoTile('Full Name', patient.fullName, Icons.person),
                _buildInfoTile('Age & Gender', '${patient.age} Yrs • ${patient.gender}', Icons.badge),
                _buildInfoTile('Phone Number', patient.phoneNumber, Icons.phone),
                _buildInfoTile('Village & Sub-centre', '${patient.village}, ${patient.subCentre}', Icons.location_on),
                _buildInfoTile('District', patient.district, Icons.map),
                const SizedBox(height: 16),
                _buildSectionHeader('Assigned Care Network'),
                _buildInfoTile('Assigned ASHA Worker', patient.assignedAsha, Icons.volunteer_activism),
                if (patient.emergencyContact != null)
                  _buildInfoTile(
                    'Emergency Contact',
                    '${patient.emergencyContact!.name} (${patient.emergencyContact!.relationship})\n${patient.emergencyContact!.phoneNumber}',
                    Icons.contact_phone,
                  ),
                const SizedBox(height: 16),
                _buildSectionHeader('Offline & Connectivity Settings'),
                SwitchListTile(
                  title: const Text('Simulate Offline Mode (डेटा बंद करा)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    cache.isOffline
                        ? 'Offline: All clinical logs saved locally to Outbox (${cache.pendingCount} pending)'
                        : 'Online: Cloud synchronization active',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: cache.isOffline,
                  activeColor: AppColors.terracotta,
                  onChanged: (val) {
                    cache.toggleOffline(val);
                  },
                ),
                if (cache.pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        cache.syncOutbox();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All outbox mutations successfully synchronized to Cloud!')),
                        );
                      },
                      icon: const Icon(Icons.sync),
                      label: Text('Sync ${cache.pendingCount} Pending Outbox Records'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestTeal, foregroundColor: Colors.white),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildSectionHeader('Language & Preferences'),
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.forestTeal),
                  title: const Text('Preferred Language / भाषा निवडा', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(session.activeLanguage),
                  trailing: DropdownButton<String>(
                    value: session.activeLanguage,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'मराठी', child: Text('मराठी (Marathi)')),
                      DropdownMenuItem(value: 'हिंदी', child: Text('हिंदी (Hindi)')),
                    ],
                    onChanged: (val) {
                      if (val != null) session.switchLanguage(val);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => DemoRoleSwitcher.show(context),
                    icon: const Icon(Icons.switch_account),
                    label: const Text('Switch Role (Demo Evaluator)'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAbhaDigitalCard(BuildContext context, dynamic patient) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forestTeal, AppColors.forestTealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestTealDark.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.health_and_safety, color: AppColors.forestTeal, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text('ABHA ID / आयुष्मान भारत', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            patient.fullName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'ABHA Number: ${patient.abhaId}',
            style: const TextStyle(color: AppColors.forestTealLight, fontSize: 13, letterSpacing: 1.1),
          ),
          Text(
            'RuralCare ID: ${patient.ruralCareId}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assigned Sector Sub-centre', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text(patient.subCentre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.qr_code_2, color: AppColors.forestTealDark, size: 38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slateNavy),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppColors.surfaceAntiGlare,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.slateNavy, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
        subtitle: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neutral900)),
      ),
    );
  }
}
