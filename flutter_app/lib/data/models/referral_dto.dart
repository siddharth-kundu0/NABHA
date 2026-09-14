import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/app/routes.dart';

class CapabilityCheckDto {
  final bool bedAvailable;
  final bool specialistAvailable;
  final bool equipmentAvailable;
  final bool diagnosticsAvailable;
  final bool bloodAvailable;
  final DateTime? checkedAt;
  final String? checkedBy;
  final String? notes;

  const CapabilityCheckDto({
    this.bedAvailable = false,
    this.specialistAvailable = false,
    this.equipmentAvailable = false,
    this.diagnosticsAvailable = false,
    this.bloodAvailable = false,
    this.checkedAt,
    this.checkedBy,
    this.notes,
  });

  bool get isFullyCapable =>
      bedAvailable && specialistAvailable && equipmentAvailable && diagnosticsAvailable;

  CapabilityCheckDto copyWith({
    bool? bedAvailable,
    bool? specialistAvailable,
    bool? equipmentAvailable,
    bool? diagnosticsAvailable,
    bool? bloodAvailable,
    DateTime? checkedAt,
    String? checkedBy,
    String? notes,
  }) {
    return CapabilityCheckDto(
      bedAvailable: bedAvailable ?? this.bedAvailable,
      specialistAvailable: specialistAvailable ?? this.specialistAvailable,
      equipmentAvailable: equipmentAvailable ?? this.equipmentAvailable,
      diagnosticsAvailable: diagnosticsAvailable ?? this.diagnosticsAvailable,
      bloodAvailable: bloodAvailable ?? this.bloodAvailable,
      checkedAt: checkedAt ?? this.checkedAt,
      checkedBy: checkedBy ?? this.checkedBy,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'bedAvailable': bedAvailable,
        'specialistAvailable': specialistAvailable,
        'equipmentAvailable': equipmentAvailable,
        'diagnosticsAvailable': diagnosticsAvailable,
        'bloodAvailable': bloodAvailable,
        'checkedAt': checkedAt?.toIso8601String(),
        'checkedBy': checkedBy,
        'notes': notes,
      };

  factory CapabilityCheckDto.fromJson(Map<String, dynamic> json) => CapabilityCheckDto(
        bedAvailable: json['bedAvailable'] as bool? ?? false,
        specialistAvailable: json['specialistAvailable'] as bool? ?? false,
        equipmentAvailable: json['equipmentAvailable'] as bool? ?? false,
        diagnosticsAvailable: json['diagnosticsAvailable'] as bool? ?? false,
        bloodAvailable: json['bloodAvailable'] as bool? ?? false,
        checkedAt: DateTime.tryParse(json['checkedAt'] as String? ?? ''),
        checkedBy: json['checkedBy'] as String?,
        notes: json['notes'] as String?,
      );
}

class BedReservationDto {
  final String bedType;
  final String wardUnit;
  final String assignedSpecialist;
  final List<String> reservedEquipment;
  final String reservationStatus; // RESERVED, PREPARED, ALLOCATED, RELEASED
  final DateTime? reservedAt;
  final String? bedNumber;

  const BedReservationDto({
    required this.bedType,
    required this.wardUnit,
    required this.assignedSpecialist,
    this.reservedEquipment = const [],
    this.reservationStatus = 'RESERVED',
    this.reservedAt,
    this.bedNumber,
  });

