import 'package:ruralcare/data/models/vitals_dto.dart';

class EmergencyContactDto {
  final String name;
  final String relationship;
  final String phoneNumber;

  const EmergencyContactDto({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'relationship': relationship,
        'phoneNumber': phoneNumber,
      };

  factory EmergencyContactDto.fromJson(Map<String, dynamic> json) => EmergencyContactDto(
        name: json['name'] as String? ?? '',
        relationship: json['relationship'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
      );
}

class PatientDto {
  final String id;
  final String ruralCareId;
  final String abhaId;
  final String fullName;
  final int age;
  final String gender;
  final String phoneNumber;
  final String village;
  final String subCentre;
  final String district;
  final String assignedAsha;

  // Maternal Profile
  final bool isPregnant;
  final int? gestationalAgeWeeks;
  final int ancVisitsCompleted;
  final DateTime? edd;
  final List<String> highRiskConditions;

  // Clinical Details
  final List<String> chronicConditions;
  final List<String> allergies;
  final EmergencyContactDto emergencyContact;
  final VitalsDto? latestVitals;

  const PatientDto({
    required this.id,
    required this.ruralCareId,
    required this.abhaId,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.phoneNumber,
    required this.village,
    required this.subCentre,
    required this.district,
    required this.assignedAsha,
    this.isPregnant = false,
    this.gestationalAgeWeeks,
    this.ancVisitsCompleted = 0,
    this.edd,
    this.highRiskConditions = const [],
    this.chronicConditions = const [],
    this.allergies = const [],
    required this.emergencyContact,
    this.latestVitals,
  });

  bool get isHighRisk =>
      highRiskConditions.isNotEmpty || (latestVitals != null && latestVitals!.isHighRisk);

  bool get isEmergency => latestVitals != null && latestVitals!.isEmergency;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ruralCareId': ruralCareId,
        'abhaId': abhaId,
        'fullName': fullName,
        'age': age,
        'gender': gender,
        'phoneNumber': phoneNumber,
        'village': village,
        'subCentre': subCentre,
        'district': district,
        'assignedAsha': assignedAsha,
        'isPregnant': isPregnant,
        'gestationalAgeWeeks': gestationalAgeWeeks,
        'ancVisitsCompleted': ancVisitsCompleted,
        'edd': edd?.toIso8601String(),
        'highRiskConditions': highRiskConditions,
        'chronicConditions': chronicConditions,
        'allergies': allergies,
        'emergencyContact': emergencyContact.toJson(),
        'latestVitals': latestVitals?.toJson(),
      };

  factory PatientDto.fromJson(Map<String, dynamic> json) => PatientDto(
        id: json['id'] as String? ?? '',
        ruralCareId: json['ruralCareId'] as String? ?? '',
        abhaId: json['abhaId'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        age: json['age'] as int? ?? 0,
        gender: json['gender'] as String? ?? 'OTHER',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        village: json['village'] as String? ?? '',
        subCentre: json['subCentre'] as String? ?? '',
        district: json['district'] as String? ?? '',
        assignedAsha: json['assignedAsha'] as String? ?? '',
        isPregnant: json['isPregnant'] as bool? ?? false,
        gestationalAgeWeeks: json['gestationalAgeWeeks'] as int?,
        ancVisitsCompleted: json['ancVisitsCompleted'] as int? ?? 0,
        edd: DateTime.tryParse(json['edd'] as String? ?? ''),
        highRiskConditions: List<String>.from(json['highRiskConditions'] as List? ?? []),
        chronicConditions: List<String>.from(json['chronicConditions'] as List? ?? []),
        allergies: List<String>.from(json['allergies'] as List? ?? []),
        emergencyContact: EmergencyContactDto.fromJson(
            json['emergencyContact'] as Map<String, dynamic>? ?? {}),
        latestVitals: json['latestVitals'] != null
            ? VitalsDto.fromJson(json['latestVitals'] as Map<String, dynamic>)
            : null,
      );
}
