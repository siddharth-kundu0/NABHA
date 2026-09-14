import 'package:flutter/foundation.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FacilityRepository extends ChangeNotifier {
  static final FacilityRepository _instance = FacilityRepository._internal();
  factory FacilityRepository() => _instance;
  FacilityRepository._internal() {
    _loadInitialFacilities();
  }

  late List<FacilityDto> _facilities;
  List<FacilityDto> get facilities => _facilities;
  FacilityDto get currentFacility => _facilities.firstWhere((f) => f.id == 'FAC-SDH-301');
  FacilityDto? getFacilityById(String id) {
    try {
      return _facilities.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  // Live Inventory Items
  late List<FacilityInventoryItem> _inventory;
  List<FacilityInventoryItem> get inventory => _inventory;

  // Live Staff Roster
  late List<FacilityStaffMember> _staffRoster;
  List<FacilityStaffMember> get staffRoster => _staffRoster;

  // Discrepancy Reports
  final List<FacilityDiscrepancy> _discrepancies = [];
  List<FacilityDiscrepancy> get discrepancies => List.unmodifiable(_discrepancies);

  // Active Role Perspective
  String _activeStaffRole = 'Admin'; // Admin, Doctor, Pharmacist, Diagnostic, Nurse, Reception
  String get activeStaffRole => _activeStaffRole;
  String get activeRoleTitle {
    switch (_activeStaffRole) {
      case 'Doctor':
        return 'Medical Officer';
      case 'Pharmacist':
        return 'Chief Pharmacist';
      case 'Diagnostic':
      case 'Lab Technician':
        return 'Lab Diagnostics Officer';
      case 'Staff Nurse':
      case 'Nurse':
        return 'Staff Nurse / Ward Sister';
      case 'Reception':
      case 'Intake Clerk':
        return 'Reception & Intake Officer';
      default:
        return 'Facility Administrator';
    }
  }

  void setActiveStaffRole(String role) {
    _activeStaffRole = role;
    notifyListeners();
  }

  // Staff & Admin Credentials Access Requests
  final List<FacilityStaffRequestDto> _staffRequests = [];
  List<FacilityStaffRequestDto> get staffRequests => List.unmodifiable(_staffRequests);

  final List<FacilityStaffRequestDto> _adminRequests = [];
  List<FacilityStaffRequestDto> get adminRequests => List.unmodifiable(_adminRequests);

  FacilityStaffRequestDto? _currentStaffSession;
  FacilityStaffRequestDto? get currentStaffSession => _currentStaffSession;

  void setCurrentStaffSession(FacilityStaffRequestDto? session) {
    _currentStaffSession = session;
    if (session != null) {
      _activeStaffRole = session.role.shortName;
    }
    notifyListeners();
  }

  // Live E-Prescriptions & Diagnostic Test Orders
  final List<PrescriptionOrderDto> _prescriptionOrders = [];
  List<PrescriptionOrderDto> get prescriptionOrders => List.unmodifiable(_prescriptionOrders);

  final List<DiagnosticOrderDto> _diagnosticOrders = [];
  List<DiagnosticOrderDto> get diagnosticOrders => List.unmodifiable(_diagnosticOrders);

  List<FacilityStaffRequestDto> getPendingStaffRequestsForFacility(String facilityId) {
    return _staffRequests
        .where((r) => r.facilityId == facilityId && r.status == FacilityApprovalStatus.pendingFacilityAdmin)
        .toList();
  }

  List<FacilityStaffRequestDto> getAllStaffRequestsForFacility(String facilityId) {
    return _staffRequests.where((r) => r.facilityId == facilityId).toList();
  }

  List<FacilityStaffRequestDto> getPendingFacilityAdminRequests() {
    return _adminRequests
        .where((r) => r.status == FacilityApprovalStatus.pendingDistrictAdmin)
        .toList();
  }

  FacilityStaffRequestDto? getRequestById(String id) {
    try {
      return _staffRequests.firstWhere((r) => r.id == id);
    } catch (_) {
      try {
        return _adminRequests.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  FacilityStaffRequestDto? findStaffByMobileOrId({
    required String mobileOrId,
    required String facilityId,
    FacilityStaffRole? role,
  }) {
    final clean = mobileOrId.trim().toLowerCase();
    for (final r in _staffRequests) {
      if ((r.mobile == clean || r.licenseOrEmployeeId.toLowerCase() == clean) &&
          r.facilityId == facilityId &&
          (role == null || r.role == role)) {
        return r;
      }
    }
    for (final a in _adminRequests) {
      if ((a.mobile == clean || a.licenseOrEmployeeId.toLowerCase() == clean) &&
          a.facilityId == facilityId) {
        return a;
      }
    }
    return null;
  }

  FacilityStaffRequestDto? findAnyStaffByMobileOrId(String mobileOrId) {
    final clean = mobileOrId.trim().toLowerCase();
    for (final r in _staffRequests) {
      if (r.mobile == clean || r.licenseOrEmployeeId.toLowerCase() == clean) {
        return r;
      }
    }
    for (final a in _adminRequests) {
      if (a.mobile == clean || a.licenseOrEmployeeId.toLowerCase() == clean) {
        return a;
      }
    }
    for (final s in _staffRoster) {
      if (s.id.toLowerCase() == clean) {
        return FacilityStaffRequestDto(
          id: s.id,
          facilityId: currentFacility.id,
          facilityName: currentFacility.name,
          staffName: s.name,
          mobile: clean,
          role: FacilityStaffRole.staffNurse,
          licenseOrEmployeeId: s.id,
          department: s.designation,
          status: FacilityApprovalStatus.approved,
          submittedAt: DateTime.now(),
        );
      }
    }
    return null;
  }

  void submitStaffRequest(FacilityStaffRequestDto req) {
    _staffRequests.removeWhere((r) => r.id == req.id);
    _staffRequests.add(req);
    notifyListeners();
  }

  void approveStaffRequest(String requestId, {String? assignedRoom}) {
    final idx = _staffRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final old = _staffRequests[idx];
      final updated = old.copyWith(
        status: FacilityApprovalStatus.approved,
        assignedRoom: assignedRoom ?? old.department,
      );
      _staffRequests[idx] = updated;

      _staffRoster.removeWhere((s) => s.id == updated.id);
      _staffRoster.add(
        FacilityStaffMember(
          id: updated.id,
          name: updated.staffName,
          role: updated.role.shortName,
          designation: '${updated.role.displayName} (${updated.licenseOrEmployeeId})',
          assignedRoom: assignedRoom ?? updated.department,
          onDutyStatus: 'On Duty',
        ),
      );
      notifyListeners();
    }
  }

  void rejectStaffRequest(String requestId, String reason) {
    final idx = _staffRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _staffRequests[idx] = _staffRequests[idx].copyWith(
        status: FacilityApprovalStatus.rejected,
        rejectionReason: reason,
      );
      notifyListeners();
    }
  }

  void submitFacilityAdminRequest(FacilityStaffRequestDto req) {
    _adminRequests.removeWhere((r) => r.id == req.id);
    _adminRequests.add(req);
    notifyListeners();
  }

  void approveFacilityAdminRequest(String requestId) {
    final idx = _adminRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final old = _adminRequests[idx];
      _adminRequests[idx] = old.copyWith(
        status: FacilityApprovalStatus.approved,
      );
      notifyListeners();
    }
  }

  void rejectFacilityAdminRequest(String requestId, String reason) {
    final idx = _adminRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _adminRequests[idx] = _adminRequests[idx].copyWith(
        status: FacilityApprovalStatus.rejected,
        rejectionReason: reason,
      );
      notifyListeners();
    }
  }

  void dispensePrescription(String orderId) {
    final idx = _prescriptionOrders.indexWhere((p) => p.id == orderId);
    if (idx != -1) {
      _prescriptionOrders[idx] = _prescriptionOrders[idx].copyWith(status: 'DISPENSED');
      notifyListeners();
    }
  }

  void addPrescriptionOrder(PrescriptionOrderDto order) {
    _prescriptionOrders.add(order);
    notifyListeners();
  }

  void updateDiagnosticOrderStatus(String orderId, String newStatus, {String? result}) {
    final idx = _diagnosticOrders.indexWhere((d) => d.id == orderId);
    if (idx != -1) {
      _diagnosticOrders[idx] = _diagnosticOrders[idx].copyWith(
        status: newStatus,
        resultValue: result ?? _diagnosticOrders[idx].resultValue,
      );
      notifyListeners();
    }
  }

  void addDiagnosticOrder(DiagnosticOrderDto order) {
    _diagnosticOrders.add(order);
    notifyListeners();
  }

  // Handover state
  String _currentShift = 'Morning Shift: 08:00 - 16:00';
  String get currentShift => _currentShift;
  String _officerInCharge = 'Sister In-Charge: Sarita Patil, RN';
  String get officerInCharge => _officerInCharge;
  final List<String> _completedHandoverTasks = [
    'Medication cabinet keys verified',
    'Cold-chain ILR temperature verified (4.2°C)',
  ];
  List<String> get completedHandoverTasks => List.unmodifiable(_completedHandoverTasks);

  void toggleHandoverTask(String task) {
    if (_completedHandoverTasks.contains(task)) {
      _completedHandoverTasks.remove(task);
    } else {
      _completedHandoverTasks.add(task);
    }
    notifyListeners();
  }

  void performHandover({
    required String shift,
    required String officerInCharge,
    required List<String> checklistCompleted,
  }) {
    _currentShift = shift;
    _officerInCharge = officerInCharge;
    _completedHandoverTasks
      ..clear()
      ..addAll(checklistCompleted);
    notifyListeners();
  }

  void _loadInitialFacilities() {
    _loadInventoryData();
    _loadStaffRosterData();
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
        totalBeds: 50,
        availableBeds: 12,
        onDutySpecialists: [
          'Obstetrician & Gynecologist (स्त्रीरोग तज्ज्ञ)',
          'Pediatrician (बालरोग तज्ज्ञ)',
          'Pulmonology / Emergency Medicine',
          'General Surgeon'
        ],
        availableBloodUnits: {'O+': 8, 'A+': 5, 'B+': 6, 'AB+': 3, 'O-': 2},
        availableDiagnostics: [
          'CBC',
          'Ultrasound (USG)',
          'Blood Sugar',
          'ECG',
          'Liver Function',
          'Renal Function',
          'Sputum AFB'
        ],
        availableMedicines: [
          'Paracetamol 500mg',
          'Amoxicillin 250mg',
          'ORS Packets',
          'Metformin 500mg',
          'IFA Tablets',
          'Rabies Vaccine',
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

  void _loadInventoryData() {
    _inventory = [
      // 1. Medicines
      const FacilityInventoryItem(
        id: 'med-01',
        name: 'Paracetamol 500mg',
        category: 'MEDICINES',
        description: 'Adequate stock • Dispensary & maternity clinic stock',
        status: 'AVAILABLE',
        stockOnHand: 1400,
        reorderThreshold: 200,
        batchNumber: 'PCM-2026-B8',
        expiryDate: '12/2027',
      ),
      const FacilityInventoryItem(
        id: 'med-02',
        name: 'Amoxicillin 250mg',
        category: 'MEDICINES',
        description: 'Reorder requested • Pediatric & respiratory antibiotic',
        status: 'LOW_STOCK',
        stockOnHand: 24,
        reorderThreshold: 100,
        batchNumber: 'AMX-2025-A1',
        expiryDate: '08/2026',
      ),
      const FacilityInventoryItem(
        id: 'med-03',
        name: 'ORS Packets',
        category: 'MEDICINES',
        description: 'Replenishment pending • WHO Oral rehydration formula',
        status: 'LOW_STOCK',
        stockOnHand: 45,
        reorderThreshold: 150,
        batchNumber: 'ORS-2026-C4',
        expiryDate: '04/2028',
      ),
      const FacilityInventoryItem(
        id: 'med-04',
        name: 'Metformin 500mg',
        category: 'MEDICINES',
        description: 'Regular stock • Chronic disease diabetes maintenance',
        status: 'AVAILABLE',
        stockOnHand: 850,
        reorderThreshold: 100,
        batchNumber: 'MET-2026-F2',
        expiryDate: '11/2027',
      ),
      const FacilityInventoryItem(
        id: 'med-05',
        name: 'IFA Tablets',
        category: 'MEDICINES',
        description: 'Maternal health supply • Iron & Folic acid prophylaxis',
        status: 'AVAILABLE',
        stockOnHand: 2200,
        reorderThreshold: 300,
        batchNumber: 'IFA-2026-K9',
        expiryDate: '01/2028',
      ),
      const FacilityInventoryItem(
        id: 'med-06',
        name: 'Rabies Vaccine',
        category: 'MEDICINES',
        description: 'Cold-chain restock scheduled • Post-exposure prophylaxis',
        status: 'UNAVAILABLE',
        stockOnHand: 0,
        reorderThreshold: 20,
        batchNumber: 'ARV-2026-R1',
        expiryDate: '09/2026',
      ),

      // 2. Diagnostics
      const FacilityInventoryItem(
        id: 'diag-01',
        name: 'Hemoglobin (CBC / Strip)',
        category: 'DIAGNOSTICS',
        description: 'Reagents verified • Microcuvettes & Sahli hemometer',
        status: 'AVAILABLE',
        stockOnHand: 320,
        reorderThreshold: 50,
        batchNumber: 'HB-2026-X1',
        expiryDate: '10/2027',
      ),
      const FacilityInventoryItem(
        id: 'diag-02',
        name: 'Blood Glucose Rapid',
        category: 'DIAGNOSTICS',
        description: 'Test strips active • Point-of-care capillary glucose',
        status: 'AVAILABLE',
        stockOnHand: 450,
        reorderThreshold: 50,
        batchNumber: 'GLU-2026-T5',
        expiryDate: '06/2027',
      ),
      const FacilityInventoryItem(
        id: 'diag-03',
        name: 'Malaria Rapid Test Kit',
        category: 'DIAGNOSTICS',
        description: 'Stock adequate • Pf/Pv dual antigen test cassette',
        status: 'AVAILABLE',
        stockOnHand: 180,
        reorderThreshold: 30,
        batchNumber: 'MAL-2026-M3',
        expiryDate: '03/2028',
      ),
      const FacilityInventoryItem(
        id: 'diag-04',
        name: 'Urine Albumin / Sugar',
        category: 'DIAGNOSTICS',
        description: 'Microcuvettes low • Multi-parameter diagnostic strip',
        status: 'LOW_STOCK',
        stockOnHand: 28,
        reorderThreshold: 80,
        batchNumber: 'URN-2026-U2',
        expiryDate: '07/2026',
      ),
      const FacilityInventoryItem(
        id: 'diag-05',
        name: 'Sputum AFB Collection',
        category: 'DIAGNOSTICS',
        description: 'Sample courier pickup 2:00 PM • Presumptive TB screening',
        status: 'UPDATE_REQUIRED',
        stockOnHand: 15,
        reorderThreshold: 40,
        batchNumber: 'AFB-2026-S9',
        expiryDate: '12/2026',
      ),

      // 3. Clinical Services
      const FacilityInventoryItem(
        id: 'serv-01',
        name: 'General OPD Clinic',
        category: 'CLINICAL_SERVICES',
        description: 'Mon–Sat, 9:00 AM – 2:00 PM • Room 2',
        status: 'AVAILABLE',
        stockOnHand: 1,
        reorderThreshold: 0,
        batchNumber: 'OPD-G1',
        expiryDate: 'Continuous',
      ),
      const FacilityInventoryItem(
        id: 'serv-02',
        name: 'MCH & Immunization',
        category: 'CLINICAL_SERVICES',
        description: 'Every Wednesday & Friday • Room 1',
        status: 'AVAILABLE',
        stockOnHand: 1,
        reorderThreshold: 0,
        batchNumber: 'MCH-ANC',
        expiryDate: 'Continuous',
      ),
      const FacilityInventoryItem(
        id: 'serv-03',
        name: '24x7 Emergency Stabilization',
        category: 'CLINICAL_SERVICES',
        description: 'Medical Officer on duty • ER Suite (4/6 Occupied)',
        status: 'AVAILABLE',
        stockOnHand: 6,
        reorderThreshold: 2,
        batchNumber: 'EMR-24',
        expiryDate: 'Continuous',
      ),
      const FacilityInventoryItem(
        id: 'serv-04',
        name: 'Telemedicine Consultation',
        category: 'CLINICAL_SERVICES',
        description: 'High-speed link connected • Virtual specialist link',
        status: 'AVAILABLE',
        stockOnHand: 1,
        reorderThreshold: 0,
        batchNumber: 'TEL-SAT',
        expiryDate: 'Continuous',
      ),

      // 4. Blood Bank
      const FacilityInventoryItem(
        id: 'blood-01',
        name: 'Blood Group O+ Positive',
        category: 'BLOOD_BANK',
        description: 'Whole blood PRBC units • Screened & refrigerated',
        status: 'AVAILABLE',
        stockOnHand: 8,
        reorderThreshold: 4,
        batchNumber: 'BLD-OP-24',
        expiryDate: '35 Days',
      ),
      const FacilityInventoryItem(
        id: 'blood-02',
        name: 'Blood Group A+ Positive',
        category: 'BLOOD_BANK',
        description: 'Whole blood PRBC units • Screened & refrigerated',
        status: 'AVAILABLE',
        stockOnHand: 5,
        reorderThreshold: 3,
        batchNumber: 'BLD-AP-24',
        expiryDate: '28 Days',
      ),
      const FacilityInventoryItem(
        id: 'blood-03',
        name: 'Blood Group B+ Positive',
        category: 'BLOOD_BANK',
        description: 'Whole blood PRBC units • Screened & refrigerated',
        status: 'AVAILABLE',
        stockOnHand: 6,
        reorderThreshold: 3,
        batchNumber: 'BLD-BP-24',
        expiryDate: '30 Days',
      ),
      const FacilityInventoryItem(
        id: 'blood-04',
        name: 'Blood Group AB+ Positive',
        category: 'BLOOD_BANK',
        description: 'Whole blood PRBC units • Screened & refrigerated',
        status: 'AVAILABLE',
        stockOnHand: 3,
        reorderThreshold: 2,
        batchNumber: 'BLD-ABP-24',
        expiryDate: '21 Days',
      ),
      const FacilityInventoryItem(
        id: 'blood-05',
        name: 'Blood Group O- Negative (Rare)',
        category: 'BLOOD_BANK',
        description: 'Universal donor PRBC units • Emergency reserved',
        status: 'LOW_STOCK',
        stockOnHand: 2,
        reorderThreshold: 3,
        batchNumber: 'BLD-ON-24',
        expiryDate: '18 Days',
      ),
    ];
  }

  void _loadStaffRosterData() {
    _staffRoster = [];
  }

  void resetToDefaults() {
    _loadInitialFacilities();
    _loadInventoryData();
    _loadStaffRosterData();
    _discrepancies.clear();
    _staffRequests.clear();
    _adminRequests.clear();
    _prescriptionOrders.clear();
    _diagnosticOrders.clear();
    _currentStaffSession = null;
    _activeStaffRole = 'Admin';
    notifyListeners();
  }

  void addApprovedDoctor({
    required String facilityId,
    required String doctorId,
    required String doctorName,
    required String specialty,
    required String qualification,
  }) {
    _staffRoster.add(
      FacilityStaffMember(
        id: doctorId,
        name: doctorName,
        role: 'Doctor',
        designation: '$specialty ($qualification)',
        assignedRoom: 'OPD Consultation Room',
        onDutyStatus: 'On Duty',
      ),
    );
    final idx = _facilities.indexWhere((f) => f.id == facilityId);
    if (idx != -1) {
      final old = _facilities[idx];
      if (!old.onDutySpecialists.contains(specialty)) {
        final updatedSpecs = List<String>.from(old.onDutySpecialists)..add(specialty);
        _facilities[idx] = FacilityDto(
          id: old.id,
          name: old.name,
          type: old.type,
          distanceKm: old.distanceKm,
          address: old.address,
          contactPhone: old.contactPhone,
          totalBeds: old.totalBeds,
          availableBeds: old.availableBeds,
          onDutySpecialists: updatedSpecs,
          availableBloodUnits: old.availableBloodUnits,
          availableDiagnostics: old.availableDiagnostics,
          availableMedicines: old.availableMedicines,
          hasEmergencyCapability: old.hasEmergencyCapability,
          hasAmbulanceAvailable: old.hasAmbulanceAvailable,
        );
      }
    }
    notifyListeners();
  }

  void updateAvailableBeds(String facilityId, int availableBeds) {
    final idx = _facilities.indexWhere((f) => f.id == facilityId);
    if (idx != -1) {
      final old = _facilities[idx];
      _facilities[idx] = FacilityDto(
        id: old.id,
        name: old.name,
        type: old.type,
        distanceKm: old.distanceKm,
        address: old.address,
        contactPhone: old.contactPhone,
        totalBeds: old.totalBeds,
        availableBeds: availableBeds,
        onDutySpecialists: old.onDutySpecialists,
        availableBloodUnits: old.availableBloodUnits,
        availableDiagnostics: old.availableDiagnostics,
        availableMedicines: old.availableMedicines,
        hasEmergencyCapability: old.hasEmergencyCapability,
        hasAmbulanceAvailable: old.hasAmbulanceAvailable,
      );
      try {
        FirebaseFirestore.instance
            .collection('facilities')
            .doc(facilityId)
            .set({'availableBeds': availableBeds}, SetOptions(merge: true));
      } catch (_) {}
      notifyListeners();
    }
  }

  void addFacility(FacilityDto facility) {
    _facilities.add(facility);
    notifyListeners();
  }

  void addStaffMember(FacilityStaffMember staff) {
    _staffRoster.add(staff);
    notifyListeners();
  }

  void updateInventoryItem(
    String id, {
    String? status,
    int? stockOnHand,
    String? batchNumber,
    String? expiryDate,
  }) {
    final idx = _inventory.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final old = _inventory[idx];
      _inventory[idx] = old.copyWith(
        status: status,
        stockOnHand: stockOnHand,
        batchNumber: batchNumber,
        expiryDate: expiryDate,
      );
      notifyListeners();
    }
  }

  void reportDiscrepancy({
    required String itemId,
    required String itemName,
    required String reason,
    required String reporter,
  }) {
    _discrepancies.insert(
      0,
      FacilityDiscrepancy(
        id: 'DISC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        itemId: itemId,
        itemName: itemName,
        reason: reason,
        reporter: reporter,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void reassignStaff({
    required String staffId,
    required String newRoom,
  }) {
    final idx = _staffRoster.indexWhere((s) => s.id == staffId);
    if (idx != -1) {
      final old = _staffRoster[idx];
      _staffRoster[idx] = old.copyWith(assignedRoom: newRoom);
      notifyListeners();
    }
  }

  // Track active blood unit reservations by referralId
  final Map<String, Map<String, int>> _bloodReservations = {};
  Map<String, Map<String, int>> get bloodReservations => Map.unmodifiable(_bloodReservations);

  bool reserveBloodUnits(Map<String, int> units, {required String referralId, String facilityId = 'FAC-SDH-301'}) {
    final facIdx = _facilities.indexWhere((f) => f.id == facilityId);
    if (facIdx == -1) return false;
    final fac = _facilities[facIdx];

    // Check availability
    for (final entry in units.entries) {
      final available = fac.availableBloodUnits[entry.key] ?? 0;
      if (available < entry.value) {
        return false;
      }
    }

    // Deduct and update inventory
    final updatedBlood = Map<String, int>.from(fac.availableBloodUnits);
    for (final entry in units.entries) {
      updatedBlood[entry.key] = (updatedBlood[entry.key] ?? 0) - entry.value;

      final invIdx = _inventory.indexWhere((i) => i.category == 'BLOOD_BANK' && i.name.contains(entry.key));
      if (invIdx != -1) {
        final invItem = _inventory[invIdx];
        final newStock = (invItem.stockOnHand - entry.value).clamp(0, 9999);
        _inventory[invIdx] = invItem.copyWith(
          stockOnHand: newStock,
          status: newStock <= invItem.reorderThreshold ? 'LOW_STOCK' : 'AVAILABLE',
        );
      }
    }

    _facilities[facIdx] = FacilityDto(
      id: fac.id,
      name: fac.name,
      type: fac.type,
      distanceKm: fac.distanceKm,
      address: fac.address,
      contactPhone: fac.contactPhone,
      totalBeds: fac.totalBeds,
      availableBeds: fac.availableBeds,
      onDutySpecialists: fac.onDutySpecialists,
      availableBloodUnits: updatedBlood,
      availableDiagnostics: fac.availableDiagnostics,
      availableMedicines: fac.availableMedicines,
      hasEmergencyCapability: fac.hasEmergencyCapability,
      hasAmbulanceAvailable: fac.hasAmbulanceAvailable,
    );

    _bloodReservations[referralId] = units;
    notifyListeners();
    return true;
  }

  void releaseBloodUnits(Map<String, int> units, {required String referralId, String facilityId = 'FAC-SDH-301'}) {
    final facIdx = _facilities.indexWhere((f) => f.id == facilityId);
    if (facIdx == -1) return;
    final fac = _facilities[facIdx];

    final updatedBlood = Map<String, int>.from(fac.availableBloodUnits);
    for (final entry in units.entries) {
      updatedBlood[entry.key] = (updatedBlood[entry.key] ?? 0) + entry.value;

      final invIdx = _inventory.indexWhere((i) => i.category == 'BLOOD_BANK' && i.name.contains(entry.key));
      if (invIdx != -1) {
        final invItem = _inventory[invIdx];
        final newStock = invItem.stockOnHand + entry.value;
        _inventory[invIdx] = invItem.copyWith(
          stockOnHand: newStock,
          status: newStock <= invItem.reorderThreshold ? 'LOW_STOCK' : 'AVAILABLE',
        );
      }
    }

    _facilities[facIdx] = FacilityDto(
      id: fac.id,
      name: fac.name,
      type: fac.type,
      distanceKm: fac.distanceKm,
      address: fac.address,
      contactPhone: fac.contactPhone,
      totalBeds: fac.totalBeds,
      availableBeds: fac.availableBeds,
      onDutySpecialists: fac.onDutySpecialists,
      availableBloodUnits: updatedBlood,
      availableDiagnostics: fac.availableDiagnostics,
      availableMedicines: fac.availableMedicines,
      hasEmergencyCapability: fac.hasEmergencyCapability,
      hasAmbulanceAvailable: fac.hasAmbulanceAvailable,
    );

    _bloodReservations.remove(referralId);
    notifyListeners();
  }

  bool _isClusterSyncing = false;
  bool get isClusterSyncing => _isClusterSyncing;

  Future<void> forceClusterSync() async {
    _isClusterSyncing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _isClusterSyncing = false;
    notifyListeners();
  }
}

class FacilityInventoryItem {
  final String id;
  final String name;
  final String category; // MEDICINES, DIAGNOSTICS, CLINICAL_SERVICES, BLOOD_BANK
  final String description;
  final String status; // AVAILABLE, LOW_STOCK, UNAVAILABLE, UPDATE_REQUIRED
  final int stockOnHand;
  final int reorderThreshold;
  final String batchNumber;
  final String expiryDate;

  const FacilityInventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.status,
    required this.stockOnHand,
    required this.reorderThreshold,
    required this.batchNumber,
    required this.expiryDate,
  });

  FacilityInventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? status,
    int? stockOnHand,
    int? reorderThreshold,
    String? batchNumber,
    String? expiryDate,
  }) =>
      FacilityInventoryItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        status: status ?? this.status,
        stockOnHand: stockOnHand ?? this.stockOnHand,
        reorderThreshold: reorderThreshold ?? this.reorderThreshold,
        batchNumber: batchNumber ?? this.batchNumber,
        expiryDate: expiryDate ?? this.expiryDate,
      );
}

class FacilityStaffMember {
  final String id;
  final String name;
  final String role; // Doctor, Nurse, Pharmacist, Diagnostic, Admin
  final String designation;
  final String assignedRoom;
  final String onDutyStatus; // On Duty, On Call, Relieved

  const FacilityStaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.designation,
    required this.assignedRoom,
    required this.onDutyStatus,
  });

  FacilityStaffMember copyWith({
    String? id,
    String? name,
    String? role,
    String? designation,
    String? assignedRoom,
    String? onDutyStatus,
  }) =>
      FacilityStaffMember(
        id: id ?? this.id,
        name: name ?? this.name,
        role: role ?? this.role,
        designation: designation ?? this.designation,
        assignedRoom: assignedRoom ?? this.assignedRoom,
        onDutyStatus: onDutyStatus ?? this.onDutyStatus,
      );
}

class FacilityDiscrepancy {
  final String id;
  final String itemId;
  final String itemName;
  final String reason;
  final String reporter;
  final DateTime timestamp;

  const FacilityDiscrepancy({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.reason,
    required this.reporter,
    required this.timestamp,
  });
}
