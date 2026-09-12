import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';

/// Teleconsultation Room Screen conforming strictly to DESIGN.md Section 6:
/// Video is primary. Captions/transcripts are collapsible and explicitly labeled
/// as a communication aid, not the official medical record. Clean controls.
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
  bool _showTranscript = false; // Collapsible by default per DESIGN.md
  int _callSeconds = 0;
  Timer? _timer;

  final List<Map<String, String>> _transcript = [
    {
      'speaker': 'Dr. Deshmukh',
      'text': 'Good morning Kavita. Your blood pressure reading from Kashti Sub-Centre is 148/96. Are you experiencing severe headaches today?',
    },
    {
      'speaker': 'Kavita Devi',
      'text': 'Yes doctor, there is persistent headache and some swelling in feet since morning.',
    },
    {
      'speaker': 'Dr. Deshmukh',
      'text': 'Understood. We will start Tab Labetalol 100mg to stabilize your blood pressure. Sunita Tai will record daily readings.',
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
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doctorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            Text('${widget.specialty} • ${_formatCallDuration(_callSeconds)}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showTranscript ? Icons.subtitles_rounded : Icons.subtitles_outlined, color: Colors.white),
            tooltip: 'Toggle live transcript',
            onPressed: () => setState(() => _showTranscript = !_showTranscript),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Primary Video Canvas
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 54,
                  backgroundColor: RuralCareColors.surfaceSubtle,
                  child: Icon(Icons.person, size: 64, color: RuralCareColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.doctorName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connected via secure WebRTC session',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

          // Collapsible Transcript Drawer (DESIGN.md: communication aid, not official record)
          if (_showTranscript)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Live speech transcript',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Communication aid only',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._transcript.map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${line['speaker']}: ',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 12),
                                ),
                                TextSpan(
                                  text: line['text'],
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // Bottom Control Bar
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callControlBtn(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  isActive: !_isMuted,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                _callControlBtn(
                  icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                  isActive: !_isVideoOff,
                  onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                ),
                // End Call Button
                FloatingActionButton(
                  backgroundColor: RuralCareColors.critical,
                  elevation: 0,
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Consultation completed.')),
                    );
                  },
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _callControlBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.white24 : Colors.white12,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
