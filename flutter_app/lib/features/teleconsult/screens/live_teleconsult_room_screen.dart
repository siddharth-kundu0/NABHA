import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/features/doctor/screens/doctor_care_plan_screen.dart';
import 'package:ruralcare/core/services/zegocloud_service.dart';

/// Stitch Screen 5: Live Consultation (Mobile 780x1768)
/// Screen ID: aef13f3732e04580aa55d8205c4f2925
class LiveTeleconsultRoomScreen extends StatefulWidget {
  final String patientName;
  final String doctorName;
  final String specialty;
  final String? appointmentId;

  const LiveTeleconsultRoomScreen({
    super.key,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    this.appointmentId,
  });

  @override
  State<LiveTeleconsultRoomScreen> createState() => _LiveTeleconsultRoomScreenState();
}

class _LiveTeleconsultRoomScreenState extends State<LiveTeleconsultRoomScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _showTranscript = false;
  int _callSeconds = 0;
  Timer? _timer;
  late final List<Map<String, String>> _transcript;

  @override
  void initState() {
    super.initState();
    _transcript = [];
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });

    final session = SessionCoordinator();
    final aptId = widget.appointmentId ?? 'APT-101';
    final currentUserId = session.currentUserId ?? 'user_teleconsult';
    final currentUserName = session.userDisplayName ??
        (session.activeRole == AppRole.doctor ? widget.doctorName : widget.patientName);

    ZegoCloudService().initializeCallSession(
      appointmentId: aptId,
      userId: currentUserId,
      userName: currentUserName,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    ZegoCloudService().endCallSession();
    super.dispose();
  }

  String _formatDuration(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showEmergencyDialog(SessionCoordinator session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emergency, color: RuralCareColors.critical, size: 24),
            const SizedBox(width: 8),
            Text(
              session.isHindi ? 'आपातकालीन सहायता का अनुरोध?' : (session.isMarathi ? 'तातडीच्या मदतीची विनंती करायची?' : 'Request Emergency Help?'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          session.isHindi
              ? 'यह निकटतम प्राथमिक स्वास्थ्य केंद्र को सतर्क करेगा और पंजीकृत स्थान पर 108 आपातकालीन वाहन भेजेगा।'
              : (session.isMarathi
                  ? 'हे जवळच्या प्राथमिक आरोग्य केंद्राला सतर्क करेल आणि नोंदणीकृत ठिकाणी १०८ रुग्णवाहिका पाठवेल.'
                  : 'This will alert the nearest primary health center and dispatch emergency transport to the registered location.'),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(session.isHindi ? 'रद्द करें' : (session.isMarathi ? 'रद्द करा' : 'Cancel & Return')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final toastMsg = session.isHindi
                  ? '108 आपातकालीन चिकित्सा सेवा को अलर्ट भेजा गया!'
                  : (session.isMarathi
                      ? '१०८ रुग्णवाहिका प्रतिसाद प्रणालीला अलर्ट पाठवला!'
                      : 'Emergency alert dispatched to 108 Emergency Medical Response!');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(toastMsg),
                  backgroundColor: RuralCareColors.critical,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.critical),
            child: Text(
              session.isHindi ? 'आपातकाल की पुष्टि करें' : (session.isMarathi ? 'तातडीची पुष्टी करा' : 'Confirm Emergency'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndCallDialog(SessionCoordinator session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          session.isHindi ? 'टेलीकंसल्टेशन समाप्त करें?' : (session.isMarathi ? 'टेलिकन्सल्टेशन समाप्त करायचे?' : 'End Teleconsultation?'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          session.isHindi
              ? 'परामर्श पूरा करें, ई-नुस्खा जारी करें और देखभाल योजना बनाएं?'
              : (session.isMarathi
                  ? 'सल्लामसलत पूर्ण करा, ई-प्रिस्क्रिप्शन जारी करा आणि काळजी योजना तयार करा?'
                  : 'Proceed to complete consultation, issue e-prescription and counter-referral plan?'),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(session.isHindi ? 'कॉल जारी रखें' : (session.isMarathi ? 'कॉल सुरू ठेवा' : 'Continue Call')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final aptId = widget.appointmentId ?? 'APT-101';
              AppointmentRepository().updateAppointmentStatus(aptId, 'COMPLETED');
              final patientRepo = PatientRepository();
              final patient = patientRepo.patients.isNotEmpty
                  ? patientRepo.patients.firstWhere(
                      (p) => p.fullName == widget.patientName,
                      orElse: () => patientRepo.activePatient ?? patientRepo.patients.first,
                    )
                  : PatientDto(
                      id: 'pat-active',
                      ruralCareId: 'RC-9921',
                      abhaId: '91-4829-1029-4821',
                      fullName: widget.patientName,
                      age: 42,
                      gender: 'Female',
                      phoneNumber: '9876543210',
                      village: 'Rampur',
                      subCentre: 'Rampur Health Sub-Centre',
                      district: 'Bilaspur',
                      assignedAsha: 'Sunita Bai',
                      emergencyContact: const EmergencyContactDto(
                        name: 'Ramesh',
                        relationship: 'Spouse',
                        phoneNumber: '9876543211',
                      ),
                    );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (c) => DoctorCarePlanScreen(
                    patient: patient,
                    appointmentId: aptId,
                    isPatientView: session.activeRole == AppRole.patient,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.teal),
            child: Text(
              session.isHindi ? 'सहेजें और देखभाल योजना खोलें' : (session.isMarathi ? 'जतन करा आणि काळजी योजना उघडा' : 'Save & Open Care Plan'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDoctorDocRequestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.folder_shared_rounded, color: Color(0xFF005140)),
            SizedBox(width: 8),
            Text('Document Access Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.doctorName} is requesting permission to view your recent ABDM Lab Reports & ANC Ultrasound Scan.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFF005140)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Access expires automatically when the teleconsultation concludes.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF005140)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document access declined.')),
              );
            },
            child: const Text('Deny', style: TextStyle(color: RuralCareColors.critical)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Granted document access to consulting clinician.'),
                  backgroundColor: Color(0xFF005140),
                ),
              );
            },
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final isHi = session.isHindi;
        final isMr = session.isMarathi;

        return Scaffold(
          backgroundColor: const Color(0xFF131B2E),
          body: SafeArea(
            child: Stack(
              children: [
                // 1. Dominant Video Feed & Canvas
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF1A233A),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: RuralCareColors.teal.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: RuralCareColors.teal, width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.person, size: 68, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.doctorName,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.specialty} • PHC Rampur',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Speaking Indicator Overlay
                Positioned(
                  top: 76,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.graphic_eq, size: 16, color: RuralCareColors.success),
                        const SizedBox(width: 6),
                        Text(
                          isHi
                              ? '${widget.doctorName} बोल रहे हैं'
                              : (isMr ? '${widget.doctorName} बोलत आहेत' : '${widget.doctorName} speaking'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // PiP (Picture in Picture) Patient self-view
                Positioned(
                  bottom: 120,
                  right: 16,
                  child: Container(
                    width: 100,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFF283044),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: _isVideoOff ? Colors.white24 : Colors.white70,
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.patientName.split(' ').first,
                                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                Icon(
                                  _isMuted ? Icons.mic_off : Icons.mic,
                                  size: 10,
                                  color: _isMuted ? RuralCareColors.critical : RuralCareColors.success,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Collapsible Live Transcript
                if (_showTranscript)
                  Positioned(
                    bottom: 110,
                    left: 16,
                    right: 125,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isHi ? 'लाइव बातचीत मजकूर' : (isMr ? 'थेट संभाषण मजकूर' : 'Live Speech Transcript'),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  isHi ? 'द्विभाषी सहायता' : (isMr ? 'द्विभाषिक मदत' : 'Bilingual Aid'),
                                  style: const TextStyle(fontSize: 9, color: Colors.white60),
                                ),
                              ],
                            ),
                            const Divider(height: 12, color: Colors.white24),
                            if (_transcript.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  isHi
                                      ? 'द्विभाषी संभाषण ट्रांसक्रिप्शन सक्रिय है। जब प्रतिभागी बोलेंगे, पाठ यहाँ दिखाई देगा।'
                                      : (isMr
                                          ? 'द्विभाषिक संभाषण मजकूर सक्रिय आहे. सहभागी बोलू लागल्यावर मजकूर येथे दिसेल.'
                                          : 'Bilingual speech transcription active. Text will stream here as participants speak.'),
                                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic),
                                ),
                              )
                            else
                              ..._transcript.map((line) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${line['speaker']} • ${line['time']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: line['isDoctor'] == 'true' ? AppColors.skyBlue : Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    line['text'] ?? '',
                                    style: const TextStyle(fontSize: 11, color: Colors.white, height: 1.3),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 2. Top Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.doctorName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                const Text('• PHC Rampur', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: RuralCareColors.success, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(
                                  isHi ? 'कनेक्टेड' : (isMr ? 'जोडले गेले' : 'Connected'),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.success),
                                ),
                                const SizedBox(width: 8),
                                Text(_formatDuration(_callSeconds), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF005140),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.videocam, size: 10, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ZEGOCLOUD • ${ZegoCloudService().activeRoomId ?? "Live"}',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showEmergencyDialog(session),
                          icon: const Icon(Icons.emergency, size: 14, color: Colors.white),
                          label: Text(
                            isHi ? 'मदद' : (isMr ? 'मदत' : 'Help'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RuralCareColors.critical,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Bottom Call Controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    color: Colors.black.withOpacity(0.8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute
                        _callButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted
                              ? (isHi ? 'अनम्यूट' : (isMr ? 'अनम्यूट' : 'Unmute'))
                              : (isHi ? 'म्यूट' : (isMr ? 'म्यूट' : 'Mute')),
                          isActive: !_isMuted,
                          onTap: () => setState(() => _isMuted = !_isMuted),
                        ),
                        // Camera
                        _callButton(
                          icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                          label: _isVideoOff
                              ? (isHi ? 'वीडियो चालू' : (isMr ? 'व्हिडिओ सुरू' : 'Start Video'))
                              : (isHi ? 'कैमरा' : (isMr ? 'कॅमेरा' : 'Camera')),
                          isActive: !_isVideoOff,
                          onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                        ),
                        // Speaker
                        _callButton(
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          label: isHi ? 'स्पीकर' : (isMr ? 'स्पीकर' : 'Speaker'),
                          isActive: _isSpeakerOn,
                          onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                        ),
                        // Transcript
                        _callButton(
                          icon: Icons.subtitles,
                          label: isHi ? 'मजकूर' : (isMr ? 'मजकूर' : 'Transcript'),
                          isActive: _showTranscript,
                          onTap: () => setState(() => _showTranscript = !_showTranscript),
                        ),
                        // Share Docs
                        _callButton(
                          icon: Icons.folder_shared_outlined,
                          label: isHi ? 'दस्तावेज' : (isMr ? 'कागदपत्रे' : 'Docs'),
                          isActive: false,
                          onTap: _showDoctorDocRequestDialog,
                        ),
                        // End Call
                        GestureDetector(
                          onTap: () => _showEndCallDialog(session),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: RuralCareColors.critical,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
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

  Widget _callButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white24 : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }
}
