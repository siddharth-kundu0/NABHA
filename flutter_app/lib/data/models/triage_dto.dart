enum TriagePriority {
  p0Red, // Emergency / Resuscitation / Immediate
  p1Yellow, // Urgent Care / High Priority
  p2Green, // Routine / Low Risk
}

extension TriagePriorityExtension on TriagePriority {
  String get code {
    switch (this) {
      case TriagePriority.p0Red:
        return 'P0';
      case TriagePriority.p1Yellow:
        return 'P1';
      case TriagePriority.p2Green:
        return 'P2';
    }
  }

  String get labelEn {
    switch (this) {
      case TriagePriority.p0Red:
        return 'P0 - Emergency (Immediate)';
      case TriagePriority.p1Yellow:
        return 'P1 - Urgent Care';
      case TriagePriority.p2Green:
        return 'P2 - Routine Care';
    }
  }

  String get labelHi {
    switch (this) {
      case TriagePriority.p0Red:
        return 'P0 - आपातकालीन (तत्काल)';
      case TriagePriority.p1Yellow:
        return 'P1 - अत्यावश्यक देखभाल';
      case TriagePriority.p2Green:
        return 'P2 - सामान्य देखभाल';
    }
  }

  String get labelMr {
    switch (this) {
      case TriagePriority.p0Red:
        return 'P0 - तातडीचे (त्वरित)';
      case TriagePriority.p1Yellow:
        return 'P1 - महत्त्वाचे उपचार';
      case TriagePriority.p2Green:
        return 'P2 - नियमित उपचार';
    }
  }

  String get waitTimeEn {
    switch (this) {
      case TriagePriority.p0Red:
        return '< 1 min (Bypass / Immediate)';
      case TriagePriority.p1Yellow:
        return '2 - 5 mins';
      case TriagePriority.p2Green:
        return '10 - 15 mins';
    }
  }
}

enum PatientCategory {
  pregnantMaternal,
  childUnder5,
  adultMale,
  adultFemaleElderly,
}

extension PatientCategoryExtension on PatientCategory {
  String get labelEn {
    switch (this) {
      case PatientCategory.pregnantMaternal:
        return 'Pregnant / Maternal';
      case PatientCategory.childUnder5:
        return 'Child (< 5 Years)';
      case PatientCategory.adultMale:
        return 'Adult Male';
      case PatientCategory.adultFemaleElderly:
        return 'Adult Female / Elderly';
    }
  }

  String get labelHi {
    switch (this) {
      case PatientCategory.pregnantMaternal:
        return 'गर्भवती / मातृ';
      case PatientCategory.childUnder5:
        return 'बालक (< 5 वर्ष)';
      case PatientCategory.adultMale:
        return 'वयस्क पुरुष';
      case PatientCategory.adultFemaleElderly:
        return 'महिला / वरिष्ठ नागरिक';
    }
  }

  String get labelMr {
    switch (this) {
      case PatientCategory.pregnantMaternal:
        return 'गरोदर / माता';
      case PatientCategory.childUnder5:
        return 'बालक (< ५ वर्षे)';
      case PatientCategory.adultMale:
        return 'प्रौढ पुरुष';
      case PatientCategory.adultFemaleElderly:
        return 'महिला / ज्येष्ठ नागरिक';
    }
  }
}

class TriageAssessmentDto {
  final String id;
  final String patientId;
  final String patientName;
  final PatientCategory category;
  // Hardware vitals (Simulated / BLE hardware stream)
  final int heartRate;
  final int spO2;
  final double bodyTemp;
  // Manual vitals (Entered by ASHA)
  final int systolicBp;
  final int diastolicBp;
  // Targeted clinical questions
  final Map<String, bool> questionAnswers;
  // NLP transcribed patient message
  final String rawPatientMessage;
  final List<String> extractedSymptoms;
  final String affectedBodyZone;
  // Triage Result
  final TriagePriority calculatedPriority;
  final String queueNumber;
  final List<String> redFlagAlerts;
  final DateTime assessedAt;

