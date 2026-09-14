import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';

class HardwareVitalsTelemetryService {
  static final HardwareVitalsTelemetryService _instance =
      HardwareVitalsTelemetryService._internal();
  factory HardwareVitalsTelemetryService() => _instance;
  HardwareVitalsTelemetryService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _telemetrySubscription;
  final StreamController<VitalsDto> _telemetryStreamController =
      StreamController<VitalsDto>.broadcast();

  Stream<VitalsDto> get telemetryStream => _telemetryStreamController.stream;

  /// Starts listening to real-time telemetry stream from hardware bridge for a patient
  void bindPatientTelemetryStream(String patientId) {
    _telemetrySubscription?.cancel();

    try {
      _telemetrySubscription = _firestore
          .collection('vitals_telemetry')
          .doc(patientId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final vitals = VitalsDto(
            id: snapshot.id,
            patientId: patientId,
            recordedById: data['recordedById'] as String? ?? 'hardware-sensor-01',
            recordedByRole: 'HARDWARE_BLE',
            recordedAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            systolicBp: (data['systolicBp'] as num?)?.toInt() ?? 120,
            diastolicBp: (data['diastolicBp'] as num?)?.toInt() ?? 80,
            pulse: (data['pulse'] as num?)?.toInt() ?? (data['heartRate'] as num?)?.toInt() ?? 76,
            spO2: (data['spO2'] as num?)?.toInt() ?? 98,
            temperature: (data['temperature'] as num?)?.toDouble() ?? 98.6,
            bloodSugar: (data['bloodSugar'] as num?)?.toInt() ?? 110,
            haemoglobin: (data['haemoglobin'] as num?)?.toDouble() ?? 12.5,
            isFromBleDevice: true,
          );

          _telemetryStreamController.add(vitals);
          PatientRepository().updateVitals(patientId, vitals);
        }
      }, onError: (e) {
        debugPrint('Notice in telemetry stream: $e');
      });
    } catch (e) {
      debugPrint('Notice binding telemetry stream: $e');
    }
  }

  /// Ingests a reading directly from the physical sensor / BLE hardware
  Future<void> ingestHardwareReading({
    required String patientId,
    required int pulse,
    required int spO2,
    required double temperature,
    int systolicBp = 120,
    int diastolicBp = 80,
    String sensorDeviceId = 'BLE-PULSE-SENSOR-01',
  }) async {
    final vitals = VitalsDto(
      id: 'vit-hw-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      recordedById: sensorDeviceId,
      recordedByRole: 'HARDWARE_BLE',
      recordedAt: DateTime.now(),
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      pulse: pulse,
      spO2: spO2,
      temperature: temperature,
      bloodSugar: 110,
      haemoglobin: 12.5,
      isFromBleDevice: true,
    );

    // 1. Update local repository
    await PatientRepository().updateVitals(patientId, vitals);
    _telemetryStreamController.add(vitals);

    // 2. Sync to cloud telemetry collection
    try {
      await _firestore.collection('vitals_telemetry').doc(patientId).set({
        'patientId': patientId,
        'pulse': pulse,
        'heartRate': pulse,
        'spO2': spO2,
        'temperature': temperature,
        'systolicBp': systolicBp,
        'diastolicBp': diastolicBp,
        'sensorDeviceId': sensorDeviceId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('vitals').doc(vitals.id).set(vitals.toJson());
    } catch (e) {
      debugPrint('Notice syncing telemetry to Firestore: $e');
    }
  }

  void stopListening() {
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
  }
}
