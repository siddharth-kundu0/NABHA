import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/emergency_event_dto.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ruralcare/data/repositories/patient_repository.dart';

class EmergencyRepository extends ChangeNotifier {
  static final EmergencyRepository _instance = EmergencyRepository._internal();
  factory EmergencyRepository() => _instance;
  EmergencyRepository._internal();

  final LocalCacheService _cache = LocalCacheService();
  EmergencyEventDto? _activeEvent;

  EmergencyEventDto? get activeEvent => _activeEvent;
  bool get hasActiveAlert => _activeEvent != null && _activeEvent!.status == 'ACTIVE';
  bool get hasActiveEmergency => hasActiveAlert;

  void triggerSos({
    required String patientId,
    required String location,
    String? patientName,
    String? assignedFacilityName,
  }) {
    String resolvedName = patientName ?? '';
    String resolvedFacility = assignedFacilityName ?? '';
    if (resolvedName.isEmpty || resolvedFacility.isEmpty) {
      final patient = PatientRepository().findPatientByMobileOrId(patientId) ??
          PatientRepository().activePatient;
      if (resolvedName.isEmpty) resolvedName = patient?.fullName ?? 'Citizen ($patientId)';
      if (resolvedFacility.isEmpty) resolvedFacility = patient?.subCentre ?? 'Emergency Response Center';
    }

    triggerEmergency(
      patientId: patientId,
      patientName: resolvedName,
      assignedFacilityName: resolvedFacility,
    );
  }

  void triggerEmergency({
    required String patientId,
    required String patientName,
    required String assignedFacilityName,
  }) {
    _activeEvent = EmergencyEventDto(
      id: 'EMG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      patientId: patientId,
      patientName: patientName,
      triggeredAt: DateTime.now(),
      urgencyLevel: 'CRITICAL',
      nextOfKinNotified: true,
      facilityNotified: true,
      ambulanceDispatched: true,
      assignedFacilityName: assignedFacilityName,
      ambulanceVehicleNo: 'MH-12-EA-1082',
      etaMinutes: 16,
      status: 'ACTIVE',
    );
    if (_cache.isOffline) {
      _cache.queueMutation('EMERGENCY', 'TRIGGER', _activeEvent!.toJson());
    } else {
      try {
        FirebaseFirestore.instance
            .collection('emergency_events')
            .doc(_activeEvent!.id)
            .set(_activeEvent!.toJson());
      } catch (_) {}
    }
    notifyListeners();
  }

  void triggerSosEvent(EmergencyEventDto event) {
    _activeEvent = event;
    if (_cache.isOffline) {
      _cache.queueMutation('EMERGENCY', 'TRIGGER', _activeEvent!.toJson());
    } else {
      try {
        FirebaseFirestore.instance
            .collection('emergency_events')
            .doc(_activeEvent!.id)
            .set(_activeEvent!.toJson());
      } catch (_) {}
    }
    notifyListeners();
  }

  void resolveEmergency() {
    if (_activeEvent != null) {
      _activeEvent = EmergencyEventDto(
        id: _activeEvent!.id,
        patientId: _activeEvent!.patientId,
        patientName: _activeEvent!.patientName,
        triggeredAt: _activeEvent!.triggeredAt,
        urgencyLevel: _activeEvent!.urgencyLevel,
        nextOfKinNotified: _activeEvent!.nextOfKinNotified,
        facilityNotified: _activeEvent!.facilityNotified,
        ambulanceDispatched: _activeEvent!.ambulanceDispatched,
        assignedFacilityName: _activeEvent!.assignedFacilityName,
        ambulanceVehicleNo: _activeEvent!.ambulanceVehicleNo,
        etaMinutes: 0,
        status: 'RESOLVED',
      );
      if (_cache.isOffline) {
        _cache.queueMutation('EMERGENCY', 'RESOLVE', {'id': _activeEvent!.id});
      } else {
        try {
          FirebaseFirestore.instance
              .collection('emergency_events')
              .doc(_activeEvent!.id)
              .set({'status': 'RESOLVED'}, SetOptions(merge: true));
        } catch (_) {}
      }
      notifyListeners();
    }
  }
}
