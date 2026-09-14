import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/models/consent_request_dto.dart';

class ConsentRepository extends ChangeNotifier {
  static final ConsentRepository _instance = ConsentRepository._internal();
  factory ConsentRepository() => _instance;
  ConsentRepository._internal();

  final LocalCacheService _cache = LocalCacheService();
  final List<ConsentRequestDto> _requests = [];

  List<ConsentRequestDto> get requests => List.unmodifiable(_requests);

  bool hasValidConsent(String patientId) {
    try {
      final consent = _requests.firstWhere((r) => r.patientId == patientId && r.isGranted);
      return consent.isGranted;
    } catch (_) {
      return false;
    }
  }

  ConsentRequestDto? getActiveConsent(String patientId) {
    try {
      return _requests.firstWhere((r) => r.patientId == patientId && r.isGranted);
    } catch (_) {
      return null;
    }
  }

  ConsentRequestDto? getPendingRequest(String patientId) {
    try {
      return _requests.firstWhere((r) => r.patientId == patientId && r.isPending);
    } catch (_) {
      return null;
    }
  }

  ConsentRequestDto sendConsentRequest({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String doctorName,
    required String doctorFacility,
    String purpose = 'Clinical Consultation & Longitudinal Health History Review',
  }) {
    // Generate a secure 6-digit numeric OTP
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    final now = DateTime.now();
    final request = ConsentRequestDto(
      id: 'CR-${now.millisecondsSinceEpoch % 100000}',
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorName: doctorName,
      doctorFacility: doctorFacility,
      purpose: purpose,
      requestedAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      otp: otp,
      status: ConsentStatus.pending,
    );

    // Remove any previous pending request for this patient
    _requests.removeWhere((r) => r.patientId == patientId && r.status == ConsentStatus.pending);
    _requests.insert(0, request);

    if (_cache.isOffline) {
      _cache.queueMutation('CONSENT', 'REQUEST', request.toJson());
    }

    notifyListeners();
    return request;
  }

  bool verifyOtp({
    required String patientId,
    required String otp,
  }) {
    final idx = _requests.indexWhere((r) => r.patientId == patientId && r.isPending);
    if (idx != -1) {
      final pending = _requests[idx];
      if (pending.otp.trim() == otp.trim()) {
        _requests[idx] = pending.copyWith(status: ConsentStatus.granted);
        if (_cache.isOffline) {
          _cache.queueMutation('CONSENT', 'GRANT', {'id': pending.id, 'patientId': patientId});
        }
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void revokeConsent(String patientId) {
    final idx = _requests.indexWhere((r) => r.patientId == patientId && r.status == ConsentStatus.granted);
    if (idx != -1) {
      _requests[idx] = _requests[idx].copyWith(status: ConsentStatus.rejected);
      notifyListeners();
    }
  }

  void resetToDefaults() {
    _requests.clear();
    notifyListeners();
  }
}
