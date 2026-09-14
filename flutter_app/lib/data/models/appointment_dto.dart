class PrescriptionItemDto {
  final String medicineName;
  final String dosage;
  final String frequency;
  final int durationDays;

  const PrescriptionItemDto({
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
  });

  String get name => medicineName;

  Map<String, dynamic> toJson() => {
        'medicineName': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'durationDays': durationDays,
      };

  factory PrescriptionItemDto.fromJson(Map<String, dynamic> json) => PrescriptionItemDto(
        medicineName: json['medicineName'] as String? ?? '',
        dosage: json['dosage'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        durationDays: json['durationDays'] as int? ?? 1,
      );
}

class PrescriptionDto {
  final String id;
  final String patientId;
  final String doctorName;
  final String diagnosis;
  final List<PrescriptionItemDto> medicines;
  final String? adviceNotes;
  final DateTime issuedAt;

  const PrescriptionDto({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.diagnosis,
    required this.medicines,
    this.adviceNotes,
    required this.issuedAt,
  });

  String? get lifestyleAdvice => adviceNotes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'doctorName': doctorName,
        'diagnosis': diagnosis,
        'medicines': medicines.map((m) => m.toJson()).toList(),
        'adviceNotes': adviceNotes,
        'issuedAt': issuedAt.toIso8601String(),
      };

  factory PrescriptionDto.fromJson(Map<String, dynamic> json) => PrescriptionDto(
        id: json['id'] as String? ?? '',
        patientId: json['patientId'] as String? ?? '',
        doctorName: json['doctorName'] as String? ?? '',
        diagnosis: json['diagnosis'] as String? ?? '',
        medicines: (json['medicines'] as List? ?? [])
            .map((m) => PrescriptionItemDto.fromJson(m as Map<String, dynamic>))
            .toList(),
        adviceNotes: json['adviceNotes'] as String?,
        issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class AppointmentDto {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final String specialty;
  final String facilityName;
  final DateTime scheduledTime;
  final String type; // TELECONSULTATION, IN_PERSON
  final String status; // SCHEDULED, WAITING_ROOM, IN_PROGRESS, COMPLETED, CANCELLED
  final String chiefComplaint;
  final String queueNumber;
  final String triagePriority; // P0, P1, P2
  final List<String> symptoms;
  final String primaryIssue;
  final String? fhirBundleJson;
  final bool consentGranted;

  const AppointmentDto({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    required this.facilityName,
    required this.scheduledTime,
    required this.type,
    required this.status,
    required this.chiefComplaint,
    this.queueNumber = 'P2-01',
    this.triagePriority = 'P2',
    this.symptoms = const [],
    this.primaryIssue = 'Routine Consultation',
    this.fhirBundleJson,
    this.consentGranted = true,
  });

  String get appointmentTime =>
      '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year} ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

  AppointmentDto copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorName,
    String? specialty,
    String? facilityName,
    DateTime? scheduledTime,
    String? type,
    String? status,
    String? chiefComplaint,
    String? queueNumber,
    String? triagePriority,
    List<String>? symptoms,
    String? primaryIssue,
    String? fhirBundleJson,
    bool? consentGranted,
  }) =>
      AppointmentDto(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        doctorName: doctorName ?? this.doctorName,
        specialty: specialty ?? this.specialty,
        facilityName: facilityName ?? this.facilityName,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        type: type ?? this.type,
        status: status ?? this.status,
        chiefComplaint: chiefComplaint ?? this.chiefComplaint,
        queueNumber: queueNumber ?? this.queueNumber,
        triagePriority: triagePriority ?? this.triagePriority,
        symptoms: symptoms ?? this.symptoms,
        primaryIssue: primaryIssue ?? this.primaryIssue,
        fhirBundleJson: fhirBundleJson ?? this.fhirBundleJson,
        consentGranted: consentGranted ?? this.consentGranted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'doctorName': doctorName,
        'specialty': specialty,
        'facilityName': facilityName,
        'scheduledTime': scheduledTime.toIso8601String(),
        'type': type,
        'status': status,
        'chiefComplaint': chiefComplaint,
        'queueNumber': queueNumber,
        'triagePriority': triagePriority,
        'symptoms': symptoms,
        'primaryIssue': primaryIssue,
        'fhirBundleJson': fhirBundleJson,
        'consentGranted': consentGranted,
      };

  factory AppointmentDto.fromJson(Map<String, dynamic> json) => AppointmentDto(
        id: json['id'] as String? ?? '',
        patientId: json['patientId'] as String? ?? '',
        patientName: json['patientName'] as String? ?? '',
        doctorName: json['doctorName'] as String? ?? '',
        specialty: json['specialty'] as String? ?? '',
        facilityName: json['facilityName'] as String? ?? '',
        scheduledTime: DateTime.tryParse(json['scheduledTime'] as String? ?? '') ?? DateTime.now(),
        type: json['type'] as String? ?? 'IN_PERSON',
        status: json['status'] as String? ?? 'SCHEDULED',
        chiefComplaint: json['chiefComplaint'] as String? ?? '',
        queueNumber: json['queueNumber'] as String? ?? 'P2-01',
        triagePriority: json['triagePriority'] as String? ?? 'P2',
        symptoms: List<String>.from(json['symptoms'] as List? ?? []),
        primaryIssue: json['primaryIssue'] as String? ?? 'Routine Consultation',
        fhirBundleJson: json['fhirBundleJson'] as String?,
        consentGranted: json['consentGranted'] as bool? ?? true,
      );
}
