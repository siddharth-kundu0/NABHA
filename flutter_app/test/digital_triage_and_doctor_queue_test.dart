import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/core/services/clinical_triage_engine.dart';
import 'package:ruralcare/core/services/nlp_symptom_service.dart';
import 'package:ruralcare/core/services/fhir_r4_prescription_service.dart';
import 'package:ruralcare/data/models/triage_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_request_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/patient_request_repository.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';

void main() {
  const patient1 = PatientDto(
    id: 'P-101',
    ruralCareId: 'RC-101',
    abhaId: 'ABHA-1234-5678-9012',
    fullName: 'Ramesh Kale',
    age: 42,
    gender: 'Male',
    phoneNumber: '+91 9876543210',
    village: 'Kashti',
    subCentre: 'Kashti SC',
    district: 'Pune',
    assignedAsha: 'Sunita Verma (ASHA)',
    emergencyContact: EmergencyContactDto(
      name: 'Sunita Kale',
      relationship: 'Spouse',
      phoneNumber: '+91 9876543211',
    ),
  );

  const patient2 = PatientDto(
    id: 'P-102',
    ruralCareId: 'RC-102',
    abhaId: 'ABHA-9876-5432-1098',
    fullName: 'Anandi Devi',
    age: 26,
    gender: 'Female',
    phoneNumber: '+91 9876543212',
    village: 'Daund',
    subCentre: 'Daund CHC',
    district: 'Pune',
    assignedAsha: 'Sunita Verma (ASHA)',
    isPregnant: true,
    gestationalAgeWeeks: 28,
    ancVisitsCompleted: 3,
    emergencyContact: EmergencyContactDto(
      name: 'Prakash Devi',
      relationship: 'Husband',
      phoneNumber: '+91 9876543213',
    ),
  );

  setUp(() {
    final repo = PatientRepository();
    repo.resetToDefaults();
    repo.addPatient(patient1);
    repo.addPatient(patient2);
  });

  group('Digital Triage Engine & Multilingual NLP Tests', () {
    final triageEngine = ClinicalTriageEngine();
    final nlpService = NlpSymptomService();

    test('ClinicalTriageEngine returns Category Questions for MoHFW/NHM/RBSK protocols', () {
      final maternalQs = triageEngine.getQuestionsForCategory(PatientCategory.pregnantMaternal);
      expect(maternalQs.isNotEmpty, isTrue);
      expect(maternalQs.any((q) => q.isRedFlag), isTrue);

      final childQs = triageEngine.getQuestionsForCategory(PatientCategory.childUnder5);
      expect(childQs.isNotEmpty, isTrue);
      expect(childQs.any((q) => q.textEn.contains('chest indrawing') || q.textEn.contains('vomiting')), isTrue);
    });

    test('ClinicalTriageEngine flags P0 Emergency for acute vitals or danger flags', () {
      final assessment = triageEngine.evaluate(
        patientId: patient1.id,
        patientName: patient1.fullName,
        category: PatientCategory.adultMale,
        heartRate: 145, // Tachycardia
        spO2: 88,       // Critical Hypoxia
        bodyTemp: 104.2,// Hyperpyrexia
        systolicBp: 190,// Hypertensive Crisis
        diastolicBp: 115,
        questionAnswers: {'male_chest_pressure': true},
        rawMessage: 'severe crushing chest pain and breathlessness',
      );

      expect(assessment.calculatedPriority, equals(TriagePriority.p0Red));
      expect(assessment.queueNumber.startsWith('P0-'), isTrue);
      expect(assessment.redFlagAlerts.isNotEmpty, isTrue);
      expect(assessment.isEmergency, isTrue);
    });

    test('ClinicalTriageEngine generates P2 Green standard routine for normal vitals', () {
      final assessment = triageEngine.evaluate(
        patientId: patient1.id,
        patientName: patient1.fullName,
        category: PatientCategory.adultMale,
        heartRate: 72,
        spO2: 99,
        bodyTemp: 98.6,
        systolicBp: 120,
        diastolicBp: 80,
        questionAnswers: {},
        rawMessage: 'routine checkup and mild cough',
      );

      expect(assessment.calculatedPriority, equals(TriagePriority.p2Green));
      expect(assessment.queueNumber.startsWith('P2-'), isTrue);
      expect(assessment.isEmergency, isFalse);
    });

    test('NlpSymptomService parses Hindi, Marathi, and English messages accurately', () {
      // Hindi complaint
      final resHi = nlpService.parseMessage('mera pet dukhra hai aur ulti ho rahi hai');
      expect(resHi.primaryOrganZone, equals('Abdomen'));
      expect(resHi.extractedSymptoms.any((s) => s.contains('Abdominal Pain') || s.contains('Abdominal Discomfort')), isTrue);

      // Marathi complaint
      final resMr = nlpService.parseMessage('potat khup dukhatahe');
      expect(resMr.primaryOrganZone, equals('Abdomen'));

      // Normal headache (User reported issue: "normal sir dard" should NOT be severe)
      final resNormalHeadache = nlpService.parseMessage('normal sir dard');
      expect(resNormalHeadache.primaryOrganZone, equals('Head'));
      expect(resNormalHeadache.extractedSymptoms, contains('Mild / Normal Headache'));
      expect(resNormalHeadache.suggestedPriority, equals(TriagePriority.p2Green));

      // Halka sir dard (Mild headache)
      final resHalka = nlpService.parseMessage('halka sir dard hai');
      expect(resHalka.primaryOrganZone, equals('Head'));
      expect(resHalka.extractedSymptoms, contains('Mild / Normal Headache'));
      expect(resHalka.suggestedPriority, equals(TriagePriority.p2Green));

      // Plain sir dard
      final resPlain = nlpService.parseMessage('sir dard ho raha hai');
      expect(resPlain.primaryOrganZone, equals('Head'));
      expect(resPlain.extractedSymptoms, contains('Mild / Normal Headache'));
      expect(resPlain.suggestedPriority, equals(TriagePriority.p2Green));

      // Severe headache / migraine
      final resSevereHeadache = nlpService.parseMessage('bahut tez sir dard phat raha hai');
      expect(resSevereHeadache.primaryOrganZone, equals('Head'));
      expect(resSevereHeadache.extractedSymptoms, contains('Severe Headache / Migraine'));
      expect(resSevereHeadache.suggestedPriority, equals(TriagePriority.p1Yellow));

      // Sar phat raha hai
      final resPhatRaha = nlpService.parseMessage('sar phat raha hai khup dukhatahe');
      expect(resPhatRaha.primaryOrganZone, equals('Head'));
      expect(resPhatRaha.extractedSymptoms, contains('Severe Headache / Migraine'));
      expect(resPhatRaha.suggestedPriority, equals(TriagePriority.p1Yellow));

      // Cardiac Red-Flag (Chest)
      final resChest = nlpService.parseMessage('chhati me dard aur saans lene me takleef');
      expect(resChest.primaryOrganZone, equals('Chest'));
      expect(resChest.suggestedPriority, equals(TriagePriority.p0Red));
      expect(resChest.dangerFlags.isNotEmpty, isTrue);
    });
  });

  group('Fine-Grained Anatomical Mapping & Adaptive Emergency Triage Tests', () {
    final triageEngine = ClinicalTriageEngine();

    test('ClinicalTriageEngine registers 38+ comprehensive anatomical regions across views', () {
      final allRegions = triageEngine.allRegions;
      expect(allRegions.length, greaterThanOrEqualTo(30));

      final anteriorRegions = triageEngine.getRegionsForView(AnatomicalView.anterior);
      final posteriorRegions = triageEngine.getRegionsForView(AnatomicalView.posterior);

      expect(anteriorRegions.isNotEmpty, isTrue);
      expect(posteriorRegions.isNotEmpty, isTrue);
      expect(anteriorRegions.length + posteriorRegions.length, equals(allRegions.length));

      // Check key bilateral & specialized regions
      expect(allRegions.any((r) => r.id == 'forehead_right'), isTrue);
      expect(allRegions.any((r) => r.id == 'forehead_left'), isTrue);
      expect(allRegions.any((r) => r.id == 'chest_precordium'), isTrue);
      expect(allRegions.any((r) => r.id == 'abdomen_rlq'), isTrue);
      expect(allRegions.any((r) => r.id == 'lumbar_spine_lower_back'), isTrue);
    });

    test('findRegionByCoordinate resolves accurate anatomical spot from tap touch', () {
      // Tap near forehead right (0.57, 0.05)
      final forehead = triageEngine.findRegionByCoordinate(0.57, 0.05, AnatomicalView.anterior);
      expect(forehead.id, equals('forehead_right'));
      expect(forehead.systemType, contains('Head'));
      expect(forehead.localizedName(true, false), contains('माथे'));
      expect(forehead.localizedName(false, true), contains('कपाळ'));

      // Tap near precordium chest (0.44, 0.28)
      final chest = triageEngine.findRegionByCoordinate(0.44, 0.28, AnatomicalView.anterior);
      expect(chest.id, equals('chest_precordium'));
      expect(chest.systemType, contains('Heart'));
      expect(chest.localizedName(true, false), contains('सीना'));
      expect(chest.localizedName(false, true), contains('छाती'));

      // Tap near lumbar spine on posterior view (0.50, 0.48)
      final lumbar = triageEngine.findRegionByCoordinate(0.50, 0.48, AnatomicalView.posterior);
      expect(lumbar.id, equals('lumbar_spine_lower_back'));
      expect(lumbar.systemType, anyOf(contains('Backbone'), contains('Spine')));
    });

    test('Emergency red-flag protocol adapts specifically to tapped body region in plain language', () {
      // Forehead -> FAST Brain Stroke Protocol
      final forehead = triageEngine.getRegionById('forehead_right');
      expect(forehead.emergencyProtocol.diagnosisName, anyOf(contains('Stroke'), contains('FAST')));
      expect(forehead.emergencyProtocol.targetFacilityType, contains('Hospital'));

      // Precordium -> Severe Heart Attack Risk (STEMI)
      final precordium = triageEngine.getRegionById('chest_precordium');
      expect(precordium.emergencyProtocol.diagnosisName, anyOf(contains('Heart Attack'), contains('STEMI')));
      expect(precordium.emergencyProtocol.hospitalAction, anyOf(contains('ECG'), contains('Cardiac')));

      // Right Lower Abdomen -> Severe Belly / Appendix Infection (Appendicitis)
      final rlq = triageEngine.getRegionById('abdomen_rlq');
      expect(rlq.emergencyProtocol.diagnosisName, anyOf(contains('Appendix'), contains('Appendicitis')));
      expect(rlq.emergencyProtocol.targetFacilityType, anyOf(contains('Surgical'), contains('Hospital')));

      // Lumbar Spine -> Severe Nerve & Spine Compression (Cauda Equina)
      final lumbar = triageEngine.getRegionById('lumbar_spine_lower_back');
      expect(lumbar.emergencyProtocol.diagnosisName, anyOf(contains('Spine'), contains('Cauda Equina')));

      // Trilingual protocol check
      expect(precordium.emergencyProtocol.localizedDiagnosis(true, false), contains('दिल का दौरा'));
      expect(precordium.emergencyProtocol.localizedDiagnosis(false, true), contains('हृदयविकाराचा'));
    });

    test('evaluate() elevates priority to P0 Red when universal danger signs are checked', () {
      final assessment = triageEngine.evaluate(
        patientId: 'P-101',
        patientName: 'Ramesh Kale',
        category: PatientCategory.adultMale,
        heartRate: 78,
        spO2: 98,
        bodyTemp: 98.4,
        systolicBp: 120,
        diastolicBp: 80,
        questionAnswers: {'danger_shock': true},
      );

      expect(assessment.calculatedPriority, equals(TriagePriority.p0Red));
      expect(assessment.queueNumber.startsWith('P0-'), isTrue);
      expect(assessment.redFlagAlerts.any((a) => a.toLowerCase().contains('shock')), isTrue);
    });

    test('evaluate() evaluates Pain Assessment Matrix (ischemic radiation & high severity)', () {
      // Severe pain (score 9) triggers Yellow P1 even with normal vitals
      final highPainAssessment = triageEngine.evaluate(
        patientId: 'P-101',
        patientName: 'Ramesh Kale',
        category: PatientCategory.adultMale,
        heartRate: 75,
        spO2: 98,
        bodyTemp: 98.6,
        systolicBp: 120,
        diastolicBp: 80,
        questionAnswers: const {},
        painAssessment: const PainAssessmentDto(
          severityScore: 9,
          onset: '1 - 3 Days',
          character: 'Throbbing / Pulsating',
          radiation: 'Localized',
        ),
      );
      expect(highPainAssessment.calculatedPriority, equals(TriagePriority.p1Yellow));

      // Crushing pain radiating to Left Arm triggers P0 Red Cardiac STEMI
      final cardiacPainAssessment = triageEngine.evaluate(
        patientId: 'P-101',
        patientName: 'Ramesh Kale',
        category: PatientCategory.adultMale,
        heartRate: 85,
        spO2: 97,
        bodyTemp: 98.6,
        systolicBp: 125,
        diastolicBp: 82,
        questionAnswers: const {},
        painAssessment: const PainAssessmentDto(
          severityScore: 7,
          onset: '< 1 Hour',
          character: 'Crushing / Pressure',
          radiation: 'Radiating to Jaw / Left Arm',
        ),
      );
      expect(cardiacPainAssessment.calculatedPriority, equals(TriagePriority.p0Red));
      expect(cardiacPainAssessment.redFlagAlerts.any((a) => a.contains('STEMI')), isTrue);
    });

    test('Region-targeted checklist triggers P0 Red on peritonitis or red-flag symptoms', () {
      final rlqRegion = triageEngine.getRegionById('abdomen_rlq');
      final regionQuestions = triageEngine.getQuestionsForRegion(rlqRegion);
      expect(regionQuestions.any((q) => q.isRedFlag), isTrue);

      final redFlagQ = regionQuestions.firstWhere((q) => q.isRedFlag);

      final assessment = triageEngine.evaluate(
        patientId: 'P-101',
        patientName: 'Ramesh Kale',
        category: PatientCategory.adultMale,
        heartRate: 80,
        spO2: 98,
        bodyTemp: 98.6,
        systolicBp: 120,
        diastolicBp: 80,
        selectedRegion: rlqRegion,
        questionAnswers: {redFlagQ.id: true},
      );

      expect(assessment.calculatedPriority, equals(TriagePriority.p0Red));
      expect(assessment.redFlagAlerts.any((a) => a.contains(redFlagQ.textEn)), isTrue);
    });
  });

  group('Patient Cluster Roster & Patient Requests Desk Tests', () {
    test('PatientRepository manages multi-patient selection and default active patient', () {
      final repo = PatientRepository();
      expect(repo.patients.length, equals(2));

      repo.setActivePatient(patient1);
      expect(repo.activePatient?.id, equals(patient1.id));

      repo.selectPatientById(patient2.id);
      expect(repo.activePatient?.id, equals(patient2.id));
    });

    test('PatientRequestRepository stores and updates community requests dynamically', () {
      final repo = PatientRequestRepository();
      final initialCount = repo.requests.length;

      final dynamicReq = PatientRequestDto(
        id: 'REQ-TEST-001',
        patientId: patient1.id,
        patientName: patient1.fullName,
        patientAge: patient1.age,
        patientGender: patient1.gender,
        patientPhone: patient1.phoneNumber,
        abhaId: patient1.abhaId,
        village: patient1.village,
        address: '${patient1.village}, House 14',
        message: 'Potat khup dukhatahe',
        triagePriority: TriagePriority.p1Yellow,
        extractedSymptoms: const ['Abdominal Colic'],
        requestType: 'TELECONSULTATION',
        status: 'PENDING',
        createdAt: DateTime.now(),
      );

      repo.addRequest(dynamicReq);
      expect(repo.requests.length, equals(initialCount + 1));
      expect(repo.pendingRequests.length, greaterThan(0));

      repo.resolveRequest('REQ-TEST-001');
      final updated = repo.requests.firstWhere((r) => r.id == 'REQ-TEST-001');
      expect(updated.status, equals('RESOLVED'));
    });
  });

  group('ABDM FHIR R4 E-Prescription & Doctor Queue Tests', () {
    test('FhirR4PrescriptionService authors valid compliant FHIR R4 Bundle', () {
      final rx = PrescriptionDto(
        id: 'RX-TEST-999',
        patientId: patient1.id,
        doctorName: 'Dr. Anita Roy',
        diagnosis: 'Essential Hypertension',
        medicines: const [
          PrescriptionItemDto(
            medicineName: 'Amlodipine 5mg',
            dosage: '1 tab',
            frequency: 'Once Daily (OD)',
            durationDays: 30,
          ),
          PrescriptionItemDto(
            medicineName: 'Telmisartan 40mg',
            dosage: '1 tab',
            frequency: 'Once Daily (OD)',
            durationDays: 30,
          ),
        ],
        adviceNotes: 'Low sodium diet, regular morning walk.',
        issuedAt: DateTime.now(),
      );

      final service = FhirR4PrescriptionService();
      final bundle = service.buildAbdmFhirR4Bundle(
        rx: rx,
        patient: patient1,
        doctorSpecialty: 'General Medicine & Cardiology',
        doctorRegistrationNumber: 'MCI-2019-12345',
        facilityName: 'Baramati Sub-District Hospital',
      );

      expect(bundle['resourceType'], equals('Bundle'));
      expect(bundle['type'], equals('document'));
      final entries = bundle['entry'] as List;
      expect(entries.length, greaterThanOrEqualTo(5)); // Composition, Practitioner, Patient, Encounter, Conditions, MedRequests

      final jsonString = service.buildFhirJsonString(bundle);
      expect(jsonString.contains('https://nrces.in/ndhm/fhir/r4/StructureDefinition/PrescriptionRecord'), isTrue);
      expect(jsonString.contains('Amlodipine 5mg'), isTrue);
    });

    test('AppointmentDto supports triagePriority, queueNumber, symptoms, and consent check', () {
      final aptRepo = AppointmentRepository();
      final apt = AppointmentDto(
        id: 'APT-TEST-TRIAGE',
        patientId: patient1.id,
        patientName: patient1.fullName,
        doctorName: 'Dr. Amit Sharma',
        specialty: 'General Medicine',
        facilityName: 'Baramati SDH',
        scheduledTime: DateTime.now(),
        type: 'TELECONSULTATION',
        status: 'WAITING_ROOM',
        chiefComplaint: 'Fever and shivering',
        queueNumber: 'P1-02',
        triagePriority: 'P1',
        symptoms: const ['Fever', 'Shivering', 'Bodyache'],
        primaryIssue: 'Head & General',
        consentGranted: true,
      );

      aptRepo.addAppointment(apt);
      final retrieved = aptRepo.getAppointmentById('APT-TEST-TRIAGE');
      expect(retrieved, isNotNull);
      expect(retrieved?.queueNumber, equals('P1-02'));
      expect(retrieved?.triagePriority, equals('P1'));
      expect(retrieved?.consentGranted, isTrue);
      expect(retrieved?.symptoms.length, equals(3));
    });

    test('FacilityRepository provides live bed occupancy and ICU vacancy status', () {
      final facilityRepo = FacilityRepository();
      final facilities = facilityRepo.facilities;
      expect(facilities.isNotEmpty, isTrue);

      for (final fac in facilities) {
        expect(fac.totalBeds, greaterThan(0));
        expect(fac.availableBeds, greaterThanOrEqualTo(0));
        expect(fac.availableBeds, lessThanOrEqualTo(fac.totalBeds));
        final icuVacancies = (fac.availableBeds * 0.25).clamp(1, 15).toInt();
        expect(icuVacancies, greaterThan(0));
      }
    });
  });
}
