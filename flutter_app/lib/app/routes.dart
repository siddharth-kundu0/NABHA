import 'package:flutter/material.dart';

enum AppRole {
  patient,
  healthWorker,
  doctor,
  facilityStaff,
  admin;

  String get label {
    switch (this) {
      case AppRole.patient:
        return 'Patient View / नागरिक';
      case AppRole.healthWorker:
        return 'Health Worker (ASHA) / आरोग्य सेविका';
      case AppRole.doctor:
        return 'Doctor / Specialist / डॉक्टर';
      case AppRole.facilityStaff:
        return 'Facility Staff (Hospital) / रुग्णालय कर्मचारी';
      case AppRole.admin:
        return 'District Admin / जिल्हा प्रशासन';
    }
  }

  String get description {
    switch (this) {
      case AppRole.patient:
        return 'Locked navigation (Home, Appointments, Records, Referrals, Profile)';
      case AppRole.healthWorker:
        return 'Prioritized field task queue, BLE sensor reading, digital triage';
      case AppRole.doctor:
        return 'OPD queue, assisted teleconsultation, e-prescriptions, counter-referral';
      case AppRole.facilityStaff:
        return 'Bed capacity management, QR referral intake desk, live stock';
      case AppRole.admin:
        return 'District health analytics, facility capability registry, ABDM audit';
    }
  }
}

class SessionCoordinator extends ChangeNotifier {
  static final SessionCoordinator _instance = SessionCoordinator._internal();
  factory SessionCoordinator() => _instance;
  SessionCoordinator._internal();

  AppRole _activeRole = AppRole.patient;
  String _activeLanguage = 'en';
  bool _hasCompletedOnboarding = false;

  // Authenticated Firebase User Profile
  String? _currentUserId;
  String? _currentUserEmail;
  String? _assignedCatchment;
  String? _assignedFacilityId;
  String? _userDisplayName;

  // Accessibility & Privacy preferences
  bool _largerText = false;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _shareWithDoctors = true;
  bool _offlineRecordCache = true;
  bool _isOffline = false;

  AppRole get activeRole => _activeRole;
  String get activeLanguage => _activeLanguage;
  String get currentLanguage => _activeLanguage;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isOffline => _isOffline;

  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get assignedCatchment => _assignedCatchment;
  String? get assignedFacilityId => _assignedFacilityId;
  String? get userDisplayName => _userDisplayName;
  bool get isAuthenticated => _currentUserId != null;

  bool get largerText => _largerText;
  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;
  bool get shareWithDoctors => _shareWithDoctors;
  bool get offlineRecordCache => _offlineRecordCache;

  bool get isHindi => _activeLanguage == 'hi' || _activeLanguage == 'Hindi' || _activeLanguage == 'हिन्दी' || _activeLanguage == 'हिंदी';
  bool get isMarathi => _activeLanguage == 'mr' || _activeLanguage == 'Marathi' || _activeLanguage == 'मराठी';
  bool get isEnglish => !isHindi && !isMarathi;
  bool get isHi => isHindi;
  bool get isMr => isMarathi;
  bool get isEn => isEnglish;
  String get canonicalLanguageCode => isHindi ? 'hi' : (isMarathi ? 'mr' : 'en');

  void switchRole(AppRole role) {
    _activeRole = role;
    notifyListeners();
  }

  void switchLanguage(String lang) {
    _activeLanguage = lang;
    notifyListeners();
  }

  void setLanguage(String lang) => switchLanguage(lang);

  void toggleOffline([bool? val]) {
    _isOffline = val ?? !_isOffline;
    notifyListeners();
  }

  void toggleLargerText(bool val) {
    _largerText = val;
    notifyListeners();
  }

  void toggleHighContrast(bool val) {
    _highContrast = val;
    notifyListeners();
  }

  void toggleReduceMotion(bool val) {
    _reduceMotion = val;
    notifyListeners();
  }

  void toggleShareWithDoctors(bool val) {
    _shareWithDoctors = val;
    notifyListeners();
  }

  void toggleOfflineRecordCache(bool val) {
    _offlineRecordCache = val;
    notifyListeners();
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void resetToOnboarding() {
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  void setAuthenticatedUser({
    required String uid,
    String? email,
    required AppRole role,
    String? displayName,
    String? catchment,
    String? facilityId,
  }) {
    _currentUserId = uid;
    _currentUserEmail = email;
    _activeRole = role;
    _userDisplayName = displayName;
    _assignedCatchment = catchment;
    _assignedFacilityId = facilityId;
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void clearAuthenticatedUser() {
    _currentUserId = null;
    _currentUserEmail = null;
    _userDisplayName = null;
    _assignedCatchment = null;
    _assignedFacilityId = null;
    _hasCompletedOnboarding = false;
    notifyListeners();
  }
}