  const TriageAssessmentDto({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.category,
    required this.heartRate,
    required this.spO2,
    required this.bodyTemp,
    required this.systolicBp,
    required this.diastolicBp,
    required this.questionAnswers,
    this.rawPatientMessage = '',
    this.extractedSymptoms = const [],
    this.affectedBodyZone = 'General',
    required this.calculatedPriority,
    required this.queueNumber,
    this.redFlagAlerts = const [],
    required this.assessedAt,
  });

  bool get isEmergency => calculatedPriority == TriagePriority.p0Red;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'category': category.name,
        'heartRate': heartRate,
        'spO2': spO2,
        'bodyTemp': bodyTemp,
        'systolicBp': systolicBp,
        'diastolicBp': diastolicBp,
        'questionAnswers': questionAnswers,
        'rawPatientMessage': rawPatientMessage,
        'extractedSymptoms': extractedSymptoms,
        'affectedBodyZone': affectedBodyZone,
        'calculatedPriority': calculatedPriority.code,
        'queueNumber': queueNumber,
        'redFlagAlerts': redFlagAlerts,
        'assessedAt': assessedAt.toIso8601String(),
      };

  factory TriageAssessmentDto.fromJson(Map<String, dynamic> json) {
    PatientCategory parsedCategory = PatientCategory.adultMale;
    for (final c in PatientCategory.values) {
      if (c.name == json['category']) {
        parsedCategory = c;
        break;
      }
    }

    TriagePriority parsedPriority = TriagePriority.p2Green;
    final code = json['calculatedPriority'] as String? ?? 'P2';
    if (code == 'P0') {
      parsedPriority = TriagePriority.p0Red;
    } else if (code == 'P1') {
      parsedPriority = TriagePriority.p1Yellow;
    }

    return TriageAssessmentDto(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      category: parsedCategory,
      heartRate: json['heartRate'] as int? ?? 75,
      spO2: json['spO2'] as int? ?? 98,
      bodyTemp: (json['bodyTemp'] as num?)?.toDouble() ?? 98.6,
      systolicBp: json['systolicBp'] as int? ?? 120,
      diastolicBp: json['diastolicBp'] as int? ?? 80,
      questionAnswers: Map<String, bool>.from(json['questionAnswers'] as Map? ?? {}),
      rawPatientMessage: json['rawPatientMessage'] as String? ?? '',
      extractedSymptoms: List<String>.from(json['extractedSymptoms'] as List? ?? []),
      affectedBodyZone: json['affectedBodyZone'] as String? ?? 'General',
      calculatedPriority: parsedPriority,
      queueNumber: json['queueNumber'] as String? ?? 'P2-01',
      redFlagAlerts: List<String>.from(json['redFlagAlerts'] as List? ?? []),
      assessedAt: DateTime.tryParse(json['assessedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

enum AnatomicalView {
  anterior, // Front view
  posterior, // Back view
}

class EmergencyProtocol {
  final String diagnosisName;
  final String warningMessage;
  final String hospitalAction;
  final String targetFacilityType;
  final String? diagnosisNameHi;
  final String? diagnosisNameMr;
  final String? warningMessageHi;
  final String? warningMessageMr;
  final String? hospitalActionHi;
  final String? hospitalActionMr;
  final String? targetFacilityTypeHi;
  final String? targetFacilityTypeMr;

  const EmergencyProtocol({
    required this.diagnosisName,
    required this.warningMessage,
    required this.hospitalAction,
    required this.targetFacilityType,
    this.diagnosisNameHi,
    this.diagnosisNameMr,
    this.warningMessageHi,
    this.warningMessageMr,
    this.hospitalActionHi,
    this.hospitalActionMr,
    this.targetFacilityTypeHi,
    this.targetFacilityTypeMr,
  });

  String localizedDiagnosis(bool isHi, bool isMr) {
    if (isMr && diagnosisNameMr != null && diagnosisNameMr!.isNotEmpty) return diagnosisNameMr!;
    if (isHi && diagnosisNameHi != null && diagnosisNameHi!.isNotEmpty) return diagnosisNameHi!;
    return diagnosisName;
  }

  String localizedWarning(bool isHi, bool isMr) {
    if (isMr && warningMessageMr != null && warningMessageMr!.isNotEmpty) return warningMessageMr!;
    if (isHi && warningMessageHi != null && warningMessageHi!.isNotEmpty) return warningMessageHi!;
    return warningMessage;
  }

  String localizedHospitalAction(bool isHi, bool isMr) {
    if (isMr && hospitalActionMr != null && hospitalActionMr!.isNotEmpty) return hospitalActionMr!;
    if (isHi && hospitalActionHi != null && hospitalActionHi!.isNotEmpty) return hospitalActionHi!;
    return hospitalAction;
  }

  String localizedTargetFacility(bool isHi, bool isMr) {
    if (isMr && targetFacilityTypeMr != null && targetFacilityTypeMr!.isNotEmpty) return targetFacilityTypeMr!;
    if (isHi && targetFacilityTypeHi != null && targetFacilityTypeHi!.isNotEmpty) return targetFacilityTypeHi!;
    return targetFacilityType;
  }
}

class AnatomicalRegionDto {
  final String id;
  final String nameEn;
  final String nameHi;
  final String nameMr;
  final String systemType;
  final String? systemTypeHi;
  final String? systemTypeMr;
  final AnatomicalView view;
  final double normalizedX; // 0.0 to 1.0 on canvas
  final double normalizedY; // 0.0 to 1.0 on canvas
  final List<String> commonSymptoms;
  final List<String>? commonSymptomsHi;
  final List<String>? commonSymptomsMr;
  final EmergencyProtocol emergencyProtocol;
  final bool isHighRisk;

  const AnatomicalRegionDto({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.nameMr,
    required this.systemType,
    this.systemTypeHi,
    this.systemTypeMr,
    required this.view,
    required this.normalizedX,
    required this.normalizedY,
    required this.commonSymptoms,
    this.commonSymptomsHi,
    this.commonSymptomsMr,
    required this.emergencyProtocol,
    this.isHighRisk = false,
  });

  String localizedName(bool isHi, bool isMr) {
    if (isMr) return nameMr;
    if (isHi) return nameHi;
    return nameEn;
  }

  String localizedSystemType(bool isHi, bool isMr) {
    if (isMr && systemTypeMr != null && systemTypeMr!.isNotEmpty) return systemTypeMr!;
    if (isHi && systemTypeHi != null && systemTypeHi!.isNotEmpty) return systemTypeHi!;
    return systemType;
  }

  List<String> localizedSymptoms(bool isHi, bool isMr) {
    if (isMr && commonSymptomsMr != null && commonSymptomsMr!.isNotEmpty) return commonSymptomsMr!;
    if (isHi && commonSymptomsHi != null && commonSymptomsHi!.isNotEmpty) return commonSymptomsHi!;
    return commonSymptoms;
  }
}

class PainAssessmentDto {
  final int severityScore; // 0 - 10
  final String onset; // '< 1 hour', '1 - 24 hours', '1 - 3 days', '> 7 days'
  final String character; // 'Crushing / Pressure', 'Throbbing / Pulsating', 'Sharp / Stabbing', 'Dull Ache / Burning', 'Colicky / Cramping'
  final String radiation; // 'Localized', 'To Left Arm & Jaw', 'To Back / Flank', 'To Groin / Pelvis', 'Down Lower Leg'

  const PainAssessmentDto({
    this.severityScore = 4,
    this.onset = '1 - 3 days',
    this.character = 'Dull Ache / Burning',
    this.radiation = 'Localized',
  });

  bool get isSevere => severityScore >= 7;

  String localizedSeverityLabel(bool isHi, bool isMr) {
    if (severityScore == 0) {
      return isMr ? 'वेदना नाही (०/१०)' : (isHi ? 'कोई दर्द नहीं (0/10)' : 'No Pain (0/10)');
    } else if (severityScore <= 3) {
      return isMr ? 'हलकी वेदना ($severityScore/१०)' : (isHi ? 'हल्का दर्द ($severityScore/10)' : 'Mild Pain ($severityScore/10)');
    } else if (severityScore <= 6) {
      return isMr ? 'मध्यम वेदना ($severityScore/१०)' : (isHi ? 'मध्यम दर्द ($severityScore/10)' : 'Moderate Pain ($severityScore/10)');
    } else {
      return isMr ? 'असह्य तीव्र वेदना ($severityScore/१०)' : (isHi ? 'असहनीय तेज दर्द ($severityScore/10)' : 'Severe Unbearable Pain ($severityScore/10)');
    }
  }
}
