import 'package:flutter/material.dart';

import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/features/doctor/screens/doctor_care_plan_screen.dart';
import 'package:ruralcare/core/services/zegocloud_service.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class LiveTeleconsultRoomScreen extends StatefulWidget {
  final String patientName;
  final String doctorName;
  final String specialty;
  final String? appointmentId;
  final String? facilityName;

  const LiveTeleconsultRoomScreen({
    super.key,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    this.appointmentId,
    this.facilityName,
  });

  @override
  State<LiveTeleconsultRoomScreen> createState() => _LiveTeleconsultRoomScreenState();
}

class _LiveTeleconsultRoomScreenState extends State<LiveTeleconsultRoomScreen> {
  late final String aptId;
  late final String currentUserId;
  late final String currentUserName;

  @override
  void initState() {
    super.initState();
    final session = SessionCoordinator();
    aptId = widget.appointmentId ?? 'APT-101';
    currentUserId = session.currentUserId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    currentUserName = session.userDisplayName ??
        (session.activeRole == AppRole.doctor ? widget.doctorName : widget.patientName);

    AppointmentRepository().updateAppointmentStatus(aptId, 'IN_PROGRESS');
  }

  void _onHangUp(BuildContext context, SessionCoordinator session) {
    AppointmentRepository().updateAppointmentStatus(aptId, 'COMPLETED');

    if (session.activeRole == AppRole.doctor) {
      final patientRepo = PatientRepository();
      
      PatientDto? patient;
      try {
        patient = patientRepo.patients.firstWhere(
          (p) => p.fullName == widget.patientName || p.id == widget.patientName,
        );
      } catch (_) {
        patient = patientRepo.activePatient ?? patientRepo.getOrCreatePatientForIdentifier(widget.patientName);
      }

      if (patient != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => DoctorCarePlanScreen(
              patient: patient!,
              appointmentId: aptId,
              isPatientView: false,
            ),
          ),
        );
      } else {
        Navigator.of(context).pop(); // fallback if patient not found
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final callId = ZegoCloudConfig.formatRoomId(aptId);

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: ZegoCloudConfig.appId,
        appSign: ZegoCloudConfig.appSign,
        userID: ZegoCloudConfig.formatUserId(currentUserId),
        userName: currentUserName,
        callID: callId,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          ..topMenuBar.isVisible = true
          ..topMenuBar.title = 'Live Teleconsultation',
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            _onHangUp(context, session);
          },
        ),
      ),
    );
  }
}
