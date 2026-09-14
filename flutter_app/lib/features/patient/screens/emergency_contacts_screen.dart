import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';

/// Dedicated Screen: Emergency Contacts Configuration
/// Conforms strictly to DESIGN.md Section 8 and Stitch Mobile Design
class EmergencyContactsScreen extends StatefulWidget {
  final PatientDto patient;

  const EmergencyContactsScreen({super.key, required this.patient});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final PatientRepository _patientRepo = PatientRepository();
  final SessionCoordinator _session = SessionCoordinator();

  void _openEditContactDialog(BuildContext context, PatientDto current) {
    final nameCtrl = TextEditingController(text: current.emergencyContact.name);
    final relCtrl = TextEditingController(text: current.emergencyContact.relationship);
    final phoneCtrl = TextEditingController(text: current.emergencyContact.phoneNumber);

    final isHi = _session.isHi;
    final isMr = _session.isMr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMr ? 'आपातकालीन संपर्क तपशील' : (isHi ? 'आपातकालीन संपर्क विवरण' : 'Emergency Contact Details'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isMr ? 'संपर्काचे पूर्ण नाव' : (isHi ? 'संपर्क का पूरा नाम' : 'Contact Full Name'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: AppDecorations.input(hintText: 'e.g. Ramesh Patil / Sunita Sharma'),
                ),
                const SizedBox(height: 14),
                Text(
                  isMr ? 'नाते / संबंध' : (isHi ? 'संबंध' : 'Relationship'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: relCtrl,
                  decoration: AppDecorations.input(hintText: 'e.g. Spouse / Husband / Parent / Brother'),
                ),
                const SizedBox(height: 14),
                Text(
                  isMr ? 'मोबाईल फोन नंबर' : (isHi ? 'मोबाइल फोन नंबर' : 'Mobile Phone Number'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: AppDecorations.input(hintText: '+91 98765 43210'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6B56),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      final r = relCtrl.text.trim();
                      final p = phoneCtrl.text.trim();
                      if (n.isNotEmpty && p.isNotEmpty) {
                        _patientRepo.updateEmergencyContact(
                          patientId: current.id,
                          contact: EmergencyContactDto(
                            name: n,
                            relationship: r.isNotEmpty ? r : 'Family',
                            phoneNumber: p,
                          ),
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isMr ? 'आपातकालीन संपर्क अद्यतनित केला' : (isHi ? 'आपातकालीन संपर्क अपडेट किया गया' : 'Emergency contact updated successfully!'),
                            ),
                            backgroundColor: const Color(0xFF0A6B56),
                          ),
                        );
                      }
                    },
                    child: Text(
                      isMr ? 'बदल जतन करा' : (isHi ? 'परिवर्तन सहेजें' : 'Save Contact'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_patientRepo, _session]),
      builder: (context, _) {
        final patient = _patientRepo.activePatient ?? widget.patient;
        final isMr = _session.isMr;
        final isHi = _session.isHi;
        final contact = patient.emergencyContact;

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
              isMr ? 'आपातकालीन संपर्क' : (isHi ? 'आपातकालीन संपर्क' : 'Emergency Contacts'),
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
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isMr
                              ? 'तातडीच्या वैद्यकीय प्रसंगी किंवा १०८ रुग्णवाहिका dispatch दरम्यान या संपर्कास सूचित केले जाईल.'
                              : (isHi
                                  ? 'आपातकालीन चिकित्सा या 108 एम्बुलेंस डिस्पैच के दौरान इस संपर्क को सूचित किया जाएगा।'
                                  : 'In critical clinical events or 108 ambulance dispatch, this designated contact receives real-time SMS & call alerts.'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Primary Contact Card
                Text(
                  isMr ? 'प्राथमिक आपातकालीन संपर्क' : (isHi ? 'प्राथमिक आपातकालीन संपर्क' : 'PRIMARY EMERGENCY CONTACT'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFE11D48), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name.isNotEmpty ? contact.name : 'No Contact Configured',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${contact.relationship} • ${contact.phoneNumber}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                            child: Text(
                              isMr ? 'सक्रिय' : (isHi ? 'सक्रिय' : 'Active'),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _openEditContactDialog(context, patient),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: Text(
                                isMr ? 'संपादित करा' : (isHi ? 'संपादित करें' : 'Edit Contact'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A6B56),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Dialing ${contact.phoneNumber}...'),
                                    backgroundColor: const Color(0xFF0A6B56),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.call, size: 16),
                              label: Text(
                                isMr ? 'कॉल करा' : (isHi ? 'कॉल करें' : 'Call Now'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dispatch Protocol Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMr
                              ? 'स्थानिक आशा कार्यकर्ती सुनिता गायकवाड यांच्याकडे देखील हा संपर्क नोंदवला गेला आहे.'
                              : (isHi
                                  ? 'स्थानीय आशा कार्यकर्ता सुनीता गायकवाड़ के पास भी यह संपर्क दर्ज है।'
                                  : 'Assigned ASHA worker Sunita Gaikwad and Kashti Sub-Centre are synchronized with this contact.'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4),
                        ),
                      ),
                    ],
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
