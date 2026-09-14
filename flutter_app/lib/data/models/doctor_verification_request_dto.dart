enum DoctorVerificationStatus {
  pending,
  accepted,
  rejected;

  String get label {
    switch (this) {
      case DoctorVerificationStatus.pending:
        return 'Verification Pending';
      case DoctorVerificationStatus.accepted:
        return 'Approved & Active';
      case DoctorVerificationStatus.rejected:
        return 'Request Rejected';
    }
  }

  String get labelHi {
    switch (this) {
      case DoctorVerificationStatus.pending:
        return 'सत्यापन लंबित';
      case DoctorVerificationStatus.accepted:
        return 'स्वीकृत व सक्रिय';
      case DoctorVerificationStatus.rejected:
        return 'अनुरोध अस्वीकृत';
    }
  }

  String get labelMr {
    switch (this) {
      case DoctorVerificationStatus.pending:
        return 'पडताळणी प्रलंबित';
      case DoctorVerificationStatus.accepted:
        return 'मंजूर आणि सक्रिय';
      case DoctorVerificationStatus.rejected:
        return 'विनंती नाकारली';
    }
  }
}

class DoctorVerificationRequestDto {
  final String id;
  final String doctorName;
  final String doctorMobile;
  final String email;
  final String qualification;
  final String registrationNumber; // MCI or State Medical Council Reg No.
  final String medicalCouncil;
  final String specialty;
  final String targetFacilityId;
  final String targetFacilityName;
  final DoctorVerificationStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? generatedDoctorId;
  final String? tempOtp; // 6-digit OTP generated upon approval for doctor activation

  const DoctorVerificationRequestDto({
    required this.id,
    required this.doctorName,
    required this.doctorMobile,
    required this.email,
    required this.qualification,
    required this.registrationNumber,
    required this.medicalCouncil,
    required this.specialty,
    required this.targetFacilityId,
    required this.targetFacilityName,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.generatedDoctorId,
    this.tempOtp,
  });

  DoctorVerificationRequestDto copyWith({
    String? id,
    String? doctorName,
    String? doctorMobile,
    String? email,
    String? qualification,
    String? registrationNumber,
    String? medicalCouncil,
    String? specialty,
    String? targetFacilityId,
    String? targetFacilityName,
    DoctorVerificationStatus? status,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? generatedDoctorId,
    String? tempOtp,
  }) {
    return DoctorVerificationRequestDto(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      doctorMobile: doctorMobile ?? this.doctorMobile,
      email: email ?? this.email,
      qualification: qualification ?? this.qualification,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      medicalCouncil: medicalCouncil ?? this.medicalCouncil,
      specialty: specialty ?? this.specialty,
      targetFacilityId: targetFacilityId ?? this.targetFacilityId,
      targetFacilityName: targetFacilityName ?? this.targetFacilityName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      generatedDoctorId: generatedDoctorId ?? this.generatedDoctorId,
      tempOtp: tempOtp ?? this.tempOtp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorName': doctorName,
        'doctorMobile': doctorMobile,
        'email': email,
        'qualification': qualification,
        'registrationNumber': registrationNumber,
        'medicalCouncil': medicalCouncil,
        'specialty': specialty,
        'targetFacilityId': targetFacilityId,
        'targetFacilityName': targetFacilityName,
        'status': status.name,
        'rejectionReason': rejectionReason,
        'submittedAt': submittedAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewedBy': reviewedBy,
        'generatedDoctorId': generatedDoctorId,
        'tempOtp': tempOtp,
      };

  factory DoctorVerificationRequestDto.fromJson(Map<String, dynamic> json) =>
      DoctorVerificationRequestDto(
        id: json['id'] as String? ?? '',
        doctorName: json['doctorName'] as String? ?? '',
        doctorMobile: json['doctorMobile'] as String? ?? '',
        email: json['email'] as String? ?? '',
        qualification: json['qualification'] as String? ?? '',
        registrationNumber: json['registrationNumber'] as String? ?? '',
        medicalCouncil: json['medicalCouncil'] as String? ?? 'Maharashtra Medical Council',
        specialty: json['specialty'] as String? ?? 'General Medicine',
        targetFacilityId: json['targetFacilityId'] as String? ?? '',
        targetFacilityName: json['targetFacilityName'] as String? ?? '',
        status: DoctorVerificationStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'pending'),
          orElse: () => DoctorVerificationStatus.pending,
        ),
        rejectionReason: json['rejectionReason'] as String?,
        submittedAt: json['submittedAt'] != null
            ? DateTime.parse(json['submittedAt'] as String)
            : DateTime.now(),
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.parse(json['reviewedAt'] as String)
            : null,
        reviewedBy: json['reviewedBy'] as String?,
        generatedDoctorId: json['generatedDoctorId'] as String?,
        tempOtp: json['tempOtp'] as String?,
      );
}
