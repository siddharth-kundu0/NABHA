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
}
