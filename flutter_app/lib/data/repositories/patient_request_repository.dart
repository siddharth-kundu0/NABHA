import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/patient_request_dto.dart';
import 'package:ruralcare/data/models/triage_dto.dart';
import 'package:ruralcare/core/database/local_cache.dart';

class PatientRequestRepository extends ChangeNotifier {
  static final PatientRequestRepository _instance = PatientRequestRepository._internal();
  factory PatientRequestRepository() => _instance;
  PatientRequestRepository._internal() {
    _loadInitialRequests();
  }

  final LocalCacheService _cache = LocalCacheService();
  final List<PatientRequestDto> _requests = [];

  List<PatientRequestDto> get requests => List.unmodifiable(_requests);
  List<PatientRequestDto> get pendingRequests =>
      _requests.where((r) => r.status == 'PENDING').toList();
  List<PatientRequestDto> get emergencyRequests =>
      _requests.where((r) => r.triagePriority == TriagePriority.p0Red).toList();

  void _loadInitialRequests() {
    _requests.clear();
  }

  void addRequest(PatientRequestDto req) {
    _requests.insert(0, req);
    if (_cache.isOffline) {
      _cache.queueMutation('PATIENT_REQUEST', 'CREATE', req.toJson());
    }
    notifyListeners();
  }

  void acceptRequest(String requestId, {String workerName = 'Kavita Verma (ASHA)'}) {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _requests[idx] = _requests[idx].copyWith(status: 'ACCEPTED');
      if (_cache.isOffline) {
        _cache.queueMutation('PATIENT_REQUEST', 'ACCEPT', {'id': requestId, 'worker': workerName});
      }
      notifyListeners();
    }
  }

  void escalateToDoctor(String requestId, {String note = 'Escalated by Frontline ASHA'}) {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _requests[idx] = _requests[idx].copyWith(status: 'ESCALATED_TO_DOCTOR');
      if (_cache.isOffline) {
        _cache.queueMutation('PATIENT_REQUEST', 'ESCALATE', {'id': requestId, 'note': note});
      }
      notifyListeners();
    }
  }

  void resolveRequest(String requestId) {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _requests[idx] = _requests[idx].copyWith(status: 'RESOLVED');
      notifyListeners();
    }
  }

  void resetToDefaults() {
    _loadInitialRequests();
    notifyListeners();
  }
}
