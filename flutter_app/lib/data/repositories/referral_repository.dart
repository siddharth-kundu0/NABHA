import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralRepository extends ChangeNotifier {
  static final ReferralRepository _instance = ReferralRepository._internal();
  factory ReferralRepository() => _instance;
  ReferralRepository._internal() {
    _loadInitialReferrals();
  }

  final LocalCacheService _cache = LocalCacheService();
  late List<ReferralDto> _referrals;
  List<ReferralDto> get referrals => _referrals;

  void _loadInitialReferrals() {
    _referrals = [
      ReferralDto(
        id: 'REF-11021',
        patientId: 'pat-001',
        patientName: 'Kavita Rajesh Devi',
        referringFacility: 'Kashti Sub-Centre (ASHA Assisted)',
        targetFacilityId: 'FAC-SDH-301',
        targetFacilityName: 'Baramati Sub-District Hospital (SDH)',
        reason: '32-Week Gestational Hypertension with Severe Anaemia requiring specialist evaluation',
        urgency: 'URGENT',
        requiredSpecialty: 'Obstetrician & Gynecologist',
        status: 'HOSPITAL_NOTIFIED',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        expectedTransitMinutes: 40,
        isOverdue: false,
        counterReferralInstructions: 'Prescribed Labetalol 100mg BD. Measure daily BP at Sub-centre. Review in 7 days.',
        recommendationRationale: 'Baramati SDH (24.5 km) recommended over Daund CHC (12 km) because Daund lacks an on-duty Gynecologist and Blood Bank capability.',
      ),
    ];
  }

  void advanceStatus(String referralId) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      String nextStatus;
      switch (current.status) {
        case 'CREATED':
          nextStatus = 'HOSPITAL_NOTIFIED';
          break;
        case 'HOSPITAL_NOTIFIED':
          nextStatus = 'AMBULANCE_ASSIGNED';
          break;
        case 'AMBULANCE_ASSIGNED':
          nextStatus = 'PATIENT_EN_ROUTE';
          break;
        case 'PATIENT_EN_ROUTE':
          nextStatus = 'PATIENT_ARRIVED';
          break;
        case 'PATIENT_ARRIVED':
          nextStatus = 'ADMITTED';
          break;
        case 'ADMITTED':
          nextStatus = 'TREATMENT_COMPLETED';
          break;
        case 'TREATMENT_COMPLETED':
          nextStatus = 'COUNTER_REFERRED';
          break;
        case 'COUNTER_REFERRED':
          nextStatus = 'CLOSED';
          break;
        default:
          nextStatus = 'CREATED';
      }
      _referrals[idx] = current.copyWith(status: nextStatus);
      if (_cache.isOffline) {
        _cache.queueMutation('REFERRAL', 'STATUS_UPDATE', {'id': referralId, 'status': nextStatus});
      } else {
        try {
          FirebaseFirestore.instance
              .collection('referrals')
              .doc(referralId)
              .set({'status': nextStatus}, SetOptions(merge: true));
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  void addReferral(ReferralDto ref) {
    _referrals.insert(0, ref);
    if (_cache.isOffline) {
      _cache.queueMutation('REFERRAL', 'CREATE', ref.toJson());
    } else {
      try {
        FirebaseFirestore.instance
            .collection('referrals')
            .doc(ref.id)
            .set(ref.toJson());
      } catch (_) {}
    }
    notifyListeners();
  }

  void addCounterReferral(String referralId, String instructions) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      _referrals[idx] = _referrals[idx].copyWith(
        status: 'COUNTER_REFERRED',
        counterReferralInstructions: instructions,
      );
      if (_cache.isOffline) {
        _cache.queueMutation('REFERRAL', 'COUNTER_REFERRAL', {
          'id': referralId,
          'instructions': instructions,
          'status': 'COUNTER_REFERRED',
        });
      } else {
        try {
          FirebaseFirestore.instance
              .collection('referrals')
              .doc(referralId)
              .set({
                'status': 'COUNTER_REFERRED',
                'counterReferralInstructions': instructions,
              }, SetOptions(merge: true));
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  void dispatchCounterReferral({required String referralId, required String instructions}) =>
      addCounterReferral(referralId, instructions);

  void updateStatus(String referralId, String newStatus) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      _referrals[idx] = _referrals[idx].copyWith(status: newStatus);
      if (_cache.isOffline) {
        _cache.queueMutation('REFERRAL', 'STATUS_UPDATE', {'id': referralId, 'status': newStatus});
      } else {
        try {
          FirebaseFirestore.instance
              .collection('referrals')
              .doc(referralId)
              .set({'status': newStatus}, SetOptions(merge: true));
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  void addCoordinationNote(String referralId, String note) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final updatedNotes = List<String>.from(current.coordinationNotes)..add(note);
      _referrals[idx] = current.copyWith(coordinationNotes: updatedNotes);
      if (_cache.isOffline) {
        _cache.queueMutation('REFERRAL', 'ADD_NOTE', {'id': referralId, 'note': note});
      } else {
        try {
          FirebaseFirestore.instance.collection('referrals').doc(referralId).set({
            'coordinationNotes': updatedNotes,
          }, SetOptions(merge: true));
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  void toggleChecklistItem(String referralId, int itemIndex, bool checked) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final updatedChecklist = List<bool>.from(current.checklistDone);
      if (itemIndex >= 0 && itemIndex < updatedChecklist.length) {
        updatedChecklist[itemIndex] = checked;
        _referrals[idx] = current.copyWith(checklistDone: updatedChecklist);
        if (_cache.isOffline) {
          _cache.queueMutation('REFERRAL', 'CHECKLIST_UPDATE', {
            'id': referralId,
            'itemIndex': itemIndex,
            'checked': checked,
          });
        } else {
          try {
            FirebaseFirestore.instance.collection('referrals').doc(referralId).set({
              'checklistDone': updatedChecklist,
            }, SetOptions(merge: true));
          } catch (_) {}
        }
        notifyListeners();
      }
    }
  }
}
