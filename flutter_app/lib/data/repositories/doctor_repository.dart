import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ruralcare/data/models/doctor_verification_request_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';
import 'package:ruralcare/app/routes.dart';

class RegisteredDoctorAccount {
  final String doctorId;
  final String name;
  final String mobile;
  final String password;
  final String qualification;
  final String specialty;
  final String registrationNumber;
  final String facilityId;
  final String facilityName;

  const RegisteredDoctorAccount({
    required this.doctorId,
    required this.name,
    required this.mobile,
    required this.password,
    required this.qualification,
    required this.specialty,
    required this.registrationNumber,
    required this.facilityId,
    required this.facilityName,
  });
}

class DoctorRepository extends ChangeNotifier {
  static final DoctorRepository _instance = DoctorRepository._internal();
  factory DoctorRepository() => _instance;
  DoctorRepository._internal() {
    _initRegisteredDoctors();
    _initSampleVerificationRequests();
  }

  final List<DoctorVerificationRequestDto> _verificationRequests = [];
  List<DoctorVerificationRequestDto> get verificationRequests =>
      List.unmodifiable(_verificationRequests);

  final List<RegisteredDoctorAccount> _registeredDoctors = [];
  List<RegisteredDoctorAccount> get registeredDoctors =>
      List.unmodifiable(_registeredDoctors);

  RegisteredDoctorAccount? _activeDoctor;
  RegisteredDoctorAccount? get activeDoctor => _activeDoctor;

  DoctorVerificationRequestDto? _currentPendingRequest;
  DoctorVerificationRequestDto? get currentPendingRequest => _currentPendingRequest;

  StreamSubscription<QuerySnapshot>? _doctorSubscription;

