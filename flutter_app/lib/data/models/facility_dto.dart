class FacilityDto {
  final String id;
  final String name;
  final String type; // SUB_CENTRE, PHC, CHC, SUB_DISTRICT_HOSPITAL, DISTRICT_HOSPITAL
  final double distanceKm;
  final String address;
  final String contactPhone;
  final int totalBeds;
  final int availableBeds;
  final List<String> onDutySpecialists;
  final Map<String, int> availableBloodUnits;
  final List<String> availableDiagnostics;
  final List<String> availableMedicines;
  final bool hasEmergencyCapability;
  final bool hasAmbulanceAvailable;

  const FacilityDto({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.address,
    required this.contactPhone,
    required this.totalBeds,
    required this.availableBeds,
    required this.onDutySpecialists,
    required this.availableBloodUnits,
    required this.availableDiagnostics,
    required this.availableMedicines,
    required this.hasEmergencyCapability,
    required this.hasAmbulanceAvailable,
  });

  String get typeLabel {
    switch (type) {
      case 'SUB_CENTRE':
        return 'Sub-Centre (उप-केंद्र)';
      case 'PHC':
        return 'PHC (प्राथमिक आरोग्य केंद्र)';
      case 'CHC':
        return 'CHC (सामुदायिक आरोग्य केंद्र)';
      case 'SUB_DISTRICT_HOSPITAL':
        return 'Sub-District Hospital (उपजिल्हा रुग्णालय)';
      case 'DISTRICT_HOSPITAL':
        return 'District Hospital (जिल्हा रुग्णालय)';
      default:
        return type;
    }
  }

  String get typeDisplay => typeLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'distanceKm': distanceKm,
        'address': address,
        'contactPhone': contactPhone,
        'totalBeds': totalBeds,
        'availableBeds': availableBeds,
        'onDutySpecialists': onDutySpecialists,
        'availableBloodUnits': availableBloodUnits,
        'availableDiagnostics': availableDiagnostics,
        'availableMedicines': availableMedicines,
        'hasEmergencyCapability': hasEmergencyCapability,
        'hasAmbulanceAvailable': hasAmbulanceAvailable,
      };

  factory FacilityDto.fromJson(Map<String, dynamic> json) => FacilityDto(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'PHC',
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        address: json['address'] as String? ?? '',
        contactPhone: json['contactPhone'] as String? ?? '',
        totalBeds: json['totalBeds'] as int? ?? 0,
        availableBeds: json['availableBeds'] as int? ?? 0,
        onDutySpecialists: List<String>.from(json['onDutySpecialists'] as List? ?? []),
        availableBloodUnits: Map<String, int>.from(json['availableBloodUnits'] as Map? ?? {}),
        availableDiagnostics: List<String>.from(json['availableDiagnostics'] as List? ?? []),
        availableMedicines: List<String>.from(json['availableMedicines'] as List? ?? []),
        hasEmergencyCapability: json['hasEmergencyCapability'] as bool? ?? false,
        hasAmbulanceAvailable: json['hasAmbulanceAvailable'] as bool? ?? false,
      );
}
