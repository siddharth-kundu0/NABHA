import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/data/models/notification_item_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralRepository extends ChangeNotifier {
  static final ReferralRepository _instance = ReferralRepository._internal();
  factory ReferralRepository() => _instance;
  ReferralRepository._internal() {
    _loadInitialReferrals();
    bindFirestoreStream();
  }

  final LocalCacheService _cache = LocalCacheService();
  late List<ReferralDto> _referrals;

  List<ReferralDto> get referrals {
    final session = SessionCoordinator();
    if (session.activeRole == AppRole.patient && session.currentUserId != null) {
      final userRefs = _referrals.where((r) =>
          r.patientId == session.currentUserId ||
          (session.userDisplayName != null && r.patientName == session.userDisplayName)).toList();
      if (userRefs.isNotEmpty) return userRefs;
    }
    return _referrals;
  }

  StreamSubscription<QuerySnapshot>? _referralSubscription;

  void bindFirestoreStream({AppRole role = AppRole.doctor, String? userId, String? facilityId}) {
    _referralSubscription?.cancel();
    if (_cache.isOffline) return;

    try {
      Query query = FirebaseFirestore.instance.collection('referrals');
      if (role == AppRole.patient && userId != null) {
        query = query.where('patientId', isEqualTo: userId);
      }

      _referralSubscription = query.snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final ref = ReferralDto.fromJson(data);
              final idx = _referrals.indexWhere((r) => r.id == ref.id);
              if (idx != -1) {
                _referrals[idx] = ref;
              } else {
                _referrals.insert(0, ref);
              }
            } catch (_) {}
          }
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Notice in referral stream: $e');
      });
    } catch (e) {
      debugPrint('Notice binding referral stream: $e');
    }
  }

  void _loadInitialReferrals() {
    _referrals = [];
  }

  // 1. Clinical Triage
  void triageReferral(String referralId, {required String priority, String? notes}) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final updatedNotes = List<String>.from(current.coordinationNotes);
      if (notes != null && notes.isNotEmpty) {
        updatedNotes.add('Triage note: $notes');
      }
      _referrals[idx] = current.copyWith(
        urgency: priority,
        status: 'TRIAGED',
        coordinationNotes: updatedNotes,
        updatedAt: DateTime.now(),
      );
      _syncUpdate(referralId, {
        'urgency': priority,
        'status': 'TRIAGED',
      });
      notifyListeners();
    }
  }

  // 2. Capability Check
  CapabilityCheckDto checkFacilityCapability({
    String facilityId = 'FAC-SDH-301',
    required String requiredSpecialty,
    required List<String> requiredResources,
    Map<String, int>? bloodRequirements,
  }) {
    final facility = FacilityRepository().getFacilityById(facilityId);
    if (facility == null) {
      return const CapabilityCheckDto();
    }

    final reqLower = requiredSpecialty.toLowerCase();
    final hasSpecialist = facility.onDutySpecialists.any((s) {
      final sLower = s.toLowerCase();
      if ((reqLower.contains('ob') || reqLower.contains('gyn')) &&
          (sLower.contains('obstetric') || sLower.contains('gynecolog') || sLower.contains('स्त्रीरोग'))) {
        return true;
      }
      return sLower.contains(reqLower.split(' ').first) || reqLower.contains(sLower.split(' ').first);
    });

    final hasBed = facility.availableBeds > 0;
    final hasEquipment = requiredResources.isEmpty || facility.hasEmergencyCapability;
    final hasDiagnostics = requiredResources.any((r) =>
            facility.availableDiagnostics.any((d) => d.toLowerCase().contains(r.toLowerCase().split(' ').first))) ||
        facility.availableDiagnostics.isNotEmpty;

    bool bloodAvailable = true;
    if (bloodRequirements != null && bloodRequirements.isNotEmpty) {
      for (final entry in bloodRequirements.entries) {
        final stock = facility.bloodBankStock[entry.key] ?? 0;
        if (stock < entry.value) {
          bloodAvailable = false;
          break;
        }
      }
    }

    return CapabilityCheckDto(
      bedAvailable: hasBed,
      specialistAvailable: hasSpecialist,
      equipmentAvailable: hasEquipment,
      diagnosticsAvailable: hasDiagnostics,
      bloodAvailable: bloodAvailable,
      checkedAt: DateTime.now(),
      checkedBy: 'Facility Coordinator',
      notes: 'Capability verified against live facility roster & inventory.',
    );
  }

  void performCapabilityCheck(String referralId, {required CapabilityCheckDto check}) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      _referrals[idx] = current.copyWith(
        capabilityCheck: check,
        updatedAt: DateTime.now(),
      );
      _syncUpdate(referralId, {'capabilityCheck': check.toJson()});
      notifyListeners();
    }
  }

  // 3. Accept Referral & Reserve Specific Resources
  void acceptReferral(
    String referralId, {
    required BedReservationDto reservation,
    Map<String, int>? bloodUnitsToReserve,
  }) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];

      // Reserve blood in FacilityRepository if requested
      if (bloodUnitsToReserve != null && bloodUnitsToReserve.isNotEmpty) {
        FacilityRepository().reserveBloodUnits(bloodUnitsToReserve, referralId: referralId);
      }

      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final updatedNotes = List<String>.from(current.coordinationNotes)
        ..add('Accepted at $timeStr by Receiving Facility Coordinator.')
        ..add('Resource Reserved: ${reservation.bedType} in ${reservation.wardUnit} (Specialist: ${reservation.assignedSpecialist}).');

      final updated = current.copyWith(
        status: 'ACCEPTED',
        bedReservation: reservation,
        bloodUnitsReserved: bloodUnitsToReserve ?? current.bloodUnitsReserved,
        coordinationNotes: updatedNotes,
        updatedAt: now,
      );

      _referrals[idx] = updated;

      // Dispatch automated notification to referring facility/worker
      final etaStr = '${now.add(Duration(minutes: current.expectedTransitMinutes)).hour.toString().padLeft(2, '0')}:${now.add(Duration(minutes: current.expectedTransitMinutes)).minute.toString().padLeft(2, '0')}';
      NotificationRepository().dispatchNotification(
        NotificationItemDto(
          id: 'NOTIF-REF-ACC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          title: 'Referral Accepted: ${current.patientName} (${current.id})',
          bilingualTitle: 'Referral Accepted / संदर्भ स्वीकारला',
          message: 'Accepted by Baramati SDH. Bed reserved in ${reservation.wardUnit}. Specialist: ${reservation.assignedSpecialist}. Expected arrival: $etaStr.',
          targetRole: AppRole.healthWorker,
          category: NotificationCategory.referrals,
          isUrgent: current.isEmergency,
          timestamp: now,
          actionRoute: '/referrals',
          actionPayload: {'referralId': current.id},
        ),
      );

      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  // 4. Reject Referral
  void rejectReferral(String referralId, {required String reason}) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final now = DateTime.now();
      final updatedNotes = List<String>.from(current.coordinationNotes)
        ..add('Referral rejected at ${now.hour}:${now.minute}. Reason: $reason');

      final updated = current.copyWith(
        status: 'REJECTED',
        rejectionReason: reason,
        coordinationNotes: updatedNotes,
        updatedAt: now,
      );
      _referrals[idx] = updated;

      // Notify referring facility
      NotificationRepository().dispatchNotification(
        NotificationItemDto(
          id: 'NOTIF-REF-REJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          title: 'Referral Rejected: ${current.patientName} (${current.id})',
          bilingualTitle: 'Referral Rejected / संदर्भ नाकारला',
          message: 'Baramati SDH unable to accept. Reason: $reason. Please re-route patient.',
          targetRole: AppRole.healthWorker,
          category: NotificationCategory.referrals,
          isUrgent: true,
          timestamp: now,
          actionRoute: '/referrals',
          actionPayload: {'referralId': current.id},
        ),
      );

      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  // 5. Re-route Referral to Higher/Alternate Facility
  void rerouteReferral(
    String referralId, {
    required String targetFacilityId,
    required String targetFacilityName,
    required String reason,
  }) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final now = DateTime.now();
      final updatedNotes = List<String>.from(current.coordinationNotes)
        ..add('Re-routed to $targetFacilityName. Reason: $reason');

      final updated = current.copyWith(
        status: 'RE_ROUTED',
        targetFacilityId: targetFacilityId,
        targetFacilityName: targetFacilityName,
        reroutedFacilityId: targetFacilityId,
        reroutedFacilityName: targetFacilityName,
        coordinationNotes: updatedNotes,
        updatedAt: now,
      );
      _referrals[idx] = updated;

      // Notify referring facility & new facility
      NotificationRepository().dispatchNotification(
        NotificationItemDto(
          id: 'NOTIF-REF-REROUTE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          title: 'Referral Re-routed: ${current.patientName}',
          bilingualTitle: 'Referral Re-routed / संदर्भ पुनर्निर्देशित',
          message: 'Re-routed by Baramati SDH to $targetFacilityName. Rationale: $reason.',
          targetRole: AppRole.healthWorker,
          category: NotificationCategory.referrals,
          isUrgent: true,
          timestamp: now,
          actionRoute: '/referrals',
          actionPayload: {'referralId': current.id},
        ),
      );

      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  // 6. Transport Status Tracking
  void updateTransportStatus(String referralId, {required TransportDetailsDto transport}) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      String newStatus = current.status;
      if (transport.transportStatus == 'AMBULANCE_ASSIGNED') {
        newStatus = 'AMBULANCE_ASSIGNED';
      } else if (transport.transportStatus == 'IN_TRANSIT' || transport.transportStatus == 'PATIENT_DEPARTED') {
        newStatus = 'IN_TRANSIT';
      } else if (transport.transportStatus == 'ARRIVED') {
        newStatus = 'ARRIVED';
      }

      final updated = current.copyWith(
        status: newStatus,
        transportDetails: transport,
        isOverdue: transport.isOverdue,
        updatedAt: DateTime.now(),
      );
      _referrals[idx] = updated;
      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  void flagOverdueTransit(String referralId, {required int delayMinutes}) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final now = DateTime.now();
      final updatedNotes = List<String>.from(current.coordinationNotes)
        ..add('DELAY ALERT: Patient overdue by $delayMinutes mins. Transport coordinator escalated at ${now.hour}:${now.minute}.');

      final updated = current.copyWith(
        isOverdue: true,
        coordinationNotes: updatedNotes,
        updatedAt: now,
      );
      _referrals[idx] = updated;

      NotificationRepository().dispatchNotification(
        NotificationItemDto(
          id: 'NOTIF-DELAY-${now.millisecondsSinceEpoch.toString().substring(7)}',
          title: 'Transit Delay Alert: ${current.patientName}',
          bilingualTitle: 'Transit Delay Alert / वाहतूक विलंब सूचना',
          message: 'Transit exceeded expected ETA by $delayMinutes mins. Vehicle: ${current.transportDetails?.vehicleId ?? "108 Ambulance"}.',
          targetRole: AppRole.facilityStaff,
          category: NotificationCategory.alerts,
          isUrgent: true,
          timestamp: now,
          actionRoute: '/referrals',
          actionPayload: {'referralId': current.id},
        ),
      );

      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  // 7. Arrival Acknowledgment & Fast-Track Token Check-In
  ReferralDto? checkInReferralByToken(String tokenOrReferralId) {
    final query = tokenOrReferralId.trim().toUpperCase();
    final idx = _referrals.indexWhere(
      (r) =>
          r.id.toUpperCase() == query ||
          (r.checkInToken != null && r.checkInToken!.toUpperCase() == query) ||
          r.patientName.toUpperCase().contains(query),
    );

    if (idx != -1) {
      final current = _referrals[idx];
      final now = DateTime.now();
      final generatedToken = current.checkInToken ?? 'TK-${now.millisecondsSinceEpoch % 900 + 100}';

      final updated = current.copyWith(
        status: 'CHECKED_IN',
        checkInToken: generatedToken,
        checkedInAt: now,
        updatedAt: now,
        coordinationNotes: List<String>.from(current.coordinationNotes)
          ..add('Arrival checked in via Token $generatedToken at ${now.hour}:${now.minute}. Linked to ${current.id}.'),
      );
      _referrals[idx] = updated;
      _syncUpdate(current.id, updated.toJson());
      notifyListeners();
      return updated;
    }
    return null;
  }

  // 8. Clinical Handoff
  void completeClinicalHandoff(
    String referralId, {
    required String receivingDoctor,
    required String handoffNotes,
  }) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final now = DateTime.now();
      final handoff = ClinicalHandoffDto(
        handoffCompleted: true,
        handoffAt: now,
        receivingDoctor: receivingDoctor,
        handoffNotes: handoffNotes,
      );

      final updated = current.copyWith(
        status: 'UNDER_EVALUATION',
        clinicalHandoff: handoff,
        updatedAt: now,
        coordinationNotes: List<String>.from(current.coordinationNotes)
          ..add('Clinical handoff completed to $receivingDoctor at ${now.hour}:${now.minute}.'),
      );
      _referrals[idx] = updated;
      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  // 9. Post-Arrival Disposition
  void recordDisposition(
    String referralId, {
    required String disposition,
    String? notes,
  }) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      String newStatus = current.status;
      if (disposition == 'ADMITTED') {
        newStatus = 'ADMITTED';
      } else if (disposition == 'TREATED_DISCHARGED') {
        newStatus = 'TREATMENT_COMPLETED';
      }

      final updated = current.copyWith(
        disposition: disposition,
        dispositionNotes: notes,
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _referrals[idx] = updated;
      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  // 10. Counter-Referral Workflow
  void dispatchCounterReferral({
    required String referralId,
    CounterReferralDto? counterReferral,
    String? instructions,
  }) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final now = DateTime.now();

      final effectiveCR = counterReferral ??
          CounterReferralDto(
            diagnosis: current.reason,
            treatmentProvided: current.dispositionNotes ??
                'Evaluated, stabilized, and specialist management completed.',
            prescribedMedicines: const [
              'Labetalol 100mg BD',
              'Iron Sucrose Infusion complete',
              'Tab Calcium 500mg OD',
            ],
            followUpInstructions: instructions ??
                current.counterReferralInstructions ??
                'Follow-up at Sub-Centre within 7 days. Monitor BP twice daily.',
            warningSigns: const [
              'Severe headache',
              'Epigastric pain',
              'Blurry vision',
              'Decreased fetal movements',
            ],
            followUpDate: DateTime.now().add(const Duration(days: 7)),
            reasonForReturn:
                'Acute condition stabilized; ongoing rural antenatal care & monitoring required.',
            receivingFacility: current.referringFacility,
            dispatchedAt: now,
            dispatchedBy: 'Dr. Rahul Shinde, MD (OB/GYN)',
          );

      // Release any reserved blood units if unused
      if (current.bloodUnitsReserved.isNotEmpty) {
        FacilityRepository().releaseBloodUnits(current.bloodUnitsReserved, referralId: referralId);
      }

      final updated = current.copyWith(
        status: 'COUNTER_REFERRED',
        counterReferral: effectiveCR,
        counterReferralInstructions: effectiveCR.followUpInstructions,
        updatedAt: now,
        coordinationNotes: List<String>.from(current.coordinationNotes)
          ..add('Counter-referral guidance dispatched to ${effectiveCR.receivingFacility}. Diagnosis: ${effectiveCR.diagnosis}.'),
      );
      _referrals[idx] = updated;

      // Dispatch actionable notification to referring ASHA / Health Worker
      NotificationRepository().dispatchNotification(
        NotificationItemDto(
          id: 'NOTIF-CR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          title: 'Counter-Referral Care Plan: ${current.patientName}',
          bilingualTitle: 'Counter-Referral Care Plan / प्रति-संदर्भ योजना',
          message: 'Discharged from Baramati SDH. Diagnosis: ${effectiveCR.diagnosis}. Follow-up instructions: ${effectiveCR.followUpInstructions}. Warning signs: ${effectiveCR.warningSigns.join(", ")}.',
          targetRole: AppRole.healthWorker,
          category: NotificationCategory.referrals,
          isUrgent: false,
          timestamp: now,
          actionRoute: '/referrals',
          actionPayload: {'referralId': current.id},
        ),
      );

      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  // 11. Referral Closure
  void closeReferral(String referralId) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final updated = current.copyWith(
        status: 'CLOSED',
        updatedAt: DateTime.now(),
        coordinationNotes: List<String>.from(current.coordinationNotes)
          ..add('Referral case completed and closed at ${DateTime.now().hour}:${DateTime.now().minute}.'),
      );
      _referrals[idx] = updated;
      _syncUpdate(referralId, updated.toJson());
      notifyListeners();
    }
  }

  // Legacy helper compatibility methods
  void advanceStatus(String referralId) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      String nextStatus;
      switch (current.status) {
        case 'CREATED':
        case 'REFERRED':
          nextStatus = 'HOSPITAL_NOTIFIED';
          break;
        case 'HOSPITAL_NOTIFIED':
        case 'TRIAGED':
          nextStatus = 'ACCEPTED';
          break;
        case 'ACCEPTED':
          nextStatus = 'IN_TRANSIT';
          break;
        case 'IN_TRANSIT':
        case 'PATIENT_EN_ROUTE':
          nextStatus = 'ARRIVED';
          break;
        case 'ARRIVED':
          nextStatus = 'CHECKED_IN';
          break;
        case 'CHECKED_IN':
          nextStatus = 'UNDER_EVALUATION';
          break;
        case 'UNDER_EVALUATION':
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
      _referrals[idx] = current.copyWith(status: nextStatus, updatedAt: DateTime.now());
      _syncUpdate(referralId, {'status': nextStatus});
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

  void createReferral({
    required String patientId,
    required String patientName,
    required String referringFacility,
    required String targetFacilityId,
    required String targetFacilityName,
    required String reason,
    required String urgency,
    required String requiredSpecialty,
    String recommendationRationale = 'Recommended higher tier referral facility for specialty care',
  }) {
    final newRef = ReferralDto(
      id: 'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      patientId: patientId,
      patientName: patientName,
      referringFacility: referringFacility,
      targetFacilityId: targetFacilityId,
      targetFacilityName: targetFacilityName,
      reason: reason,
      urgency: urgency,
      requiredSpecialty: requiredSpecialty,
      status: 'HOSPITAL_NOTIFIED',
      createdAt: DateTime.now(),
      recommendationRationale: recommendationRationale,
    );
    addReferral(newRef);
  }

  void addCounterReferral(String referralId, String instructions) {
    dispatchCounterReferral(
      referralId: referralId,
      counterReferral: CounterReferralDto(
        diagnosis: 'Clinical condition managed and stabilized.',
        treatmentProvided: 'Specialist consultation and medical management.',
        prescribedMedicines: const ['Prescribed discharge medications'],
        followUpInstructions: instructions,
        warningSigns: const ['Fever > 101F', 'Persistent pain', 'Breathing difficulty'],
        reasonForReturn: 'Primary condition managed; ongoing monitoring at frontline Sub-Centre.',
        receivingFacility: 'Kashti Sub-Centre',
        dispatchedAt: DateTime.now(),
        dispatchedBy: 'Sister In-Charge / Medical Officer',
      ),
    );
  }

  void updateStatus(String referralId, String newStatus) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      _referrals[idx] = _referrals[idx].copyWith(status: newStatus, updatedAt: DateTime.now());
      _syncUpdate(referralId, {'status': newStatus});
      notifyListeners();
    }
  }

  void acknowledgeArrival(String referralId) {
    updateStatus(referralId, 'ARRIVED');
    addCoordinationNote(
      referralId,
      'Patient arrival acknowledged at facility gate / triage at ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );
  }

  void addCoordinationNote(String referralId, String note) {
    final idx = _referrals.indexWhere((r) => r.id == referralId);
    if (idx != -1) {
      final current = _referrals[idx];
      final updatedNotes = List<String>.from(current.coordinationNotes)..add(note);
      _referrals[idx] = current.copyWith(coordinationNotes: updatedNotes);
      _syncUpdate(referralId, {'coordinationNotes': updatedNotes});
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
        _syncUpdate(referralId, {'checklistDone': updatedChecklist});
        notifyListeners();
      }
    }
  }

  ReferralDto? getReferralById(String id) {
    try {
      return _referrals.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void resetToDefaults() {
    _referrals = [];
    notifyListeners();
  }

  void _syncUpdate(String referralId, Map<String, dynamic> data) {
    if (_cache.isOffline) {
      _cache.queueMutation('REFERRAL', 'STATUS_UPDATE', {'id': referralId, ...data});
    } else {
      try {
        FirebaseFirestore.instance
            .collection('referrals')
            .doc(referralId)
            .set(data, SetOptions(merge: true));
      } catch (_) {}
    }
  }
}
