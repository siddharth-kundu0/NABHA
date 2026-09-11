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
  String _activeLanguage = 'English';
  bool _hasCompletedOnboarding = true;

  AppRole get activeRole => _activeRole;
  String get activeLanguage => _activeLanguage;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  void switchRole(AppRole role) {
    _activeRole = role;
    notifyListeners();
  }

  void switchLanguage(String lang) {
    _activeLanguage = lang;
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
}
