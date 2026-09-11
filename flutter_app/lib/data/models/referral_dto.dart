class ReferralDto {
  final String id;
  final String patientId;
  final String patientName;
  final String referringFacility;
  final String targetFacilityId;
  final String targetFacilityName;
  final String reason;
  final String urgency;
  final String requiredSpecialty;
  final String status;
  final DateTime createdAt;
  final int expectedTransitMinutes;
  final bool isOverdue;
  final String? counterReferralInstructions;
  final String recommendationRationale;

  const ReferralDto({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.referringFacility,
    required this.targetFacilityId,
    required this.targetFacilityName,
    required this.reason,
    required this.urgency,
    required this.requiredSpecialty,
    required this.status,
    required this.createdAt,
    this.expectedTransitMinutes = 45,
    this.isOverdue = false,
    this.counterReferralInstructions,
    required this.recommendationRationale,
  });

  String get statusLabel {
    switch (status) {
      case 'CREATED':
        return 'Referral Created / संदर्भ नोंदणी झाली';
      case 'HOSPITAL_NOTIFIED':
        return 'Hospital Pre-alerted / रुग्णालयाला पूर्वसूचना दिली';
      case 'AMBULANCE_ASSIGNED':
        return 'Ambulance Assigned / रुग्णवाहिका पाठवली';
      case 'PATIENT_EN_ROUTE':
        return 'Patient In Transit / रुग्ण प्रवासात आहे';
      case 'PATIENT_ARRIVED':
        return 'Arrived at Facility / रुग्ण रुग्णालयात पोहोचले';
      case 'ADMITTED':
        return 'Admitted / दाखल केले';
      case 'TREATMENT_COMPLETED':
        return 'Treatment Completed / उपचार पूर्ण';
      case 'COUNTER_REFERRED':
        return 'Counter-Referred to PHC / परत संदर्भ';
      case 'CLOSED':
        return 'Case Completed / प्रकरण पूर्ण';
      default:
        return status;
    }
  }

  String get statusDisplay => statusLabel;

  ReferralDto copyWith({
    String? status,
    bool? isOverdue,
    String? counterReferralInstructions,
  }) {
    return ReferralDto(
      id: id,
      patientId: patientId,
      patientName: patientName,
      referringFacility: referringFacility,
      targetFacilityId: targetFacilityId,
      targetFacilityName: targetFacilityName,
      reason: reason,
      urgency: urgency,
      requiredSpecialty: requiredSpecialty,
      status: status ?? this.status,
      createdAt: createdAt,
      expectedTransitMinutes: expectedTransitMinutes,
      isOverdue: isOverdue ?? this.isOverdue,
      counterReferralInstructions: counterReferralInstructions ?? this.counterReferralInstructions,
      recommendationRationale: recommendationRationale,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'referringFacility': referringFacility,
        'targetFacilityId': targetFacilityId,
        'targetFacilityName': targetFacilityName,
        'reason': reason,
        'urgency': urgency,
        'requiredSpecialty': requiredSpecialty,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'expectedTransitMinutes': expectedTransitMinutes,
        'isOverdue': isOverdue,
        'counterReferralInstructions': counterReferralInstructions,
        'recommendationRationale': recommendationRationale,
      };

  factory ReferralDto.fromJson(Map<String, dynamic> json) => ReferralDto(
        id: json['id'] as String? ?? '',
        patientId: json['patientId'] as String? ?? '',
        patientName: json['patientName'] as String? ?? '',
        referringFacility: json['referringFacility'] as String? ?? '',
        targetFacilityId: json['targetFacilityId'] as String? ?? '',
        targetFacilityName: json['targetFacilityName'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        urgency: json['urgency'] as String? ?? 'ROUTINE',
        requiredSpecialty: json['requiredSpecialty'] as String? ?? '',
        status: json['status'] as String? ?? 'CREATED',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        expectedTransitMinutes: json['expectedTransitMinutes'] as int? ?? 45,
        isOverdue: json['isOverdue'] as bool? ?? false,
        counterReferralInstructions: json['counterReferralInstructions'] as String?,
        recommendationRationale: json['recommendationRationale'] as String? ?? '',
      );
}
