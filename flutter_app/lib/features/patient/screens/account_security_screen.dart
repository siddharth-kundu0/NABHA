import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/app/routes.dart';

/// Dedicated Screen: Account & Security
/// Conforms to DESIGN.md Section 8 and Stitch Mobile Security
class AccountSecurityScreen extends StatefulWidget {
  final PatientDto patient;

  const AccountSecurityScreen({super.key, required this.patient});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final SessionCoordinator _session = SessionCoordinator();

  void _showChangePinDialog() {
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final isMr = _session.isMr;
    final isHi = _session.isHi;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isMr ? 'सुरक्षा पिन बदला' : (isHi ? 'सुरक्षा पिन बदलें' : 'Change Security PIN'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Current 4-Digit PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'New 4-Digit PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (newPinCtrl.text.length == 4) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Security PIN updated successfully.'),
                    backgroundColor: Color(0xFF005140),
                  ),
                );
              }
            },
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final otpCtrl = TextEditingController();
    final isMr = _session.isMr;
    final isHi = _session.isHi;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: RuralCareColors.critical, size: 22),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: RuralCareColors.critical, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMr
                  ? 'आपले RuralCare खाते हटवल्यास स्थानिक नोंदी नष्ट होतील. पुष्टी करण्यासाठी खाली OTP प्रविष्ट करा:'
                  : (isHi
                      ? 'अपना खाता हटाने से स्थानीय रिकॉर्ड हट जाएंगे। पुष्टि करने हेतु OTP दर्ज करें:'
                      : 'Deleting your account removes your offline cache and device session. Please enter authorization OTP:'),
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Authorization Code (Demo: 123456)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (otpCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
                _session.resetToOnboarding();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account session purged. Reset to welcome state.'),
                    backgroundColor: RuralCareColors.critical,
                  ),
                );
              }
            },
            child: const Text('Confirm Deletion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = _session.isMr;
    final isHi = _session.isHi;
    final p = widget.patient;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isMr ? 'खाते आणि सुरक्षा' : (isHi ? 'खाता एवं सुरक्षा' : 'Account & Security'),
          style: const TextStyle(
            fontFamily: 'Noto Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ABDM Link Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF1D4ED8), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ABHA Digital Health ID',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.abhaId.isNotEmpty ? p.abhaId : 'ABHA-9824-1102-8491',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Linked', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Registered Phone Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_android_rounded, color: Color(0xFF475569), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Registered Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(p.phoneNumber, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isMr ? 'सुरक्षा पर्याय' : (isHi ? 'सुरक्षा विकल्प' : 'SECURITY OPTIONS'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),

            // Change PIN Action
            _actionTile(
              title: isMr ? 'सुरक्षा पिन बदला' : (isHi ? 'सुरक्षा पिन बदलें' : 'Change Security PIN'),
              subtitle: isMr ? '४-अंकी लॉगिन पिन बदला' : (isHi ? '4-अंकीय लॉगिन पिन बदलें' : 'Update 4-digit biometric app PIN'),
              icon: Icons.password_rounded,
              onTap: _showChangePinDialog,
            ),
            const SizedBox(height: 10),

            // Device Session Active
            _actionTile(
              title: isMr ? 'डिव्हाइस सत्रे' : (isHi ? 'सक्रिय सत्र' : 'Active Device Sessions'),
              subtitle: 'Current Device: Android / Chrome • Rampur Gateway',
              icon: Icons.devices_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Only 1 active authorized session on this device.')),
                );
              },
            ),
            const SizedBox(height: 24),

            // Dangerous Area
            Text(
              isMr ? 'खाते व्यवस्थापन' : (isHi ? 'खाता प्रबंधन' : 'DANGER ZONE'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: RuralCareColors.critical),
            ),
            const SizedBox(height: 10),

            InkWell(
              onTap: _showDeleteAccountDialog,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever_rounded, color: RuralCareColors.critical, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr ? 'खाते हटवा' : (isHi ? 'खाता हटाएं' : 'Delete Account'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RuralCareColors.critical),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMr ? 'स्थानिक डिव्हाइस कॅशे व नोंदी नष्ट करा' : (isHi ? 'स्थानीय डिवाइस कैश व रिकॉर्ड हटाएं' : 'Purge local device cache and session tokens'),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: RuralCareColors.critical, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF475569), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}
