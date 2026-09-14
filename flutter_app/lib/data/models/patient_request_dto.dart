import 'package:ruralcare/data/models/triage_dto.dart';

class PatientRequestDto {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientPhone;
  final String abhaId;
  final String village;
  final String address;
  final String message;
  final List<String> extractedSymptoms;
  final TriagePriority triagePriority;
  final String requestType; // TELECONSULTATION, HOME_VISIT, MEDICINE_REFILL, EMERGENCY_SOS
  final String status; // PENDING, ACCEPTED, ESCALATED_TO_DOCTOR, RESOLVED
  final DateTime createdAt;

  const PatientRequestDto({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientPhone,
    required this.abhaId,
    required this.village,
    required this.address,
    required this.message,
    this.extractedSymptoms = const [],
    this.triagePriority = TriagePriority.p2Green,
    required this.requestType,
    this.status = 'PENDING',
    required this.createdAt,
  });

  bool get isEmergency => triagePriority == TriagePriority.p0Red;

  PatientRequestDto copyWith({
    String? id,
    String? patientId,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? patientPhone,
    String? abhaId,
    String? village,
    String? address,
    String? message,
    List<String>? extractedSymptoms,
    TriagePriority? triagePriority,
    String? requestType,
    String? status,
    DateTime? createdAt,
  }) {
    return PatientRequestDto(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientPhone: patientPhone ?? this.patientPhone,
      abhaId: abhaId ?? this.abhaId,
      village: village ?? this.village,
      address: address ?? this.address,
      message: message ?? this.message,
      extractedSymptoms: extractedSymptoms ?? this.extractedSymptoms,
      triagePriority: triagePriority ?? this.triagePriority,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'patientPhone': patientPhone,
        'abhaId': abhaId,
        'village': village,
        'address': address,
        'message': message,
        'extractedSymptoms': extractedSymptoms,
        'triagePriority': triagePriority.code,
        'requestType': requestType,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PatientRequestDto.fromJson(Map<String, dynamic> json) {
    TriagePriority priority = TriagePriority.p2Green;
    final code = json['triagePriority'] as String? ?? 'P2';
    if (code == 'P0') {
      priority = TriagePriority.p0Red;
    } else if (code == 'P1') {
      priority = TriagePriority.p1Yellow;
    }

    return PatientRequestDto(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      patientAge: json['patientAge'] as int? ?? 30,
      patientGender: json['patientGender'] as String? ?? 'Female',
      patientPhone: json['patientPhone'] as String? ?? '',
      abhaId: json['abhaId'] as String? ?? '',
      village: json['village'] as String? ?? '',
      address: json['address'] as String? ?? '',
      message: json['message'] as String? ?? '',
      extractedSymptoms: List<String>.from(json['extractedSymptoms'] as List? ?? []),
      triagePriority: priority,
      requestType: json['requestType'] as String? ?? 'TELECONSULTATION',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
