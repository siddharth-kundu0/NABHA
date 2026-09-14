import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientRepository extends ChangeNotifier {
  static final PatientRepository _instance = PatientRepository._internal();
  factory PatientRepository() => _instance;
  PatientRepository._internal() {
    _loadInitialData();
    bindFirestoreStream();
  }

  final LocalCacheService _cache = LocalCacheService();
  late List<PatientDto> _patients;
  PatientDto? _activePatient;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  List<PatientDto> get patients {
    final session = SessionCoordinator();
    if (session.activeRole == AppRole.patient && session.currentUserId != null) {
      final cleanId = session.currentUserEmail?.replaceAll('@ruralcare.nabha.gov.in', '') ?? session.currentUserId ?? '';
      final userMatch = _patients.where((p) {
        final cleanPhone = p.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
        final cleanAbha = p.abhaId.replaceAll(RegExp(r'[^0-9]'), '');
        final targetClean = cleanId.replaceAll(RegExp(r'[^0-9]'), '');
        return p.id == session.currentUserId ||
            (targetClean.isNotEmpty && cleanPhone.endsWith(targetClean)) ||
            (targetClean.isNotEmpty && cleanAbha.endsWith(targetClean));
      }).toList();
      if (userMatch.isNotEmpty) return userMatch;
      if (_activePatient != null) return [_activePatient!];
    }
    return _patients;
  }

  PatientDto getOrCreatePatientForIdentifier(String identifier) {
    final cleanId = identifier.replaceAll(RegExp(r'[^0-9]'), '');
    final matches = _patients.where((p) {
      final cleanPhone = p.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanAbha = p.abhaId.replaceAll(RegExp(r'[^0-9]'), '');
      return p.id == identifier ||
          (cleanId.isNotEmpty && cleanPhone.endsWith(cleanId)) ||
          (cleanId.isNotEmpty && cleanAbha.endsWith(cleanId));
    });

    if (matches.isNotEmpty) {
      _activePatient = matches.first;
      return matches.first;
    }

    final newPatient = PatientDto(
      id: 'pat-${identifier.hashCode.abs().toString().substring(0, 6)}',
      ruralCareId: 'RC-MH-${identifier.length >= 4 ? identifier.substring(identifier.length - 4) : "1001"}',
      abhaId: '91-${identifier.length >= 8 ? "${identifier.substring(0, 4)}-${identifier.substring(4, 8)}" : "8492-1029"}-8472',
      fullName: 'Citizen ($identifier)',
      age: 28,
      gender: 'FEMALE',
      phoneNumber: identifier.startsWith('+') ? identifier : '+91$identifier',
      village: 'Kashti',
      subCentre: 'Kashti Sub-Centre',
      district: 'Pune Rural',
      assignedAsha: 'Sunita Tai Gaikwad',
      emergencyContact: EmergencyContactDto(
        name: 'Family Member',
        relationship: 'Family',
        phoneNumber: identifier.startsWith('+') ? identifier : '+91$identifier',
      ),
    );
    addPatient(newPatient);
    _activePatient = newPatient;
    return newPatient;
  }

  PatientDto? get defaultPatient => _patients.isNotEmpty ? _patients.first : null;
  PatientDto? get activePatient => _activePatient ?? defaultPatient;
  bool get hasPatients => _patients.isNotEmpty;

  PatientDto? findPatientByMobileOrId(String identifier) {
    final clean = identifier.trim().toLowerCase();
    final digits = clean.replaceAll(RegExp(r'\D'), '');
    for (final p in _patients) {
      final pPhone = p.phoneNumber.replaceAll(RegExp(r'\D'), '');
      final pAbha = p.abhaId.replaceAll(RegExp(r'\D'), '');
      if (p.id.toLowerCase() == clean ||
          (digits.isNotEmpty && pPhone.isNotEmpty && (pPhone.endsWith(digits) || digits.endsWith(pPhone))) ||
          (digits.isNotEmpty && pAbha.isNotEmpty && (pAbha.endsWith(digits) || digits.endsWith(pAbha)))) {
        return p;
      }
    }
    return null;
  }

  void bindFirestoreStream({AppRole role = AppRole.doctor, String? userId, String? subCentre}) {
    _firestoreSubscription?.cancel();
    if (_cache.isOffline) return;

    try {
      Query query = FirebaseFirestore.instance.collection('patients');
      if (role == AppRole.patient && userId != null) {
        query = query.where('userId', isEqualTo: userId);
      } else if (role == AppRole.healthWorker && subCentre != null && subCentre.isNotEmpty) {
        query = query.where('subCentre', isEqualTo: subCentre);
      }

      _firestoreSubscription = query.snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final cp = PatientDto.fromJson(data);
              final existingIdx = _patients.indexWhere((p) => p.id == cp.id);
              if (existingIdx != -1) {
                _patients[existingIdx] = cp;
              } else {
                _patients.add(cp);
              }
            } catch (_) {}
          }
          if (role == AppRole.patient && _patients.isNotEmpty) {
            _activePatient = _patients.first;
          }
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Notice in patient firestore stream: $e');
      });
    } catch (e) {
      debugPrint('Notice binding patient stream: $e');
    }
  }

  void _loadInitialData() {
    _patients = [];
    _activePatient = null;
  }

  void setActivePatient(PatientDto? patient) {
    _activePatient = patient;
    notifyListeners();
  }

  void selectPatientById(String id) {
    try {
      _activePatient = _patients.firstWhere((p) => p.id == id);
      notifyListeners();
    } catch (_) {}
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
    _activePatient = patient;
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

  PatientDto? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void resetToDefaults() {
    _patients = [];
    _activePatient = null;
    notifyListeners();
  }
}
