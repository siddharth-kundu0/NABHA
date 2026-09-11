import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/core/database/local_cache.dart';

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
      }
      notifyListeners();
    }
  }

  void addReferral(ReferralDto ref) {
    _referrals.insert(0, ref);
    if (_cache.isOffline) {
      _cache.queueMutation('REFERRAL', 'CREATE', ref.toJson());
    }
    notifyListeners();
  }
}
