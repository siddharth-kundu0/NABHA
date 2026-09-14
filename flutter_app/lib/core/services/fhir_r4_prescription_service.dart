import 'dart:convert';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';

class FhirR4PrescriptionService {
  static final FhirR4PrescriptionService _instance = FhirR4PrescriptionService._internal();
  factory FhirR4PrescriptionService() => _instance;
  FhirR4PrescriptionService._internal();

  /// Authors an ABDM-compliant FHIR R4 E-Prescription Bundle
  Map<String, dynamic> buildAbdmFhirR4Bundle({
    required PrescriptionDto rx,
    required PatientDto patient,
    required String doctorSpecialty,
    required String doctorRegistrationNumber,
    required String facilityName,
    String encounterType = 'VR', // Virtual Encounter / Teleconsultation
  }) {
    final bundleId = 'urn:uuid:${rx.id.toLowerCase()}';
    final timestamp = rx.issuedAt.toIso8601String();
    final patientRef = 'Patient/${patient.id}';
    final practitionerRef = 'Practitioner/DOC-${doctorRegistrationNumber.replaceAll(' ', '-')}';

    final entries = <Map<String, dynamic>>[];

    // 1. Composition Resource (ABDM Prescription Document Header)
    entries.add({
      'fullUrl': 'urn:uuid:composition-${rx.id}',
      'resource': {
        'resourceType': 'Composition',
        'id': 'composition-${rx.id}',
        'status': 'final',
        'type': {
          'coding': [
            {
              'system': 'https://projecteka.in/snomed',
              'code': '440545006',
              'display': 'Prescription record',
            }
          ],
          'text': 'Prescription',
        },
        'subject': {'reference': patientRef, 'display': patient.fullName},
        'date': timestamp,
        'author': [
          {'reference': practitionerRef, 'display': rx.doctorName}
        ],
        'title': 'ABDM FHIR R4 E-Prescription',
        'section': [
          {
            'title': 'Chief Complaints & Clinical Diagnosis',
            'code': {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '422843007',
                  'display': 'Diagnostic section',
                }
              ]
            },
            'text': {'status': 'generated', 'div': '<div>${rx.diagnosis}</div>'},
          },
          {
            'title': 'Medications Prescribed',
            'code': {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '10036007',
                  'display': 'Medication history',
                }
              ]
            },
            'entry': rx.medicines
                .asMap()
                .entries
                .map((e) => {'reference': 'urn:uuid:medrx-${rx.id}-${e.key}'})
                .toList(),
          }
        ],
      },
    });

    // 2. Practitioner Resource
    entries.add({
      'fullUrl': practitionerRef,
      'resource': {
        'resourceType': 'Practitioner',
        'id': practitionerRef.replaceAll('Practitioner/', ''),
        'identifier': [
          {
            'system': 'https://doctor.ndhm.gov.in',
            'value': doctorRegistrationNumber,
          }
        ],
        'name': [
          {'text': rx.doctorName}
        ],
        'qualification': [
          {
            'code': {
              'text': doctorSpecialty,
            }
          }
        ],
      },
    });

    // 3. Patient Resource
    entries.add({
      'fullUrl': patientRef,
      'resource': {
        'resourceType': 'Patient',
        'id': patient.id,
        'identifier': [
          {
            'system': 'https://healthid.ndhm.gov.in',
            'value': patient.abhaId.isNotEmpty ? patient.abhaId : 'ABHA-${patient.ruralCareId}',
          },
          {
            'system': 'https://ruralcare.gov.in/beneficiary',
            'value': patient.ruralCareId,
          }
        ],
        'name': [
          {'text': patient.fullName}
        ],
        'gender': patient.gender.toLowerCase(),
        'address': [
          {
            'city': patient.village,
            'district': patient.district,
            'state': 'Maharashtra',
            'country': 'IN',
          }
        ],
      },
    });

    // 4. Encounter Resource
    entries.add({
      'fullUrl': 'urn:uuid:encounter-${rx.id}',
      'resource': {
        'resourceType': 'Encounter',
        'id': 'encounter-${rx.id}',
        'status': 'finished',
        'class': {
          'system': 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
          'code': encounterType,
          'display': encounterType == 'VR' ? 'Virtual Encounter' : 'Ambulatory Encounter',
        },
        'subject': {'reference': patientRef},
        'serviceProvider': {'display': facilityName},
        'period': {'start': timestamp, 'end': timestamp},
      },
    });

    // 5. Condition Resource (Clinical Diagnosis)
    entries.add({
      'fullUrl': 'urn:uuid:condition-${rx.id}',
      'resource': {
        'resourceType': 'Condition',
        'id': 'condition-${rx.id}',
        'clinicalStatus': {
          'coding': [
            {
              'system': 'http://terminology.hl7.org/CodeSystem/condition-clinical',
              'code': 'active',
            }
          ]
        },
        'code': {
          'text': rx.diagnosis,
        },
        'subject': {'reference': patientRef},
      },
    });

    // 6. MedicationRequest Resources
    for (int i = 0; i < rx.medicines.length; i++) {
      final med = rx.medicines[i];
      entries.add({
        'fullUrl': 'urn:uuid:medrx-${rx.id}-$i',
        'resource': {
          'resourceType': 'MedicationRequest',
          'id': 'medrx-${rx.id}-$i',
          'status': 'active',
          'intent': 'order',
          'medicationCodeableConcept': {
            'text': med.medicineName,
          },
          'subject': {'reference': patientRef},
          'authoredOn': timestamp,
          'requester': {'reference': practitionerRef, 'display': rx.doctorName},
          'dosageInstruction': [
            {
              'text': '${med.dosage}, ${med.frequency} for ${med.durationDays} days',
              'timing': {
                'code': {'text': med.frequency},
              },
            }
          ],
          'dispenseRequest': {
            'expectedSupplyDuration': {
              'value': med.durationDays,
              'unit': 'days',
              'system': 'http://unitsofmeasure.org',
              'code': 'd',
            }
          },
        },
      });
    }

    return {
      'resourceType': 'Bundle',
      'id': bundleId,
      'meta': {
        'versionId': '1',
        'lastUpdated': timestamp,
        'profile': [
          'https://nrces.in/ndhm/fhir/r4/StructureDefinition/PrescriptionRecord'
        ],
      },
      'identifier': {
        'system': 'https://abdm.gov.in/prescription',
        'value': rx.id,
      },
      'type': 'document',
      'timestamp': timestamp,
      'entry': entries,
    };
  }

  String formatAsPrettyJson(Map<String, dynamic> bundle) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(bundle);
  }

  String buildFhirJsonString(Map<String, dynamic> bundle) {
    return formatAsPrettyJson(bundle);
  }
}