  BedReservationDto copyWith({
    String? bedType,
    String? wardUnit,
    String? assignedSpecialist,
    List<String>? reservedEquipment,
    String? reservationStatus,
    DateTime? reservedAt,
    String? bedNumber,
  }) {
    return BedReservationDto(
      bedType: bedType ?? this.bedType,
      wardUnit: wardUnit ?? this.wardUnit,
      assignedSpecialist: assignedSpecialist ?? this.assignedSpecialist,
      reservedEquipment: reservedEquipment ?? this.reservedEquipment,
      reservationStatus: reservationStatus ?? this.reservationStatus,
      reservedAt: reservedAt ?? this.reservedAt,
      bedNumber: bedNumber ?? this.bedNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'bedType': bedType,
        'wardUnit': wardUnit,
        'assignedSpecialist': assignedSpecialist,
        'reservedEquipment': reservedEquipment,
        'reservationStatus': reservationStatus,
        'reservedAt': reservedAt?.toIso8601String(),
        'bedNumber': bedNumber,
      };

  factory BedReservationDto.fromJson(Map<String, dynamic> json) => BedReservationDto(
        bedType: json['bedType'] as String? ?? 'General Bed',
        wardUnit: json['wardUnit'] as String? ?? 'General Ward',
        assignedSpecialist: json['assignedSpecialist'] as String? ?? 'Medical Officer',
        reservedEquipment: (json['reservedEquipment'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        reservationStatus: json['reservationStatus'] as String? ?? 'RESERVED',
        reservedAt: DateTime.tryParse(json['reservedAt'] as String? ?? ''),
        bedNumber: json['bedNumber'] as String?,
      );
}

class TransportDetailsDto {
  final String requirement; // AMBULANCE_108, OWN_TRANSPORT, CRITICAL_CARE_ESCORT
  final String transportStatus; // NOT_REQUESTED, REQUESTED, AMBULANCE_ASSIGNED, PATIENT_DEPARTED, IN_TRANSIT, ARRIVED
  final String? vehicleId;
  final String? driverName;
  final String? driverPhone;
  final DateTime? departureTime;
  final int estimatedTransitMinutes;
  final DateTime? expectedArrivalTime;
  final DateTime? actualArrivalTime;
  final bool isOverdue;

  const TransportDetailsDto({
    this.requirement = 'AMBULANCE_108',
    this.transportStatus = 'IN_TRANSIT',
    this.vehicleId,
    this.driverName,
    this.driverPhone,
    this.departureTime,
    this.estimatedTransitMinutes = 30,
    this.expectedArrivalTime,
    this.actualArrivalTime,
    this.isOverdue = false,
  });

  TransportDetailsDto copyWith({
    String? requirement,
    String? transportStatus,
    String? vehicleId,
    String? driverName,
    String? driverPhone,
    DateTime? departureTime,
    int? estimatedTransitMinutes,
    DateTime? expectedArrivalTime,
    DateTime? actualArrivalTime,
    bool? isOverdue,
  }) {
    return TransportDetailsDto(
      requirement: requirement ?? this.requirement,
      transportStatus: transportStatus ?? this.transportStatus,
      vehicleId: vehicleId ?? this.vehicleId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      departureTime: departureTime ?? this.departureTime,
      estimatedTransitMinutes: estimatedTransitMinutes ?? this.estimatedTransitMinutes,
      expectedArrivalTime: expectedArrivalTime ?? this.expectedArrivalTime,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }

  Map<String, dynamic> toJson() => {
        'requirement': requirement,
        'transportStatus': transportStatus,
        'vehicleId': vehicleId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'departureTime': departureTime?.toIso8601String(),
        'estimatedTransitMinutes': estimatedTransitMinutes,
        'expectedArrivalTime': expectedArrivalTime?.toIso8601String(),
        'actualArrivalTime': actualArrivalTime?.toIso8601String(),
        'isOverdue': isOverdue,
      };

  factory TransportDetailsDto.fromJson(Map<String, dynamic> json) => TransportDetailsDto(
        requirement: json['requirement'] as String? ?? 'AMBULANCE_108',
        transportStatus: json['transportStatus'] as String? ?? 'IN_TRANSIT',
        vehicleId: json['vehicleId'] as String?,
        driverName: json['driverName'] as String?,
        driverPhone: json['driverPhone'] as String?,
        departureTime: DateTime.tryParse(json['departureTime'] as String? ?? ''),
        estimatedTransitMinutes: json['estimatedTransitMinutes'] as int? ?? 30,
        expectedArrivalTime: DateTime.tryParse(json['expectedArrivalTime'] as String? ?? ''),
        actualArrivalTime: DateTime.tryParse(json['actualArrivalTime'] as String? ?? ''),
        isOverdue: json['isOverdue'] as bool? ?? false,
      );
}

class ClinicalHandoffDto {
  final bool handoffCompleted;
  final DateTime? handoffAt;
  final String? receivingDoctor;
  final String? handoffNotes;
  final String? attendingNurse;

  const ClinicalHandoffDto({
    this.handoffCompleted = false,
    this.handoffAt,
    this.receivingDoctor,
    this.handoffNotes,
    this.attendingNurse,
  });

  ClinicalHandoffDto copyWith({
    bool? handoffCompleted,
    DateTime? handoffAt,
    String? receivingDoctor,
    String? handoffNotes,
    String? attendingNurse,
  }) {
    return ClinicalHandoffDto(
      handoffCompleted: handoffCompleted ?? this.handoffCompleted,
      handoffAt: handoffAt ?? this.handoffAt,
      receivingDoctor: receivingDoctor ?? this.receivingDoctor,
      handoffNotes: handoffNotes ?? this.handoffNotes,
      attendingNurse: attendingNurse ?? this.attendingNurse,
    );
  }

  Map<String, dynamic> toJson() => {
        'handoffCompleted': handoffCompleted,
        'handoffAt': handoffAt?.toIso8601String(),
        'receivingDoctor': receivingDoctor,
        'handoffNotes': handoffNotes,
        'attendingNurse': attendingNurse,
      };

  factory ClinicalHandoffDto.fromJson(Map<String, dynamic> json) => ClinicalHandoffDto(
        handoffCompleted: json['handoffCompleted'] as bool? ?? false,
        handoffAt: DateTime.tryParse(json['handoffAt'] as String? ?? ''),
        receivingDoctor: json['receivingDoctor'] as String?,
        handoffNotes: json['handoffNotes'] as String?,
        attendingNurse: json['attendingNurse'] as String?,
      );
}

class CounterReferralDto {
  final String diagnosis;
  final String treatmentProvided;
  final List<String> prescribedMedicines;
  final String followUpInstructions;
  final List<String> warningSigns;
  final DateTime? followUpDate;
  final String reasonForReturn;
  final String receivingFacility;
  final DateTime? dispatchedAt;
  final String? dispatchedBy;

  const CounterReferralDto({
    required this.diagnosis,
    required this.treatmentProvided,
    required this.prescribedMedicines,
    required this.followUpInstructions,
    required this.warningSigns,
    this.followUpDate,
    required this.reasonForReturn,
    required this.receivingFacility,
    this.dispatchedAt,
    this.dispatchedBy,
  });

  Map<String, dynamic> toJson() => {
        'diagnosis': diagnosis,
        'treatmentProvided': treatmentProvided,
        'prescribedMedicines': prescribedMedicines,
        'followUpInstructions': followUpInstructions,
        'warningSigns': warningSigns,
        'followUpDate': followUpDate?.toIso8601String(),
        'reasonForReturn': reasonForReturn,
        'receivingFacility': receivingFacility,
        'dispatchedAt': dispatchedAt?.toIso8601String(),
        'dispatchedBy': dispatchedBy,
      };

  factory CounterReferralDto.fromJson(Map<String, dynamic> json) => CounterReferralDto(
        diagnosis: json['diagnosis'] as String? ?? '',
        treatmentProvided: json['treatmentProvided'] as String? ?? '',
        prescribedMedicines: (json['prescribedMedicines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        followUpInstructions: json['followUpInstructions'] as String? ?? '',
        warningSigns: (json['warningSigns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        followUpDate: DateTime.tryParse(json['followUpDate'] as String? ?? ''),
        reasonForReturn: json['reasonForReturn'] as String? ?? '',
        receivingFacility: json['receivingFacility'] as String? ?? '',
        dispatchedAt: DateTime.tryParse(json['dispatchedAt'] as String? ?? ''),
        dispatchedBy: json['dispatchedBy'] as String?,
      );
}

class ReferralDto {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientPhone;
  final String patientVillage;
  final String patientDistrict;

  final String referringFacility;
  final String referringFacilityId;
  final String referringProviderName;
  final String referringProviderRole;

  final String targetFacilityId;
  final String targetFacilityName;
  final String reason;
  final String urgency; // EMERGENCY, URGENT, ROUTINE
  final String requiredSpecialty;
  final List<String> requiredResources;
  final String status; // REFERRED, TRIAGED, ACCEPTED, REJECTED, RE_ROUTED, RESOURCE_RESERVED, TRANSPORT_ASSIGNED, PATIENT_EN_ROUTE, PATIENT_ARRIVED, CHECKED_IN, UNDER_EVALUATION, ADMITTED, TREATMENT_COMPLETED, COUNTER_REFERRED, CLOSED
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int expectedTransitMinutes;
  final bool isOverdue;

  // Pre-transfer clinical parameters
  final VitalsDto? vitals;
  final List<String> chronicConditions;
  final List<String> allergies;
  final List<String> priorMedications;
  final List<String> diagnosticsPerformed;

  // Capability check & reservations
  final CapabilityCheckDto? capabilityCheck;
  final BedReservationDto? bedReservation;
  final Map<String, int> bloodUnitsRequired;
  final Map<String, int> bloodUnitsReserved;

  // Transport & tracking
  final TransportDetailsDto? transportDetails;

  // Check-in & Handoff
  final String? checkInToken;
  final DateTime? checkedInAt;
  final ClinicalHandoffDto? clinicalHandoff;

  // Disposition
  final String disposition; // PENDING, ADMITTED, TREATED_DISCHARGED, OBSERVATION, REFERRED_HIGHER, COUNTER_REFERRED
  final String? dispositionNotes;

  // Counter referral
  final CounterReferralDto? counterReferral;
  final String? counterReferralInstructions;

  // Rejection & Re-route
  final String? rejectionReason;
  final String? reroutedFacilityId;
  final String? reroutedFacilityName;

  final String recommendationRationale;
  final List<String> coordinationNotes;
  final List<bool> checklistDone;

  const ReferralDto({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientAge = 35,
    this.patientGender = 'FEMALE',
    this.patientPhone = '+919823411204',
    this.patientVillage = 'Kashti',
    this.patientDistrict = 'Pune Rural',
    required this.referringFacility,
    this.referringFacilityId = 'FAC-SC-102',
    this.referringProviderName = 'Sunita Tai Gaikwad',
    this.referringProviderRole = 'ASHA Worker',
    required this.targetFacilityId,
    required this.targetFacilityName,
    required this.reason,
    required this.urgency,
    required this.requiredSpecialty,
    this.requiredResources = const [],
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.expectedTransitMinutes = 45,
    this.isOverdue = false,
    this.vitals,
    this.chronicConditions = const [],
    this.allergies = const [],
    this.priorMedications = const [],
    this.diagnosticsPerformed = const [],
    this.capabilityCheck,
    this.bedReservation,
    this.bloodUnitsRequired = const {},
    this.bloodUnitsReserved = const {},
    this.transportDetails,
    this.checkInToken,
    this.checkedInAt,
    this.clinicalHandoff,
    this.disposition = 'PENDING',
    this.dispositionNotes,
    this.counterReferral,
    this.counterReferralInstructions,
    this.rejectionReason,
    this.reroutedFacilityId,
    this.reroutedFacilityName,
    required this.recommendationRationale,
    this.coordinationNotes = const [
      'Sunita Dmri (ASHA Rampur): Patient informed about hospital arrival and fasting schedule.',
    ],
    this.checklistDone = const [true, true, false],
  });

  bool get isEmergency => urgency.toUpperCase() == 'EMERGENCY';
  bool get isUrgent => urgency.toUpperCase() == 'URGENT' || isEmergency;
  String get doctorName => referringProviderName;

  String get statusLabel {
    final session = SessionCoordinator();
    final isHi = session.isHindi;
    final isMr = session.isMarathi;
    switch (status) {
      case 'CREATED':
      case 'REFERRED':
        return isHi ? 'रेफरल बनाया गया' : (isMr ? 'संदर्भ नोंदणी झाली' : 'Referral Created');
      case 'TRIAGED':
        return isHi ? 'ट्राइएज पूर्ण' : (isMr ? 'ट्रायज पूर्ण' : 'Triage Complete');
      case 'ACCEPTED':
        return isHi ? 'रेफरल स्वीकृत' : (isMr ? 'संदर्भ स्वीकारला' : 'Referral Accepted');
      case 'REJECTED':
        return isHi ? 'रेफरल अस्वीकृत' : (isMr ? 'संदर्भ नाकारला' : 'Referral Rejected');
      case 'RE_ROUTED':
        return isHi ? 'वैकल्पिक अस्पताल भेजा गया' : (isMr ? 'दुसऱ्या रुग्णालयात पाठवले' : 'Re-routed to Alternate Facility');
      case 'RESOURCE_RESERVED':
        return isHi ? 'संसाधन आरक्षित' : (isMr ? 'खाट आणि साधनसामग्री आरक्षित' : 'Resources Reserved');
      case 'HOSPITAL_NOTIFIED':
        return isHi ? 'अस्पताल को पूर्व-सूचना' : (isMr ? 'रुग्णालयाला पूर्वसूचना दिली' : 'Hospital Pre-alerted');
      case 'AMBULANCE_ASSIGNED':
        return isHi ? 'एम्बुलेंस आवंटित' : (isMr ? 'रुग्णवाहिका पाठवली' : 'Ambulance Assigned');
      case 'PATIENT_EN_ROUTE':
      case 'IN_TRANSIT':
        return isHi ? 'मरीज़ रास्ते में है' : (isMr ? 'रुग्ण प्रवासात आहे' : 'Patient In Transit');
      case 'PATIENT_ARRIVED':
      case 'ARRIVED':
        return isHi ? 'अस्पताल पहुंचे' : (isMr ? 'रुग्णालयात पोहोचले' : 'Arrived at Facility');
      case 'CHECKED_IN':
        return isHi ? 'टोकन चेक-इन हुआ' : (isMr ? 'टोकन चेक-इन झाले' : 'Checked-In via Token');
      case 'UNDER_EVALUATION':
        return isHi ? 'नैदानिक मूल्यांकन जारी' : (isMr ? 'वैद्यकीय तपासणी सुरू' : 'Under Clinical Evaluation');
      case 'ADMITTED':
        return isHi ? 'भर्ती' : (isMr ? 'दाखल केले' : 'Admitted');
      case 'TREATMENT_COMPLETED':
        return isHi ? 'उपचार पूर्ण' : (isMr ? 'उपचार पूर्ण' : 'Treatment Completed');
      case 'COUNTER_REFERRED':
        return isHi ? 'पीएचसी में प्रति-रेफरल' : (isMr ? 'परत संदर्भ' : 'Counter-Referred to PHC');
      case 'CLOSED':
        return isHi ? 'केस पूर्ण' : (isMr ? 'प्रकरण पूर्ण' : 'Case Completed');
      default:
        return status;
    }
  }

  String get statusDisplay => statusLabel;
  String get referringFacilityName => referringFacility;
  String get reasonSummary => reason;

  int get currentStage {
    switch (status) {
      case 'CREATED':
      case 'REFERRED':
        return 1;
      case 'HOSPITAL_NOTIFIED':
      case 'TRIAGED':
      case 'RE_ROUTED':
        return 2;
      case 'ACCEPTED':
      case 'RESOURCE_RESERVED':
      case 'AMBULANCE_ASSIGNED':
      case 'PATIENT_EN_ROUTE':
      case 'IN_TRANSIT':
        return 3;
      case 'PATIENT_ARRIVED':
      case 'ARRIVED':
      case 'CHECKED_IN':
      case 'UNDER_EVALUATION':
        return 4;
      case 'ADMITTED':
      case 'TREATMENT_COMPLETED':
        return 5;
      case 'COUNTER_REFERRED':
      case 'CLOSED':
      case 'REJECTED':
        return 6;
      default:
        return 1;
    }
  }

  ReferralDto copyWith({
    String? id,
    String? patientId,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? patientPhone,
    String? patientVillage,
    String? patientDistrict,
    String? referringFacility,
    String? referringFacilityId,
    String? referringProviderName,
    String? referringProviderRole,
    String? targetFacilityId,
    String? targetFacilityName,
    String? reason,
    String? urgency,
    String? requiredSpecialty,
    List<String>? requiredResources,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? expectedTransitMinutes,
    bool? isOverdue,
    VitalsDto? vitals,
    List<String>? chronicConditions,
    List<String>? allergies,
    List<String>? priorMedications,
    List<String>? diagnosticsPerformed,
    CapabilityCheckDto? capabilityCheck,
    BedReservationDto? bedReservation,
    Map<String, int>? bloodUnitsRequired,
    Map<String, int>? bloodUnitsReserved,
    TransportDetailsDto? transportDetails,
    String? checkInToken,
    DateTime? checkedInAt,
    ClinicalHandoffDto? clinicalHandoff,
    String? disposition,
    String? dispositionNotes,
    CounterReferralDto? counterReferral,
    String? counterReferralInstructions,
    String? rejectionReason,
    String? reroutedFacilityId,
    String? reroutedFacilityName,
    String? recommendationRationale,
    List<String>? coordinationNotes,
    List<bool>? checklistDone,
  }) {
    return ReferralDto(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientPhone: patientPhone ?? this.patientPhone,
      patientVillage: patientVillage ?? this.patientVillage,
      patientDistrict: patientDistrict ?? this.patientDistrict,
      referringFacility: referringFacility ?? this.referringFacility,
      referringFacilityId: referringFacilityId ?? this.referringFacilityId,
      referringProviderName: referringProviderName ?? this.referringProviderName,
      referringProviderRole: referringProviderRole ?? this.referringProviderRole,
      targetFacilityId: targetFacilityId ?? this.targetFacilityId,
      targetFacilityName: targetFacilityName ?? this.targetFacilityName,
      reason: reason ?? this.reason,
      urgency: urgency ?? this.urgency,
      requiredSpecialty: requiredSpecialty ?? this.requiredSpecialty,
      requiredResources: requiredResources ?? this.requiredResources,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expectedTransitMinutes: expectedTransitMinutes ?? this.expectedTransitMinutes,
      isOverdue: isOverdue ?? this.isOverdue,
      vitals: vitals ?? this.vitals,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      allergies: allergies ?? this.allergies,
      priorMedications: priorMedications ?? this.priorMedications,
      diagnosticsPerformed: diagnosticsPerformed ?? this.diagnosticsPerformed,
      capabilityCheck: capabilityCheck ?? this.capabilityCheck,
      bedReservation: bedReservation ?? this.bedReservation,
      bloodUnitsRequired: bloodUnitsRequired ?? this.bloodUnitsRequired,
      bloodUnitsReserved: bloodUnitsReserved ?? this.bloodUnitsReserved,
      transportDetails: transportDetails ?? this.transportDetails,
      checkInToken: checkInToken ?? this.checkInToken,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      clinicalHandoff: clinicalHandoff ?? this.clinicalHandoff,
      disposition: disposition ?? this.disposition,
      dispositionNotes: dispositionNotes ?? this.dispositionNotes,
      counterReferral: counterReferral ?? this.counterReferral,
      counterReferralInstructions: counterReferralInstructions ?? this.counterReferralInstructions,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reroutedFacilityId: reroutedFacilityId ?? this.reroutedFacilityId,
      reroutedFacilityName: reroutedFacilityName ?? this.reroutedFacilityName,
      recommendationRationale: recommendationRationale ?? this.recommendationRationale,
      coordinationNotes: coordinationNotes ?? this.coordinationNotes,
      checklistDone: checklistDone ?? this.checklistDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'patientPhone': patientPhone,
        'patientVillage': patientVillage,
        'patientDistrict': patientDistrict,
        'referringFacility': referringFacility,
        'referringFacilityId': referringFacilityId,
        'referringProviderName': referringProviderName,
        'referringProviderRole': referringProviderRole,
        'targetFacilityId': targetFacilityId,
        'targetFacilityName': targetFacilityName,
        'reason': reason,
        'urgency': urgency,
        'requiredSpecialty': requiredSpecialty,
        'requiredResources': requiredResources,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'expectedTransitMinutes': expectedTransitMinutes,
        'isOverdue': isOverdue,
        'vitals': vitals?.toJson(),
        'chronicConditions': chronicConditions,
        'allergies': allergies,
        'priorMedications': priorMedications,
        'diagnosticsPerformed': diagnosticsPerformed,
        'capabilityCheck': capabilityCheck?.toJson(),
        'bedReservation': bedReservation?.toJson(),
        'bloodUnitsRequired': bloodUnitsRequired,
        'bloodUnitsReserved': bloodUnitsReserved,
        'transportDetails': transportDetails?.toJson(),
        'checkInToken': checkInToken,
        'checkedInAt': checkedInAt?.toIso8601String(),
        'clinicalHandoff': clinicalHandoff?.toJson(),
        'disposition': disposition,
        'dispositionNotes': dispositionNotes,
        'counterReferral': counterReferral?.toJson(),
        'counterReferralInstructions': counterReferralInstructions,
        'rejectionReason': rejectionReason,
        'reroutedFacilityId': reroutedFacilityId,
        'reroutedFacilityName': reroutedFacilityName,
        'recommendationRationale': recommendationRationale,
        'coordinationNotes': coordinationNotes,
        'checklistDone': checklistDone,
      };

  factory ReferralDto.fromJson(Map<String, dynamic> json) => ReferralDto(
        id: json['id'] as String? ?? '',
        patientId: json['patientId'] as String? ?? '',
        patientName: json['patientName'] as String? ?? '',
        patientAge: json['patientAge'] as int? ?? 35,
        patientGender: json['patientGender'] as String? ?? 'FEMALE',
        patientPhone: json['patientPhone'] as String? ?? '',
        patientVillage: json['patientVillage'] as String? ?? '',
        patientDistrict: json['patientDistrict'] as String? ?? '',
        referringFacility: json['referringFacility'] as String? ?? '',
        referringFacilityId: json['referringFacilityId'] as String? ?? '',
        referringProviderName: json['referringProviderName'] as String? ?? '',
        referringProviderRole: json['referringProviderRole'] as String? ?? '',
        targetFacilityId: json['targetFacilityId'] as String? ?? '',
        targetFacilityName: json['targetFacilityName'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        urgency: json['urgency'] as String? ?? 'ROUTINE',
        requiredSpecialty: json['requiredSpecialty'] as String? ?? '',
        requiredResources: (json['requiredResources'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        status: json['status'] as String? ?? 'CREATED',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
        expectedTransitMinutes: json['expectedTransitMinutes'] as int? ?? 45,
        isOverdue: json['isOverdue'] as bool? ?? false,
        vitals: json['vitals'] != null ? VitalsDto.fromJson(json['vitals'] as Map<String, dynamic>) : null,
        chronicConditions: (json['chronicConditions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        allergies: (json['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        priorMedications: (json['priorMedications'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        diagnosticsPerformed: (json['diagnosticsPerformed'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        capabilityCheck: json['capabilityCheck'] != null ? CapabilityCheckDto.fromJson(json['capabilityCheck'] as Map<String, dynamic>) : null,
        bedReservation: json['bedReservation'] != null ? BedReservationDto.fromJson(json['bedReservation'] as Map<String, dynamic>) : null,
        bloodUnitsRequired: (json['bloodUnitsRequired'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? const {},
        bloodUnitsReserved: (json['bloodUnitsReserved'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? const {},
        transportDetails: json['transportDetails'] != null ? TransportDetailsDto.fromJson(json['transportDetails'] as Map<String, dynamic>) : null,
        checkInToken: json['checkInToken'] as String?,
        checkedInAt: DateTime.tryParse(json['checkedInAt'] as String? ?? ''),
        clinicalHandoff: json['clinicalHandoff'] != null ? ClinicalHandoffDto.fromJson(json['clinicalHandoff'] as Map<String, dynamic>) : null,
        disposition: json['disposition'] as String? ?? 'PENDING',
        dispositionNotes: json['dispositionNotes'] as String?,
        counterReferral: json['counterReferral'] != null ? CounterReferralDto.fromJson(json['counterReferral'] as Map<String, dynamic>) : null,
        counterReferralInstructions: json['counterReferralInstructions'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        reroutedFacilityId: json['reroutedFacilityId'] as String?,
        reroutedFacilityName: json['reroutedFacilityName'] as String?,
        recommendationRationale: json['recommendationRationale'] as String? ?? '',
        coordinationNotes: (json['coordinationNotes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        checklistDone: (json['checklistDone'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? const [true, true, false],
      );
}