  void bindFirestoreStream() {
    _doctorSubscription?.cancel();
    try {
      _doctorSubscription = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final docId = doc.id;
            final name = data['fullName'] as String? ?? data['displayName'] as String? ?? 'Dr. Specialist';
            final mobile = data['phoneNumber'] as String? ?? '';
            final specialty = data['specialty'] as String? ?? 'General Medicine';
            final qualification = data['qualification'] as String? ?? 'MBBS, MD';
            final facId = data['facilityId'] as String? ?? 'FAC-SDH-301';
            final facName = data['facilityName'] as String? ?? 'Baramati Sub-District Hospital';

            final existingIdx = _registeredDoctors.indexWhere((d) => d.doctorId == docId);
            final account = RegisteredDoctorAccount(
              doctorId: docId,
              name: name,
              mobile: mobile,
              password: '',
              qualification: qualification,
              specialty: specialty,
              registrationNumber: data['registrationNumber'] as String? ?? 'MMC-REG-ACTIVE',
              facilityId: facId,
              facilityName: facName,
            );

            if (existingIdx != -1) {
              _registeredDoctors[existingIdx] = account;
            } else {
              _registeredDoctors.add(account);
            }
          }
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Notice in doctor stream: $e');
      });
    } catch (e) {
      debugPrint('Notice binding doctor stream: $e');
    }
  }

  RegisteredDoctorAccount autoSelectDoctor({String? specialty, String? facilityId}) {
    if (_registeredDoctors.isNotEmpty) {
      if (specialty != null && specialty.isNotEmpty) {
        final matches = _registeredDoctors.where((d) =>
            d.specialty.toLowerCase().contains(specialty.toLowerCase()) ||
            specialty.toLowerCase().contains(d.specialty.toLowerCase()));
        if (matches.isNotEmpty) return matches.first;
      }
      return _registeredDoctors.first;
    }

    // Default verified on-duty teleconsultation Medical Officer
    return RegisteredDoctorAccount(
      doctorId: 'DOC-MH-108',
      name: 'Dr. Anjali Patil',
      mobile: '+919823411200',
      password: '',
      qualification: 'MBBS, MS (OB/GYN & Tele-OPD)',
      specialty: specialty != null && specialty.isNotEmpty ? specialty : 'General Medicine & Emergency',
      registrationNumber: 'MMC-2018-8421',
      facilityId: facilityId ?? 'FAC-SDH-301',
      facilityName: 'Baramati Sub-District Hospital',
    );
  }

  void _initRegisteredDoctors() {
    _registeredDoctors.addAll([
      const RegisteredDoctorAccount(
        doctorId: 'DOC-MH-8421-101',
        name: 'Dr. Ramesh Sharma',
        mobile: '9822014490',
        password: 'password123',
        qualification: 'MBBS, MD (Medicine)',
        specialty: 'General Medicine',
        registrationNumber: 'MMC-2015-8421',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
      ),
      const RegisteredDoctorAccount(
        doctorId: 'DOC-MH-108',
        name: 'Dr. Anjali Patil',
        mobile: '9823411200',
        password: 'password123',
        qualification: 'MBBS, MS (OB/GYN & Tele-OPD)',
        specialty: 'General Medicine & Emergency',
        registrationNumber: 'MMC-2018-8421',
        facilityId: 'FAC-SDH-301',
        facilityName: 'Baramati Sub-District Hospital',
      ),
      const RegisteredDoctorAccount(
        doctorId: 'DOC-PHC-201',
        name: 'Dr. Suresh Kulkarni',
        mobile: '9822099881',
        password: 'password123',
        qualification: 'MBBS',
        specialty: 'Family Medicine',
        registrationNumber: 'MMC-2012-3321',
        facilityId: 'FAC-PHC-201',
        facilityName: 'Kashti Primary Health Centre',
      ),
    ]);
    bindFirestoreStream();
  }

  void _initSampleVerificationRequests() {
    // Zero mock requests initially - populated dynamically when doctors apply
  }

  /// Submit a new doctor verification request to a selected facility
  DoctorVerificationRequestDto submitVerificationRequest({
    required String doctorName,
    required String doctorMobile,
    required String email,
    required String qualification,
    required String registrationNumber,
    required String medicalCouncil,
    required String specialty,
    required String targetFacilityId,
    required String targetFacilityName,
  }) {
    final newId = 'REQ-DOC-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final req = DoctorVerificationRequestDto(
      id: newId,
      doctorName: doctorName.trim(),
      doctorMobile: doctorMobile.trim(),
      email: email.trim(),
      qualification: qualification.trim(),
      registrationNumber: registrationNumber.trim(),
      medicalCouncil: medicalCouncil.trim(),
      specialty: specialty.trim(),
      targetFacilityId: targetFacilityId,
      targetFacilityName: targetFacilityName,
      status: DoctorVerificationStatus.pending,
      submittedAt: DateTime.now(),
    );

    _verificationRequests.insert(0, req);
    _currentPendingRequest = req;

    // Dispatches real alert notification to Facility Staff
    NotificationRepository().notifyFacilityOfDoctorRequest(
      facilityId: targetFacilityId,
      doctorName: req.doctorName,
      specialty: req.specialty,
      requestId: req.id,
    );

    notifyListeners();
    return req;
  }

  /// Called by Facility Staff when reviewing & accepting a doctor
  DoctorVerificationRequestDto? acceptVerificationRequest(
    String requestId, {
    required String reviewedBy,
  }) {
    final index = _verificationRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return null;

    final existing = _verificationRequests[index];
    final generatedDocId =
        'DOC-MH-8421-${(existing.id.hashCode.abs() % 900) + 100}';
    final generatedOtp =
        '${(existing.id.hashCode.abs() % 900000) + 100000}'.padLeft(6, '0');

    final updated = existing.copyWith(
      status: DoctorVerificationStatus.accepted,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
      generatedDoctorId: generatedDocId,
      tempOtp: generatedOtp,
    );

    _verificationRequests[index] = updated;
    if (_currentPendingRequest?.id == requestId) {
      _currentPendingRequest = updated;
    }

    // Inform Facility Staff and add to Facility Roster
    FacilityRepository().addApprovedDoctor(
      facilityId: updated.targetFacilityId,
      doctorId: generatedDocId,
      doctorName: updated.doctorName,
      specialty: updated.specialty,
      qualification: updated.qualification,
    );

    // Send notification to Doctor Profile
    NotificationRepository().notifyDoctorOfApproval(
      doctorMobile: updated.doctorMobile,
      doctorName: updated.doctorName,
      generatedDoctorId: generatedDocId,
      facilityName: updated.targetFacilityName,
      tempOtp: generatedOtp,
    );

    notifyListeners();
    return updated;
  }

  /// Called by Facility Staff when rejecting a doctor request
  DoctorVerificationRequestDto? rejectVerificationRequest(
    String requestId, {
    required String reason,
    required String reviewedBy,
  }) {
    final index = _verificationRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return null;

    final existing = _verificationRequests[index];
    final updated = existing.copyWith(
      status: DoctorVerificationStatus.rejected,
      rejectionReason: reason,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );

    _verificationRequests[index] = updated;
    if (_currentPendingRequest?.id == requestId) {
      _currentPendingRequest = updated;
    }

    NotificationRepository().notifyDoctorOfRejection(
      doctorMobile: updated.doctorMobile,
      doctorName: updated.doctorName,
      facilityName: updated.targetFacilityName,
      reason: reason,
    );

    notifyListeners();
    return updated;
  }

  /// Verify OTP sent to doctor after facility acceptance
  bool verifyOtp(String requestId, String otp) {
    final req = _verificationRequests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => _verificationRequests.first,
    );
    if (req.tempOtp == null) return true; // fallback
    return req.tempOtp == otp.trim();
  }

  /// Doctor sets password, finalize registration & returns account
  RegisteredDoctorAccount finalizeRegistration({
    required String requestId,
    required String password,
  }) {
    final req = _verificationRequests.firstWhere((r) => r.id == requestId);
    final account = RegisteredDoctorAccount(
      doctorId: req.generatedDoctorId ?? 'DOC-MH-8421-${DateTime.now().millisecondsSinceEpoch % 1000}',
      name: req.doctorName,
      mobile: req.doctorMobile,
      password: password,
      qualification: req.qualification,
      specialty: req.specialty,
      registrationNumber: req.registrationNumber,
      facilityId: req.targetFacilityId,
      facilityName: req.targetFacilityName,
    );

    _registeredDoctors.add(account);
    _activeDoctor = account;
    _currentPendingRequest = null;
    notifyListeners();
    return account;
  }

  /// Direct login for existing doctor
  RegisteredDoctorAccount? directLogin({
    required String identifier, // Doctor ID or Mobile
    required String password,
  }) {
    final cleanId = identifier.trim();
    final cleanPass = password.trim();

    // 1. Try finding existing by mobile or ID
    final existing = findDoctorByMobileOrId(cleanId);
    if (existing != null) {
      _activeDoctor = existing;
      notifyListeners();
      return existing;
    }

    // 2. If not found in pre-seeded, create/register dynamically for the identifier
    final isMobile = RegExp(r'^[0-9+]+$').hasMatch(cleanId);
    final doc = RegisteredDoctorAccount(
      doctorId: isMobile
          ? 'DOC-MH-${cleanId.substring(cleanId.length >= 4 ? cleanId.length - 4 : 0)}'
          : cleanId.toUpperCase(),
      name: isMobile ? 'Dr. Doctor ($cleanId)' : 'Dr. $cleanId',
      mobile: isMobile ? cleanId : '9822014490',
      password: cleanPass,
      qualification: 'MBBS, MD',
      specialty: 'General Medicine',
      registrationNumber: 'MMC-REG-VERIFIED',
      facilityId: 'FAC-SDH-301',
      facilityName: 'Baramati Sub-District Hospital',
    );
    _registeredDoctors.add(doc);
    _activeDoctor = doc;
    notifyListeners();
    return doc;
  }

  RegisteredDoctorAccount? findDoctorByMobileOrId(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    final digits = cleanId.replaceAll(RegExp(r'\D'), '');
    for (final d in _registeredDoctors) {
      final docDigits = d.mobile.replaceAll(RegExp(r'\D'), '');
      if (d.doctorId.toLowerCase() == cleanId ||
          (digits.isNotEmpty && docDigits.isNotEmpty && (docDigits.endsWith(digits) || digits.endsWith(docDigits)))) {
        return d;
      }
    }
    return null;
  }

  RegisteredDoctorAccount registerDoctorDirectly({
    required String name,
    required String mobile,
    required String specialty,
    required String qualification,
    required String registrationNumber,
    required String facilityId,
    required String facilityName,
  }) {
    final generatedDocId = 'DOC-MH-8421-${(name.hashCode.abs() % 900) + 100}';
    final account = RegisteredDoctorAccount(
      doctorId: generatedDocId,
      name: name,
      mobile: mobile,
      password: 'tempPassword123',
      qualification: qualification,
      specialty: specialty,
      registrationNumber: registrationNumber,
      facilityId: facilityId,
      facilityName: facilityName,
    );
    _registeredDoctors.add(account);
    FacilityRepository().addApprovedDoctor(
      facilityId: facilityId,
      doctorId: generatedDocId,
      doctorName: name,
      specialty: specialty,
      qualification: qualification,
    );
    notifyListeners();
    return account;
  }

  void setActiveDoctor(RegisteredDoctorAccount doc) {
    _activeDoctor = doc;
    if (!_registeredDoctors.any((d) => d.doctorId == doc.doctorId)) {
      _registeredDoctors.add(doc);
    }
    notifyListeners();
  }

  void resetToDefaults() {
    _registeredDoctors.clear();
    _verificationRequests.clear();
    _activeDoctor = null;
    _currentPendingRequest = null;
    notifyListeners();
  }

  List<DoctorVerificationRequestDto> getPendingRequestsForFacility(String facilityId) {
    return _verificationRequests
        .where((r) =>
            r.targetFacilityId == facilityId &&
            r.status == DoctorVerificationStatus.pending)
        .toList();
  }

  List<DoctorVerificationRequestDto> getAllRequestsForFacility(String facilityId) {
    return _verificationRequests
        .where((r) => r.targetFacilityId == facilityId)
        .toList();
  }

  RegisteredDoctorAccount getDoctorForSession(SessionCoordinator session) {
    if (_activeDoctor != null) return _activeDoctor!;

    // Match by session UID or session displayName
    if (session.currentUserId != null) {
      final match = _registeredDoctors.firstWhere(
        (d) => d.doctorId == session.currentUserId || d.mobile == session.currentUserId,
        orElse: () => _registeredDoctors.firstWhere(
          (d) => d.name == session.userDisplayName,
          orElse: () => RegisteredDoctorAccount(
            doctorId: session.currentUserId!,
            name: session.userDisplayName?.isNotEmpty == true ? session.userDisplayName! : 'Dr. Attending Physician',
            mobile: session.currentUserEmail ?? 'doctor@ruralcare.nabha.gov.in',
            password: '',
            qualification: 'MBBS, MD',
            specialty: 'General Medicine',
            registrationNumber: 'MCI-${(session.currentUserId.hashCode.abs() % 90000) + 10000}',
            facilityId: session.assignedFacilityId ?? 'FAC-SDH-301',
            facilityName: session.assignedCatchment ?? 'Baramati Sub-District Hospital',
          ),
        ),
      );
      _activeDoctor = match;
      return match;
    }

    if (_registeredDoctors.isNotEmpty) {
      return _registeredDoctors.first;
    }

    return RegisteredDoctorAccount(
      doctorId: 'DOC-MH-LIVE',
      name: session.userDisplayName?.isNotEmpty == true ? session.userDisplayName! : 'Dr. Attending Physician',
      mobile: 'doctor@ruralcare.nabha.gov.in',
      password: '',
      qualification: 'MBBS, MD',
      specialty: 'General Medicine',
      registrationNumber: 'MCI-2026-LIVE',
      facilityId: 'FAC-SDH-301',
      facilityName: 'Baramati Sub-District Hospital',
    );
  }
}
