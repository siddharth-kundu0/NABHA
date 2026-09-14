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
  Map<String, int> get bloodBankStock => availableBloodUnits;

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

enum FacilityStaffRole {
  facilityAdmin,
  pharmacist,
  labTechnician,
  staffNurse,
  receptionClerk;

  String get displayName {
    switch (this) {
      case FacilityStaffRole.facilityAdmin:
        return 'Facility Administrator (Medical Superintendent)';
      case FacilityStaffRole.pharmacist:
        return 'Registered Pharmacist (Dispensary)';
      case FacilityStaffRole.labTechnician:
        return 'Lab Technician (Diagnostics & Pathology)';
      case FacilityStaffRole.staffNurse:
        return 'Staff Nurse (Inpatient Wards & Triage)';
      case FacilityStaffRole.receptionClerk:
        return 'Reception & Referral Intake Clerk';
    }
  }

  String get shortName {
    switch (this) {
      case FacilityStaffRole.facilityAdmin:
        return 'Facility Admin';
      case FacilityStaffRole.pharmacist:
        return 'Pharmacist';
      case FacilityStaffRole.labTechnician:
        return 'Lab Technician';
      case FacilityStaffRole.staffNurse:
        return 'Staff Nurse';
      case FacilityStaffRole.receptionClerk:
        return 'Intake Clerk';
    }
  }

  String get defaultDepartment {
    switch (this) {
      case FacilityStaffRole.facilityAdmin:
        return 'Hospital Administration & Superintendent Office';
      case FacilityStaffRole.pharmacist:
        return 'Pharmacy Dispensary & Drug Stores';
      case FacilityStaffRole.labTechnician:
        return 'Central Diagnostic & Pathology Lab';
      case FacilityStaffRole.staffNurse:
        return 'Inpatient Wards & Emergency Triage';
      case FacilityStaffRole.receptionClerk:
        return 'Patient Registration & 108 Intake Desk';
    }
  }
}

enum FacilityApprovalStatus {
  pendingFacilityAdmin,
  pendingDistrictAdmin,
  approved,
  rejected;

  String get label {
    switch (this) {
      case FacilityApprovalStatus.pendingFacilityAdmin:
        return 'Pending Facility Admin Approval';
      case FacilityApprovalStatus.pendingDistrictAdmin:
        return 'Pending District Admin Approval';
      case FacilityApprovalStatus.approved:
        return 'Approved & Active';
      case FacilityApprovalStatus.rejected:
        return 'Application Rejected';
    }
  }
}

class FacilityStaffRequestDto {
  final String id;
  final String facilityId;
  final String facilityName;
  final String staffName;
  final String mobile;
  final FacilityStaffRole role;
  final String licenseOrEmployeeId;
  final String department;
  final FacilityApprovalStatus status;
  final DateTime submittedAt;
  final String? assignedRoom;
  final String? rejectionReason;

  const FacilityStaffRequestDto({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.staffName,
    required this.mobile,
    required this.role,
    required this.licenseOrEmployeeId,
    required this.department,
    required this.status,
    required this.submittedAt,
    this.assignedRoom,
    this.rejectionReason,
  });

  FacilityStaffRequestDto copyWith({
    String? id,
    String? facilityId,
    String? facilityName,
    String? staffName,
    String? mobile,
    FacilityStaffRole? role,
    String? licenseOrEmployeeId,
    String? department,
    FacilityApprovalStatus? status,
    DateTime? submittedAt,
    String? assignedRoom,
    String? rejectionReason,
  }) {
    return FacilityStaffRequestDto(
      id: id ?? this.id,
      facilityId: facilityId ?? this.facilityId,
      facilityName: facilityName ?? this.facilityName,
      staffName: staffName ?? this.staffName,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      licenseOrEmployeeId: licenseOrEmployeeId ?? this.licenseOrEmployeeId,
      department: department ?? this.department,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      assignedRoom: assignedRoom ?? this.assignedRoom,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class PrescriptionOrderDto {
  final String id;
  final String patientName;
  final String patientRuralCareId;
  final String doctorName;
  final List<String> prescribedMedicines;
  final String dosageInstructions;
  final String status; // PENDING, DISPENSED
  final DateTime orderedAt;

  const PrescriptionOrderDto({
    required this.id,
    required this.patientName,
    required this.patientRuralCareId,
    required this.doctorName,
    required this.prescribedMedicines,
    required this.dosageInstructions,
    required this.status,
    required this.orderedAt,
  });

  PrescriptionOrderDto copyWith({
    String? id,
    String? patientName,
    String? patientRuralCareId,
    String? doctorName,
    List<String>? prescribedMedicines,
    String? dosageInstructions,
    String? status,
    DateTime? orderedAt,
  }) {
    return PrescriptionOrderDto(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientRuralCareId: patientRuralCareId ?? this.patientRuralCareId,
      doctorName: doctorName ?? this.doctorName,
      prescribedMedicines: prescribedMedicines ?? this.prescribedMedicines,
      dosageInstructions: dosageInstructions ?? this.dosageInstructions,
      status: status ?? this.status,
      orderedAt: orderedAt ?? this.orderedAt,
    );
  }
}

class DiagnosticOrderDto {
  final String id;
  final String patientName;
  final String patientRuralCareId;
  final String testName;
  final String urgency; // Routine, Priority, Urgent
  final String status; // ORDERED, SAMPLE_COLLECTED, ANALYZING, COMPLETED
  final String? resultValue;
  final DateTime orderedAt;

  const DiagnosticOrderDto({
    required this.id,
    required this.patientName,
    required this.patientRuralCareId,
    required this.testName,
    required this.urgency,
    required this.status,
    this.resultValue,
    required this.orderedAt,
  });

  DiagnosticOrderDto copyWith({
    String? id,
    String? patientName,
    String? patientRuralCareId,
    String? testName,
    String? urgency,
    String? status,
    String? resultValue,
    DateTime? orderedAt,
  }) {
    return DiagnosticOrderDto(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientRuralCareId: patientRuralCareId ?? this.patientRuralCareId,
      testName: testName ?? this.testName,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      resultValue: resultValue ?? this.resultValue,
      orderedAt: orderedAt ?? this.orderedAt,
    );
  }
}

