import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

class HealthWorkerProfileScreen extends StatefulWidget {
  const HealthWorkerProfileScreen({super.key});

  @override
  State<HealthWorkerProfileScreen> createState() => _HealthWorkerProfileScreenState();
}

class _HealthWorkerProfileScreenState extends State<HealthWorkerProfileScreen> {
  bool _isSyncing = false;
  String _workerName = 'Kavita Verma';
  final String _workerRole = 'ASHA / Frontline Health Worker';
  String _workerPhone = '+91 98234 11200';
  String _workerSubcentre = 'Kashti Sub-Centre • Sector 3';

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, cache, session]),
      builder: (context, _) {
        final totalBeneficiaries = patientRepo.patients.length;
        final pendingMutations = cache.pendingOutboxCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Card matching Stitch V2 Profile Aesthetic
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.neutral300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Squircle Avatar with Verified Checkmark Overlay
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppColors.forestTealDark,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.forestTeal.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'KV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
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
                                _workerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkSlate,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _workerRole,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.forestTeal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.skyBlueSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ID: HW-ASHA-4412',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navyBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '• Active Field Duty',
                                    style: TextStyle(fontSize: 10, color: AppColors.slateGray),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.neutral200),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.forestTeal),
                            const SizedBox(width: 4),
                            Text(
                              _workerSubcentre,
                              style: const TextStyle(fontSize: 11, color: AppColors.darkSlate),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _showEditProfileSheet(context),
                          child: const Text(
                            'Edit Details',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestTeal),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Offline Cache & Sync Management Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_sync_outlined, color: AppColors.navyBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Cache & Sync Desk',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                              ),
                              Text(
                                'स्थानीय डेटा व सिंक्रोनाइज़ेशन',
                                style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Local Records', style: TextStyle(fontSize: 10, color: AppColors.slateGray)),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalBeneficiaries Cached',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Outbox Queue', style: TextStyle(fontSize: 10, color: AppColors.slateGray)),
                                const SizedBox(height: 2),
                                Text(
                                  '$pendingMutations Pending',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: pendingMutations > 0 ? AppColors.terracotta : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isSyncing
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _isSyncing = true);
                                await cache.flushOutboxQueue();
                                if (mounted) {
                                  setState(() => _isSyncing = false);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Field outbox queue synchronized with PHC server')),
                                  );
                                }
                              },
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.sync_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _isSyncing ? 'Syncing with Server...' : 'Sync Now / डेटा सिंक करें',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestTealDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Assigned Catchment & Supervisor Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.map_outlined, color: Color(0xFF065F46), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coverage Area & Supervisor',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                              ),
                              Text(
                                'कार्यक्षेत्र व पर्यवेक्षक संपर्क',
                                style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _profileDetailRow('Assigned Villages', 'Rampur Village, Kashti Sector 3, Kalyanpur'),
                    const SizedBox(height: 8),
                    _profileDetailRow('Total Population', '~1,850 registered residents'),
                    const SizedBox(height: 8),
                    _profileDetailRow('Medical Officer', 'Dr. Anita Roy (PHC Rampur)'),
                    const SizedBox(height: 8),
                    _profileDetailRow('Official Contact', _workerPhone),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Language & Accessibility Preferences Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.translate_rounded, color: Color(0xFF4338CA), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Language & Accessibility',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                              ),
                              Text(
                                'भाषा एवं दृश्य प्राथमिकताएं',
                                style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Language Switcher Options
                    Row(
                      children: [
                        _langButton(session, 'English', 'EN'),
                        const SizedBox(width: 8),
                        _langButton(session, 'हिन्दी', 'हि'),
                        const SizedBox(width: 8),
                        _langButton(session, 'मराठी', 'म'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Larger Text (बड़ा फ़ॉन्ट)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Optimized readability for field visits', style: TextStyle(fontSize: 11)),
                      value: session.largerText,
                      activeColor: AppColors.forestTeal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => session.toggleLargerText(v),
                    ),
                    SwitchListTile(
                      title: const Text('High Contrast (उच्च कंट्रास्ट)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Enhanced visibility in bright sunlight', style: TextStyle(fontSize: 11)),
                      value: session.highContrast,
                      activeColor: AppColors.forestTeal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => session.toggleHighContrast(v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Emergency Pre-Alert & Support
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emergency_outlined, size: 20, color: Color(0xFFDC2626)),
                        SizedBox(width: 8),
                        Text(
                          'Frontline Emergency Protocol',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Direct line to Sub-District Hospital pre-alert triage and 108 emergency ambulance control room.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dialing 108 Emergency Ambulance Control...')),
                          );
                        },
                        icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                        label: const Text('Call 108 Ambulance Dispatcher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6. Sign Out / Switch Role Button matching Stitch Profile
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => DemoRoleSwitcher.show(context),
                  icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFDC2626), size: 20),
                  label: const Text(
                    'Sign Out / Switch Role',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _profileDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkSlate)),
        ),
      ],
    );
  }

  Widget _langButton(SessionCoordinator session, String name, String code) {
    final isSel = session.activeLanguage == name;
    return Expanded(
      child: InkWell(
        onTap: () => session.switchLanguage(name),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.forestTealDark : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? AppColors.forestTealDark : AppColors.neutral300),
          ),
          child: Text(
            '$code • $name',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              color: isSel ? Colors.white : AppColors.darkSlate,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _workerName);
    final phoneCtrl = TextEditingController(text: _workerPhone);
    final subcentreCtrl = TextEditingController(text: _workerSubcentre);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Health Worker Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: subcentreCtrl, decoration: const InputDecoration(labelText: 'Sub-Centre / Catchment', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _workerName = nameCtrl.text.trim();
                        _workerPhone = phoneCtrl.text.trim();
                        _workerSubcentre = subcentreCtrl.text.trim();
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Worker credentials updated locally')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestTealDark),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
