class EmergencyEventDto {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime triggeredAt;
  final String urgencyLevel;
  final bool nextOfKinNotified;
  final bool facilityNotified;
  final bool ambulanceDispatched;
  final String assignedFacilityName;
  final String ambulanceVehicleNo;
  final int etaMinutes;
  final String status;

  const EmergencyEventDto({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.triggeredAt,
    required this.urgencyLevel,
    this.nextOfKinNotified = true,
    this.facilityNotified = true,
    this.ambulanceDispatched = true,
    required this.assignedFacilityName,
    required this.ambulanceVehicleNo,
    required this.etaMinutes,
    required this.status,
  });

  String get ambulanceVehicleNumber => ambulanceVehicleNo;
  String get ambulanceDriverName => 'Santosh More';
  String get ambulanceContact => '108 / 9822019283';
  String get assignedHospital => assignedFacilityName;
  bool get isNextOfKinAlerted => nextOfKinNotified;
  bool get isHospitalAlerted => facilityNotified;
  bool get isAmbulanceDispatched => ambulanceDispatched;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'triggeredAt': triggeredAt.toIso8601String(),
        'urgencyLevel': urgencyLevel,
        'nextOfKinNotified': nextOfKinNotified,
        'facilityNotified': facilityNotified,
        'ambulanceDispatched': ambulanceDispatched,
        'assignedFacilityName': assignedFacilityName,
        'ambulanceVehicleNo': ambulanceVehicleNo,
        'etaMinutes': etaMinutes,
        'status': status,
      };

  factory EmergencyEventDto.fromJson(Map<String, dynamic> json) => EmergencyEventDto(
        id: json['id'] as String? ?? '',
        patientId: json['patientId'] as String? ?? '',
        patientName: json['patientName'] as String? ?? '',
        triggeredAt: DateTime.tryParse(json['triggeredAt'] as String? ?? '') ?? DateTime.now(),
        urgencyLevel: json['urgencyLevel'] as String? ?? 'EMERGENCY',
        nextOfKinNotified: json['nextOfKinNotified'] as bool? ?? true,
        facilityNotified: json['facilityNotified'] as bool? ?? true,
        ambulanceDispatched: json['ambulanceDispatched'] as bool? ?? true,
        assignedFacilityName: json['assignedFacilityName'] as String? ?? '',
        ambulanceVehicleNo: json['ambulanceVehicleNo'] as String? ?? '',
        etaMinutes: json['etaMinutes'] as int? ?? 15,
        status: json['status'] as String? ?? 'ACTIVE',
      );
}
