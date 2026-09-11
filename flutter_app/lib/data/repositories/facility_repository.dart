import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/facility_dto.dart';

class FacilityRepository extends ChangeNotifier {
  static final FacilityRepository _instance = FacilityRepository._internal();
  factory FacilityRepository() => _instance;
  FacilityRepository._internal() {
    _loadInitialFacilities();
  }

  late List<FacilityDto> _facilities;
  List<FacilityDto> get facilities => _facilities;

  void _loadInitialFacilities() {
    _facilities = [
      const FacilityDto(
        id: 'FAC-SC-102',
        name: 'Kashti Sub-Centre (उप-केंद्र)',
        type: 'SUB_CENTRE',
        distanceKm: 1.2,
        address: 'Main Road, Kashti Village',
        contactPhone: '+91 2112 245001',
        totalBeds: 2,
        availableBeds: 1,
        onDutySpecialists: ['Community Health Officer (CHO)'],
        availableBloodUnits: {},
        availableDiagnostics: ['Rapid Blood Sugar', 'Urine Albumin', 'Rapid Malaria'],
        availableMedicines: ['Paracetamol', 'Iron & Folic Acid', 'ORS'],
        hasEmergencyCapability: false,
        hasAmbulanceAvailable: false,
      ),
      const FacilityDto(
        id: 'FAC-CHC-201',
        name: 'Daund Community Health Centre (CHC)',
        type: 'CHC',
        distanceKm: 12.0,
        address: 'Station Road, Daund',
        contactPhone: '+91 2117 262002',
        totalBeds: 30,
        availableBeds: 8,
        onDutySpecialists: ['General Physician', 'Medical Officer'],
        availableBloodUnits: {'O+': 2},
        availableDiagnostics: ['CBC (Complete Blood Count)', 'Blood Sugar', 'X-Ray'],
        availableMedicines: ['Paracetamol', 'Metformin', 'Amoxicillin', 'Iron & Folic Acid'],
        hasEmergencyCapability: true,
        hasAmbulanceAvailable: true,
      ),
      const FacilityDto(
        id: 'FAC-SDH-301',
        name: 'Baramati Sub-District Hospital (SDH)',
        type: 'SUB_DISTRICT_HOSPITAL',
        distanceKm: 24.5,
        address: 'MIDC Road, Baramati',
        contactPhone: '+91 2112 224003',
        totalBeds: 100,
        availableBeds: 22,
        onDutySpecialists: [
          'Obstetrician & Gynecologist (स्त्रीरोग तज्ज्ञ)',
          'Pediatrician (बालरोग तज्ज्ञ)',
          'General Surgeon'
        ],
        availableBloodUnits: {'O+': 8, 'A+': 5, 'B+': 6, 'AB+': 3},
        availableDiagnostics: [
          'CBC',
          'Ultrasound (USG)',
          'Blood Sugar',
          'ECG',
          'Liver Function',
          'Renal Function'
        ],
        availableMedicines: [
          'Nifedipine',
          'Labetalol',
          'Metformin',
          'Insulin',
          'Amoxicillin',
          'Iron Sucrose Injection',
          'Oxytocin'
        ],
        hasEmergencyCapability: true,
        hasAmbulanceAvailable: true,
      ),
      const FacilityDto(
        id: 'FAC-DH-401',
        name: 'Aundh District Hospital (जिल्हा रुग्णालय)',
        type: 'DISTRICT_HOSPITAL',
        distanceKm: 68.0,
        address: 'Aundh, Pune',
        contactPhone: '+91 20 27280004',
        totalBeds: 350,
        availableBeds: 64,
        onDutySpecialists: ['Cardiologist', 'Neurologist', 'OB/GYN', 'Pediatrician', 'Critical Care / ICU'],
        availableBloodUnits: {'O+': 20, 'O-': 4, 'A+': 15, 'B+': 18, 'AB+': 8},
        availableDiagnostics: ['CT Scan', 'MRI', 'Echocardiogram', 'Ultrasound', 'CBC'],
        availableMedicines: ['All Essential & Specialized Formulations'],
        hasEmergencyCapability: true,
        hasAmbulanceAvailable: true,
      ),
    ];
  }
}
