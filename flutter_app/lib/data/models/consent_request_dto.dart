enum ConsentStatus {
  pending,
  granted,
  rejected,
  expired,
}

class ConsentRequestDto {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String doctorName;
  final String doctorFacility;
  final String purpose;
  final DateTime requestedAt;
  final DateTime expiresAt;
  final String otp;
  final ConsentStatus status;

  const ConsentRequestDto({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorName,
    required this.doctorFacility,
    required this.purpose,
    required this.requestedAt,
    required this.expiresAt,
    required this.otp,
    this.status = ConsentStatus.pending,
  });

  bool get isGranted => status == ConsentStatus.granted && DateTime.now().isBefore(expiresAt);
  bool get isPending => status == ConsentStatus.pending && DateTime.now().isBefore(expiresAt);

  ConsentRequestDto copyWith({
    ConsentStatus? status,
  }) {
    return ConsentRequestDto(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorName: doctorName,
      doctorFacility: doctorFacility,
      purpose: purpose,
      requestedAt: requestedAt,
      expiresAt: expiresAt,
      otp: otp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'doctorName': doctorName,
      'doctorFacility': doctorFacility,
      'purpose': purpose,
      'requestedAt': requestedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'otp': otp,
      'status': status.name,
    };
  }

  factory ConsentRequestDto.fromJson(Map<String, dynamic> json) {
    return ConsentRequestDto(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      patientPhone: (json['patientPhone'] as String?) ?? '+919823411204',
      doctorName: json['doctorName'] as String,
      doctorFacility: json['doctorFacility'] as String,
      purpose: json['purpose'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      otp: json['otp'] as String,
      status: ConsentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ConsentStatus.pending,
      ),
    );
  }
}
