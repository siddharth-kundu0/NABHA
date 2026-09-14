import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentRepository extends ChangeNotifier {
  static final AppointmentRepository _instance = AppointmentRepository._internal();
  factory AppointmentRepository() => _instance;
  AppointmentRepository._internal() {
    _loadInitialData();
    bindFirestoreStream();
  }

  final LocalCacheService _cache = LocalCacheService();
  late List<AppointmentDto> _appointments;
  late List<PrescriptionDto> _prescriptions;
  StreamSubscription<QuerySnapshot>? _apptSubscription;

  List<AppointmentDto> get appointments {
    final session = SessionCoordinator();
    if (session.activeRole == AppRole.patient) {
      final patient = PatientRepository().activePatient;
      final userAppts = getAppointmentsForPatient(
        patient,
        sessionUid: session.currentUserId,
        displayName: session.userDisplayName,
      );
      if (userAppts.isNotEmpty) return userAppts;
    }
    return _appointments;
  }

  List<AppointmentDto> getAppointmentsForPatient(
    PatientDto? patient, {
    String? sessionUid,
    String? displayName,
  }) {
    if (patient == null && sessionUid == null && displayName == null) {
      return _appointments;
    }
    final cleanPName = patient?.fullName.trim().toLowerCase() ?? '';
    final cleanDName = displayName?.trim().toLowerCase() ?? '';
    final pId = patient?.id;
    final cleanPhone = patient?.phoneNumber.replaceAll(RegExp(r'\D'), '') ?? '';

    return _appointments.where((a) {
      final aPId = a.patientId;
      final aPName = a.patientName.trim().toLowerCase();

      if (pId != null && pId.isNotEmpty && aPId == pId) return true;
      if (sessionUid != null && sessionUid.isNotEmpty && aPId == sessionUid) return true;
      if (cleanPName.isNotEmpty && aPName == cleanPName) return true;
      if (cleanDName.isNotEmpty && aPName == cleanDName) return true;
      if (cleanPhone.isNotEmpty && cleanPhone.length >= 6 && (aPId.contains(cleanPhone) || a.patientName.contains(cleanPhone))) return true;
      return false;
    }).toList();
  }

  AppointmentDto? getActiveCallForPatient(
    PatientDto? patient, {
    String? sessionUid,
    String? displayName,
  }) {
    final list = getAppointmentsForPatient(patient, sessionUid: sessionUid, displayName: displayName);
    try {
      return list.firstWhere((a) => a.status == 'IN_PROGRESS' || a.status == 'CALLING');
    } catch (_) {
      return null;
    }
  }

  List<PrescriptionDto> get prescriptions => _prescriptions;

  void bindFirestoreStream({AppRole role = AppRole.doctor, String? userId, String? doctorName}) {
    _apptSubscription?.cancel();
    if (_cache.isOffline) return;

    try {
      final Query query = FirebaseFirestore.instance.collection('appointments');

      _apptSubscription = query.snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final apt = AppointmentDto.fromJson(data);
              final idx = _appointments.indexWhere((a) => a.id == apt.id);
              if (idx != -1) {
                _appointments[idx] = apt;
              } else {
                _appointments.insert(0, apt);
              }
            } catch (_) {}
          }
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Notice in appointment stream: $e');
      });
    } catch (e) {
      debugPrint('Notice binding appointment stream: $e');
    }
  }

  void _loadInitialData() {
    _appointments = [];
    _prescriptions = [];
  }

  bool hasConflict({
    required String patientId,
    required String doctorName,
    required String scheduledTimeStr,
  }) {
    return _appointments.any(
      (a) =>
          a.patientId == patientId &&
          a.doctorName.toLowerCase() == doctorName.toLowerCase() &&
          a.appointmentTime.toLowerCase() == scheduledTimeStr.toLowerCase() &&
          a.status != 'COMPLETED' &&
          a.status != 'CANCELLED',
    );
  }

  void scheduleFollowUp({
    required String patientId,
    required String patientName,
    required String doctorName,
    required String specialty,
    required String facilityName,
    required DateTime scheduledTime,
    String chiefComplaint = 'Clinical Follow-up & Treatment Review',
  }) {
    final newApt = AppointmentDto(
      id: 'APT-${DateTime.now().millisecondsSinceEpoch % 100000}',
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      specialty: specialty,
      facilityName: facilityName,
      scheduledTime: scheduledTime,
      type: 'TELECONSULTATION',
      status: 'CONFIRMED',
      chiefComplaint: chiefComplaint,
    );
    addAppointment(newApt);
  }

  List<PrescriptionDto> getPrescriptionsForPatient(String patientId) {
    return _prescriptions.where((p) => p.patientId == patientId).toList();
  }

  void updateAppointmentStatus(String appointmentId, String newStatus) {
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx != -1) {
      final oldApt = _appointments[idx];
      _appointments[idx] = oldApt.copyWith(status: newStatus);
      if (_cache.isOffline) {
        _cache.queueMutation('APPOINTMENT', 'UPDATE_STATUS', {'id': appointmentId, 'status': newStatus});
      } else {
        try {
          FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .set({'status': newStatus}, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore appointment status notice: $e');
        }
      }

      // If call is initiated/in progress, notify patient urgently
      if (newStatus == 'IN_PROGRESS' || newStatus == 'CALLING') {
        NotificationRepository().notifyPatientOfIncomingCall(
          patientName: oldApt.patientName,
          doctorName: oldApt.doctorName,
          specialty: oldApt.specialty,
          appointmentId: appointmentId,
          facilityName: oldApt.facilityName,
        );
      } else if (newStatus == 'COMPLETED') {
        NotificationRepository().notifyPatientOfConsultationCompleted(
          patientName: oldApt.patientName,
          doctorName: oldApt.doctorName,
          appointmentId: appointmentId,
        );
      }

      notifyListeners();
    }
  }

  void updateStatus(String appointmentId, String newStatus) =>
      updateAppointmentStatus(appointmentId, newStatus);

  void assignRoom(String appointmentId, String room) {
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx != -1) {
      _appointments[idx] = _appointments[idx].copyWith(facilityName: room);
      notifyListeners();
    }
  }

  void markConsultationCompleted({
    required String appointmentId,
    required PrescriptionDto rx,
  }) {
    addPrescription(rx);
    updateAppointmentStatus(appointmentId, 'COMPLETED');
  }

  void addPrescription(PrescriptionDto rx) {
    _prescriptions.insert(0, rx);
    if (_cache.isOffline) {
      _cache.queueMutation('PRESCRIPTION', 'CREATE', rx.toJson());
    } else {
      try {
        FirebaseFirestore.instance
            .collection('prescriptions')
            .doc(rx.id)
            .set(rx.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore prescription create notice: $e');
      }
    }
    notifyListeners();
  }

  AppointmentDto? getAppointmentById(String id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void resetToDefaults() {
    _appointments = [];
    _prescriptions = [];
    notifyListeners();
  }

  void addAppointment(AppointmentDto apt) {
    final idx = _appointments.indexWhere((a) => a.id == apt.id);
    if (idx != -1) {
      _appointments[idx] = apt;
    } else {
      _appointments.insert(0, apt);
    }

    if (_cache.isOffline) {
      _cache.queueMutation('APPOINTMENT', 'CREATE', apt.toJson());
    } else {
      try {
        FirebaseFirestore.instance
            .collection('appointments')
            .doc(apt.id)
            .set(apt.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore appointment create notice: $e');
      }
    }

    // Trigger dual notifications for both Doctor and Patient
    NotificationRepository().notifyDoctorOfAppointment(
      doctorName: apt.doctorName,
      patientName: apt.patientName,
      time: apt.appointmentTime,
      type: apt.type,
      specialty: apt.specialty,
      appointmentId: apt.id,
    );
    NotificationRepository().notifyPatientOfAppointment(
      patientName: apt.patientName,
      doctorName: apt.doctorName,
      time: apt.appointmentTime,
      type: apt.type,
      specialty: apt.specialty,
      appointmentId: apt.id,
    );

    notifyListeners();
  }
}
