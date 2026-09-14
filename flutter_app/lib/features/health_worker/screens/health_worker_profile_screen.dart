import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

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
        final activeWorkerName = session.userDisplayName?.isNotEmpty == true ? session.userDisplayName! : _workerName;
        final activeWorkerPhone = session.currentUserEmail?.isNotEmpty == true && session.currentUserEmail!.contains('@')
            ? session.currentUserEmail!.split('@')[0]
            : (session.currentUserId?.isNotEmpty == true ? session.currentUserId! : _workerPhone);
        final activeWorkerSubcentre = session.assignedCatchment?.isNotEmpty == true ? session.assignedCatchment! : _workerSubcentre;
        final activeDoc = DoctorRepository().getDoctorForSession(session);
        final cleanWorker = activeWorkerName.trim();
        final initials = cleanWorker.isNotEmpty
            ? cleanWorker.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
            : 'HW';

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
                              child: Text(
                                initials,
                                style: const TextStyle(
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
                                activeWorkerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkSlate,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _workerRole,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeWorkerSubcentre,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slateGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
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
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showEditProfileSheet(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.forestTeal.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.forestTeal.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined, size: 12, color: AppColors.forestTeal),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit Details',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestTeal),
                                  ),
                                ],
                              ),
                            ),
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
                          child: InkWell(
                            onTap: () => _showLocalRecordsSheet(context, patientRepo),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.neutral300.withOpacity(0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Local Records', style: TextStyle(fontSize: 10, color: AppColors.slateGray)),
                                      Icon(Icons.info_outline, size: 12, color: AppColors.forestTeal),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalBeneficiaries Cached',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showOutboxQueueSheet(context, cache),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: pendingMutations > 0 ? AppColors.terracotta.withOpacity(0.4) : AppColors.neutral300.withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Outbox Queue', style: TextStyle(fontSize: 10, color: AppColors.slateGray)),
                                      Icon(Icons.open_in_new_rounded, size: 12, color: pendingMutations > 0 ? AppColors.terracotta : const Color(0xFF10B981)),
                                    ],
                                  ),
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
                                await Future.delayed(const Duration(milliseconds: 300));
                                if (mounted) {
                                  setState(() => _isSyncing = false);
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Field outbox queue synchronized with PHC server (Rampur Hub)'),
                                      backgroundColor: AppColors.forestTealDark,
                                    ),
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
                    _profileDetailRow('Medical Officer', '${activeDoc.name} (${activeDoc.facilityName})'),
                    const SizedBox(height: 8),
                    _profileDetailRow('Official Contact', activeWorkerPhone),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => _showCatchmentDetails(context, patientRepo),
                        icon: const Icon(Icons.people_outline_rounded, size: 16, color: Color(0xFF065F46)),
                        label: const Text('View Villages & Supervisor Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: const BorderSide(color: Color(0xFFA7F3D0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
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
                    const SizedBox(height: 8),
                    _switchSettingRow(
                      title: 'Larger Text (बड़ा फ़ॉन्ट)',
                      subtitle: 'Optimized readability for field visits',
                      value: session.largerText,
                      onChanged: (v) => session.toggleLargerText(v),
                    ),
                    const Divider(height: 16, color: AppColors.neutral200),
                    _switchSettingRow(
                      title: 'High Contrast (उच्च कंट्रास्ट)',
                      subtitle: 'Enhanced visibility in bright sunlight',
                      value: session.highContrast,
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
                        onPressed: () => _showEmergencyEscalationSheet(context),
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

  Widget _switchSettingRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkSlate),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.forestTeal,
            onChanged: onChanged,
          ),
        ],
      ),
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
    final isSel = (code.toLowerCase() == 'en' || name == 'English')
        ? session.isEnglish
        : (code == 'hi' || code == 'हि' || name == 'Hindi' || name == 'हिंदी' || name == 'हिन्दी')
            ? session.isHindi
            : session.isMarathi;
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

  void _showCatchmentDetails(BuildContext context, PatientRepository patientRepo) {
    final villageCounts = <String, int>{};
    for (final p in patientRepo.patients) {
      villageCounts[p.village] = (villageCounts[p.village] ?? 0) + 1;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                const Row(
                  children: [
                    Icon(Icons.map_outlined, color: Color(0xFF065F46), size: 22),
                    SizedBox(width: 8),
                    Text('Catchment & Supervisor Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('ASSIGNED VILLAGES & BENEFICIARIES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...villageCounts.entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_city_rounded, size: 16, color: AppColors.forestTeal),
                      const SizedBox(width: 8),
                      Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkSlate)),
                    ],
                  ),
                  Text('${entry.value} Beneficiaries', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
                ],
              ),
            )),
            const SizedBox(height: 14),
            const Text('PRIMARY MEDICAL SUPERVISORS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: Color(0xFF065F46), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${DoctorRepository().getDoctorForSession(SessionCoordinator()).name} (Medical Officer)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                        Text('${DoctorRepository().getDoctorForSession(SessionCoordinator()).facilityName} • Mobile: +91 94220 88190', style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: Color(0xFF065F46), size: 20),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dialing ${DoctorRepository().getDoctorForSession(SessionCoordinator()).name}...')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestTealDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyEscalationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                const Row(
                  children: [
                    Icon(Icons.emergency_outlined, color: Color(0xFFDC2626), size: 24),
                    SizedBox(width: 8),
                    Text('Emergency Escalation Desk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Frontline emergency pre-alert protocol for Kashti Sub-Centre. Select an action below:',
              style: TextStyle(fontSize: 12, color: AppColors.slateGray),
            ),
            const SizedBox(height: 16),
            _emergencyActionTile(
              icon: Icons.airport_shuttle_rounded,
              title: 'Call 108 Emergency Ambulance',
              subtitle: 'Direct link to State EMS control room with live GPS',
              color: const Color(0xFFDC2626),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connected to 108 Dispatcher • Sub-Centre GPS transmitted • ETA 14 mins'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _emergencyActionTile(
              icon: Icons.phone_in_talk_rounded,
              title: 'Call PHC MO (${DoctorRepository().getDoctorForSession(SessionCoordinator()).name})',
              subtitle: 'Duty Medical Officer • ${DoctorRepository().getDoctorForSession(SessionCoordinator()).facilityName}',
              color: AppColors.navyBlue,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dialing ${DoctorRepository().getDoctorForSession(SessionCoordinator()).name}...'),
                    backgroundColor: AppColors.navyBlue,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _emergencyActionTile(
              icon: Icons.map_rounded,
              title: 'Open Live Emergency Tracking',
              subtitle: 'Track incoming ambulance & notify Sub-District Hospital',
              color: const Color(0xFF047857),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (c) => const EmergencyTrackingScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _emergencyActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLocalRecordsSheet(BuildContext context, PatientRepository patientRepo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                Text(
                  'Cached Local Records (${patientRepo.patients.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'All records are stored encrypted in SQLite / local memory for zero-latency offline operation.',
              style: TextStyle(fontSize: 11, color: AppColors.slateGray),
            ),
            const SizedBox(height: 12),
            ...patientRepo.patients.take(4).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkSlate)),
                  Text(p.ruralCareId, style: const TextStyle(fontSize: 11, color: AppColors.forestTeal, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestTealDark),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOutboxQueueSheet(BuildContext context, LocalCacheService cache) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                Text(
                  'Outbox Sync Queue (${cache.pendingOutboxCount})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cache.pendingOutboxCount == 0
                  ? 'All local mutations are currently synchronized with the central server.'
                  : 'Mutations waiting for server connectivity or sync trigger:',
              style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
            ),
            const SizedBox(height: 12),
            if (cache.pendingOutboxCount > 0)
              ...cache.queuedMutations.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m['action']?.toString() ?? 'Mutation', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                    Text(m['entityType']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                  ],
                ),
              )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      cache.queueMutation('Vitals', 'FOLLOWUP_RECORD', {'bp': '120/80', 'patient': 'pat-001'});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test mutation queued in outbox')),
                      );
                    },
                    child: const Text('+ Queue Test', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await cache.flushOutboxQueue();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Outbox queue synchronized with PHC server')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestTealDark),
                    child: const Text('Flush Queue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
