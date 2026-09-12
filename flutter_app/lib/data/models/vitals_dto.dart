class VitalsDto {
  final String id;
  final String patientId;
  final String recordedById;
  final String recordedByRole;
  final DateTime recordedAt;
  final int systolicBp;
  final int diastolicBp;
  final int pulse;
  final int spO2;
  final double temperature;
  final int bloodSugar;
  final double haemoglobin;
  final bool isFromBleDevice;
  final String syncStatus;

  const VitalsDto({
    required this.id,
    required this.patientId,
    required this.recordedById,
    required this.recordedByRole,
    required this.recordedAt,
    required this.systolicBp,
    required this.diastolicBp,
    required this.pulse,
    required this.spO2,
    required this.temperature,
    required this.bloodSugar,
    required this.haemoglobin,
    this.isFromBleDevice = false,
    this.syncStatus = 'SYNCED',
  });

  bool get isHighRisk {
    if (systolicBp >= 140 || diastolicBp >= 90) return true;
    if (spO2 < 94) return true;
    if (bloodSugar >= 200) return true;
    if (haemoglobin < 8.0) return true; // Severe anaemia threshold
    if (temperature >= 102.0) return true;
    return false;
  }

  bool get isEmergency {
    if (systolicBp >= 180 || diastolicBp >= 120) return true;
    if (spO2 < 90) return true;
    return false;
  }

  bool get hasWarning => isHighRisk || isEmergency;

  VitalsDto copyWith({
    String? id,
    String? patientId,
    String? recordedById,
    String? recordedByRole,
    DateTime? recordedAt,
    int? systolicBp,
    int? diastolicBp,
    int? pulse,
    int? spO2,
    double? temperature,
    int? bloodSugar,
    double? haemoglobin,
    bool? isFromBleDevice,
    String? syncStatus,
  }) {
    return VitalsDto(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      recordedById: recordedById ?? this.recordedById,
      recordedByRole: recordedByRole ?? this.recordedByRole,
      recordedAt: recordedAt ?? this.recordedAt,
      systolicBp: systolicBp ?? this.systolicBp,
      diastolicBp: diastolicBp ?? this.diastolicBp,
      pulse: pulse ?? this.pulse,
      spO2: spO2 ?? this.spO2,
      temperature: temperature ?? this.temperature,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      haemoglobin: haemoglobin ?? this.haemoglobin,
      isFromBleDevice: isFromBleDevice ?? this.isFromBleDevice,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'recordedById': recordedById,
        'recordedByRole': recordedByRole,
        'recordedAt': recordedAt.toIso8601String(),
        'systolicBp': systolicBp,
        'diastolicBp': diastolicBp,
        'pulse': pulse,
        'spO2': spO2,
        'temperature': temperature,
        'bloodSugar': bloodSugar,
        'haemoglobin': haemoglobin,
        'isFromBleDevice': isFromBleDevice,
        'syncStatus': syncStatus,
      };

  factory VitalsDto.fromJson(Map<String, dynamic> json) => VitalsDto(
        id: json['id'] as String? ?? '',
        patientId: json['patientId'] as String? ?? '',
        recordedById: json['recordedById'] as String? ?? '',
        recordedByRole: json['recordedByRole'] as String? ?? '',
        recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
        systolicBp: json['systolicBp'] as int? ?? 120,
        diastolicBp: json['diastolicBp'] as int? ?? 80,
        pulse: json['pulse'] as int? ?? 72,
        spO2: json['spO2'] as int? ?? 98,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 98.6,
        bloodSugar: json['bloodSugar'] as int? ?? 100,
        haemoglobin: (json['haemoglobin'] as num?)?.toDouble() ?? 12.0,
        isFromBleDevice: json['isFromBleDevice'] as bool? ?? false,
        syncStatus: json['syncStatus'] as String? ?? 'SYNCED',
      );
}
