import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';

class LiveTeleconsultRoomScreen extends StatefulWidget {
  final String patientName;
  final String doctorName;
  final String specialty;

  const LiveTeleconsultRoomScreen({
    super.key,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
  });

  @override
  State<LiveTeleconsultRoomScreen> createState() => _LiveTeleconsultRoomScreenState();
}

class _LiveTeleconsultRoomScreenState extends State<LiveTeleconsultRoomScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _showTranscript = true;
  int _callSeconds = 0;
  Timer? _timer;

  final List<Map<String, String>> _transcript = [
    {
      'speaker': 'Dr. Anjali Patil',
      'marathi': 'नमस्ते कविता, तुमचा रक्तदाब १४८/९६ नोंदवला आहे. सध्या डोकेदुखी किंवा डोळ्यांसमोर अंधुक दिसते का?',
      'english': 'Hello Kavita, your BP was recorded as 148/96. Are you having headaches or blurred vision right now?',
    },
    {
      'speaker': 'Kavita Devi (ASHA Assisted)',
      'marathi': 'हो डॉक्टर, सकाळपासून तीव्र डोकेदुखी आहे आणि पायांवर सूज जास्त आली आहे.',
      'english': 'Yes doctor, severe headache since morning and increased swelling on both feet.',
    },
    {
      'speaker': 'Dr. Anjali Patil',
      'marathi': 'हे गर्भावस्थेतील उच्च रक्तदाबाचे (Preeclampsia) लक्षण आहे. मी ताबडतोब टॅबलेट लॅबेटाजोल १०० मिलीग्राम सुरू करत आहे.',
      'english': 'This is gestational hypertension with pre-eclampsia risk. I am immediately prescribing Tab Labetalol 100mg twice daily.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCallDuration(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final patient = patientRepo.defaultPatient;
    final vitals = patient.latestVitals;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doctorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('${widget.specialty} • ${_formatCallDuration(_callSeconds)}', style: const TextStyle(fontSize: 11, color: AppColors.forestTealLight)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showTranscript ? Icons.subtitles : Icons.subtitles_off, color: Colors.white),
            tooltip: 'Toggle Bilingual Transcript',
            onPressed: () => setState(() => _showTranscript = !_showTranscript),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Remote Video View (Doctor Video Mockup)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1E293B),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.forestTeal.withOpacity(0.3),
                    child: const Icon(Icons.person, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(widget.doctorName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.specialty, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Color(0xFF10B981), size: 12),
                        SizedBox(width: 4),
                        Text('ABDM 256-Bit Encrypted Tele-Consult', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Picture-in-Picture Local Self View (Patient + ASHA)
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              width: 110,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: _isVideoOff
                        ? const Icon(Icons.videocam_off, color: Colors.white54)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircleAvatar(radius: 24, backgroundColor: AppColors.terracotta, child: Icon(Icons.person, color: Colors.white, size: 28)),
                              const SizedBox(height: 4),
                              Text(widget.patientName.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              const Text('ASHA Assisted', style: TextStyle(color: Colors.white70, fontSize: 8)),
                            ],
                          ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: Icon(_isMuted ? Icons.mic_off : Icons.mic, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vitals HUD Floating Banner
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.terracotta, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LIVE BLE VITALS', style: TextStyle(color: AppColors.terracotta, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('BP: ${vitals?.systolicBp}/${vitals?.diastolicBp} mmHg', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Pulse: ${vitals?.pulse} bpm | SpO2: ${vitals?.spO2}%', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Text('Hb: ${vitals?.haemoglobin} g/dL (Severe)', style: const TextStyle(color: AppColors.terracotta, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Collapsible Bilingual Live Transcript
          if (_showTranscript)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _transcript.length,
                  itemBuilder: (context, idx) {
                    final t = _transcript[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['speaker']!, style: const TextStyle(color: AppColors.forestTealLight, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(t['marathi']!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(t['english']!, style: const TextStyle(color: Colors.white60, fontSize: 10, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // Video Controls Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              color: Colors.black.withOpacity(0.85),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlBtn(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? AppColors.criticalRed : Colors.white24,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  _controlBtn(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    color: _isVideoOff ? AppColors.criticalRed : Colors.white24,
                    onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                  ),
                  _controlBtn(
                    icon: Icons.receipt_long,
                    color: AppColors.forestTeal,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-Prescription tab opened in side drawer.')),
                      );
                    },
                  ),
                  _controlBtn(
                    icon: Icons.call_end,
                    color: AppColors.criticalRed,
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Teleconsultation ended. Summary saved to patient health records.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required Color color,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      shape: const CircleBorder(),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
