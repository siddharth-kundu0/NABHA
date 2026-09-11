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
  });

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
      );
}
