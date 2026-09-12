import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientRepository extends ChangeNotifier {
  static final PatientRepository _instance = PatientRepository._internal();
  factory PatientRepository() => _instance;
  PatientRepository._internal() {
    _loadInitialData();
  }

  final LocalCacheService _cache = LocalCacheService();
  late List<PatientDto> _patients;

  List<PatientDto> get patients => _patients;
  PatientDto get defaultPatient => _patients.first;

  void _loadInitialData() {
    _patients = [
      PatientDto(
        id: 'pat-001',
        ruralCareId: 'RC-MH-11021',
        abhaId: '91-4829-1029-8472',
        fullName: 'Kavita Rajesh Devi',
        age: 26,
        gender: 'FEMALE',
        phoneNumber: '+919823411204',
        village: 'Kashti',
        subCentre: 'Kashti Sub-Centre',
        district: 'Pune Rural',
        assignedAsha: 'Sunita Tai Gaikwad',
        isPregnant: true,
        gestationalAgeWeeks: 32,
        ancVisitsCompleted: 3,
        edd: DateTime.now().add(const Duration(days: 56)),
        highRiskConditions: ['GESTATIONAL_HYPERTENSION', 'SEVERE_ANAEMIA'],
        chronicConditions: ['ANAEMIA'],
        allergies: ['PENICILLIN'],
        emergencyContact: const EmergencyContactDto(
          name: 'Rajesh Devi',
          relationship: 'HUSBAND',
          phoneNumber: '+919823411205',
        ),
        latestVitals: VitalsDto(
          id: 'vit-001',
          patientId: 'pat-001',
          recordedById: 'asha-904',
          recordedByRole: 'HEALTH_WORKER',
          recordedAt: DateTime.now().subtract(const Duration(hours: 2)),
          systolicBp: 148,
          diastolicBp: 96,
          pulse: 88,
          spO2: 96,
          temperature: 98.6,
          bloodSugar: 142,
          haemoglobin: 7.8,
          isFromBleDevice: true,
        ),
      ),
      PatientDto(
        id: 'pat-002',
        ruralCareId: 'RC-MH-11022',
        abhaId: '91-3829-9182-1102',
        fullName: 'Ramesh Balu Jadhav',
        age: 54,
        gender: 'MALE',
        phoneNumber: '+919811234567',
        village: 'Kashti',
        subCentre: 'Kashti Sub-Centre',
        district: 'Pune Rural',
        assignedAsha: 'Sunita Tai Gaikwad',
        isPregnant: false,
        chronicConditions: ['TYPE_2_DIABETES', 'HYPERTENSION'],
        allergies: [],
        emergencyContact: const EmergencyContactDto(
          name: 'Sunita Jadhav',
          relationship: 'WIFE',
          phoneNumber: '+919811234568',
        ),
        latestVitals: VitalsDto(
          id: 'vit-002',
          patientId: 'pat-002',
          recordedById: 'asha-904',
          recordedByRole: 'HEALTH_WORKER',
          recordedAt: DateTime.now().subtract(const Duration(days: 1)),
          systolicBp: 155,
          diastolicBp: 92,
          pulse: 78,
          spO2: 97,
          temperature: 98.4,
          bloodSugar: 210,
          haemoglobin: 13.2,
        ),
      ),
    ];
  }

  Future<void> updateVitals(String patientId, VitalsDto newVitals) async {
    final idx = _patients.indexWhere((p) => p.id == patientId);
    if (idx != -1) {
      final old = _patients[idx];
      _patients[idx] = PatientDto(
        id: old.id,
        ruralCareId: old.ruralCareId,
        abhaId: old.abhaId,
        fullName: old.fullName,
        age: old.age,
        gender: old.gender,
        phoneNumber: old.phoneNumber,
        village: old.village,
        subCentre: old.subCentre,
        district: old.district,
        assignedAsha: old.assignedAsha,
        isPregnant: old.isPregnant,
        gestationalAgeWeeks: old.gestationalAgeWeeks,
        ancVisitsCompleted: old.ancVisitsCompleted,
        edd: old.edd,
        highRiskConditions: old.highRiskConditions,
        chronicConditions: old.chronicConditions,
        allergies: old.allergies,
        emergencyContact: old.emergencyContact,
        latestVitals: newVitals,
      );

      if (_cache.isOffline) {
        _cache.queueMutation('PATIENT_VITALS', 'UPDATE', newVitals.toJson());
      } else {
        try {
          FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .set({'latestVitals': newVitals.toJson()}, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore patient sync notice: $e');
        }
      }
      notifyListeners();
    }
  }

  Future<void> updatePatientVitals(String patientId, VitalsDto newVitals) => updateVitals(patientId, newVitals);

  Future<void> updatePatientProfile({
    required String patientId,
    String? fullName,
    int? age,
    String? gender,
    String? phoneNumber,
    String? village,
    String? subCentre,
    String? district,
    EmergencyContactDto? emergencyContact,
  }) async {
    final idx = _patients.indexWhere((p) => p.id == patientId);
    if (idx != -1) {
      final old = _patients[idx];
      final updated = PatientDto(
        id: old.id,
        ruralCareId: old.ruralCareId,
        abhaId: old.abhaId,
        fullName: fullName ?? old.fullName,
        age: age ?? old.age,
        gender: gender ?? old.gender,
        phoneNumber: phoneNumber ?? old.phoneNumber,
        village: village ?? old.village,
        subCentre: subCentre ?? old.subCentre,
        district: district ?? old.district,
        assignedAsha: old.assignedAsha,
        isPregnant: old.isPregnant,
        gestationalAgeWeeks: old.gestationalAgeWeeks,
        ancVisitsCompleted: old.ancVisitsCompleted,
        edd: old.edd,
        highRiskConditions: old.highRiskConditions,
        chronicConditions: old.chronicConditions,
        allergies: old.allergies,
        emergencyContact: emergencyContact ?? old.emergencyContact,
        latestVitals: old.latestVitals,
      );

      _patients[idx] = updated;

      if (_cache.isOffline) {
        _cache.queueMutation('PATIENT_PROFILE', 'UPDATE', updated.toJson());
      } else {
        try {
          FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .set(updated.toJson(), SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore profile update notice: $e');
        }
      }
      notifyListeners();
    }
  }

  Future<void> updateEmergencyContact({
    required String patientId,
    required EmergencyContactDto contact,
  }) async {
    await updatePatientProfile(patientId: patientId, emergencyContact: contact);
  }

  void addPatient(PatientDto patient) {
    _patients.insert(0, patient);
    if (_cache.isOffline) {
      _cache.queueMutation('PATIENT', 'CREATE', patient.toJson());
    } else {
      try {
        FirebaseFirestore.instance
            .collection('patients')
            .doc(patient.id)
            .set(patient.toJson());
      } catch (e) {
        debugPrint('Firestore patient create notice: $e');
      }
    }
    notifyListeners();
  }

  Future<void> recordFollowUpVisit({
    required String patientId,
    required int systolic,
    required int diastolic,
    required String notes,
    required String status,
    required String visitMode,
    List<String> adherenceChecklist = const [],
  }) async {
    final idx = _patients.indexWhere((p) => p.id == patientId);
    if (idx != -1) {
      final old = _patients[idx];
      final newVitals = (old.latestVitals ?? VitalsDto(
        id: 'vit-${DateTime.now().millisecondsSinceEpoch}',
        patientId: patientId,
        recordedById: 'asha-904',
        recordedByRole: 'HEALTH_WORKER',
        recordedAt: DateTime.now(),
        systolicBp: systolic,
        diastolicBp: diastolic,
        pulse: 76,
        spO2: 98,
        temperature: 98.6,
        bloodSugar: 100,
        haemoglobin: 12.0,
      )).copyWith(
        systolicBp: systolic,
        diastolicBp: diastolic,
        recordedAt: DateTime.now(),
      );

      _patients[idx] = old.copyWith(latestVitals: newVitals);

      final visitPayload = {
        'patientId': patientId,
        'systolic': systolic,
        'diastolic': diastolic,
        'notes': notes,
        'status': status,
        'visitMode': visitMode,
        'adherenceChecklist': adherenceChecklist,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (_cache.isOffline) {
        _cache.queueMutation('FOLLOW_UP_VISIT', 'CREATE', visitPayload);
      } else {
        try {
          await FirebaseFirestore.instance
              .collection('follow_up_visits')
              .add(visitPayload);
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .set({'latestVitals': newVitals.toJson()}, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore follow up visit record notice: $e');
        }
      }
      notifyListeners();
    }
  }
}
