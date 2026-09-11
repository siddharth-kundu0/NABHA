import 'package:flutter/foundation.dart';
import '../models/appointment_dto.dart';
import '../../core/database/local_cache.dart';

class AppointmentRepository extends ChangeNotifier {
  static final AppointmentRepository _instance = AppointmentRepository._internal();
  factory AppointmentRepository() => _instance;
  AppointmentRepository._internal() {
    _loadInitialData();
  }

  final LocalCacheService _cache = LocalCacheService();
  late List<AppointmentDto> _appointments;
  late List<PrescriptionDto> _prescriptions;

  List<AppointmentDto> get appointments => _appointments;
  List<PrescriptionDto> get prescriptions => _prescriptions;

  void _loadInitialData() {
    _appointments = [
      AppointmentDto(
        id: 'APT-901',
        patientId: 'pat-001',
        patientName: 'Kavita Rajesh Devi',
        doctorName: 'Dr. Anjali Patil (OB/GYN)',
        specialty: 'Obstetrics & Gynecology',
        facilityName: 'Baramati Sub-District Hospital',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        type: 'TELECONSULTATION',
        status: 'WAITING_ROOM',
        chiefComplaint: 'Severe headache, blurred vision, elevated BP 148/96',
      ),
    ];

    _prescriptions = [
      PrescriptionDto(
        id: 'RX-4401',
        patientId: 'pat-001',
        doctorName: 'Dr. Anjali Patil',
        diagnosis: 'Gestational Hypertension (32 Wks) + Nutritional Anaemia',
        medicines: const [
          PrescriptionItemDto(
            medicineName: 'Tab. Labetalol 100mg',
            dosage: '100 mg',
            frequency: '1-0-1 (Twice daily after food)',
            durationDays: 14,
          ),
          PrescriptionItemDto(
            medicineName: 'Tab. Iron & Folic Acid (IFA)',
            dosage: '100mg Elemental Iron',
            frequency: '0-0-1 (Once daily at bedtime)',
            durationDays: 30,
          ),
        ],
        adviceNotes: 'Bed rest. Low salt diet. Measure BP daily via local ASHA worker.',
        issuedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  void addPrescription(PrescriptionDto rx) {
    _prescriptions.insert(0, rx);
    if (_cache.isOffline) {
      _cache.queueMutation('PRESCRIPTION', 'CREATE', rx.toJson());
    }
    notifyListeners();
  }

  void addAppointment(AppointmentDto apt) {
    _appointments.insert(0, apt);
    if (_cache.isOffline) {
      _cache.queueMutation('APPOINTMENT', 'CREATE', apt.toJson());
    }
    notifyListeners();
  }
}
